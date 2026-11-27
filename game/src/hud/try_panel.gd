class_name TryPanel
extends PanelContainer
## Try it: a ready-made circuit to poke at before building. It shows the
## prompt, the things to try (each ticks once done, in order), the live values
## that matter, and "I'm ready to build", which is always there.

signal ready_pressed

var game: Game

var _prompt: RichTextLabel
var _rows: VBoxContainer
var _readouts: VBoxContainer
var _ready_button: Button
var _col: VBoxContainer
## Lesson 9: switches the picture between the current's way and the electrons'.
var _flow: Button
## Lessons 5 and 6: the truth table, filled in as the switch cases are seen.
var _table: Diagram
var _signature := ""


func _ready() -> void:
	name = "TryPanel"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	_col = col
	var title := Label.new()
	title.text = "Try it"
	title.theme_type_variation = "HeadingLabel"
	HudText.font_size(title, 20, game)
	col.add_child(title)
	_prompt = HudText.label(game, 16)
	col.add_child(_prompt)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	col.add_child(_rows)
	_readouts = VBoxContainer.new()
	_readouts.add_theme_constant_override("separation", 2)
	col.add_child(_readouts)
	_flow = Button.new()
	_flow.theme_type_variation = "FlatButton"
	_flow.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
	_flow.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_flow.visible = false
	_flow.pressed.connect(_toggle_flow)
	col.add_child(_flow)
	_ready_button = Button.new()
	_ready_button.text = "I'm ready to build"
	_ready_button.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
	_ready_button.pressed.connect(func() -> void: ready_pressed.emit())
	col.add_child(_ready_button)


func refresh(s: GameState) -> void:
	if s.level == null:
		return
	HudText.put(_prompt, s.level.try_prompt, game)
	_refresh_table(s)
	_flow.visible = _wants_flow(s.level)
	var electrons := bool(game.state.view_settings().get("electron_flow", false))
	_flow.text = "Show the current's way" if electrons else "Show the electrons' way"
	var reads := s.readouts()
	var sig := "%s|%s|%s" % [s.session.poke_done, reads, game.state.progress.settings.get("night", false)]
	if sig == _signature:
		return
	_signature = sig
	for c in _rows.get_children() + _readouts.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()
	for i in s.level.pokes.size():
		var done := i < s.session.poke_done.size() and s.session.poke_done[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var mark := Label.new()
		mark.text = "✓" if done else "○"
		mark.custom_minimum_size = Vector2(18, 0)
		HudText.font_size(mark, 16, game)
		row.add_child(mark)
		var text := HudText.label(game, 15)
		HudText.put(text, str(s.level.pokes[i]["text"]), game)
		row.add_child(text)
		row.set_meta("done", done)
		row.set_meta("text", str(s.level.pokes[i]["text"]))
		_rows.add_child(row)
	for r in reads:
		var l := Label.new()
		l.text = str(r["text"])
		l.theme_type_variation = "HeadingLabel"
		HudText.font_size(l, 18, game)
		_readouts.add_child(l)


## A truth table when Try it's circuit has switches A and B; each case seen
## is marked with what the LED did. A new Try it starts a new table.
func _refresh_table(s: GameState) -> void:
	var wanted := TruthRows.row(s.level.try_circuit) >= 0
	var rows := s.truth_rows()
	if _table != null:
		var stale := not wanted
		var marked: Array = _table.call("results")
		for i in marked.size():
			if int(marked[i]) >= 0 and not rows.has(i):
				stale = true
		if stale:
			_col.remove_child(_table)
			_table.queue_free()
			_table = null
	if wanted and _table == null:
		_table = Diagrams.make("truth_table", game)
		_table.custom_minimum_size = Vector2(0, 150)
		_col.add_child(_table)
		_col.move_child(_table, _rows.get_index() + 1)
	if _table != null:
		for row in rows:
			_table.call("mark", int(row), bool(rows[row]))


## A Try it whose pokes ask to switch the picture between the current's way
## and the electrons' way gets the button that does it.
static func _wants_flow(level: LevelDef) -> bool:
	for poke in level.pokes:
		var flag := str((poke["check"] as Dictionary).get("flag", ""))
		if flag in ["did:electron_flow", "did:current_flow"]:
			return true
	return false


## Switches Try it's own picture; the saved Electron flow setting stays as it
## is, so nothing carries into later lessons.
func _toggle_flow() -> void:
	var electrons := not game.state.try_electron_flow
	game.state.try_electron_flow = electrons
	game.set_ui_flag("did:electron_flow" if electrons else "did:current_flow")


func flow_button() -> Button:
	return _flow if _flow.visible else null


## The truth table (null when this Try it has none).
func truth_table() -> Diagram:
	return _table


func prompt_text() -> String:
	return _prompt.get_parsed_text()


## [{text, done}] for each thing to try, in order.
func poke_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row in _rows.get_children():
		if not row.is_queued_for_deletion():
			out.append({"text": str(row.get_meta("text")), "done": bool(row.get_meta("done"))})
	return out


func readout_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for l in _readouts.get_children():
		if not l.is_queued_for_deletion():
			out.append((l as Label).text)
	return out


func ready_button() -> Button:
	return _ready_button
