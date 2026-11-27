class_name IconButton
extends Button
## A round-cornered button with a small drawn icon, so the HUD never depends on
## a font having symbol glyphs. Icons: back, undo, redo, calculator, book,
## gear, bulb, close, test.

var icon_name := ""


static func make(icon_id: String, tip: String, label := "") -> IconButton:
	var b := IconButton.new()
	b.icon_name = icon_id
	b.tooltip_text = tip
	b.text = label
	b.custom_minimum_size = Vector2(48, 48)
	if label != "":
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_constant_override("h_separation", 0)
	return b


func _ready() -> void:
	if text != "":
		# Leave room for the icon on the left.
		add_theme_stylebox_override("normal", _padded("normal"))
		add_theme_stylebox_override("hover", _padded("hover"))
		add_theme_stylebox_override("pressed", _padded("pressed"))
		add_theme_stylebox_override("disabled", _padded("disabled"))


func _padded(state: String) -> StyleBox:
	var sb := get_theme_stylebox(state).duplicate() as StyleBox
	if sb is StyleBoxFlat:
		(sb as StyleBoxFlat).content_margin_left = 46
	return sb


func _draw() -> void:
	var ink := get_theme_color("font_disabled_color" if disabled else "font_color")
	var s := 22.0
	var c := Vector2(24.0, size.y / 2.0) if text != "" else size / 2.0
	HudIcons.draw(self, icon_name, Rect2(c - Vector2(s, s) / 2.0, Vector2(s, s)), ink)
