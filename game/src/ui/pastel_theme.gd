class_name PastelTheme
extends RefCounted
## Builds the pastel interface Theme in code: rounded cards and buttons,
## soft shadows and the Nunito font.

const FONT_REGULAR := "res://assets/fonts/nunito-latin-400-normal.woff2"
const FONT_BOLD := "res://assets/fonts/nunito-latin-700-normal.woff2"
const FONT_EXTRABOLD := "res://assets/fonts/nunito-latin-800-normal.woff2"


static func build(night := false, large_text := false) -> Theme:
	var scale := 1.25 if large_text else 1.0
	var t := Theme.new()
	var regular: Font = load(FONT_REGULAR)
	var bold: Font = load(FONT_BOLD)
	var extrabold: Font = load(FONT_EXTRABOLD)
	var ink := Palette.color("ink", night)
	var ink_soft := Palette.color("ink_soft", night)
	t.default_font = regular
	t.default_font_size = 22 if large_text else 18

	_buttons(t, night, ink, ink_soft)

	var panel := _card(Palette.color("paper", night), 20, ink, 10)
	panel.set_content_margin_all(16)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)

	t.set_color("font_color", "Label", ink)
	t.set_type_variation("HeadingLabel", "Label")
	t.set_font("font", "HeadingLabel", extrabold)
	t.set_font_size("font_size", "HeadingLabel", roundi(28 * scale))
	t.set_color("font_color", "HeadingLabel", ink)

	t.set_color("default_color", "RichTextLabel", ink)
	t.set_font("normal_font", "RichTextLabel", regular)
	t.set_font("bold_font", "RichTextLabel", bold)
	return t


static func _buttons(t: Theme, night: bool, ink: Color, ink_soft: Color) -> void:
	var normal := _card(Palette.color("lilac", night), 16, ink, 6)
	var hover := _card(Palette.color("lavender", night), 16, ink, 6)
	var pressed := _card(Palette.color("lavender", night), 16, ink, 2)
	pressed.shadow_offset = Vector2(0, 1)
	var disabled := _card(Palette.color("line", night), 16, ink, 0)
	var focus := _card(Color(0, 0, 0, 0), 16, ink, 0)
	focus.draw_center = false
	focus.set_border_width_all(3)
	focus.border_color = Palette.color("lavender", night)
	for pair in [["normal", normal], ["hover", hover], ["pressed", pressed],
			["disabled", disabled], ["focus", focus]]:
		var sb: StyleBoxFlat = pair[1]
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		t.set_stylebox(pair[0], "Button", sb)
	# Pastel accents keep their light values at night, so text on them is
	# always the dark ink; disabled buttons sit on "line" and follow the theme.
	var on_pastel := Palette.color("ink", false)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", on_pastel)
	t.set_color("font_disabled_color", "Button", ink_soft)


## A rounded, softly shadowed card: 2 px border in ink at 15% alpha and a
## shadow in ink at 12% alpha, offset (0, 3).
static func _card(fill: Color, radius: int, ink: Color, shadow: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(2)
	sb.border_color = Color(ink, 0.15)
	sb.shadow_size = shadow
	sb.shadow_color = Color(ink, 0.12)
	sb.shadow_offset = Vector2(0, 3)
	sb.anti_aliasing = true
	return sb
