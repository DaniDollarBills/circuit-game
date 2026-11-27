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
var _signature := ""


func _ready() -> void:
	name = "TryPanel"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
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
	_ready_button = Button.new()
	_ready_button.text = "I'm ready to build"
	_ready_button.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
	_ready_button.pressed.connect(func() -> void: ready_pressed.emit())
	col.add_child(_ready_button)


func refresh(s: GameState) -> void:
	if s.level == null:
		return
	HudText.put(_prompt, s.level.try_prompt, game)
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
