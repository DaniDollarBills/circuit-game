class_name GlobeLayer
extends TitleLayer
## The whole Earth, turned so Bude (UK) faces the camera. Layer units are
## kilometers on the plane touching the globe at Bude (x east, y south).
## Day texture: Natural Earth II (or flat land outlines if it's missing),
## with shiny oceans, a drifting cloud shell, a lilac rim of atmosphere, and
## seven undersea cables drawn as glowing arcs with pulses of light.

const RADIUS := 6371.0
const FOCUS := Vector2(50.83, -4.55)
const EARTH := "res://assets/third_party/naturalearth/natural_earth_ii_2048.jpg"
const CABLES := [
	[Vector2(40.71, -74.01), Vector2(50.83, -4.55)],
	[Vector2(36.85, -75.98), Vector2(43.26, -2.93)],
	[Vector2(-3.73, -38.52), Vector2(37.96, -8.87)],
	[Vector2(34.05, -118.24), Vector2(34.95, 139.95)],
	[Vector2(43.30, 5.37), Vector2(31.20, 29.92)],
	[Vector2(1.35, 103.82), Vector2(-31.95, 115.86)],
	[Vector2(19.08, 72.88), Vector2(23.59, 58.41)],
]
const CABLE_ALTITUDE := 20.0
const PULSES_PER_CABLE := 4

const EARTH_SHADER := """
shader_type spatial;
uniform sampler2D day : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
void fragment() {
	vec3 c = texture(day, UV + vec2(0.5, 0.0)).rgb;
	float ocean = smoothstep(0.02, 0.14, c.b - max(c.r, c.g));
	ALBEDO = c;
	ROUGHNESS = mix(0.92, 0.42, ocean);
	SPECULAR = mix(0.15, 0.5, ocean);
}
"""
const NOISE := """
float hash(vec3 q) { q = fract(q * 0.3183099 + 0.1); q *= 17.0; return fract(q.x * q.y * q.z * (q.x + q.y + q.z)); }
float noise(vec3 x) {
	vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
float fbm(vec3 x) { float v = 0.0; float a = 0.5; for (int i = 0; i < 6; i++) { v += a * noise(x); x *= 2.03; a *= 0.5; } return v; }
"""
const CLOUD_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, specular_disabled;
uniform float coverage = 0.44;
varying vec3 p;
%s
void vertex() { p = VERTEX / %f; }
void fragment() {
	vec3 q = p * 3.2 + vec3(TIME * 0.004, 0.0, 0.0);
	float n = fbm(q + fbm(q * 2.1) * 0.7);
	float band = coverage + 0.1 * cos(abs(p.y) * 6.0);
	ALBEDO = vec3(1.0);
	ALPHA = smoothstep(band, band + 0.2, n) * 0.9;
	ROUGHNESS = 1.0;
}
"""
const RIM_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
uniform vec4 rim : source_color = vec4(0.80, 0.72, 0.96, 1.0);
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = rim.rgb * f * 1.3;
}
"""
const STAR_SHADER := """
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never;
varying vec3 dir;
float hash(vec3 q) { q = fract(q * 0.3183099 + 0.1); q *= 17.0; return fract(q.x * q.y * q.z * (q.x + q.y + q.z)); }
void vertex() { dir = VERTEX; }
void fragment() {
	vec3 d = normalize(dir) * 380.0;
	vec3 cell = floor(d);
	float h = hash(cell);
	float star = step(0.986, h) * smoothstep(0.14, 0.0, length(fract(d) - 0.5));
	ALBEDO = vec3(0.01, 0.012, 0.025) + vec3(star) * (0.5 + 0.5 * hash(cell + 7.0));
}
"""

var earth: Node3D
var _cables: Array[PackedVector3Array] = []
var _pulses: MultiMeshInstance3D
var _land_viewport: SubViewport


func _init() -> void:
	layer_id = "title.globe"
	meters_per_unit = 1000.0
	min_view = 300.0
	max_view = 40000.0
	home_view = 30000.0


func build() -> void:
	earth = Node3D.new()
	earth.name = "Earth"
	var up := Geo.to_vec3(FOCUS.x, FOCUS.y, 1.0)
	var lon := deg_to_rad(FOCUS.y)
	var east := Vector3(cos(lon), 0, -sin(lon))
	var north := up.cross(east)
	# Rows east, north, up: Bude ends up on +z with north up.
	earth.transform.basis = Basis(east, north, up).transposed()
	world.add_child(earth)
	_add_sphere(RADIUS, _earth_material(), 128, 64)
	_add_sphere(RADIUS + 12.0, _shader(CLOUD_SHADER % [NOISE, RADIUS + 12.0]), 96, 48)
	_add_sphere(RADIUS * 1.025, _shader(RIM_SHADER), 96, 48)
	var stars := MeshInstance3D.new()
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 400000.0
	star_mesh.height = 800000.0
	stars.mesh = star_mesh
	stars.material_override = _shader(STAR_SHADER)
	world.add_child(stars)
	_add_cables()
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.7
	world.add_child(sun)
	sun.look_at_from_position(Vector3(-0.55, 0.45, 0.7) * 100000.0, Vector3.ZERO, Vector3.UP)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.01, 0.012, 0.025)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.25, 0.28, 0.4)
	e.ambient_light_energy = 0.12
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.glow_enabled = true
	e.glow_hdr_threshold = 1.0
	e.glow_intensity = 0.8
	for level in 7:
		e.set_glow_level(level, 1.0 if level < 3 else 0.0)
	env.environment = e


func _process(delta: float) -> void:
	if _pulses == null or not is_visible_in_tree():
		return
	var mm := _pulses.multimesh
	var t := Time.get_ticks_msec() / 1000.0
	for c in _cables.size():
		for k in PULSES_PER_CABLE:
			var f := fposmod(t * 0.07 + float(k) / PULSES_PER_CABLE + c * 0.13, 1.0)
			mm.set_instance_transform(c * PULSES_PER_CABLE + k, Transform3D(Basis(), _along(_cables[c], f)))


## The camera looks straight down at the plane touching Bude, `view` km tall.
func apply_view(center: Vector2, view: float) -> void:
	view_center = center
	view_height = view
	if camera == null:
		return
	var d := view / 2.0 / tan(deg_to_rad(fov / 2.0))
	var focus := Vector3(center.x, -center.y, RADIUS)
	camera.position = focus + Vector3(0, 0, d)
	camera.look_at(focus, Vector3.UP)
	camera.near = maxf(d * 0.01, 0.5)
	camera.far = maxf(d * 200.0, 1000000.0)


func _earth_material() -> Material:
	var tex := TitleLayer.load_texture(EARTH)
	if tex == null:
		# The flat land-outline map stands in for the photo.
		var land := LandTexture.build(LandTexture.load_polygons())
		_land_viewport = land.get_meta("viewport")
		add_child(_land_viewport)
		tex = land
	var m := _shader(EARTH_SHADER)
	m.set_shader_parameter("day", tex)
	return m


func _add_sphere(r: float, mat: Material, segments: int, rings: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = 2.0 * r
	s.radial_segments = segments
	s.rings = rings
	mi.mesh = s
	mi.material_override = mat
	earth.add_child(mi)
	return mi


func _add_cables() -> void:
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(Palette.color("peach"))
	glow.emission_enabled = true
	glow.emission = Color(Palette.color("peach"))
	glow.emission_energy_multiplier = 3.0
	for pair in CABLES:
		var pts := Geo.great_circle(pair[0], pair[1], RADIUS + CABLE_ALTITUDE, 96)
		_cables.append(pts)
		var tube := MeshInstance3D.new()
		# WireMesh works in millimeters of a 1 cm world: 160 → 16 km here,
		# far thicker than a real cable so it shows from orbit.
		tube.mesh = WireMesh.tube(pts, 160.0, 6)
		tube.material_override = glow
		earth.add_child(tube)
	var pulse := StandardMaterial3D.new()
	pulse.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pulse.albedo_color = Color(1.0, 0.95, 0.85)
	pulse.emission_enabled = true
	pulse.emission = Color(1.0, 0.92, 0.8)
	pulse.emission_energy_multiplier = 6.0
	var dot := SphereMesh.new()
	dot.radius = 45.0
	dot.height = 90.0
	dot.material = pulse
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = CABLES.size() * PULSES_PER_CABLE
	mm.mesh = dot
	_pulses = MultiMeshInstance3D.new()
	_pulses.multimesh = mm
	earth.add_child(_pulses)
	_process(0.0)


static func _along(pts: PackedVector3Array, f: float) -> Vector3:
	var x := f * (pts.size() - 1)
	var i := mini(int(x), pts.size() - 2)
	return pts[i].lerp(pts[i + 1], x - i)


static func _shader(code: String) -> ShaderMaterial:
	var s := Shader.new()
	s.code = code
	var m := ShaderMaterial.new()
	m.shader = s
	return m
