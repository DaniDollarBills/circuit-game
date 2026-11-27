extends TestCase


func _path(c: Circuit, wire_id: String) -> PackedVector2Array:
	return CircuitGeometry.wire_path(c, c.find_wire(wire_id))


func test_rotate_offset_cw() -> void:
	assert_eq(CircuitGeometry.rotate_offset(Vector2i(2, 0), 90), Vector2i(0, 2))
	assert_eq(CircuitGeometry.rotate_offset(Vector2i(2, 0), 180), Vector2i(-2, 0))
	assert_eq(CircuitGeometry.rotate_offset(Vector2i(2, 0), 270), Vector2i(0, -2))
	assert_eq(CircuitGeometry.rotate_offset(Vector2i(0, -2), 90), Vector2i(2, 0))


func test_led_rot90_pins() -> void:
	var led := Part.make("L1", "led", 4, 0, 90)
	assert_eq(CircuitGeometry.pin_position(led, "anode"), Vector2i(4, -1))
	assert_eq(CircuitGeometry.pin_position(led, "cathode"), Vector2i(4, 1))


func test_part_rect_rotated() -> void:
	var r := Part.make("R1", "resistor", 0, 0, 90)
	assert_eq(CircuitGeometry.part_rect(r), Rect2(-0.5, -2, 1, 4))


func test_pin_outward() -> void:
	assert_eq(CircuitGeometry.pin_outward(Part.make("R1", "resistor", 0, 0), "a"), Vector2i(-1, 0))
	assert_eq(CircuitGeometry.pin_outward(Part.make("B1", "battery", 0, 0), "pos"), Vector2i(0, -1))


func test_wire_path_compact_loop() -> void:
	var c := TestCircuits.compact_loop()
	assert_eq(_path(c, "w1"), PackedVector2Array([Vector2(-6, -2), Vector2(-6, -4), Vector2(-4, -4)]))
	assert_eq(_path(c, "w2"), PackedVector2Array([Vector2(0, -4), Vector2(6, -4), Vector2(6, -1)]))
	assert_eq(_path(c, "w3"), PackedVector2Array([Vector2(6, 1), Vector2(6, 3), Vector2(-6, 3), Vector2(-6, 2)]))


func test_wire_path_bracket() -> void:
	var c := Circuit.new()
	c.parts.append(Part.make("A", "switch", 4, -4))
	c.parts.append(Part.make("B", "switch", 4, -7))
	c.wires.append(Wire.make("w", "A", "a", "B", "a"))
	assert_eq(_path(c, "w"), PackedVector2Array([Vector2(2, -4), Vector2(1, -4), Vector2(1, -7), Vector2(2, -7)]))


func test_wire_path_via() -> void:
	var c := TestCircuits.compact_loop()
	var via: Array[Vector2i] = [Vector2i(-4, -6), Vector2i(9, -6), Vector2i(9, 1)]
	c.wires.append(Wire.make("w_bad", "R1", "a", "L1", "cathode", false, via))
	assert_eq(_path(c, "w_bad"), PackedVector2Array([
		Vector2(-4, -4), Vector2(-4, -6), Vector2(9, -6), Vector2(9, 1), Vector2(6, 1)]))


func test_one_watt_resistor_pins_wider() -> void:
	var r := Part.make("R1", "resistor", 0, 0, 0, {"watts": 1.0})
	assert_eq(CircuitGeometry.pin_position(r, "a"), Vector2i(-3, 0))
	assert_eq(CircuitGeometry.pin_position(r, "b"), Vector2i(3, 0))
	assert_eq(CircuitGeometry.part_rect(r), Rect2(-3, -0.5, 6, 1))
