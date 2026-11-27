class_name StepsChecklist
extends PanelContainer
## Heavy help's checklist: the level's steps, ticked as they're done, with the
## first unticked step highlighted. In portrait only that step is shown.

var game: Game
var compact := false

var _rows: VBoxContainer
var _signature := ""
## The step whose why is showing (-1 for none), and its button and text.
var _why_open := -1
var _why_button: Button
var _why_label: RichTextLabel
var _current_row: Control


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
	if _why_open != current:
		_why_open = -1
	var sig := "%s|%s|%s|%s|%s" % [session.step_results, compact, current, night, _why_open]
	if sig == _signature:
		return
	_signature = sig
	_why_button = null
	_why_label = null
	_current_row = null
	_last_level = level
	_last_session = session
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
		var stack := VBoxContainer.new()
		row.add_child(stack)
		var line := HBoxContainer.new()
		stack.add_child(line)
		var mark := Label.new()
		mark.text = "✓" if _ticked(session, i) else "%d" % (i + 1)
		mark.custom_minimum_size = Vector2(22, 0)
		line.add_child(mark)
		line.add_child(HudText.make(game, str(level.steps[i]["text"]), 15))
		var why := str(level.steps[i].get("why", ""))
		if i == current and why != "":
			_why_button = Button.new()
			_why_button.text = "Why?"
			_why_button.theme_type_variation = "FlatButton"
			_why_button.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
			_why_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var at := i
			_why_button.pressed.connect(func() -> void:
				_why_open = -1 if _why_open == at else at
				refresh(_last_level, _last_session))
			line.add_child(_why_button)
			if _why_open == i:
				_why_label = HudText.make(game, why, 14)
				stack.add_child(_why_label)
		_rows.add_child(row)
		if i == current:
			_current_row = row


var _last_level: LevelDef
var _last_session: LevelSession


## The current step's row (null when every step is ticked).
func current_row() -> Control:
	return _current_row


## The current step's Why? button (null when it has no why).
func why_button() -> Button:
	return _why_button


## The why that's showing, or "".
func why_text() -> String:
	return _why_label.get_parsed_text() if _why_label != null else ""


## How many steps are ticked.
static func ticked_count(session: LevelSession) -> int:
	var n := 0
	for r in session.step_results:
		n += int(bool(r["pass"]))
	return n


static func _ticked(session: LevelSession, i: int) -> bool:
	return i < session.step_results.size() and bool(session.step_results[i]["pass"])
