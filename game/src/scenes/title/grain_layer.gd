class_name GrainLayer
extends TitleLayer
## A few grains of beach sand under a macro lens, 1 unit = 10 µm: rounded,
## frosted, see-through quartz with a few amber and dark mineral grains, lit
## like a studio photograph with a shallow depth of field. The zoom lands on
## the top of the middle grain, at the origin; below a view of 5 (50 µm) its
## pitted surface comes into view.

const STUDIO := "res://assets/third_party/polyhaven/hdri/studio_small_09_2k.hdr"
const PIT_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never;
uniform float fade = 0.0;
varying vec3 w;
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { w = VERTEX; }
void fragment() {
	vec2 p = w.xz * 1.6;
	vec2 cell = floor(p);
	float pit = 0.0;
	for (int i = -1; i <= 1; i++) { for (int j = -1; j <= 1; j++) {
		vec2 c = cell + vec2(float(i), float(j));
		vec2 o = c + vec2(hash2(c), hash2(c + 3.1));
		float r = 0.15 + 0.3 * hash2(c + 7.7);
		pit = max(pit, smoothstep(r, r * 0.3, length(p - o)));
	} }
	ALBEDO = mix(vec3(0.86, 0.84, 0.8), vec3(0.62, 0.6, 0.57), pit);
	ROUGHNESS = mix(0.45, 0.8, pit);
	ALPHA = fade * smoothstep(9.0, 4.0, length(w.xz));
}
"""

var _camera_attributes := CameraAttributesPractical.new()
var _pits: ShaderMaterial


func _init() -> void:
	layer_id = "title.grain"
	meters_per_unit = 1e-5
	min_view = 0.4
	max_view = 2000.0
	home_view = 150.0
	pitch = 38.0


func build() -> void:
	var quartz := StandardMaterial3D.new()
	quartz.albedo_color = Color(0.96, 0.95, 0.92, 0.46)
	quartz.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	quartz.roughness = 0.2
	quartz.clearcoat_enabled = true
	quartz.clearcoat = 0.5
	quartz.clearcoat_roughness = 0.35
	quartz.specular = 0.6
	quartz.rim_enabled = true
	quartz.rim = 0.35
	quartz.refraction_enabled = true
	quartz.refraction_scale = 0.04
	var amber := quartz.duplicate() as StandardMaterial3D
	amber.albedo_color = Color(0.86, 0.6, 0.36, 0.6)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.18, 0.16, 0.15)
	dark.roughness = 0.5
	var shell := StandardMaterial3D.new()
	shell.albedo_color = Color(0.95, 0.92, 0.86)
	shell.roughness = 0.6
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	# The middle grain: its top touches the origin, where the zoom lands.
	_grain(Vector3(0, -24.0, 0), 25.0, quartz, rng)
	for i in 34:
		var a := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(42.0, 230.0)
		var r := rng.randf_range(10.0, 26.0)
		var mat: Material = quartz
		var pick := rng.randf()
		if pick > 0.86:
			mat = amber
		elif pick > 0.8:
			mat = dark
		elif pick > 0.74:
			mat = shell
		_grain(Vector3(cos(a) * dist, -50.0 + r * 0.8 + rng.randf_range(-6.0, 6.0), sin(a) * dist), r, mat, rng)
	var bed := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6000, 6000)
	bed.mesh = plane
	var bed_mat := StandardMaterial3D.new()
	bed_mat.albedo_color = Color(0.66, 0.56, 0.43)
	bed_mat.roughness = 1.0
	bed.material_override = bed_mat
	bed.position.y = -52.0
	world.add_child(bed)
	var pits := MeshInstance3D.new()
	var disc := PlaneMesh.new()
	disc.size = Vector2(20, 20)
	pits.mesh = disc
	pits.position.y = 0.05
	_pits = GlobeLayer._shader(PIT_SHADER)
	pits.material_override = _pits
	world.add_child(pits)
	var key := DirectionalLight3D.new()
	key.light_energy = 0.8
	key.shadow_enabled = true
	world.add_child(key)
	key.look_at_from_position(Vector3(-300, 500, 300), Vector3.ZERO, Vector3.UP)
	var e := TitleLayer.hdri_environment(STUDIO, false, 0.7)
	e.background_color = Color(0.12, 0.11, 0.1)
	env.environment = e
	_camera_attributes.dof_blur_far_enabled = true
	_camera_attributes.dof_blur_near_enabled = true
	_camera_attributes.dof_blur_amount = 0.12
	env.camera_attributes = _camera_attributes


## Depth of field follows the focus, and the pitted surface fades in close up.
func on_view(_center: Vector2, view: float, distance: float) -> void:
	_camera_attributes.dof_blur_far_distance = distance * 1.25
	_camera_attributes.dof_blur_far_transition = distance * 0.8
	_camera_attributes.dof_blur_near_distance = distance * 0.65
	_camera_attributes.dof_blur_near_transition = distance * 0.3
	if _pits != null:
		_pits.set_shader_parameter("fade", clampf((5.0 - view) / 2.5, 0.0, 1.0))


## A grain worn round by the sea: a sphere pushed in and out by smooth noise,
## a little flattened.
func _grain(at: Vector3, r: float, mat: Material, rng: RandomNumberGenerator) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 1.1
	var sphere := SphereMesh.new()
	sphere.radial_segments = 40
	sphere.rings = 20
	var arrays := sphere.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var stretch := Vector3(rng.randf_range(0.85, 1.2), rng.randf_range(0.6, 0.85), rng.randf_range(0.85, 1.2))
	for i in verts.size():
		var v := verts[i].normalized()
		verts[i] = v * (1.0 + 0.16 * noise.get_noise_3dv(v * 1.5)) * stretch * r
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in idx:
		st.add_vertex(verts[i])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.position = at
	mi.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.0, TAU), rng.randf_range(-0.3, 0.3))
	if at == Vector3(0, -24.0, 0):
		mi.rotation = Vector3.ZERO
	world.add_child(mi)
