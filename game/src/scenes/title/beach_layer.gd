class_name BeachLayer
extends TitleLayer
## Standing on the beach, 1 unit = 1 cm: real PBR sand, the sea rolling in
## with foam and wet sand where the waves reach, shells, and the little
## wooden shack that becomes your workshop. The next zoom lands on one grain at
## (0, 0).

const SKY := "res://assets/third_party/polyhaven/hdri/kloofendal_48d_partly_cloudy_puresky_2k.hdr"
const SAND := "res://assets/third_party/polyhaven/textures/sand_01/sand_01_%s_2k.jpg"
const WOOD := "res://assets/third_party/polyhaven/textures/wood_table_001/wood_table_001_%s_2k.jpg"
## The waterline sits this far west of the grain (cm).
const SHORE := -900.0

const SEA_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform float shore = -900.0;
varying vec3 w;
%s
void vertex() {
	w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float swell = sin(w.x * 0.012 + TIME * 1.1) * 6.0 + sin(w.z * 0.02 + TIME * 0.7) * 3.0;
	VERTEX.y += swell * smoothstep(shore - 300.0, shore - 1500.0, w.x);
}
void fragment() {
	float d = shore - w.x;                     // distance out to sea, cm
	float n = fbm(vec3(w.xz * 0.004, TIME * 0.05));
	float run = sin(w.x * 0.02 - TIME * 1.4 + n * 4.0);
	float foam = smoothstep(0.86, 1.0, run) * smoothstep(700.0, 60.0, d) * (0.4 + 0.6 * n) + smoothstep(90.0, 0.0, d + n * 70.0);
	vec3 water = mix(vec3(0.12, 0.36, 0.4), vec3(0.03, 0.15, 0.24), smoothstep(0.0, 3000.0, d));
	ALBEDO = mix(water, vec3(0.94, 0.96, 0.97), clamp(foam, 0.0, 1.0));
	ALPHA = clamp(smoothstep(-40.0, 120.0, d) + foam, 0.0, 1.0);
	ROUGHNESS = mix(0.06, 0.7, clamp(foam, 0.0, 1.0));
	NORMAL_MAP = vec3(0.5 + 0.1 * sin(w.x * 0.05 + TIME * 2.0 + n * 9.0), 0.5 + 0.1 * cos(w.z * 0.04 + TIME * 1.5), 1.0);
}
"""


func _init() -> void:
	layer_id = "title.beach"
	meters_per_unit = 0.01
	min_view = 1.5
	max_view = 30000.0
	home_view = 3000.0
	pitch = 74.0


func build() -> void:
	var sand := StandardMaterial3D.new()
	sand.albedo_texture = TitleLayer.load_texture(SAND % "diff")
	sand.normal_enabled = true
	sand.normal_texture = TitleLayer.load_texture(SAND % "nor_gl")
	sand.roughness_texture = TitleLayer.load_texture(SAND % "rough")
	sand.uv1_triplanar = true
	sand.uv1_world_triplanar = true
	sand.uv1_scale = Vector3.ONE / 120.0
	sand.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	sand.albedo_color = Color(0.86, 0.84, 0.8)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60000, 60000)
	ground.mesh = plane
	ground.material_override = sand
	world.add_child(ground)
	var seabed := MeshInstance3D.new()
	var bed := PlaneMesh.new()
	bed.size = Vector2(60000, 60000)
	seabed.mesh = bed
	seabed.material_override = sand
	# Hinged 2 m out from the waterline, dropping 4° out to sea.
	seabed.position = Vector3(SHORE - 200.0 - 30000.0 * cos(deg_to_rad(4.0)), -30000.0 * sin(deg_to_rad(4.0)), 0)
	seabed.rotation.z = deg_to_rad(4.0)
	world.add_child(seabed)
	ground.position.x = 30000.0 + SHORE - 200.0
	var sea := MeshInstance3D.new()
	var water := PlaneMesh.new()
	water.size = Vector2(60000, 60000)
	water.subdivide_width = 200
	water.subdivide_depth = 200
	sea.mesh = water
	sea.position = Vector3(SHORE - 30000.0 + 300.0, 0.8, 0)
	var m := GlobeLayer._shader(SEA_SHADER % GlobeLayer.NOISE)
	m.set_shader_parameter("shore", SHORE)
	sea.material_override = m
	world.add_child(sea)
	_add_shack()
	_add_shells()
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	world.add_child(sun)
	sun.look_at_from_position(Vector3(-600, 900, 500), Vector3.ZERO, Vector3.UP)
	var e := TitleLayer.hdri_environment(SKY)
	e.fog_enabled = true
	e.fog_light_color = Color(0.7, 0.78, 0.86)
	e.fog_density = 0.00004
	env.environment = e


## A small weathered shack: plank walls, a sloping roof, a door and a window.
func _add_shack() -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_texture = TitleLayer.load_texture(WOOD % "diff")
	wood.normal_enabled = true
	wood.normal_texture = TitleLayer.load_texture(WOOD % "nor_gl")
	wood.uv1_triplanar = true
	wood.uv1_scale = Vector3.ONE / 90.0
	wood.albedo_color = Color(0.85, 0.82, 0.78)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.16, 0.14, 0.13)
	var shack := Node3D.new()
	shack.position = Vector3(950, 0, -820)
	shack.rotation.y = deg_to_rad(-20.0)
	world.add_child(shack)
	_box(shack, Vector3(0, 115, 0), Vector3(300, 230, 240), wood)
	var roof := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(340, 12, 290)
	roof.mesh = slab
	roof.position = Vector3(0, 250, 0)
	roof.rotation.z = deg_to_rad(-9.0)
	roof.material_override = wood
	shack.add_child(roof)
	_box(shack, Vector3(-151, 95, 30), Vector3(4, 190, 80), dark)
	_box(shack, Vector3(-151, 150, -70), Vector3(4, 60, 70), dark)


func _box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = at
	mi.material_override = mat
	parent.add_child(mi)


func _add_shells() -> void:
	var shell := StandardMaterial3D.new()
	shell.albedo_color = Color(0.95, 0.88, 0.82)
	shell.roughness = 0.35
	shell.clearcoat_enabled = true
	shell.clearcoat = 0.4
	var rng := RandomNumberGenerator.new()
	rng.seed = 2025
	for i in 18:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = rng.randf_range(1.5, 3.5)
		s.height = s.radius * 0.9
		s.is_hemisphere = true
		mi.mesh = s
		mi.scale = Vector3(1.0, 0.55, rng.randf_range(0.8, 1.3))
		mi.rotation.y = rng.randf_range(0.0, TAU)
		mi.position = Vector3(rng.randf_range(-700.0, 500.0), 0.0, rng.randf_range(-500.0, 500.0))
		mi.material_override = shell
		world.add_child(mi)
