extends TestCase
## The Notebook as a textbook: Lessons, Parts, Words and Badges. Any lesson
## read can be read again (with example numbers), any part met can be met
## again, and a finished chapter gets a summary.

var _dir := ""


func before_each() -> void:
	_dir = "user://test_notebook_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)


func after_each() -> void:
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _game() -> Game:
	var game := Game.new()
	add_to_tree(game)
	game.boot(_dir.path_join("progress.json"))
	return game


func _screen(game: Game) -> LevelScreen:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	game.open_level("ch1.light-it-up", true)
	var s: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
	s.game = game
	host.add_child(s)
	await wait_frames(3)
	return s


func test_four_tabs() -> void:
	var s := await _screen(_game())
	assert_eq(s.notebook.tab_ids(), PackedStringArray(["lessons", "parts", "words", "badges"]))


func test_lessons_tab_lists_read_lessons() -> void:
	var game := _game()
	game.state.progress.mark_complete("ch1.workbench", false, 1)
	game.state.progress.mark_lesson("ch1.light-it-up", "learn", 2)
	var s := await _screen(game)
	s.notebook.open()
	s.notebook.show_tab("lessons")
	assert_eq(s.notebook.lesson_rows(), PackedStringArray(["Lesson 0 · Your workbench", "Lesson 1 · Light it up"]))


func test_reading_a_lesson_again() -> void:
	var game := _game()
	game.state.progress.mark_lesson("ch1.light-it-up", "learn", 2)
	var s := await _screen(game)
	var phase := game.state.session.phase
	s.notebook.open_lesson.emit("ch1.light-it-up")
	await wait_frames(2)
	var deck := s.textbook.deck
	assert_true(deck.visible and deck.read_only)
	assert_false(deck.skip_button().visible, "reading, not skipping")
	assert_eq(game.state.session.phase, phase, "the lesson underneath isn't touched")
	var l := game.state.level
	for i in l.deck_size() - 1:
		deck.next_button().pressed.emit()
	await wait_frames(1)
	assert_eq(deck.card_kind(), "closing")
	assert_true("example numbers" in deck.body_text().to_lower(), deck.body_text())
	assert_true("13.8 mA" in deck.body_text(), "the recap filled from the solution")
	deck.next_button().pressed.emit()
	await wait_frames(1)
	assert_false(deck.visible, "Close closes it")


func test_parts_tab_opens_meet_card() -> void:
	var game := _game()
	game.state.progress.parts_seen = {"led": 1, "battery": 2}
	var s := await _screen(game)
	s.notebook.open()
	s.notebook.show_tab("parts")
	assert_eq(s.notebook.part_rows(), PackedStringArray(["LED", "Battery pack"]))
	s.notebook.open_part.emit("battery")
	await wait_frames(2)
	assert_true(s.textbook.meet_card != null and s.textbook.meet_card.visible)
	assert_eq(s.textbook.meet_card.key, "battery")


func test_chapter_summary_after_last_lesson() -> void:
	var game := _game()
	var s := await _screen(game)
	s.notebook.open()
	s.notebook.show_tab("lessons")
	assert_false(s.notebook.has_chapter_summary("ch1"))
	for id in Levels.chapter_ids("ch1"):
		game.state.progress.mark_complete(id, false, 1)
	s.notebook.show_tab("lessons")
	assert_true(s.notebook.has_chapter_summary("ch1"))
	assert_true(Chapters.SUMMARY["ch1"].size() >= 5)
	assert_true("complete loop" in s.notebook.chapter_summary_text("ch1"))


func test_map_notebook_reads_lessons_too() -> void:
	var game := _game()
	game.state.progress.mark_lesson("ch1.light-it-up", "learn", 2)
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	var map: MapScreen = load("res://src/screens/map_screen.tscn").instantiate()
	map.game = game
	host.add_child(map)
	await wait_frames(3)
	map.notebook.open_lesson.emit("ch1.light-it-up")
	await wait_frames(2)
	assert_true(map.textbook.deck.visible)
