extends TestCase


func _state() -> GameState:
	var s := GameState.new()
	s.progress = Progress.defaults()
	s.now_fn = func() -> int: return 1000
	return s


func _start(s: GameState, id: String) -> LevelDef:
	var level := Levels.by_id(id)
	s.start_level(level)
	while s.session.phase == "intro":
		s.next_intro()
	return level


func _events(s: GameState, type: String) -> Array:
	return s.take_events().filter(func(e: Dictionary) -> bool: return e["type"] == type)


func _direct_led(level: LevelDef) -> Circuit:
	var c := level.circuit.copy()
	c.wires.append(Wire.make("w1", "B1", "pos", "L1", "anode"))
	c.wires.append(Wire.make("w2", "L1", "cathode", "B1", "neg"))
	return c


func test_start_level_uses_draft() -> void:
	var s := _state()
	var level := Levels.by_id("ch1.light-it-up")
	s.progress.drafts[level.id] = CircuitIO.to_dict(TestCircuits.with_wire(level.circuit, "w1", "B1", "pos", "R1", "a"))
	s.start_level(level)
	assert_eq(s.history.present.wires.size(), 1)
	s.progress.drafts[level.id] = {"format": 99}
	s.start_level(level)
	assert_eq(s.history.present.wires.size(), 0, "an unreadable draft falls back to the start circuit")
	var foreign := Circuit.new()
	foreign.parts.append(Part.make("X1", "resistor", 0, 0))
	s.progress.drafts[level.id] = CircuitIO.to_dict(foreign)
	s.start_level(level)
	assert_true(s.history.present.find_part("B1") != null, "a draft missing the level's own parts is ignored")


func test_commit_burn_stores_burnt_circuit_and_event() -> void:
	var s := _state()
	var level := _start(s, "ch1.pop")
	s.take_events()
	s.commit(_direct_led(level))
	assert_true(s.history.present.find_part("L1").props.get("burnt", false))
	var burns := s.take_events().filter(func(e: Dictionary) -> bool: return e["type"] == "burnt")
	assert_eq(burns, [{"type": "burnt", "part": "L1", "reason": "overcurrent"}])
	assert_eq(s.progress.stats["parts_burnt"], 1)


func test_undo_after_burn_restores_part() -> void:
	var s := _state()
	var level := _start(s, "ch1.pop")
	s.commit(_direct_led(level))
	s.take_events()
	assert_true(s.undo())
	assert_false(s.history.present.find_part("L1").props.get("burnt", false))
	assert_false(s.outcome.circuit.find_part("L1").props.get("burnt", false))
	assert_eq(s.outcome.damage.size(), 0)
	assert_eq(_events(s, "burnt").size(), 0, "undo raises no new burn")
	assert_true(s.redo())
	assert_true(s.outcome.circuit.find_part("L1").props.get("burnt", false))
	assert_eq(_events(s, "burnt").size(), 0, "redo shows the burnt part without burning it again")


func test_l1_solution_passes_and_unlocks_l2() -> void:
	var s := _state()
	var level := _start(s, "ch1.light-it-up")
	s.commit(level.solution)
	assert_eq(s.session.phase, "passed")
	assert_true(s.progress.completed.has(level.id))
	assert_true(s.progress.is_unlocked("ch1.pop", Levels.chapter_ids("ch1")))
	assert_eq(_events(s, "passed").size(), 1)


func test_l2_star_with_150() -> void:
	var s := _state()
	var level := _start(s, "ch1.pop")
	s.commit(level.solution)
	assert_true(s.progress.completed["ch1.pop"]["star"])


func test_zoom_goal_passes_on_layer() -> void:
	var s := _state()
	_start(s, "ch1.inside-the-wire")
	s.set_zoom_layer("wire.copper")
	assert_eq(s.session.phase, "passed")


func test_ui_flag_ticks_step() -> void:
	var s := _state()
	_start(s, "ch1.pop")
	assert_false(s.session.step_results[0]["pass"])
	s.set_ui_flag("datasheet:L1")
	assert_true(s.session.step_results[0]["pass"])


func test_zoom_seen_keeps_closeup_step() -> void:
	var s := _state()
	_start(s, "ch1.inside-the-wire")
	s.set_zoom_layer("wire.closeup")
	s.set_zoom_layer("wire.copper")
	assert_true(s.session.step_results[0]["pass"] and s.session.step_results[1]["pass"])


func test_badge_event_on_first_light() -> void:
	var s := _state()
	var level := _start(s, "ch1.light-it-up")
	s.commit(level.solution)
	var badges := _events(s, "badge")
	assert_eq(badges, [{"type": "badge", "id": "first_light"}])
	assert_eq(s.progress.achievements["first_light"], 1000)


func test_magic_smoke_badge_on_first_burn() -> void:
	var s := _state()
	var level := _start(s, "ch1.pop")
	s.take_events()
	s.commit(_direct_led(level))
	assert_true({"type": "badge", "id": "magic_smoke"} in s.take_events())


func test_terms_seen_saved_in_progress() -> void:
	var s := _state()
	assert_eq(s.mark_terms_seen(PackedStringArray(["current", "volt"]), 77), PackedStringArray(["current", "volt"]))
	assert_eq(s.progress.seen_terms["current"], 77)


func test_drafts_saved_per_level() -> void:
	var s := _state()
	var l1 := _start(s, "ch1.light-it-up")
	s.commit(TestCircuits.with_wire(l1.circuit, "w1", "B1", "pos", "R1", "a"))
	var l2 := _start(s, "ch1.pop")
	s.commit(_direct_led(l2))
	assert_eq(CircuitIO.from_dict(s.progress.drafts[l1.id]).wires.size(), 1)
	assert_eq(CircuitIO.from_dict(s.progress.drafts[l2.id]).wires.size(), 2)


func test_preview_leaves_history_alone() -> void:
	var s := _state()
	var level := _start(s, "ch1.light-it-up")
	s.preview(level.solution)
	assert_eq(s.history.present.wires.size(), 0)
	assert_true(s.shown().result.part_amps["L1"] > 0.01, "the preview is what's drawn")
	assert_eq(s.outcome.circuit.wires.size(), 0, "goals still judge the committed circuit")
	s.set_ui_flag("value:R1")
	assert_eq(s.session.phase, "build", "a preview never passes a level")
	s.commit(level.solution)
	assert_eq(s.preview_circuit, null, "a commit ends the preview")
	assert_eq(s.shown(), s.outcome)


func test_star_after_passing_is_recorded() -> void:
	var s := _state()
	var level := _start(s, "ch1.pop")
	s.commit(CircuitEdits.set_props(level.solution, "R1", {"ohms": 220.0}))
	assert_eq(s.session.phase, "passed")
	assert_false(s.progress.completed["ch1.pop"]["star"])
	s.take_events()
	s.commit(level.solution)
	assert_true(s.progress.completed["ch1.pop"]["star"], "a star earned after passing still counts")
	var events := s.take_events()
	assert_true({"type": "star"} in events)
	assert_true({"type": "badge", "id": "on_spec"} in events)
	assert_eq(events.filter(func(e: Dictionary) -> bool: return e["type"] == "passed").size(), 0, "passing is announced once")


func test_tray_used_counts_placed_parts() -> void:
	var s := _state()
	var level := _start(s, "ch1.pop")
	assert_eq(s.tray_used(), [0, 0, 0, 0, 0, 0] as Array[int])
	s.commit(level.solution)
	assert_eq(s.tray_used(), [0, 0, 1, 0, 0, 0] as Array[int])


## A test report describes the circuit it ran on. Any change to the circuit
## (an edit, undo or redo) clears it, and "Press Test." needs pressing again.
func test_changing_the_circuit_clears_the_old_test_report() -> void:
	var s := _state()
	_start(s, "ch1.both")
	for change in ["commit", "undo", "redo"]:
		s.set_ui_flag("tested")
		s.run_tests()
		assert_false(s.session.test_report.is_empty(), change)
		match change:
			"commit":
				var c := s.history.present.copy()
				c.parts[0].x += 1
				s.commit(c)
			"undo":
				s.undo()
			"redo":
				s.redo()
		assert_true(s.session.test_report.is_empty(), "%s keeps a stale report" % change)
		assert_false(bool(s.ui_flags.get("tested", false)), "%s keeps the tested flag" % change)


## Start over: back to the level's own start, in one undoable step that
## also clears the old test report.
func test_start_over_is_undoable() -> void:
	var s := _state()
	var level := _start(s, "ch1.both")
	var c := s.history.present.copy()
	c.parts.append(Part.make("S9", "switch", 4, 4))
	s.commit(c)
	s.run_tests()
	s.start_over()
	assert_eq(s.history.present.parts.size(), level.circuit.parts.size())
	for p in level.circuit.parts:
		assert_true(s.history.present.find_part(p.id) != null, p.id + " is back")
	assert_eq(s.history.present.find_part("S9"), null)
	assert_true(s.session.test_report.is_empty())
	assert_true(s.undo())
	assert_true(s.history.present.find_part("S9") != null, "undo brings the edits back")
