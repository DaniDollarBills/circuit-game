extends TestCase
## The start-up options for development and screenshots: --open=level:<id>
## (with --skip-intro and --show=…) and --night and --large-text, which hold
## only for that start.

var _dir := ""
var e2e: E2E


func before_each() -> void:
	_dir = "user://test_main_args_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)
	e2e = E2E.new(tree)


func after_each() -> void:
	e2e.stop()
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func test_open_a_lesson_at_night() -> void:
	var main := await e2e.start(_dir.path_join("progress.json"))
	assert_true(main.call("open_from", PackedStringArray(["--open=level:ch1.pop", "--night"])))
	await e2e.frames(2)
	var game: Game = main.get("game")
	assert_eq(game.state.level.id, "ch1.pop")
	assert_true(bool(game.state.progress.settings["night"]))
	assert_false(bool(game.state.progress.settings["large_text"]))
	assert_true(main.call("open_from", PackedStringArray(["--open=level:ch1.pop", "--large-text"])))
	assert_false(bool(game.state.progress.settings["night"]), "Night only when asked for")
	assert_true(bool(game.state.progress.settings["large_text"]))
	# Let the screen it replaced finish its last refresh before Main goes.
	await e2e.frames(3)


func test_no_options_opens_nothing() -> void:
	var main := await e2e.start(_dir.path_join("progress.json"))
	assert_false(main.call("open_from", PackedStringArray([])))
