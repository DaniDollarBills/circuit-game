extends TestCase
## Lessons as data: the builder's course helpers, and the rules that keep a
## lesson teachable.


func _builder() -> LevelBuilder:
	var b := LevelBuilder.new("t.lesson", "ch1", "A lesson")
	b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4).part("L1", "led", 6, 0, 90)
	b.goal({"kind": "led_lit", "part": "L1"})
	return b


func _choices(correct: Array[bool], whys := ["a", "b", "c"]) -> Array:
	var out := []
	for i in correct.size():
		out.append({"text": "Choice %d" % i, "correct": correct[i], "why": whys[i] if i < whys.size() else ""})
	return out


func test_builder_records_cards() -> void:
	var b := _builder()
	b.learn_goals(["Why a loop", "What a resistor does"])
	b.idea("A loop.", "loop_flow", "wow", "More.", "A. Volta, Phil. Trans. 90, 403 (1800)")
	b.analogy("Like water.", "Water spills; charge doesn't.", "loop_gap")
	b.worked("Ohm's law.", ["I = V ÷ R", "I = 5 V ÷ 500 Ω", "I = 0.010 A"])
	b.meet("led")
	b.control("Turn the dial.", "battery_push")
	b.real("In every phone.")
	b.history("Ohm, 1827.", "G. S. Ohm, Die galvanische Kette, 1827")
	b.tour("This is the tray.", "tray")
	var l := b.done()
	assert_eq(l.learn_goals, PackedStringArray(["Why a loop", "What a resistor does"]))
	var types: Array = l.learn.map(func(c: Dictionary) -> String: return c["type"])
	assert_eq(types, ["idea", "analogy", "worked", "meet", "control", "real", "history", "tour"])
	assert_eq(l.learn[0]["diagram"], "loop_flow")
	assert_eq(l.learn[0]["mood"], "wow")
	assert_eq(l.learn[0]["deeper"], "More.")
	assert_eq(l.learn[0]["source"], "A. Volta, Phil. Trans. 90, 403 (1800)")
	assert_eq(l.learn[1]["breaks"], "Water spills; charge doesn't.")
	assert_eq(l.learn[2]["steps"], PackedStringArray(["I = V ÷ R", "I = 5 V ÷ 500 Ω", "I = 0.010 A"]))
	assert_eq(l.learn[3]["part"], "led")
	assert_eq(l.learn[4]["diagram"], "battery_push")
	assert_eq(l.learn[6]["source"], "G. S. Ohm, Die galvanische Kette, 1827")
	assert_eq(l.learn[7]["target"], "tray")
	assert_eq(l.deck_size(), 10, "a goals card, the eight cards and a closing card")
	assert_eq(LessonRules.problems(l), PackedStringArray())


func test_no_cards_no_deck() -> void:
	assert_eq(_builder().done().deck_size(), 0)


func test_why_attaches_to_last_step() -> void:
	var b := _builder()
	b.step("Wire + to the resistor.", {"kind": "connected", "a": "B1:pos", "b": "R1:a"}).why("Current starts at +.")
	b.step("Close the loop.", {"kind": "led_lit", "part": "L1"})
	var l := b.done()
	assert_eq(l.steps[0]["why"], "Current starts at +.")
	assert_eq(str(l.steps[1].get("why", "")), "")


func test_rules_flag_bad_question() -> void:
	var good := _builder()
	good.question("Which?", _choices([true, false, false]))
	assert_eq(LessonRules.problems(good.done()).size(), 0)
	var two := _builder()
	two.question("Which?", _choices([true, false]))
	assert_eq(LessonRules.problems(two.done()).size(), 1, "two choices")
	var both := _builder()
	both.question("Which?", _choices([true, true, false]))
	assert_eq(LessonRules.problems(both.done()).size(), 1, "two correct")
	var bare := _builder()
	bare.question("Which?", _choices([true, false, false], ["a", "", "c"]))
	assert_eq(LessonRules.problems(bare.done()).size(), 1, "a choice with no explanation")


func test_rules_flag_analogy_without_breaks() -> void:
	var b := _builder()
	b.analogy("Like water in pipes.", "", "")
	assert_eq(LessonRules.problems(b.done()).size(), 1)


func test_rules_flag_short_worked_example_and_bad_tour() -> void:
	var b := _builder()
	b.worked("One step is no example.", ["I = V ÷ R"])
	b.tour("Look here.", "nowhere")
	assert_eq(LessonRules.problems(b.done()).size(), 2)


func test_rules_flag_goal_count() -> void:
	var b := _builder()
	b.learn_goals(["Only one"])
	assert_eq(LessonRules.problems(b.done()).size(), 1)


func test_rules_flag_try_without_pokes() -> void:
	var b := _builder()
	b.try_it("Try it.")
	b.try_part("B1", "battery", -6, 0)
	b.try_path_edit(func(c: Circuit) -> Circuit: return c)
	var l := b.done()
	assert_true(l.has_try())
	assert_eq(LessonRules.problems(l).size(), 1, "a try with nothing to do")


func test_try_path_applies_edits_in_order() -> void:
	var b := _builder()
	b.try_it("Break it, then fix it.")
	b.try_part("B1", "battery", -6, 0).try_part("R1", "resistor", -2, -4, 0, {"ohms": 220.0}).try_part("L1", "led", 6, 0, 90)
	b.try_wire("w1", "B1", "pos", "R1", "a").try_wire("w2", "R1", "b", "L1", "anode").try_wire("w3", "L1", "cathode", "B1", "neg")
	b.poke("Delete a wire.", {"kind": "led_dark", "part": "L1"})
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.delete_wire(c, "w1"))
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.add_wire(c, "B1", "pos", "R1", "a"))
	var l := b.done()
	assert_eq(l.try_path.size(), 2)
	assert_eq(l.try_path[0].wires.size(), 2)
	assert_eq(l.try_path[1].wires.size(), 3)
	assert_eq(l.try_circuit.wires.size(), 3, "the try circuit itself is untouched")
	assert_eq(l.circuit.wires.size(), 0, "and so is the build circuit")
	assert_eq(LessonRules.problems(l), PackedStringArray())
