class_name StepsChecklist
extends PanelContainer
## Heavy help's checklist: the level's steps, ticked as they're done, with the
## first unticked step highlighted. In portrait only that step is shown.

var game: Game
var compact := false

var _rows: VBoxContainer
var _signature := ""


func _ready() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	add_child(col)
	var title := Label.new()
	title.text = "Steps"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Palette.color("ink_soft"))
	col.add_child(title)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	col.add_child(_rows)


func refresh(level: LevelDef, session: LevelSession) -> void:
	var current := -1
	for i in level.steps.size():
		if not _ticked(session, i):
			current = i
			break
	var sig := "%s|%s|%s" % [session.step_results, compact, current]
	if sig == _signature:
		return
	_signature = sig
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	for i in level.steps.size():
		if compact and i != current:
			continue
		var row := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		sb.bg_color = Palette.color("lilac") if i == current else Color(0, 0, 0, 0)
		row.add_theme_stylebox_override("panel", sb)
		var line := HBoxContainer.new()
		row.add_child(line)
		var mark := Label.new()
		mark.text = "✓" if _ticked(session, i) else "%d" % (i + 1)
		mark.custom_minimum_size = Vector2(22, 0)
		line.add_child(mark)
		line.add_child(HudText.make(game, str(level.steps[i]["text"]), 15))
		_rows.add_child(row)


## How many steps are ticked.
static func ticked_count(session: LevelSession) -> int:
	var n := 0
	for r in session.step_results:
		n += int(bool(r["pass"]))
	return n


static func _ticked(session: LevelSession, i: int) -> bool:
	return i < session.step_results.size() and bool(session.step_results[i]["pass"])
