extends TestCase
## What the player just did, read from the circuit before and after a commit:
## Lesson 0 ticks its steps from these.


func _base() -> Circuit:
	var c := Levels.by_id("ch1.light-it-up").circuit.copy()
	for p in c.parts:
		p.locked = false
	return c


func test_placed() -> void:
	var before := _base()
	var after := CircuitEdits.add_part(before, Part.make("R2", "resistor", 2, 6))
	assert_eq(CircuitDiff.actions(before, after), PackedStringArray(["placed"]))


func test_moved() -> void:
	var before := _base()
	assert_eq(CircuitDiff.actions(before, CircuitEdits.move_part(before, "R1", 3, -4)), PackedStringArray(["moved"]))


func test_rotated() -> void:
	var before := _base()
	assert_eq(CircuitDiff.actions(before, CircuitEdits.rotate_part(before, "R1")), PackedStringArray(["rotated"]))


func test_wired() -> void:
	var before := _base()
	assert_eq(CircuitDiff.actions(before, CircuitEdits.add_wire(before, "B1", "pos", "R1", "a")), PackedStringArray(["wired"]))


func test_deleted() -> void:
	var wired := CircuitEdits.add_wire(_base(), "B1", "pos", "R1", "a")
	var wire_id := wired.wires[0].id
	assert_eq(CircuitDiff.actions(wired, CircuitEdits.delete_wire(wired, wire_id)), PackedStringArray(["deleted"]))
	assert_true("deleted" in CircuitDiff.actions(_base(), CircuitEdits.delete_part(_base(), "R1")))


func test_move_and_wire_in_one_commit() -> void:
	var before := _base()
	var after := CircuitEdits.add_wire(CircuitEdits.move_part(before, "R1", 3, -4), "B1", "pos", "R1", "a")
	var acts := CircuitDiff.actions(before, after)
	assert_true("moved" in acts and "wired" in acts, str(acts))


func test_no_change_no_action() -> void:
	assert_eq(CircuitDiff.actions(_base(), _base()), PackedStringArray())
