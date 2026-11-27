class_name AtomLayer
extends TitleLayer
## One silicon atom, 1 unit = 1 pm: a nucleus of 14 protons and 14 neutrons
## inside a soft electron cloud whose density follows silicon's shells (2, 8
## and 4 electrons). `simple_picture` swaps the cloud for the classic drawing:
## rings of radius 50, 100 and 150 with 2, 8 and 4 electrons going round.

const GO_DEEPER := "Electrons don't orbit like tiny planets. This cloud shows where they're likely to be. The nucleus is drawn far too big: if this atom were a stadium, its nucleus would be a pea."
const SHELLS := [[50.0, 2, 16.0], [100.0, 8, 26.0], [150.0, 4, 34.0]]
const CLOUD_R := 230.0
## Ray-marches the cloud: density is the sum of the shells' electrons spread
## over their spheres, each blurred into a soft band.
const CLOUD_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec4 tint : source_color = vec4(0.62, 0.78, 1.0, 1.0);
uniform float strength = 520.0;
varying vec3 center_v;
float density(float r) {
	return 2.0 / 2500.0 * exp(-pow((r - 50.0) / 16.0, 2.0))
		+ 8.0 / 10000.0 * exp(-pow((r - 100.0) / 26.0, 2.0))
		+ 4.0 / 22500.0 * exp(-pow((r - 150.0) / 34.0, 2.0));
}
void vertex() { center_v = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz; }
void fragment() {
	vec3 dir = normalize(VERTEX);
	float b = dot(dir, center_v);
	float c = dot(center_v, center_v) - %f * %f;
	float h = b * b - c;
	if (h <= 0.0) { discard; }
	h = sqrt(h);
	float t0 = max(b - h, 0.0);
	float t1 = b + h;
	float sum = 0.0;
	float dt = (t1 - t0) / 32.0;
	for (int i = 0; i < 32; i++) {
		vec3 p = dir * (t0 + (float(i) + 0.5) * dt) - center_v;
		sum += density(length(p)) * dt;
	}
	ALBEDO = tint.rgb * 0.85 * (1.0 - exp(-sum * strength / 100.0));
}
"""

var simple_picture := false:
	set(value):
		simple_picture = value
		if _cloud != null:
			_cloud.visible = not value
			_rings.visible = value

var _cloud: MeshInstance3D
var _rings: Node3D
var _electrons: Array[Dictionary] = []


func _init() -> void:
	layer_id = "title.atom"
	meters_per_unit = 1e-12
	min_view = 200.0
	max_view = 400.0
	home_view = 400.0
	plane = "xy"


func build() -> void:
	_add_nucleus()
	_cloud = MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = CLOUD_R
	s.height = 2.0 * CLOUD_R
	s.radial_segments = 48
	s.rings = 24
	_cloud.mesh = s
	_cloud.material_override = GlobeLayer._shader(CLOUD_SHADER % [CLOUD_R, CLOUD_R])
	world.add_child(_cloud)
	_add_rings()
	simple_picture = simple_picture
	var key := DirectionalLight3D.new()
	key.light_energy = 1.2
	world.add_child(key)
	key.look_at_from_position(Vector3(-100, 150, 200), Vector3.ZERO, Vector3.UP)
	var e := TitleLayer.hdri_environment(SilicaLayer.STUDIO, false, 0.6)
	e.background_color = Color(0.04, 0.04, 0.08)
	env.environment = e


func _process(delta: float) -> void:
	if not simple_picture or not is_visible_in_tree():
		return
	for e in _electrons:
		e["angle"] += delta * float(e["speed"])
		(e["node"] as Node3D).position = Vector3(cos(e["angle"]), 0, sin(e["angle"])) * float(e["r"])


## 14 protons and 14 neutrons packed in a ball (drawn far too big to see
## otherwise).
func _add_nucleus() -> void:
	var proton := _glossy(Color("#E9787D"))
	var neutron := _glossy(Color("#9BA7BA"))
	var ball := SphereMesh.new()
	ball.radius = 6.0
	ball.height = 12.0
	for i in 28:
		var y := 1.0 - 2.0 * (i + 0.5) / 28.0
		var a := i * PI * (3.0 - sqrt(5.0))
		var r := sqrt(1.0 - y * y)
		var mi := MeshInstance3D.new()
		mi.mesh = ball
		mi.material_override = proton if i % 2 == 0 else neutron
		mi.position = Vector3(cos(a) * r, y, sin(a) * r) * (9.0 if i % 3 else 5.0)
		world.add_child(mi)


func _add_rings() -> void:
	_rings = Node3D.new()
	world.add_child(_rings)
	var line := StandardMaterial3D.new()
	line.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.albedo_color = Color(Palette.color("lavender"))
	var electron := StandardMaterial3D.new()
	electron.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	electron.albedo_color = Color(0.7, 0.85, 1.0)
	electron.emission_enabled = true
	electron.emission = Color(0.6, 0.8, 1.0)
	electron.emission_energy_multiplier = 2.0
	var dot := SphereMesh.new()
	dot.radius = 7.0
	dot.height = 14.0
	var tilts := [Vector3(70, 0, 10), Vector3(62, 35, 0), Vector3(55, -30, 15)]
	for s in SHELLS.size():
		var r: float = SHELLS[s][0]
		var ring_node := Node3D.new()
		ring_node.rotation_degrees = tilts[s]
		_rings.add_child(ring_node)
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = r - 0.9
		torus.outer_radius = r + 0.9
		torus.rings = 96
		ring.mesh = torus
		ring.material_override = line
		ring_node.add_child(ring)
		var n: int = SHELLS[s][1]
		for k in n:
			var e := MeshInstance3D.new()
			e.mesh = dot
			e.material_override = electron
			ring_node.add_child(e)
			_electrons.append({"node": e, "r": r, "angle": TAU * k / n, "speed": 1.6 / (s + 1)})
	_process(0.0)


static func _glossy(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.35
	return m
