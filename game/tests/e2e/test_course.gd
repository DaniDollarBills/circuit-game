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
	assert_eq(s.game.state.session.phase, "build")
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
