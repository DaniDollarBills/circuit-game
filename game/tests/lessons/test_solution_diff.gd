extends TestCase


## L2-like level: battery and LED placed, resistors in the tray, the 150 Ω one
## in the solution with three wires.
func _pop_level() -> LevelDef:
	var b := LevelBuilder.new("test.pop", "ch1", "Pop!")
	b.part("B1", "battery", -6, 0).part("L1", "led", 6, 0, 90)
	b.tray("resistor", {"ohms": 47.0}).tray("resistor", {"ohms": 150.0}).tray("resistor", {"ohms": 220.0})
	b.solution_part("R1", "resistor", -2, -4, 0, {"ohms": 150.0})
	b.solution_wire("B1", "pos", "R1", "a").solution_wire("R1", "b", "L1", "anode").solution_wire("L1", "cathode", "B1", "neg")
	return b.done()


func test_builder_solution_has_tray_index_and_wires() -> void:
	var level := _pop_level()
	assert_eq(level.circuit.parts.size(), 2)
	assert_eq(level.solution.parts.size(), 3)
	assert_eq(level.solution.find_part("R1").tray, 1)
	assert_eq(level.solution.wires.size(), 3)
	assert_true(level.circuit.find_part("B1").locked)


func test_solution_diff_lists_missing_tray_part_and_wires() -> void:
	var level := _pop_level()
	var d := SolutionDiff.compute(level.circuit, level.solution)
	assert_eq(d["parts"].size(), 1)
	assert_eq(d["parts"][0].props["ohms"], 150.0)
	assert_eq(d["wires"].size(), 1)
	assert_eq(d["wires"][0], {"a_part": "L1", "a_pin": "cathode", "b_part": "B1", "b_pin": "neg"})


func test_solution_diff_ghost_wire_needs_both_ends() -> void:
	var level := _pop_level()
	var placed := Part.make("R7", "resistor", 0, -6, 0, {"ohms": 150.0})
	placed.tray = 1
	var current := CircuitEdits.add_part(level.circuit, placed)
	var d := SolutionDiff.compute(current, level.solution)
	assert_eq(d["parts"].size(), 0)
	assert_eq(d["wires"].size(), 3)
	assert_eq(d["wires"][0], {"a_part": "B1", "a_pin": "pos", "b_part": "R7", "b_pin": "a"})
	current = CircuitEdits.add_wire(current, "R7", "a", "B1", "pos")
	assert_eq(SolutionDiff.compute(current, level.solution)["wires"].size(), 2)


func test_solution_diff_props_and_removals() -> void:
	var b := LevelBuilder.new("test.props", "ch1", "Props")
	b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4, 0, {"ohms": 1000.0, "adjustable": true})
	b.part("L1", "led", 6, 0, 90)
	b.wire("w1", "B1", "pos", "R1", "a").wire("w2", "R1", "b", "L1", "anode").wire("w3", "L1", "cathode", "B1", "neg")
	b.wire("w_bad", "R1", "a", "L1", "cathode", false)
	b.solution_props("R1", {"ohms": 500.0}).solution_remove_wire("w_bad")
	var level := b.done()
	var d := SolutionDiff.compute(level.circuit, level.solution)
	assert_eq(d["props"], [{"part": "R1", "key": "ohms", "value": 500.0}])
	assert_eq(d["remove_wires"], PackedStringArray(["w_bad"]))
	assert_false(level.solution.find_wire("w_bad") != null)


## L4-like level: wide layout with w1 and w3 locked, one switch in the tray.
func _switch_level() -> LevelDef:
	var b := LevelBuilder.new("test.switch", "ch1", "On and off")
	b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4).part("L1", "led", 12, 0, 90)
	b.wire("w1", "B1", "pos", "R1", "a").wire("w3", "L1", "cathode", "B1", "neg")
	b.tray("switch", {"label": "S"})
	b.solution_part("SW1", "switch", 6, -4, 0, {"label": "S"})
	b.solution_wire("R1", "b", "SW1", "a").solution_wire("SW1", "b", "L1", "anode")
	return b.done()


func _solved_switch_circuit(level: LevelDef) -> Circuit:
	var sw := Part.make("SW9", "switch", 6, -4, 0, {"label": "S", "closed": true})
	sw.tray = 0
	var c := CircuitEdits.add_part(level.circuit, sw)
	c = CircuitEdits.add_wire(c, "R1", "b", "SW9", "a")
	return CircuitEdits.add_wire(c, "SW9", "b", "L1", "anode")


## Flipping a switch is testing, not building, so it never shows up as a change.
func test_solution_diff_empty_when_solved_with_switch_closed() -> void:
	var level := _switch_level()
	var d := SolutionDiff.compute(_solved_switch_circuit(level), level.solution)
	assert_eq(d["parts"].size(), 0)
	assert_eq(d["wires"].size(), 0)
	assert_eq(d["props"].size(), 0)
	assert_eq(d["remove_wires"].size(), 0)


func test_solution_diff_lists_extra_player_wire_for_removal() -> void:
	var level := _switch_level()
	var c := CircuitEdits.add_wire(_solved_switch_circuit(level), "R1", "b", "L1", "anode")
	var bypass := c.wires[c.wires.size() - 1].id
	assert_eq(SolutionDiff.compute(c, level.solution)["remove_wires"], PackedStringArray([bypass]))
