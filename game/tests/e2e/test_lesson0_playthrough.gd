extends TestCase
## Lesson 0 played with real mouse input: the tour, then every control once
## (place, move, turn, wire, delete, undo, zoom, pan, datasheet, hint), and
## the lesson passes.

var _dir := ""
var e2e: E2E


func before_each() -> void:
	_dir = "user://test_l0_e2e_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)
	e2e = E2E.new(tree)


func after_each() -> void:
	e2e.stop()
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _flag(s: LevelScreen, f: String) -> bool:
	return s.game.state.ui_flags.has(f)


func _placed(s: LevelScreen) -> Part:
	for p in s.game.state.history.present.parts:
		if not p.locked:
			return p
	return null


## An empty spot on the board, below the parts.
func _empty(s: LevelScreen) -> Vector2:
	return e2e.grid(s, Vector2(-1, 9))


func test_lesson0_steps_tick_with_real_input() -> void:
	await e2e.start(_dir.path_join("progress.json"))
	e2e.game().open_level("ch1.workbench", true)
	await e2e.frames(4)
	var s := e2e.screen() as LevelScreen
	await e2e.skip_intro(s)
	assert_eq(s.game.state.session.phase, "build")
	assert_true(s.hand.playing(), "the hand shows the first step")
	# Place: tap the resistor in the tray, then the board.
	var item: Control = s.tray.items()[0]
	await e2e.clear_cards_at(s, [item.get_global_rect().get_center()])
	await e2e.click_control(item)
	var spot := e2e.grid(s, Vector2(0, 4))
	await e2e.clear_cards_at(s, [spot])
	await e2e.click(spot)
	await e2e.frames(2)
	assert_true(_flag(s, "did:placed"), "placed")
	var r := _placed(s)
	# Move: drag it somewhere else.
	await e2e.drag(e2e.part_top(s, r.id), e2e.grid(s, Vector2(2, 4)))
	assert_true(_flag(s, "did:moved"), "moved")
	# Turn: long press, then Rotate.
	await e2e.long_press(e2e.part_top(s, r.id))
	assert_true(s.menu.visible, "a long press opens the menu")
	await e2e.click_control(s.menu.button("Rotate"))
	assert_true(_flag(s, "did:rotated"), "rotated")
	# Wire: drag from the battery's + to the resistor.
	var from := e2e.pin(s, "B1", "pos")
	var to := e2e.pin(s, r.id, "a")
	await e2e.clear_cards_at(s, [from, to])
	await e2e.drag(from, to)
	assert_true(_flag(s, "did:wired"), "wired")
	# Delete it: right-click the wire, then Delete.
	var c := s.game.state.history.present
	var w := c.wires[c.wires.size() - 1]
	var path := CircuitGeometry.wire_path(c, w)
	# Halfway along it, clear of the battery's lead and the resistor's body.
	await e2e.click(e2e.grid(s, Diagram.along(path, Diagram.path_length(path) / 2.0)), MOUSE_BUTTON_RIGHT)
	assert_true(s.menu.visible and s.menu.target.has("wire"), "the wire's menu: %s" % str(s.menu.target))
	await e2e.click_control(s.menu.button("Delete"))
	assert_true(_flag(s, "did:deleted"), "deleted")
	# Undo.
	await e2e.click_control(s.top_bar.button("undo"))
	assert_true(_flag(s, "did:undone"), "undone")
	# Zoom and pan over an empty spot.
	await e2e.scroll(_empty(s))
	await e2e.frames(2)
	assert_true(_flag(s, "did:zoomed"), "zoomed")
	await e2e.drag(_empty(s), _empty(s) + Vector2(80, 0))
	assert_true(_flag(s, "did:panned"), "panned")
	# The LED's datasheet, then a hint.
	await e2e.click(e2e.part_top(s, "L1"))
	await e2e.frames(2)
	assert_true(_flag(s, "datasheet:L1"), "the datasheet opened")
	s.datasheet.close()
	await e2e.click_control(s.hint_button)
	await e2e.frames(3)
	assert_eq(s.game.state.session.phase, "passed", "every step done: " + str(s.game.state.ui_flags.keys()))
	assert_true(s.recap.visible)
	assert_false(s.hand.playing(), "no more demos")
