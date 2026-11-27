class_name GuideBubble
extends PanelContainer
## Pip's speech bubble. It shows the intro and the outro one line at a time
## with Next, and Pip's help (mistakes, hints, offers) with optional action
## buttons. `kind` says what is showing: "intro", "outro", "help" or "".

var game: Game
var pip := Pip.new()
var mood := "happy"
var kind := ""

var _text: RichTextLabel
var _source: RichTextLabel
var _actions: HFlowContainer
var _close: IconButton
var _line := ""


func _ready() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	pip.custom_minimum_size = Vector2(72, 72)
	pip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(pip)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	row.add_child(col)
	_text = HudText.label(game)
	col.add_child(_text)
	_source = HudText.label(game, 13)
	_source.visible = false
	col.add_child(_source)
	_actions = HFlowContainer.new()
	_actions.add_theme_constant_override("h_separation", 8)
	_actions.add_theme_constant_override("v_separation", 8)
	col.add_child(_actions)
	_close = IconButton.make("close", "Close")
	_close.custom_minimum_size = Vector2(IconButton.MIN_TOUCH, IconButton.MIN_TOUCH)
	_close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_close.pressed.connect(hide_bubble)
	row.add_child(_close)
	visible = false


## `actions` are {label, callback}; `source` is shown small under the text.
func show_line(text: String, line_mood: String, line_kind: String, actions: Array = [], source := "", closable := true) -> void:
	kind = line_kind
	mood = line_mood
	pip.mood = line_mood
	_line = text
	HudText.put(_text, text, game)
	_source.visible = source != ""
	if source != "":
		HudText.put(_source, "Source: " + source, game, false, false)
	for c in _actions.get_children():
		_actions.remove_child(c)
		c.queue_free()
	for a in actions:
		var b := Button.new()
		b.text = a["label"]
		b.pressed.connect(a["callback"])
		_actions.add_child(b)
	_actions.visible = not actions.is_empty()
	_close.visible = closable
	visible = true


## Adds `more` under the line showing (a mistake's why), once.
func expand(more: String) -> void:
	if more == "" or more in _text.get_parsed_text():
		return
	HudText.put(_text, _line + "\n" + more, game)


func hide_bubble() -> void:
	visible = false
	kind = ""


func plain_text() -> String:
	return _text.get_parsed_text()


func action_buttons() -> Array[Button]:
	var out: Array[Button] = []
	for c in _actions.get_children():
		if c is Button and not c.is_queued_for_deletion():
			out.append(c)
	return out
