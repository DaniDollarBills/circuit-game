class_name WireMesh
extends RefCounted
## Jumper wires as they really sit on a perfboard: down into a hole at each end,
## and a little above the board in between, with rounded bends.

const RED := "#D2342B"
const BLACK := "#1E1E22"
const CYCLE := ["#E8C547", "#4FA36B", "#3D7CC9", "#EDEDED", "#E8833A"]
const CORNER_MM := 1.5


## The wire's centerline in world units: a drop into the first hole, the path
## `lift_mm` above the board with rounded corners, and a drop into the last hole.
static func points(path: PackedVector2Array, lift_mm := 1.2) -> PackedVector3Array:
	var out := PackedVector3Array()
	if path.size() < 2:
		return out
	var lift := Vector3(0, PartDims.mm(lift_mm), 0)
	var hole := Vector3(0, -PartDims.mm(PartDims.BOARD_THICK) / 2.0, 0)
	var flat := PackedVector3Array()
	for p in path:
		flat.append(PartDims.grid_to_world(p) + lift)
	out.append(flat[0] - lift + hole)
	out.append_array(fillet(flat, PartDims.mm(CORNER_MM)))
	out.append(flat[flat.size() - 1] - lift + hole)
	return out


## Rounds every interior corner of a polyline with radius `r` (smaller where a
## segment is too short), at least 6 segments per 90°.
static func fillet(pts: PackedVector3Array, r: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	if pts.size() < 3:
		return pts.duplicate()
	out.append(pts[0])
	for i in range(1, pts.size() - 1):
		var d_in := (pts[i] - pts[i - 1]).normalized()
		var d_out := (pts[i + 1] - pts[i]).normalized()
		var turn := d_in.angle_to(d_out)
		if turn < 1e-4:
			out.append(pts[i])
			continue
		var t := r * tan(turn / 2.0)
		var room := minf(pts[i].distance_to(pts[i - 1]), pts[i].distance_to(pts[i + 1])) / 2.0
		var radius := r
		if t > room:
			radius = room / tan(turn / 2.0)
			t = room
		var a := pts[i] - d_in * t
		var b := pts[i] + d_out * t
		var inward := (d_out - d_in * d_in.dot(d_out)).normalized()
		var center := a + inward * radius
		var n := maxi(6, ceili(6.0 * turn / (PI / 2.0)))
		var u := a - center
		var v := b - center
		for k in n + 1:
			out.append(center + u.slerp(v, float(k) / n))
	out.append(pts[pts.size() - 1])
	return out


## A round tube along `points` (a square one with sides = 4).
static func tube(points: PackedVector3Array, radius_mm := 0.7, sides := 12) -> ArrayMesh:
	var r := PartDims.mm(radius_mm)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var count := points.size()
	if count < 2:
		return ArrayMesh.new()
	var prev_normal := Vector3.ZERO
	for i in count:
		var tangent: Vector3
		if i == 0:
			tangent = points[1] - points[0]
		elif i == count - 1:
			tangent = points[i] - points[i - 1]
		else:
			tangent = (points[i] - points[i - 1]).normalized() + (points[i + 1] - points[i]).normalized()
		tangent = tangent.normalized()
		var normal: Vector3
		if i == 0:
			normal = tangent.cross(Vector3.UP if absf(tangent.y) < 0.9 else Vector3.RIGHT).normalized()
		else:
			normal = (prev_normal - tangent * prev_normal.dot(tangent)).normalized()
		prev_normal = normal
		var binormal := tangent.cross(normal)
		for s in sides:
			var a := TAU * (s + (0.5 if sides == 4 else 0.0)) / sides
			var radial := normal * cos(a) + binormal * sin(a)
			verts.append(points[i] + radial * r)
			normals.append(radial)
	for i in count - 1:
		for s in sides:
			var a0 := i * sides + s
			var a1 := i * sides + (s + 1) % sides
			var b0 := a0 + sides
			var b1 := a1 + sides
			indices.append_array([a0, b0, a1, a1, b0, b1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Red when either end is on a battery's + net, black on a − net, otherwise
## the next of yellow, green, blue, white and orange. Nets follow wires only,
## so flipping a switch never recolors a wire.
static func color_for(c: Circuit, w: Wire, index: int) -> Color:
	var nets := SolutionDiff.Nets.new()
	for x in c.wires:
		nets.join(Netlist.key(x.a_part, x.a_pin), Netlist.key(x.b_part, x.b_pin))
	var ends := [Netlist.key(w.a_part, w.a_pin), Netlist.key(w.b_part, w.b_pin)]
	for sign in [["pos", RED], ["neg", BLACK]]:
		for p in c.parts:
			if p.kind == "battery":
				for e in ends:
					if nets.same(e, Netlist.key(p.id, sign[0])):
						return Color(sign[1])
	return Color(CYCLE[posmod(index, CYCLE.size())])
