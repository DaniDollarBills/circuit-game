extends TestCase
## Lesson 0 on screen: the tour spotlights each part of the screen with the
## deck out of its way, the moving hand shows the current step where it's
## done, and the lesson can be skipped.

var _dir := ""


func before_each() -> void:
	_dir = "user://test_l0_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)


func after_each() -> void:
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _screen(size := Vector2(1280, 720)) -> LevelScreen:
	var game := Game.new()
	add_to_tree(game)
	game.boot(_dir.path_join("progress.json"))
	var host := Control.new()
	host.size = size
	add_to_tree(host)
	game.open_level("ch1.workbench", true)
	var s: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
	s.game = game
	host.add_child(s)
	await wait_frames(4)
	return s


func test_tour_spotlights_its_target() -> void:
	var s := await _screen()
	assert_eq(s.game.state.session.phase, "learn")
	assert_false(s.spotlight.visible, "the goals card points at nothing")
	# The deck's own Skip skips the tour; "Skip Lesson 0" skips the lesson.
	assert_eq(s.deck.skip_button().text, "Skip the tour")
	var seen := 0
	for i in range(1, s.game.state.level.learn.size() + 1):
		s.game.next_card()
		await wait_frames(2)
		var card: Dictionary = s.game.state.level.learn[i - 1]
		if card["type"] != "tour":
			continue
		seen += 1
		assert_true(s.spotlight.visible, card["target"])
		var hole := s.spotlight.hole()
		assert_true(hole.has_point(s.tour_rect(card["target"]).get_center()), "%s: %s in %s" % [card["target"], s.tour_rect(card["target"]), hole])
		if card["target"] != "board":
			assert_false(s.deck.get_rect().intersects(hole), "the deck keeps out of the way of the %s" % card["target"])
	assert_eq(seen, 8)


## Each top-bar card lights up its own buttons and no others.
func test_top_bar_tour_lights_each_group() -> void:
	var s := await _screen()
	var groups := {"map_button": ["map"], "edit_buttons": ["restart", "undo", "redo"],
			"tool_buttons": ["calculator", "notebook", "settings"]}
	for target in groups:
		var hole := s.tour_rect(target)
		for id in ["map", "restart", "undo", "redo", "calculator", "notebook", "settings"]:
			var b := s.top_bar.button(id)
			var center := b.get_global_rect().get_center() - s.global_position
			assert_eq(hole.has_point(center), id in groups[target], "%s and the %s button" % [target, id])


func test_hand_shows_the_current_step() -> void:
	var s := await _screen()
	s.game.skip_learn()
	await wait_frames(3)
	assert_eq(s.game.state.session.phase, "build")
	assert_true(s.hand.playing(), "the first step's demo plays")
	var first: Dictionary = s.game.state.level.steps[0]["demo"]
	assert_near(s.hand.hand_position().distance_to(s.demo_target(first["from"])), 0.0, 2.0)


func test_demo_targets_resolve_on_screen() -> void:
	for size in [Vector2(1280, 720), Vector2(390, 844)]:
		var s := await _screen(size)
		s.game.skip_learn()
		var c := s.game.state.history.present
		var r := Part.make("R1", "resistor", 0, 5, 0, {"ohms": 220.0}, false)
		r.tray = 0
		c = CircuitEdits.add_part(c, r)
		c = CircuitEdits.add_wire(c, "B1", "pos", "R1", "a")
		s.game.commit(c)
		await wait_frames(3)
		var screen := Rect2(Vector2.ZERO, size)
		for st in s.game.state.level.steps:
			var demo: Dictionary = st["demo"]
			for end in ["from", "to"]:
				if demo.has(end):
					var at := s.demo_target(demo[end])
					assert_true(screen.has_point(at), "%s %s at %s: %s" % [st["text"], end, size, at])
		s.get_parent().queue_free()
		await wait_frames(1)


func test_skip_lesson0_unlocks_lesson1() -> void:
	var s := await _screen()
	assert_true(s.skip_tutorial_button.visible)
	s.skip_tutorial_button.pressed.emit()
	await wait_frames(2)
	var p := s.game.state.progress
	assert_true(p.completed.has("ch1.workbench"))
	assert_false(bool(p.completed["ch1.workbench"]["star"]))
	assert_true(p.is_unlocked("ch1.light-it-up", Levels.chapter_ids("ch1")))
	assert_eq(s.game.state.level.id, "ch1.light-it-up", "on to Lesson 1")


func test_tutorial_keeps_its_tools_in_view() -> void:
	var s := await _screen()
	assert_eq(s.game.state.session.phase, "learn")
	assert_true(s.tray.visible, "the tour points at the tray")
	assert_true(s.column_scroll.visible)
	assert_true(s.hint_button.visible)
	assert_true(s.meet_card == null or not s.meet_card.visible, "Lesson 0 is about the controls, not the parts")


## Checkpoint S: on a landscape phone, Lesson 0's first step sat below the
## fold of the column, cut off by its edge. The current step is always in view.
func test_current_step_in_view_on_every_screen() -> void:
	for size in [Vector2(844, 390), Vector2(640, 360), Vector2(390, 844), Vector2(1280, 720)]:
		var s := await _screen(size)
		s.game.skip_learn()
		await wait_frames(4)
		for i in 2:
			var row := s.checklist.current_row()
			assert_true(row != null, str(size))
			if row == null:
				break
			var view := s.column_scroll.get_global_rect()
			assert_true(view.grow(0.5).encloses(row.get_global_rect()), "%s, step %d: %s inside %s" % [size, i + 1, row.get_global_rect(), view])
			s.game.set_ui_flag("did:placed")
			await wait_frames(4)


## Code review (checkpoint S): with help Off the lightbulb was hidden, so
## Lesson 0's last step could never be done (and at Light and Off its steps
## were hidden too). A tutorial keeps its steps and Hint at every help level.
func test_lesson0_completes_at_every_help_level() -> void:
	for help in ["heavy", "light", "off"]:
		var s := await _screen()
		s.game.set_setting("help_level", help)
		s.game.skip_learn()
		await wait_frames(3)
		assert_true(s.checklist.visible, help + ": the steps show")
		assert_true(s.hint_button.visible, help + ": the lightbulb shows")
		for st in s.game.state.level.steps:
			var flag := str(st["check"]["flag"])
			if flag != "did:hint":
				s.game.set_ui_flag(flag)
		s.hint_button.pressed.emit()
		await wait_frames(3)
		assert_eq(s.game.state.session.phase, "passed", help)


## Code review (checkpoint S): skipping Lesson 0 counts it as done, so the
## badges are checked then too.
func test_skipping_lesson0_checks_badges() -> void:
	var s := await _screen()
	s.game.state.progress.mark_complete("ch1.light-it-up", false, 1)
	assert_false(s.game.state.progress.achievements.has("first_light"))
	s.game.skip_tutorial()
	await wait_frames(2)
	assert_true(s.game.state.progress.achievements.has("first_light"), "checked when Lesson 0 is skipped")
