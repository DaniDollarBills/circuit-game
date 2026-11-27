class_name WireCloseupLayer
extends TitleLayer
## Inside the hook-up wire, 1 unit = 10 µm: a copper core 0.6 mm across in
## PVC insulation 1.4 mm across, with the insulation cut away along a stretch
## to show the core, under studio light with a macro lens's depth of field.
## Peach arrows (a teaching overlay) move the way conventional current flows.

const STUDIO := "res://assets/third_party/polyhaven/hdri/studio_small_09_2k.hdr"
const CORE_R := 30.0
const INSULATION_R := 70.0
const LENGTH := 6000.0
const CUT := 700.0
const ARROWS := 14
const ARROW_GAP := 160.0

## Conventional current, in amps (a size) and as a unit direction in this
## layer's plane.
var amps := 0.0
var direction := Vector2.RIGHT
## The next layer down, told the same current.
var copper: CopperLayer

var _wire: Node3D
var _arrows: Array[MeshInstance3D] = []
var _offset := 0.0
var _camera_attributes := CameraAttributesPractical.new()


func _init() -> void:
	layer_id = "wire.closeup"
	meters_per_unit = 1e-5
	min_view = 2.0
	max_view = 762.0
	home_view = 200.0
	pitch = 30.0
	navigable = true


func set_wire(current: float, dir: Vector2) -> void:
	amps = absf(current)
	direction = dir.normalized() if dir.length() > 1e-9 else Vector2.RIGHT
	if _wire != null:
		_wire.rotation.y = -atan2(direction.y, direction.x)
	if copper != null:
		copper.set_flow(amps, direction)


func build() -> void:
	_wire = Node3D.new()
	world.add_child(_wire)
	var core := MeshInstance3D.new()
	core.mesh = _tube(CORE_R, LENGTH, 0.0, TAU)
	core.material_override = Materials.copper()
	_wire.add_child(core)
	# Its own copy: the cutaway shows the insulation's inside, so no culling.
	var pvc := Materials.pvc(Color(Palette.color("signal_high")).darkened(0.1)).duplicate() as StandardMaterial3D
	pvc.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side in [-1.0, 1.0]:
		var whole := MeshInstance3D.new()
		whole.mesh = _tube(INSULATION_R, (LENGTH - CUT) / 2.0, 0.0, TAU, true)
		whole.position = Vector3(side * (CUT + (LENGTH - CUT) / 2.0) / 2.0, 0, 0)
		whole.material_override = pvc
		_wire.add_child(whole)
	# The cutaway: only the lower half of the insulation is left along CUT.
	var half := MeshInstance3D.new()
	half.mesh = _tube(INSULATION_R, CUT, PI, TAU, true)
	half.material_override = pvc
	_wire.add_child(half)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(Palette.color("peach"))
	glow.emission_enabled = true
	glow.emission = Color(Palette.color("peach"))
	glow.emission_energy_multiplier = 1.5
	var chevron := PrismMesh.new()
	chevron.size = Vector3(26, 46, 4)
	for i in ARROWS:
		var a := MeshInstance3D.new()
		a.mesh = chevron
		a.material_override = glow
		# Lying flat over the core, pointing along +x (the current's way).
		a.rotation = Vector3(-PI / 2.0, 0, -PI / 2.0)
		_wire.add_child(a)
		_arrows.append(a)
	var key := DirectionalLight3D.new()
	key.light_energy = 0.9
	world.add_child(key)
	key.look_at_from_position(Vector3(-200, 400, 300), Vector3.ZERO, Vector3.UP)
	var e := TitleLayer.hdri_environment(STUDIO, false, 0.7)
	e.background_color = Color(0.1, 0.09, 0.12)
	env.environment = e
	_camera_attributes.dof_blur_far_enabled = true
	_camera_attributes.dof_blur_amount = 0.1
	env.camera_attributes = _camera_attributes
	set_wire(amps, direction)
	_place_arrows()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_offset = fposmod(_offset + WireArt.dot_speed(amps) * 40.0 * delta, ARROW_GAP)
	_place_arrows()


## The view frames the copper's top surface, which the zoom goes into.
func focus_point(center: Vector2) -> Vector3:
	return Vector3(center.x, CORE_R, center.y)


func on_view(_center: Vector2, _view: float, distance: float) -> void:
	_camera_attributes.dof_blur_far_distance = distance * 1.3
	_camera_attributes.dof_blur_far_transition = distance


func _place_arrows() -> void:
	var still := amps < 1e-5
	for i in _arrows.size():
		var x := -ARROWS * ARROW_GAP / 2.0 + i * ARROW_GAP + _offset
		_arrows[i].position = Vector3(x, CORE_R + 30.0, 0)
		_arrows[i].visible = not still and absf(x) < CUT / 2.0 + 400.0


## A tube along x of radius r and length `len`, spanning angles a0..a1 around
## the axis, with end caps when `caps` (a ring for a partial tube's ends).
static func _tube(r: float, len: float, a0: float, a1: float, caps := true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 48
	var half := len / 2.0
	for i in n:
		var t0 := lerpf(a0, a1, float(i) / n)
		var t1 := lerpf(a0, a1, float(i + 1) / n)
		var p00 := Vector3(-half, r * sin(t0), r * cos(t0))
		var p01 := Vector3(half, r * sin(t0), r * cos(t0))
		var p10 := Vector3(-half, r * sin(t1), r * cos(t1))
		var p11 := Vector3(half, r * sin(t1), r * cos(t1))
		for v in [p00, p10, p11, p00, p11, p01]:
			st.set_normal(Vector3(0, v.y, v.z).normalized())
			st.add_vertex(v)
		if caps:
			for x in [-half, half]:
				var s := signf(x)
				st.set_normal(Vector3(s, 0, 0))
				var tri := [Vector3(x, 0, 0), Vector3(x, r * sin(t0), r * cos(t0)), Vector3(x, r * sin(t1), r * cos(t1))]
				if s < 0:
					tri = [tri[0], tri[2], tri[1]]
				for v in tri:
					st.add_vertex(v)
	return st.commit()
