class_name TestSheet
extends PanelContainer
## For levels with tests: a Test button and each test case ✓ or ✗ with what
## went wrong. Pressing Test sets the "tested" flag.

var game: Game

var _rows: VBoxContainer
var _signature := ""


func _ready() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	add_child(col)
	var run := IconButton.make("test", "Try every switch setting", "Test")
	run.pressed.connect(func() -> void:
		game.run_tests()
		game.set_ui_flag("tested"))
	col.add_child(run)
	_rows = VBoxContainer.new()
	col.add_child(_rows)


func refresh(session: LevelSession) -> void:
	var cases: Array = session.test_report.get("cases", [])
	var sig := str(cases)
	if sig == _signature:
		return
	_signature = sig
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	for case in cases:
		var ok := bool(case["pass"])
		var text := "%s %s" % ["✓" if ok else "✗", case["name"]]
		for m in case["messages"]:
			text += "\n" + str(m)
		_rows.add_child(HudText.make(game, text, 15))
