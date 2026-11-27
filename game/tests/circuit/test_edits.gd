extends TestCase


func test_add_part_returns_new_circuit_original_unchanged() -> void:
	var c := TestCircuits.compact_loop()
	var d := CircuitEdits.add_part(c, Part.make("S", "switch", 3, -6))
	assert_eq(c.parts.size(), 3)
	assert_eq(d.parts.size(), 4)
	assert_eq(d.find_part("S").kind, "switch")


func test_move_part() -> void:
	var c := TestCircuits.compact_loop()
	var d := CircuitEdits.move_part(c, "R1", 1, -5)
	assert_eq(Vector2i(d.find_part("R1").x, d.find_part("R1").y), Vector2i(1, -5))
	assert_eq(c.find_part("R1").x, -2)


func test_move_locked_is_noop() -> void:
	var c := TestCircuits.compact_loop()
	c.find_part("R1").locked = true
	var d := CircuitEdits.move_part(c, "R1", 9, 9)
	assert_eq(Vector2i(d.find_part("R1").x, d.find_part("R1").y), Vector2i(-2, -4))


func test_rotate_cycles() -> void:
	var c := TestCircuits.compact_loop()
	var seen: Array[int] = []
	for i in 4:
		c = CircuitEdits.rotate_part(c, "R1")
		seen.append(c.find_part("R1").rot)
	assert_eq(seen, [90, 180, 270, 0])


func test_delete_part_removes_its_wires() -> void:
	var c := TestCircuits.compact_loop()
	var d := CircuitEdits.delete_part(c, "R1")
	assert_eq(d.find_part("R1"), null)
	assert_eq(d.wires.size(), 1)
	assert_eq(d.wires[0].id, "w3")
	assert_eq(c.wires.size(), 3)


func test_delete_locked_part_noop() -> void:
	var c := TestCircuits.compact_loop()
	c.find_part("L1").locked = true
	assert_eq(CircuitEdits.delete_part(c, "L1").find_part("L1").id, "L1")


func test_set_props_on_locked_part() -> void:
	var c := TestCircuits.compact_loop()
	c.find_part("L1").locked = true
	var d := CircuitEdits.set_props(c, "L1", {"burnt": true})
	assert_eq(d.find_part("L1").props["burnt"], true)
	assert_eq(d.find_part("L1").props["color"], "red")
	assert_false(c.find_part("L1").props.has("burnt"))


func test_can_add_wire_reasons() -> void:
	var c := TestCircuits.compact_loop()
	assert_eq(CircuitEdits.can_add_wire(c, "R1", "a", "R1", "a"), "same pin")
	assert_eq(CircuitEdits.can_add_wire(c, "R1", "a", "B1", "pos"), "duplicate")
	assert_eq(CircuitEdits.can_add_wire(c, "R1", "zz", "B1", "pos"), "unknown pin")
	assert_eq(CircuitEdits.can_add_wire(c, "nope", "a", "B1", "pos"), "unknown pin")
	assert_eq(CircuitEdits.can_add_wire(c, "R1", "a", "L1", "cathode"), "")


func test_add_and_delete_wire() -> void:
	var c := TestCircuits.compact_loop()
	var d := CircuitEdits.add_wire(c, "R1", "a", "L1", "cathode")
	assert_eq(d.wires.size(), 4)
	var new_id := d.wires[3].id
	assert_eq(new_id, "w4")
	assert_eq(CircuitEdits.delete_wire(d, new_id).wires.size(), 3)


func test_delete_locked_wire_noop() -> void:
	var c := TestCircuits.compact_loop()
	c.find_wire("w1").locked = true
	assert_eq(CircuitEdits.delete_wire(c, "w1").wires.size(), 3)


func test_next_id_skips_existing() -> void:
	var c := Circuit.new()
	c.parts.append(Part.make("B1", "battery", 0, 0))
	c.parts.append(Part.make("R1", "resistor", 4, 0))
	c.wires.append(Wire.make("w1", "B1", "pos", "R1", "a"))
	c.wires.append(Wire.make("w2", "B1", "neg", "R1", "b"))
	assert_eq(CircuitEdits.next_id(c, "w"), "w3")
	assert_eq(CircuitEdits.next_id(c, "R"), "R2")
	assert_eq(CircuitEdits.next_id(c, "SW"), "SW1")
