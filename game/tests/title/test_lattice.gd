extends TestCase


func _interior(p: Vector3, size: float, margin: float) -> bool:
	return p.x > margin and p.y > margin and p.z > margin and p.x < size - margin and p.y < size - margin and p.z < size - margin


func _count_within(p: Vector3, pts: PackedVector3Array, r: float) -> int:
	var n := 0
	for q in pts:
		if q != p and p.distance_to(q) <= r:
			n += 1
	return n


func test_silica_bonds() -> void:
	var a := 7.16
	var s := Lattice.silica(Vector3i(3, 3, 3), a)
	var si: PackedVector3Array = s["si"]
	var o: PackedVector3Array = s["o"]
	var size := 3.0 * a
	var checked := 0
	var nearest := INF
	for p in si:
		if _interior(p, size, 2.0):
			assert_eq(_count_within(p, o, 1.7), 4, "Si at %s" % p)
			checked += 1
		for q in o:
			nearest = minf(nearest, p.distance_to(q))
	for q in o:
		if _interior(q, size, 2.0):
			assert_eq(_count_within(q, si, 1.7), 2, "O at %s" % q)
	assert_true(checked > 10, "enough interior Si to check")
	assert_near(nearest, 1.550, 1e-3)


func test_fcc_neighbors() -> void:
	var a := 3.615
	var pts := Lattice.fcc(Vector3i(3, 3, 3), a)
	var checked := 0
	for p in pts:
		if not _interior(p, 3.0 * a, a):
			continue
		var near := 0
		for q in pts:
			var d := p.distance_to(q)
			if q != p and d < 3.0:
				near += 1
				assert_near(d, 2.556, 1e-3)
		assert_eq(near, 12)
		checked += 1
	assert_true(checked > 0)
