extends TestCase
## The course, played with real mouse input: the Learn deck, then building.

var _dir := ""
var e2e: E2E


func before_each() -> void:
	_dir = "user://test_course_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)
	e2e = E2E.new(tree)


func after_each() -> void:
	e2e.stop()
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func test_learn_deck_by_tapping() -> void:
	await e2e.start(_dir.path_join("progress.json"))
	e2e.game().open_level("ch1.light-it-up", true)
	await e2e.frames(4)
	var s := e2e.screen() as LevelScreen
	assert_eq(s.game.state.session.phase, "learn", "a first visit opens on the lesson")
	assert_true(s.deck.visible)
	var taps := 0
	while s.game.state.session.phase == "learn" and taps < 20:
		await e2e.click_control(s.deck.next_button())
		taps += 1
	assert_eq(s.game.state.session.phase, "try", "the deck ends on Try it")
	assert_eq(taps, s.game.state.level.deck_size(), "one tap per card")
	assert_false(s.deck.visible)
	assert_true(s.game.state.progress.lesson_marks("ch1.light-it-up").has("learn"))


func test_zoom_and_pan_set_flags() -> void:
	await e2e.start(_dir.path_join("progress.json"))
	e2e.game().state.progress.settings["help_level"] = "off"
	e2e.game().state.progress.parts_seen = {"battery": 1, "resistor": 1, "led": 1}
	e2e.game().open_level("ch1.light-it-up", true)
	await e2e.frames(4)
	var s := e2e.screen() as LevelScreen
	var spot := s.editor.global_position + s.editor.safe_rect.get_center() + Vector2(0, s.editor.safe_rect.size.y * 0.35)
	await e2e.scroll(spot)
	await e2e.frames(2)
	assert_true(s.game.state.ui_flags.has("did:zoomed"))
	await e2e.drag(spot, spot + Vector2(60, 0))
	await e2e.frames(2)
	assert_true(s.game.state.ui_flags.has("did:panned"))


## Lesson 1's whole rhythm with real mouse input: the deck (with its Meet the
## part cards), Try it (break the loop, then fix it), building, the recap, and
## on to Lesson 2.
func test_lesson1_full_rhythm() -> void:
	await e2e.start(_dir.path_join("progress.json"))
	e2e.game().state.progress.mark_complete("ch1.workbench", false, 1)
	e2e.game().open_level("ch1.light-it-up")
	await e2e.frames(4)
	var s := e2e.screen() as LevelScreen
	assert_eq(s.game.state.session.phase, "learn")
	var met := 0
	for i in 40:
		if s.game.state.session.phase != "learn":
			break
		if s.deck.card_kind() == "meet":
			met += 1
		await e2e.click_control(s.deck.next_button())
	assert_eq(met, 4, "the battery, wire, resistor and LED")
	assert_eq(s.game.state.session.phase, "try")
	assert_true(s.meet_card == null or not s.meet_card.visible, "parts met in the deck don't pop up again")
	# Break the loop: right-click a wire, then Delete.
	var c := s.game.state.history.present
	var w := c.find_wire("w2")
	var path := CircuitGeometry.wire_path(c, w)
	await e2e.click(e2e.grid(s, Diagram.along(path, Diagram.path_length(path) / 2.0)), MOUSE_BUTTON_RIGHT)
	await e2e.click_control(s.menu.button("Delete"))
	assert_eq(s.try_panel.poke_rows()[0]["done"], true, "the light went out")
	# Fix it.
	await e2e.click_control(s.top_bar.button("undo"))
	assert_eq(s.try_panel.poke_rows()[1]["done"], true, "and came back")
	await e2e.click_control(s.try_panel.ready_button())
	assert_eq(s.game.state.session.phase, "build")
	for pair in [[["B1", "pos"], ["R1", "a"]], [["R1", "b"], ["L1", "anode"]], [["L1", "cathode"], ["B1", "neg"]]]:
		var from := e2e.pin(s, pair[0][0], pair[0][1])
		var to := e2e.pin(s, pair[1][0], pair[1][1])
		await e2e.clear_cards_at(s, [from, to])
		await e2e.drag(from, to)
	await e2e.frames(3)
	assert_eq(s.game.state.session.phase, "passed")
	assert_true(s.recap.visible)
	assert_true("13.8 mA" in "\n".join(s.recap.point_texts()), str(s.recap.point_texts()))
	var choice := E2E.find_button(s.recap, "Everything stops.")
	await e2e.click_control(choice)
	assert_true("Right" in s.recap.explanation_text(0))
	await e2e.click_control(s.recap.next_button())
	await e2e.frames(3)
	assert_eq((e2e.screen() as LevelScreen).game.state.level.id, "ch1.pop")
