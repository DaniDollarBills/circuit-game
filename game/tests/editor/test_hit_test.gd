extends TestCase


func test_pin_beats_part_body() -> void:
	var c := TestCircuits.compact_loop()
	var a := Vector2(CircuitGeometry.pin_position(c.find_part("R1"), "a"))
	var h := HitTest.at(c, a + Vector2(0.2, 0), 0.35, 0.3)
	assert_eq(h["kind"], "pin")
	assert_eq(h["part"], "R1")
	assert_eq(h["pin"], "a")
	assert_eq(h["at"], a)


func test_part_rect_hit_rotated() -> void:
	var c := TestCircuits.compact_loop()
	assert_eq(HitTest.at(c, Vector2(6.3, 0.2), 0.35, 0.3)["part"], "L1", "the LED turned 90° stands upright")
	assert_eq(HitTest.at(c, Vector2(-2, -4.2), 0.35, 0.3)["kind"], "part")
	assert_eq(HitTest.at(c, Vector2(7.6, 0), 0.35, 0.3)["kind"], "empty")


func test_wire_hit_within_radius() -> void:
	var c := TestCircuits.compact_loop()
	var path := CircuitGeometry.wire_path(c, c.find_wire("w3"))
	var mid := (path[path.size() - 2] + path[path.size() - 1]) / 2.0
	var h := HitTest.at(c, mid + Vector2(0, 0.2), 0.35, 0.3)
	assert_eq(h["kind"], "wire")
	assert_eq(h["wire"], "w3")


func test_empty() -> void:
	assert_eq(HitTest.at(TestCircuits.compact_loop(), Vector2(30, 30), 0.35, 0.3)["kind"], "empty")
