extends TestCase
## Fingers on the board: a pinch zooms without touching the circuit, and a
## second finger landing mid-wire cancels the wire.

var _dir := ""
var e2e: E2E


func before_each() -> void:
	_dir = "user://test_touch_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)
	e2e = E2E.new(tree)


func after_each() -> void:
	e2e.stop()
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _level() -> LevelScreen:
	await e2e.start(_dir.path_join("progress.json"))
	e2e.game().open_level("ch1.light-it-up", true)
	await e2e.frames(4)
	var s := e2e.screen() as LevelScreen
	await e2e.skip_intro(s)
	for c in s.visible_word_cards():
		c.finish()
	await e2e.frames(2)
	return s


func test_touch_pinch_zoom() -> void:
	var s := await _level()
	var before := s.stage.camera().view
	var wires := s.game.state.history.present.wires.size()
	var mid := s.editor.safe_rect.end - Vector2(220, 120) + s.editor.global_position
	var a := mid - Vector2(40, 0)
	var b := mid + Vector2(40, 0)
	e2e.touch(0, a, true)
	e2e.touch(1, b, true)
	for k in range(1, 11):
		var spread := 40.0 * (1.0 + float(k) / 10.0)
		e2e.touch_drag(0, mid - Vector2(spread, 0), Vector2(-4, 0))
		e2e.touch_drag(1, mid + Vector2(spread, 0), Vector2(4, 0))
	e2e.touch(0, mid - Vector2(80, 0), false)
	e2e.touch(1, mid + Vector2(80, 0), false)
	await e2e.frames(2)
	assert_near(s.stage.camera().view, before / 2.0, before * 0.01)
	assert_eq(s.game.state.history.present.wires.size(), wires, "the circuit is untouched")


func test_touch_second_finger_cancels_wire() -> void:
	var s := await _level()
	var c := s.game.state.history.present
	var from := e2e.pin(s, "B1", "pos")
	e2e.touch(0, from, true)
	for k in range(1, 6):
		e2e.touch_drag(0, from + Vector2(12 * k, 6 * k), Vector2(12, 6))
	await e2e.frames(1)
	assert_eq(s.editor.controller.mode["kind"], "wiring", "the wire is being dragged")
	var other := s.editor.safe_rect.end - Vector2(200, 120) + s.editor.global_position
	e2e.touch(1, other, true)
	e2e.touch(0, from + Vector2(60, 30), false)
	e2e.touch(1, other, false)
	await e2e.frames(2)
	assert_eq(s.game.state.history.present, c, "no wire was made")
	assert_eq(s.editor.controller.mode["kind"], "idle")
