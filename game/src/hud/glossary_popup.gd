class_name GlossaryPopup
extends PanelContainer
## A word's definition, opened by tapping a linked word: the plain meaning
## first, then More precisely.

var game: Game
var term := ""

var _title: Label
var _simple: RichTextLabel
var _precise: RichTextLabel


func _ready() -> void:
	custom_minimum_size = Vector2(340, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	_title = Label.new()
	_title.theme_type_variation = "HeadingLabel"
	_title.add_theme_font_size_override("font_size", 22)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(_title)
	var close_b := IconButton.make("close", "Close")
	close_b.custom_minimum_size = Vector2(36, 36)
	close_b.pressed.connect(func() -> void: visible = false)
	top.add_child(close_b)
	_simple = HudText.label(game, 17)
	col.add_child(_simple)
	var more := Label.new()
	more.text = "More precisely"
	more.add_theme_font_size_override("font_size", 14)
	more.add_theme_color_override("font_color", Palette.color("ink_soft"))
	col.add_child(more)
	_precise = HudText.label(game, 15)
	col.add_child(_precise)
	visible = false


func open(t: String) -> void:
	var key := GlossaryText.resolve(t)
	if not Glossary.ENTRIES.has(key):
		return
	term = key
	var e: Dictionary = Glossary.ENTRIES[key]
	_title.text = e["title"]
	HudText.put(_simple, e["simple"], game)
	HudText.put(_precise, e["precise"], game)
	visible = true
