class_name TitleLayer
extends ZoomLayer
## A 3D world in the title zoom. Layer units are world units. The camera looks
## at the layer's plane (the ground, or a face-on xy plane) from `pitch`
## degrees off its normal, framing `view` units of height around `center`.

var world: Node3D
var camera: Camera3D
var env: WorldEnvironment
## Degrees between the camera's line of sight and the plane's normal.
var pitch := 0.0
## "xz": layer (x, y) is the ground (x, z). "xy": layer (x, y) is (x, −y).
var plane := "xz"
var fov := 35.0
## True for layers the player zooms and pans by hand (the wire close-ups);
## the title drives its own layers.
var navigable := false

var _pointer: PointerInput


func _ready() -> void:
	super._ready()
	if navigable:
		_pointer = PointerInput.new()
		add_child(_pointer)
		_pointer.gesture.connect(_on_gesture)
	viewport.own_world_3d = true
	world = Node3D.new()
	viewport.add_child(world)
	camera = Camera3D.new()
	camera.fov = fov
	camera.current = true
	viewport.add_child(camera)
	env = WorldEnvironment.new()
	viewport.add_child(env)
	build()
	apply_view(view_center, home_view)


func _gui_input(event: InputEvent) -> void:
	if _pointer != null:
		_pointer.feed(event, PointerInput.now())
		accept_event()


## Wheel, pinch and drag move the shared zoom.
func _on_gesture(g: Dictionary) -> void:
	var stage := get_parent() as ZoomStage
	if stage == null:
		return
	match str(g["type"]):
		"zoom":
			stage.zoom_at_screen(float(g["factor"]), (g["at"] as Vector2) + position)
		"pan":
			stage.pan_screen(g["delta"])
		"drag_move":
			if g.has("delta"):
				stage.pan_screen(g["delta"])


func set_live(live: bool, interactive: bool) -> void:
	super.set_live(live, interactive)
	if not interactive and _pointer != null:
		_pointer.reset()


## Virtual: fill `world` and `env`.
func build() -> void:
	pass


## Virtual: react to a new view (depth of field, fades).
func on_view(_center: Vector2, _view: float, _distance: float) -> void:
	pass


func focus_point(center: Vector2) -> Vector3:
	return Vector3(center.x, 0, center.y) if plane == "xz" else Vector3(center.x, -center.y, 0)


func apply_view(center: Vector2, view: float) -> void:
	super.apply_view(center, view)
	if camera == null:
		return
	var d := view / 2.0 / tan(deg_to_rad(fov / 2.0))
	var p := deg_to_rad(pitch)
	var focus := focus_point(center)
	if plane == "xz":
		camera.position = focus + Vector3(0, d * cos(p), d * sin(p))
		camera.look_at(focus, Vector3.UP if pitch > 0.5 else Vector3.FORWARD)
	else:
		camera.position = focus + Vector3(0, d * sin(p), d * cos(p))
		camera.look_at(focus, Vector3.UP)
	camera.near = d * 0.01
	camera.far = d * 200.0
	on_view(center, view, d)


## An environment lit by an HDRI with ACES tone mapping. No glow: nothing in
## these scenes is emissive, and screen-wide bloom only washes them out.
static func hdri_environment(path: String, show_sky := true, energy := 1.0) -> Environment:
	var e := Environment.new()
	var sky := Sky.new()
	var mat := PanoramaSkyMaterial.new()
	mat.panorama = load(path)
	mat.energy_multiplier = energy
	sky.sky_material = mat
	e.sky = sky
	e.background_mode = Environment.BG_SKY if show_sky else Environment.BG_COLOR
	e.background_color = Color(0, 0, 0, 0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.ambient_light_sky_contribution = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 0.85
	return e


static func load_texture(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null
