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
	HudText.font_size(title, 15, game)
	title.theme_type_variation = "SoftLabel"
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
	var night := bool(game.state.progress.settings.get("night", false))
	var sig := "%s|%s|%s|%s" % [session.step_results, compact, current, night]
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
		if i == current:
			# Pale enough that text and links keep 7:1 (spec §11): a lavender
			# tint by day, the darker board color at night, with a lavender edge.
			sb.bg_color = Palette.color("cream", true) if night else Palette.color("paper").lerp(Palette.color("lavender"), 0.15)
			sb.set_border_width_all(2)
			sb.border_color = Palette.color("lavender")
		else:
			sb.bg_color = Color(0, 0, 0, 0)
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
