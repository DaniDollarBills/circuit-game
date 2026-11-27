extends TestCase
## The course around a lesson: what plays first, Try it's own circuit (which
## never touches the build draft), pokes, readouts, and the lesson marks.

const NOW := 1_700_000_000


## A two-card deck and a Try it: a working loop (L1 lit) where deleting w1
## darkens the LED and undoing lights it again. The build starts with the
## parts and no wires.
func _lesson() -> LevelDef:
	var b := LevelBuilder.new("t.course", "ch1", "Course")
	b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4).part("L1", "led", 6, 0, 90)
	b.goal({"kind": "led_lit", "part": "L1"})
	b.idea("One.").idea("Two.")
	b.try_it("Break it, then fix it.")
	b.try_part("B1", "battery", -6, 0).try_part("R1", "resistor", -2, -4, 0, {"ohms": 220.0}).try_part("L1", "led", 6, 0, 90)
	b.try_wire("w1", "B1", "pos", "R1", "a").try_wire("w2", "R1", "b", "L1", "anode").try_wire("w3", "L1", "cathode", "B1", "neg")
	b.poke("Delete a wire.", {"kind": "led_dark", "part": "L1"})
	b.poke("Undo it.", {"kind": "led_lit", "part": "L1"})
	b.readout("L1", "mA")
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.delete_wire(c, "w1"))
	return b.done()


func _state(help := "heavy") -> GameState:
	var s := GameState.new()
	s.progress = Progress.defaults()
	s.progress.settings["help_level"] = help
	s.now_fn = func() -> int: return NOW
	return s


func _to_try(s: GameState, l: LevelDef) -> void:
	s.start_level(l)
	s.skip_learn()


func test_first_visit_heavy_starts_on_learn() -> void:
	var s := _state()
	s.start_level(_lesson())
	assert_eq(s.session.phase, "learn")


func test_light_help_starts_on_build() -> void:
	for help in ["light", "off"]:
		var s := _state(help)
		s.start_level(_lesson())
		assert_eq(s.session.phase, "build", help)


func test_completed_lesson_opens_on_build() -> void:
	var s := _state()
	s.progress.completed["t.course"] = {"star": false, "at": 1}
	s.start_level(_lesson())
	assert_eq(s.session.phase, "build", "a v0.2.0 player who passed it isn't made to sit through it")


## Final review: a lesson passed before, opened on a draft that still passes,
## announced the pass again (the recap and its chime). It's already passed:
## no announcement, and the recap's numbers are kept from that circuit.
func test_completed_lesson_with_a_passing_draft_opens_quietly() -> void:
	var s := _state()
	var l := _lesson()
	s.progress.completed["t.course"] = {"star": false, "at": 1}
	var done := l.circuit.copy()
	done = CircuitEdits.add_wire(done, "B1", "pos", "R1", "a")
	done = CircuitEdits.add_wire(done, "R1", "b", "L1", "anode")
	done = CircuitEdits.add_wire(done, "L1", "cathode", "B1", "neg")
	s.progress.drafts["t.course"] = CircuitIO.to_dict(done)
	s.start_level(l)
	assert_eq(s.session.phase, "passed")
	assert_true(s.take_events().filter(func(e: Dictionary) -> bool: return e["type"] == "passed").is_empty(),
			"not announced again")
	assert_true(s.passed_outcome != null, "the passing circuit is kept for the recap")
	assert_true(absf(float(s.passed_outcome.result.part_amps.get("L1", 0.0))) > 0.001, "with its LED lit")


func test_seen_lesson_opens_on_build() -> void:
	var s := _state()
	s.progress.mark_lesson("t.course", "learn", 5)
	s.start_level(_lesson())
	assert_eq(s.session.phase, "build")


func test_learn_then_try_then_build() -> void:
	var s := _state()
	var l := _lesson()
	s.start_level(l)
	for i in 4:
		s.next_card()
	assert_eq(s.session.phase, "try")
	assert_true(s.trying())
	assert_eq(s.history.present.wires.size(), 3, "the bench holds the try circuit")
	s.finish_try()
	assert_eq(s.session.phase, "build")
	assert_eq(s.history.present.wires.size(), 0, "and now the build circuit")
	assert_eq(s.outcome.circuit.wires.size(), 0)


func test_try_edits_never_touch_draft() -> void:
	var s := _state()
	var l := _lesson()
	var built := CircuitEdits.add_wire(l.circuit, "B1", "pos", "R1", "a")
	s.progress.drafts[l.id] = CircuitIO.to_dict(built)
	s.progress.settings["help_level"] = "heavy"
	_to_try(s, l)
	s.commit(CircuitEdits.delete_wire(s.history.present, "w1"))
	s.commit(CircuitEdits.delete_wire(s.history.present, "w2"))
	assert_eq(CircuitIO.from_dict(s.progress.drafts[l.id]).wires.size(), 1, "the saved draft is the build's")
	s.finish_try()
	assert_eq(s.history.present.wires.size(), 1, "back to the build, as it was")
	assert_eq(s.history.present.wires[0].a_part, "B1")


func test_undo_in_try_stays_in_try_circuit() -> void:
	var s := _state()
	_to_try(s, _lesson())
	s.commit(CircuitEdits.delete_wire(s.history.present, "w1"))
	assert_true(s.undo())
	assert_eq(s.history.present.wires.size(), 3)
	assert_false(s.undo(), "nothing to undo before the try circuit")
	assert_eq(s.history.present.wires.size(), 3, "undo never reaches the build circuit")


func test_start_over_in_try_resets_try_circuit() -> void:
	var s := _state()
	var l := _lesson()
	_to_try(s, l)
	s.commit(CircuitEdits.delete_wire(s.history.present, "w1"))
	s.start_over()
	assert_true(s.trying())
	assert_eq(s.history.present.wires.size(), 3)


func test_leaving_during_try_keeps_draft() -> void:
	var s := _state()
	var l := _lesson()
	s.progress.drafts[l.id] = CircuitIO.to_dict(CircuitEdits.add_wire(l.circuit, "B1", "pos", "R1", "a"))
	_to_try(s, l)
	s.commit(CircuitEdits.delete_wire(s.history.present, "w1"))
	s.start_level(Levels.by_id("ch1.pop"))
	s.progress.mark_lesson(l.id, "learn", 5)
	s.start_level(l)
	assert_eq(s.session.phase, "build")
	assert_eq(s.history.present.wires.size(), 1, "the build draft, not the try circuit")


func test_reopen_keeps_build_circuit() -> void:
	var s := _state()
	var l := _lesson()
	s.start_level(l)
	s.skip_learn()
	s.finish_try()
	s.commit(CircuitEdits.add_wire(s.history.present, "B1", "pos", "R1", "a"))
	s.reopen_lesson()
	assert_eq(s.session.phase, "learn")
	assert_eq(s.session.card_index, 0)
	s.skip_learn()
	assert_true(s.trying())
	assert_eq(s.history.present.wires.size(), 3, "a fresh try circuit")
	s.finish_try()
	assert_eq(s.history.present.wires.size(), 1, "the build kept its wire")


func test_pokes_latch_in_order() -> void:
	var s := _state()
	_to_try(s, _lesson())
	assert_eq(s.session.poke_done, [false, false], "lit at the start, but poke 1 waits for poke 0")
	s.commit(CircuitEdits.delete_wire(s.history.present, "w1"))
	assert_eq(s.session.poke_done, [true, false])
	s.undo()
	assert_eq(s.session.poke_done, [true, true])
	s.commit(CircuitEdits.delete_wire(s.history.present, "w2"))
	assert_eq(s.session.poke_done, [true, true], "a ticked poke stays ticked")


func test_try_never_passes_the_lesson() -> void:
	var s := _state()
	var l := _lesson()
	_to_try(s, l)
	assert_eq(s.session.phase, "try", "the try circuit lights the LED, but trying isn't building")
	assert_false(s.progress.completed.has(l.id))


func test_readouts_follow_sim() -> void:
	var s := _state()
	_to_try(s, _lesson())
	var r := s.readouts()
	assert_eq(r.size(), 1)
	assert_eq(r[0]["text"], "LED: 13.8 mA", "5 V, 220 Ω and a red LED: (5 − 1.89) ÷ 226 ≈ 13.8 mA")
	s.commit(CircuitEdits.delete_wire(s.history.present, "w1"))
	assert_eq(s.readouts()[0]["text"], "LED: 0.0 mA")


func test_lesson_marks_recorded() -> void:
	var s := _state()
	var l := _lesson()
	s.start_level(l)
	s.skip_learn()
	assert_eq(s.progress.lesson_marks(l.id), {"learn": NOW})
	s.finish_try()
	assert_eq(s.progress.lesson_marks(l.id), {"learn": NOW, "try": NOW})


func test_current_tray_follows_phase() -> void:
	var b := LevelBuilder.new("t.trays", "ch1", "Trays")
	b.part("B1", "battery", -6, 0).goal({"kind": "no_damage"})
	b.tray("resistor", {"ohms": 150.0})
	b.idea("One.")
	b.try_it("Try.").try_part("B1", "battery", -6, 0).try_tray("resistor", {"ohms": 330.0}).try_tray("led")
	b.poke("Anything.", {"kind": "no_damage"}).try_path_edit(func(c: Circuit) -> Circuit: return c)
	var l := b.done()
	var s := _state()
	s.start_level(l)
	s.skip_learn()
	assert_eq(s.current_tray().size(), 2)
	assert_eq(s.tray_used().size(), 2)
	s.finish_try()
	assert_eq(s.current_tray().size(), 1)
	assert_eq(s.current_tray()[0]["props"]["ohms"], 150.0)


func test_commit_sets_did_flags() -> void:
	var s := _state("off")
	s.start_level(Levels.by_id("ch1.light-it-up"))
	s.commit(CircuitEdits.add_wire(s.history.present, "B1", "pos", "R1", "a"))
	assert_true(s.ui_flags.has("did:wired"))
	assert_false(s.ui_flags.has("did:placed"))


func test_undo_sets_did_undone() -> void:
	var s := _state("off")
	s.start_level(Levels.by_id("ch1.light-it-up"))
	s.commit(CircuitEdits.add_wire(s.history.present, "B1", "pos", "R1", "a"))
	assert_false(s.ui_flags.has("did:undone"))
	s.undo()
	assert_true(s.ui_flags.has("did:undone"))


## Lessons 5 and 6: while trying, each switch case the circuit is in is noted
## (row:<n>, with whether the LED was lit) so Try it's truth table can fill in
## and its poke can tick; the build never notes them.
func test_truth_rows_noted_while_trying() -> void:
	var s := _state()
	var l := Levels.by_id("ch1.both")
	s.start_level(l)
	s.skip_learn()
	assert_true(s.trying())
	assert_eq(s.truth_rows(), {0: false}, "both open to begin with")
	assert_true(s.ui_flags.has("row:0"))
	s.commit(CircuitEdits.set_props(s.history.present, "SW2", {"closed": true}))
	s.commit(CircuitEdits.set_props(s.history.present, "SW1", {"closed": true}))
	assert_eq(s.truth_rows(), {0: false, 1: false, 3: true})
	s.finish_try()
	s.commit(s.history.present)
	assert_false(s.ui_flags.has("row:2"), "only Try it notes cases")


## Lesson 8's readouts name each resistor a player might place; only the ones
## on the bench show.
func test_readouts_skip_parts_not_on_the_bench() -> void:
	var s := _state()
	var l := Levels.by_id("ch1.too-hot")
	s.start_level(l)
	s.skip_learn()
	assert_true(s.trying())
	assert_eq(s.readouts(), [] as Array[Dictionary], "no resistor placed yet")
	var c := s.history.present.copy()
	c.parts.append(Part.make("R1", "resistor", -2, 0, 90, {"ohms": 220.0, "watts": 0.25}, false))
	c = CircuitEdits.add_wire(c, "B1", "pos", "R1", "a")
	c = CircuitEdits.add_wire(c, "R1", "b", "B1", "neg")
	s.commit(c)
	assert_eq(s.readouts().size(), 1)
	assert_eq(s.readouts()[0]["text"], "220 Ω resistor: 0.11 W", "220 Ω across 5 V")
