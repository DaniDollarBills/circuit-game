class_name CopperLayer
extends TitleLayer
## The copper in the wire, 1 unit = 1 Å: atoms (radius 1.28 Å) in their
## face-centered cubic lattice, and free electrons that jitter about with
## heat while drifting slowly the opposite way to conventional current.

const CAPTION := "Copper atoms sit in a neat grid called a crystal lattice. Electrons zip around them and drift slowly from − to +."
const STUDIO := "res://assets/third_party/polyhaven/hdri/studio_small_09_2k.hdr"
const CELLS := Vector3i(10, 10, 2)
const A := 3.615
const ELECTRONS := 60
const THERMAL := 9.0

var amps := 0.0
## Conventional current's direction in this layer's plane; electrons drift
## the other way.
var direction := Vector2.RIGHT

var _electrons: MultiMeshInstance3D
var _pos: PackedVector3Array = []
var _vel: PackedVector3Array = []
var _box := AABB()
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	layer_id = "wire.copper"
	meters_per_unit = 1e-10
	min_view = 15.0
	max_view = 60.0
	home_view = 40.0
	plane = "xy"
	navigable = true


func set_flow(current: float, dir: Vector2) -> void:
	amps = absf(current)
	direction = dir.normalized() if dir.length() > 1e-9 else Vector2.RIGHT


## Å per second the electrons drift on screen (not to scale: real drift is far
## slower), growing with the current.
static func drift_speed(current: float) -> float:
	return clampf(0.5 * log(absf(current) / 1e-5) / log(10.0), 0.0, 3.0) if absf(current) > 0.0 else 0.0


func build() -> void:
	var shift := -Vector3(CELLS) * A / 2.0
	var atoms := PackedVector3Array()
	for p in Lattice.fcc(CELLS, A):
		atoms.append(p + shift)
	_box = AABB(shift, Vector3(CELLS) * A)
	var ball := SphereMesh.new()
	ball.radius = 1.28
	ball.height = 2.56
	ball.radial_segments = 24
	ball.rings = 12
	ball.material = Materials.copper()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ball
	mm.instance_count = atoms.size()
	for i in atoms.size():
		mm.set_instance_transform(i, Transform3D(Basis(), atoms[i]))
	var lattice := MultiMeshInstance3D.new()
	lattice.multimesh = mm
	world.add_child(lattice)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(Palette.color("butter"))
	glow.emission_enabled = true
	glow.emission = Color(Palette.color("butter"))
	glow.emission_energy_multiplier = 1.4
	var dot := SphereMesh.new()
	dot.radius = 0.32
	dot.height = 0.64
	dot.material = glow
	var em := MultiMesh.new()
	em.transform_format = MultiMesh.TRANSFORM_3D
	em.mesh = dot
	em.instance_count = ELECTRONS
	_electrons = MultiMeshInstance3D.new()
	_electrons.multimesh = em
	world.add_child(_electrons)
	_rng.seed = 1897
	for i in ELECTRONS:
		_pos.append(_box.position + Vector3(_rng.randf(), _rng.randf(), _rng.randf()) * _box.size)
		_vel.append(_random_dir() * THERMAL)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.0
	world.add_child(key)
	key.look_at_from_position(Vector3(-20, 30, 40), Vector3.ZERO, Vector3.UP)
	var e := TitleLayer.hdri_environment(STUDIO, false, 0.8)
	e.background_color = Color(0.07, 0.06, 0.08)
	env.environment = e
	_process(0.0)


## Each electron wanders with heat and, on top of that, drifts against the
## conventional current; it wraps round inside the patch.
func _process(delta: float) -> void:
	if _electrons == null or not is_visible_in_tree():
		return
	var drift := -Vector3(direction.x, -direction.y, 0) * drift_speed(amps)
	for i in ELECTRONS:
		if _rng.randf() < delta * 4.0:
			_vel[i] = _random_dir() * THERMAL
		var p := _pos[i] + (_vel[i] + drift) * delta
		p = _box.position + (p - _box.position).posmodv(_box.size)
		_pos[i] = p
		_electrons.multimesh.set_instance_transform(i, Transform3D(Basis(), p))


## The net drift of the electrons in this layer's plane (for tests).
func drift_direction() -> Vector2:
	return -direction if drift_speed(amps) > 0.0 else Vector2.ZERO


func _random_dir() -> Vector3:
	return Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized()
