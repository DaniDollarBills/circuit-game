class_name CoastLayer
extends TitleLayer
## A stretch of coast from a plane, 1 unit = 10 m: sea to the west with waves
## and foam, a sandy beach (an aerial beach photo), fields inland, a few
## houses, the cable landing station, and the undersea cable running out to
## sea (drawn glowing and labeled as a visualization). The beach at (0, 0) is
## where the next zoom lands.

## The cable's real radius: 4 m (0.4 units of 10 m).
const CABLE_REAL_RADIUS := 0.4
const SKY := "res://assets/third_party/polyhaven/hdri/kloofendal_48d_partly_cloudy_puresky_2k.hdr"
const BEACH := "res://assets/third_party/polyhaven/textures/aerial_beach_01/aerial_beach_01_diff_2k.jpg"

## The shoreline, x as a function of z (10 m units), passing x = 0 at z = 0.
const COAST_FN := """
float coast(float z) { return 620.0 * sin(z / 2600.0) + 210.0 * sin(z / 830.0 + 1.3) + 55.0 * sin(z / 190.0 + 0.4) + 12.0 * sin(z / 41.0 + 2.0) - 210.0 * sin(1.3) - 55.0 * sin(0.4) - 12.0 * sin(2.0); }
"""
const GROUND_SHADER := """
shader_type spatial;
uniform sampler2D beach : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 w;
%s
%s
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float d = w.x - coast(w.z);            // + inland, − out to sea (10 m units)
	float n = fbm(w * 0.01);
	// Sea: deep blue-green offshore, clearer over the sand, foam at the edge.
	vec3 sea = mix(vec3(0.02, 0.1, 0.18), vec3(0.08, 0.3, 0.36), smoothstep(-160.0, -4.0, d));
	sea = mix(sea, texture(beach, w.xz / 40.0).rgb * vec3(0.55, 0.75, 0.8), smoothstep(-6.0, -0.5, d) * 0.6);
	float swell = sin(w.x * 0.8 + TIME * 1.4 + n * 7.0);
	float foam = smoothstep(-2.5, -0.3, d) * (0.55 + 0.45 * swell) + smoothstep(0.8, 1.0, swell) * smoothstep(-14.0, -3.0, d) * 0.6;
	sea = mix(sea, vec3(0.9, 0.93, 0.94), clamp(foam, 0.0, 1.0));
	// Land: a narrow beach (the aerial photo), then hedged fields.
	vec3 sand = texture(beach, w.xz / 40.0).rgb;
	// Irregular fields: a grid bent by noise, cells of varied crops.
	vec2 warp = vec2(fbm(w * 0.004 + 3.0), fbm(w * 0.004 + 9.0)) * 3.0;
	vec2 fp = w.xz / vec2(34.0, 26.0) + warp;
	vec2 cell = floor(fp);
	float pick = h2(cell);
	vec3 crop = pick < 0.5 ? vec3(0.24, 0.34, 0.13) : (pick < 0.72 ? vec3(0.33, 0.4, 0.17) : (pick < 0.9 ? vec3(0.5, 0.46, 0.27) : vec3(0.38, 0.3, 0.2)));
	crop *= 0.88 + 0.24 * fbm(w * 0.08);
	vec2 edge = abs(fract(fp) - 0.5);
	vec3 fields = mix(crop, vec3(0.1, 0.16, 0.07), smoothstep(0.46, 0.5, max(edge.x, edge.y)));
	// Woods and moor at a larger scale, a town by the beach.
	float wood = smoothstep(0.58, 0.64, fbm(w * 0.0021 + 17.0));
	fields = mix(fields, vec3(0.09, 0.15, 0.07) * (0.8 + 0.4 * n), wood);
	float moor = smoothstep(0.6, 0.7, fbm(w * 0.0012 + 31.0));
	fields = mix(fields, vec3(0.36, 0.33, 0.24), moor * 0.7);
	float town = smoothstep(90.0, 30.0, length(vec2(d - 40.0, w.z - 10.0))) * step(0.45, h2(floor(w.xz / 2.5)));
	fields = mix(fields, vec3(0.62, 0.6, 0.58), town * 0.8);
	vec3 land = mix(sand, fields, smoothstep(2.5, 5.0, d + n * 2.0));
	float is_sea = 1.0 - smoothstep(-0.15, 0.15, d);
	ALBEDO = mix(land, sea, is_sea);
	ROUGHNESS = mix(0.95, 0.35, is_sea * (1.0 - clamp(foam, 0.0, 1.0)));
	SPECULAR = mix(0.25, 0.5, is_sea);
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), vec3(0.5 + 0.06 * sin(w.x * 2.1 + TIME * 1.3 + n * 9.0), 0.5 + 0.06 * cos(w.z * 1.7 + TIME), 1.0), is_sea);
}
"""


## The cable as drawn, in units (it widens as the view zooms out).
var cable_radius := CABLE_REAL_RADIUS
var _cable: MeshInstance3D
var _cable_pts := PackedVector3Array()

func _init() -> void:
	layer_id = "title.coast"
	meters_per_unit = 10.0
	min_view = 20.0
	max_view = 40000.0
	home_view = 4000.0
	pitch = 68.0


func build() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400000, 400000)
	ground.mesh = plane
	var m := GlobeLayer._shader(GROUND_SHADER % [GlobeLayer.NOISE, COAST_FN])
	m.set_shader_parameter("beach", TitleLayer.load_texture(BEACH))
	ground.material_override = m
	world.add_child(ground)
	_add_village()
	_add_cable()
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	world.add_child(sun)
	sun.look_at_from_position(Vector3(-400, 600, 300), Vector3.ZERO, Vector3.UP)
	var e := TitleLayer.hdri_environment(SKY)
	e.fog_enabled = true
	e.fog_light_color = Color(0.7, 0.78, 0.86)
	e.fog_density = 0.000035
	e.fog_aerial_perspective = 0.5
	env.environment = e


func _add_village() -> void:
	var walls := StandardMaterial3D.new()
	walls.albedo_color = Color(0.93, 0.91, 0.86)
	walls.roughness = 0.9
	var roofs := StandardMaterial3D.new()
	roofs.albedo_color = Color(0.32, 0.34, 0.38)
	roofs.roughness = 0.7
	var rng := RandomNumberGenerator.new()
	rng.seed = 5083
	for i in 26:
		var z := rng.randf_range(-60.0, 70.0)
		var x := _coast_x(z) + rng.randf_range(9.0, 40.0)
		_house(Vector3(x, 0, z), rng.randf_range(0.0, TAU), walls, roofs, Vector3(1.0, 0.6, 1.4) * rng.randf_range(0.8, 1.3))
	# The cable landing station: a plain windowless building in a fenced yard.
	var station := StandardMaterial3D.new()
	station.albedo_color = Color(0.78, 0.8, 0.82)
	_box(Vector3(_coast_x(4.0) + 8.0, 0.45, 4.0), Vector3(3.0, 0.9, 2.0), station)


func _house(at: Vector3, turn: float, walls: Material, roofs: Material, size: Vector3) -> void:
	var house := Node3D.new()
	house.position = at
	house.rotation.y = turn
	world.add_child(house)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	body.mesh = box
	body.position.y = size.y / 2.0
	body.material_override = walls
	house.add_child(body)
	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(size.x * 1.1, size.y * 0.7, size.z * 1.05)
	roof.mesh = prism
	roof.position.y = size.y + size.y * 0.35
	roof.material_override = roofs
	house.add_child(roof)


func _box(at: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = at
	mi.material_override = mat
	world.add_child(mi)


## The cable runs from the station across the beach and out to sea. Undersea
## cables really are buried near the shore and lie on the seabed beyond; the
## glow only shows where it is.
func _add_cable() -> void:
	var start := Vector3(_coast_x(4.0) + 8.0, 0.1, 4.0)
	_cable_pts.clear()
	for i in 41:
		var t := i / 40.0
		var x := lerpf(start.x, -900.0, t * t)
		_cable_pts.append(Vector3(x, 0.15 - 0.1 * t, lerpf(4.0, -40.0, t)))
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(Palette.color("peach"))
	glow.emission_enabled = true
	glow.emission = Color(Palette.color("peach"))
	glow.emission_energy_multiplier = 2.5
	_cable = MeshInstance3D.new()
	_cable.material_override = glow
	world.add_child(_cable)
	_set_cable_radius(cable_radius)
	var label := Label3D.new()
	label.text = "Undersea cable (visualization)"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true
	label.pixel_size = 0.00045
	label.font_size = 36
	label.outline_size = 8
	label.modulate = Color(Palette.color("ink"))
	label.outline_modulate = Color(Palette.color("paper"))
	# On the cable's middle, its text just above the line so the cable shows;
	# drawn over the ground rather than half buried in it.
	label.position = _cable_pts[_cable_pts.size() / 2]
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.offset = Vector2(0, 10)
	label.no_depth_test = true
	world.add_child(label)


## The real cable is 4 m across at most, far under a pixel from kilometres up:
## the visualization keeps it about 3 px wide at any zoom.
func on_view(_center: Vector2, view: float, _distance: float) -> void:
	if _cable == null or size.y < 1.0:
		return
	var want := maxf(CABLE_REAL_RADIUS, 1.5 * view / size.y)
	# Rebuilt only when the width is off by a quarter, not on every frame.
	if absf(log(want / cable_radius)) > log(1.25):
		_set_cable_radius(want)


func _set_cable_radius(r: float) -> void:
	cable_radius = r
	_cable.mesh = WireMesh.tube(_cable_pts, r / PartDims.mm(1.0), 6)


static func _coast_x(z: float) -> float:
	return 620.0 * sin(z / 2600.0) + 210.0 * sin(z / 830.0 + 1.3) + 55.0 * sin(z / 190.0 + 0.4) + 12.0 * sin(z / 41.0 + 2.0) \
			- 210.0 * sin(1.3) - 55.0 * sin(0.4) - 12.0 * sin(2.0)
