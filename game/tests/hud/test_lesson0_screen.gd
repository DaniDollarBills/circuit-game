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
	assert_eq(seen, 6)


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
