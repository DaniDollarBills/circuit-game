class_name SilicaLayer
extends TitleLayer
## Silica (SiO₂) as chemists draw it, 1 unit = 1 Å: silicon (tan, r 0.9) and
## oxygen (red, r 0.6) balls joined by thin sticks, each silicon at the
## center of a tetrahedron of four oxygens. Seen face-on; the next zoom opens
## on the silicon nearest the middle.

const STUDIO := "res://assets/third_party/polyhaven/hdri/studio_small_09_2k.hdr"
const SI_COLOR := "#F0C8A0"
const O_COLOR := "#FF0D0D"
const BOND := 1.7


func _init() -> void:
	layer_id = "title.silica"
	meters_per_unit = 1e-10
	min_view = 3.0
	max_view = 60.0
	home_view = 30.0
	plane = "xy"


func build() -> void:
	var patch := TitleChain.silica_patch()
	var si: PackedVector3Array = patch["si"]
	var o: PackedVector3Array = patch["o"]
	world.add_child(_balls(si, 0.9, _glossy(Color(SI_COLOR))))
	world.add_child(_balls(o, 0.6, _glossy(Color(O_COLOR))))
	var buckets := {}
	for p in si:
		var key := Vector3i((p / BOND).floor())
		if not buckets.has(key):
			buckets[key] = PackedVector3Array()
		buckets[key].append(p)
	var bonds: Array[Transform3D] = []
	var around := {}
	for q in o:
		var home := Vector3i((q / BOND).floor())
		var near := PackedVector3Array()
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					near.append_array(buckets.get(home + Vector3i(dx, dy, dz), PackedVector3Array()))
		for p in near:
			var d := q.distance_to(p)
			if d < BOND:
				if not around.has(p):
					around[p] = PackedVector3Array()
				around[p].append(q)
				var mid := (p + q) / 2.0
				var dir := (p - q).normalized()
				var axis := Vector3.UP.cross(dir)
				var b := Basis() if axis.length() < 1e-6 else Basis(axis.normalized(), Vector3.UP.angle_to(dir))
				bonds.append(Transform3D(b.scaled(Vector3(1, d, 1)), mid))
	var stick := CylinderMesh.new()
	stick.top_radius = 0.16
	stick.bottom_radius = 0.16
	stick.height = 1.0
	stick.radial_segments = 10
	stick.material = _glossy(Color(0.72, 0.72, 0.76))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = stick
	mm.instance_count = bonds.size()
	for i in bonds.size():
		mm.set_instance_transform(i, bonds[i])
	var sticks := MultiMeshInstance3D.new()
	sticks.multimesh = mm
	world.add_child(sticks)
	world.add_child(_tetrahedra(around))
	var key := DirectionalLight3D.new()
	key.light_energy = 0.8
	world.add_child(key)
	key.look_at_from_position(Vector3(-30, 40, 60), Vector3.ZERO, Vector3.UP)
	var e := TitleLayer.hdri_environment(STUDIO, false, 0.6)
	e.background_color = Color(0.07, 0.065, 0.1)
	env.environment = e


## Each silicon with its four oxygens drawn as a see-through tetrahedron, the
## way mineralogists show silica's framework.
static func _tetrahedra(around: Dictionary) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in around:
		var corners: PackedVector3Array = around[p]
		if corners.size() != 4:
			continue
		for face in [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]]:
			for k in face:
				st.add_vertex(corners[k])
	st.generate_normals()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(SI_COLOR, 0.22)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.4
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


static func _glossy(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.28
	m.metallic_specular = 0.7
	return m


static func _balls(pts: PackedVector3Array, r: float, mat: Material) -> MultiMeshInstance3D:
	var ball := SphereMesh.new()
	ball.radius = r
	ball.height = 2.0 * r
	ball.radial_segments = 24
	ball.rings = 12
	ball.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ball
	mm.instance_count = pts.size()
	for i in pts.size():
		mm.set_instance_transform(i, Transform3D(Basis(), pts[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	return mmi
