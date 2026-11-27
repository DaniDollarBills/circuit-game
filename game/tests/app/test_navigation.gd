extends TestCase

var _dir := ""


func before_each() -> void:
	_dir = "user://test_nav_%d_%d" % [Time.get_ticks_usec(), randi()]
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


func _map(game: Game) -> MapScreen:
	var map: MapScreen = load("res://src/screens/map_screen.tscn").instantiate()
	map.game = game
	add_to_tree(map)
	return map


func test_map_only_l1_enabled_on_fresh_progress() -> void:
	var map := _map(_game())
	var buttons := map.level_buttons()
	assert_eq(buttons.size(), 9)
	assert_false(buttons[0].disabled)
	for i in range(1, 9):
		assert_true(buttons[i].disabled, str(i))
	assert_eq(map.chapter_cards().size(), 12)


func test_map_l2_enabled_after_l1() -> void:
	var game := _game()
	game.state.progress.mark_complete("ch1.light-it-up", false, 1)
	var map := _map(game)
	assert_false(map.level_buttons()[1].disabled)
	assert_true(map.level_buttons()[0].text.contains("✓"))
	assert_true(map.level_buttons()[2].disabled)


func test_open_level_shows_level_screen() -> void:
	var main: Control = load("res://src/app/main.tscn").instantiate()
	main.set("progress_path", _dir.path_join("progress.json"))
	add_to_tree(main)
	await wait_frames(2)
	(main.get("game") as Game).open_level("ch1.light-it-up")
	await wait_frames(2)
	assert_true(main.get("screen") is LevelScreen)
	var screen: LevelScreen = main.get("screen")
	assert_true(screen.editor != null and screen.stage != null)
	assert_eq(screen.editor.circuit.parts.size(), 3)


func test_commit_autosaves_after_debounce() -> void:
	var game := _game()
	var path := _dir.path_join("progress.json")
	game.open_level("ch1.light-it-up")
	game.commit(TestCircuits.with_wire(game.state.level.circuit, "w1", "B1", "pos", "R1", "a"))
	assert_false(FileAccess.file_exists(path), "saves wait for the debounce")
	await tree.create_timer(Game.SAVE_DELAY_S + 0.2).timeout
	var saved: Progress = ProgressStorage.load(path)["progress"]
	assert_eq(CircuitIO.from_dict(saved.drafts["ch1.light-it-up"]).wires.size(), 1)


func test_close_request_saves_immediately() -> void:
	var game := _game()
	var path := _dir.path_join("progress.json")
	game.open_level("ch1.light-it-up")
	game.commit(TestCircuits.with_wire(game.state.level.circuit, "w1", "B1", "pos", "R1", "a"))
	game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_true(ProgressStorage.load(path)["progress"].drafts.has("ch1.light-it-up"))


func test_set_setting_rejects_invalid_values() -> void:
	var game := _game()
	game.set_setting("help_level", "light")
	game.set_setting("help_level", "lots")
	game.set_setting("night", "yes")
	game.set_setting("no_such_setting", true)
	assert_eq(game.state.progress.settings["help_level"], "light")
	assert_eq(game.state.progress.settings["night"], false)
	assert_false(game.state.progress.settings.has("no_such_setting"))


func test_damaged_save_starts_fresh_with_toast() -> void:
	var path := _dir.path_join("progress.json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	var game := Game.new()
	add_to_tree(game)
	var toasts: Array[String] = []
	game.toast.connect(func(t: String) -> void: toasts.append(t))
	game.boot(path)
	await wait_frames(1)
	assert_true(game.state.progress.completed.is_empty())
	assert_eq(toasts, [Game.DAMAGED_SAVE_KEPT] as Array[String])
