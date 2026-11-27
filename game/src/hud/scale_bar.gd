class_name ScaleBar
extends Control
## The real-size scale bar ("1 cm", "5 nm") for the current view, with the
## zoom jump badge when the view crosses into a smaller world.

var meters_visible := 0.0
var jump_text := ""
## Pixels across the view that `meters_visible` covers (the stage's height).
var view_px := 720.0


func _init() -> void:
	custom_minimum_size = Vector2(180, 48)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_view(meters: float, jump: String, height_px: float) -> void:
	meters_visible = meters
	jump_text = jump
	view_px = maxf(height_px, 1.0)
	queue_redraw()


## The bar's length in meters: 1, 2 or 5 times a power of ten, about 100 px.
static func nice_length(meters_per_px: float, target_px := 100.0) -> float:
	var raw := meters_per_px * target_px
	if not (raw > 0.0):
		return 0.0
	var p := pow(10.0, floorf(log(raw) / log(10.0)))
	for k in [1.0, 2.0, 5.0, 10.0]:
		if k * p >= raw * 0.75:
			return k * p
	return 10.0 * p


func _draw() -> void:
	if not (meters_visible > 0.0):
		return
	var mpp := meters_visible / view_px
	var length := nice_length(mpp)
	var px := length / mpp
	var ink := Palette.color("ink")
	var y := size.y - 10.0
	var bar := Rect2(Vector2(4, y - 6), Vector2(px, 6))
	draw_rect(bar.grow(2), Color(Palette.color("paper"), 0.85))
	draw_rect(bar, ink)
	var font := get_theme_default_font()
	draw_string_outline(font, Vector2(4, y - 12), ScaleFormat.meters(length), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Palette.color("paper"))
	draw_string(font, Vector2(4, y - 12), ScaleFormat.meters(length), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
	if jump_text != "":
		var at := Vector2(px + 16, y)
		draw_string_outline(font, at, jump_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Palette.color("paper"))
		draw_string(font, at, jump_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.color("ink"))
