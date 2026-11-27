extends TestCase


func test_wire_points_drop_into_holes_and_round_corners() -> void:
	var path := PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(4, 3)])
	var pts := WireMesh.points(path)
	var lift := 0.12
	var start := PartDims.grid_to_world(path[0])
	var end := PartDims.grid_to_world(path[2])
	assert_true(pts[0].y < 0.0 and is_equal_approx(pts[0].x, start.x) and is_equal_approx(pts[0].z, start.z), "drops into the first hole")
	assert_true(pts[1].is_equal_approx(Vector3(start.x, lift, start.z)))
	assert_true(pts[pts.size() - 1].y < 0.0 and is_equal_approx(pts[pts.size() - 1].x, end.x), "drops into the last hole")
	for i in range(1, pts.size() - 1):
		assert_near(pts[i].y, lift, 1e-6)
	var corner := PartDims.grid_to_world(path[1]) + Vector3(0, lift, 0)
	var arc_center := corner + Vector3(-0.15, 0, 0.15)
	var on_arc := 0
	for i in range(1, pts.size() - 1):
		assert_false(pts[i].is_equal_approx(corner), "the corner is rounded")
		if absf(pts[i].distance_to(arc_center) - 0.15) < 1e-4:
			on_arc += 1
	assert_true(on_arc >= 7, "at least 6 segments per 90°, got %d points" % on_arc)


func test_tube_mesh_follows_the_path() -> void:
	var pts := WireMesh.points(PackedVector2Array([Vector2(0, 0), Vector2(4, 0)]))
	var mesh := WireMesh.tube(pts, 0.7, 12)
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_true(verts.size() >= pts.size() * 12)
	var box := mesh.get_aabb()
	assert_near(box.size.x, 4 * 0.254 + 2 * 0.07, 0.01)


func test_wire_colors_red_black_by_battery_net() -> void:
	var c := TestCircuits.compact_loop()
	assert_eq(WireMesh.color_for(c, c.find_wire("w1"), 0), Color("#D2342B"))
	assert_eq(WireMesh.color_for(c, c.find_wire("w3"), 0), Color("#1E1E22"))
	assert_eq(WireMesh.color_for(c, c.find_wire("w2"), 0), Color("#E8C547"))
	assert_eq(WireMesh.color_for(c, c.find_wire("w2"), 1), Color("#4FA36B"))
	assert_eq(WireMesh.color_for(c, c.find_wire("w2"), 5), Color("#E8C547"), "the colors cycle")
	var sw := TestCircuits.compact_loop()
	sw.parts.append(Part.make("S1", "switch", 2, -7, 0, {"closed": true}))
	sw.wires.append(Wire.make("w8", "R1", "a", "S1", "a"))
	sw.wires.append(Wire.make("w9", "S1", "b", "L1", "cathode"))
	assert_eq(WireMesh.color_for(sw, sw.find_wire("w8"), 0), Color("#D2342B"))
	assert_eq(WireMesh.color_for(sw, sw.find_wire("w9"), 0), Color("#1E1E22"), "a closed switch doesn't recolor wires")
