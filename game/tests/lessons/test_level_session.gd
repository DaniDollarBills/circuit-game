extends TestCase


func _ctx(c: Circuit, flags := {}) -> Dictionary:
	var out := Simulator.simulate(c)
	return {"circuit": out.circuit, "sim": out.result, "zoom_layer": "editor", "zoom_seen": {}, "ui_flags": flags}


## Goals-only level: compact parts with no wires, a two-card learn deck, two
## steps, three hints.
func _light_level() -> LevelDef:
	var b := LevelBuilder.new("t.light", "ch1", "Light it up")
	b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4).part("L1", "led", 6, 0, 90)
	b.idea("Hi!").idea("Let's build.", "", "curious")
	b.goal({"kind": "led_lit", "part": "L1"}).goal({"kind": "no_short"})
	b.step("Wire + to the resistor.", {"kind": "connected", "a": "B1:pos", "b": "R1:a"})
	b.step("Press Test.", {"kind": "ui_flag", "flag": "tested"})
	b.hint("One").hint("Two", [{"part": "B1"}]).hint("Three", [], true)
	return b.done()


## Level with tests and no learn deck: one switch in the tray.
func _switch_level() -> LevelDef:
	var b := LevelBuilder.new("t.switch", "ch1", "On and off")
	b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4).part("L1", "led", 12, 0, 90)
	b.wire("w1", "B1", "pos", "R1", "a").wire("w3", "L1", "cathode", "B1", "neg")
	b.tray("switch", {"label": "S"})
	b.goal({"kind": "no_damage"}).goal({"kind": "uses", "part_kind": "switch", "min": 1})
	b.test("Switch off: LED off", [{"target": "S", "prop": "closed", "value": false}], [{"kind": "led_dark", "part": "L1"}])
	b.test("Switch on: LED on", [{"target": "S", "prop": "closed", "value": true}], [{"kind": "led_lit", "part": "L1"}])
	return b.done()


func _switch_wired(level: LevelDef) -> Circuit:
	var sw := Part.make("SW1", "switch", 6, -4, 0, {"label": "S"})
	sw.tray = 0
	var c := CircuitEdits.add_part(level.circuit, sw)
	c = CircuitEdits.add_wire(c, "R1", "b", "SW1", "a")
	return CircuitEdits.add_wire(c, "SW1", "b", "L1", "anode")


func test_learn_then_build() -> void:
	var level := _light_level()
	var s := LevelSession.start(level, true)
	assert_eq(s.level_id, "t.light")
	assert_eq(s.phase, "learn")
	assert_eq(s.card_index, 0)
	for i in 3:
		LevelSession.next_card(s, level)
	assert_eq(s.phase, "learn", "a goals card, two cards and a closing card")
	assert_eq(s.card_index, 3)
	LevelSession.next_card(s, level)
	assert_eq(s.phase, "build")
	assert_eq(LevelSession.start(_switch_level(), true).phase, "build", "no deck: straight to building")


func test_not_auto_starts_on_build() -> void:
	assert_eq(LevelSession.start(_light_level(), false).phase, "build")


func test_back_card_stops_at_zero() -> void:
	var level := _light_level()
	var s := LevelSession.start(level, true)
	LevelSession.back_card(s)
	assert_eq(s.card_index, 0)
	LevelSession.next_card(s, level)
	LevelSession.next_card(s, level)
	LevelSession.back_card(s)
	assert_eq(s.card_index, 1)
	assert_eq(s.phase, "learn")


func test_skip_learn_to_build() -> void:
	var level := _light_level()
	var s := LevelSession.start(level, true)
	LevelSession.next_card(s, level)
	LevelSession.skip_learn(s, level)
	assert_eq(s.phase, "build")
	LevelSession.skip_learn(s, level)
	assert_eq(s.phase, "build", "skipping when not learning does nothing")


func test_goals_only_level_passes_on_update() -> void:
	var level := _light_level()
	var s := LevelSession.start(level, true)
	LevelSession.update(s, level, _ctx(TestCircuits.compact_loop()))
	assert_eq(s.phase, "learn", "never passes while the lesson is showing")
	LevelSession.skip_learn(s, level)
	LevelSession.update(s, level, _ctx(level.circuit))
	assert_eq(s.phase, "build")
	assert_eq(s.goal_results.size(), 2)
	assert_false(s.goal_results[0]["pass"])
	LevelSession.update(s, level, _ctx(TestCircuits.compact_loop()))
	assert_eq(s.phase, "passed", "the unticked Press Test step doesn't block passing")


func test_tests_level_needs_run_tests() -> void:
	var level := _switch_level()
	var s := LevelSession.start(level, true)
	var c := _switch_wired(level)
	LevelSession.update(s, level, _ctx(c))
	assert_true(s.goal_results[0]["pass"] and s.goal_results[1]["pass"])
	assert_eq(s.phase, "build", "goals pass, but the tests haven't run yet")
	var bypass := CircuitEdits.add_wire(c, "R1", "b", "L1", "anode")
	LevelSession.run_tests(s, level, bypass, _ctx(bypass))
	assert_eq(s.phase, "build")
	assert_false(s.test_report["pass"])
	LevelSession.run_tests(s, level, c, _ctx(c))
	assert_true(s.test_report["pass"])
	assert_eq(s.phase, "passed")


func test_hint_tier_caps() -> void:
	var level := _light_level()
	var s := LevelSession.start(level, true)
	assert_false(s.used_hints)
	LevelSession.hint(s, level)
	assert_eq(s.hint_tier, 1)
	assert_true(s.used_hints)
	for i in 4:
		LevelSession.hint(s, level)
	assert_eq(s.hint_tier, 3)


func test_steps_tick_live() -> void:
	var level := _light_level()
	var s := LevelSession.start(level, true)
	LevelSession.update(s, level, _ctx(level.circuit))
	assert_eq(s.step_results.size(), 2)
	assert_false(s.step_results[0]["pass"])
	var one := TestCircuits.with_wire(level.circuit, "w1", "B1", "pos", "R1", "a")
	LevelSession.update(s, level, _ctx(one))
	assert_true(s.step_results[0]["pass"])
	assert_false(s.step_results[1]["pass"])
	LevelSession.update(s, level, _ctx(one, {"tested": true}))
	assert_true(s.step_results[1]["pass"])
