class_name Spotlight
extends Control
## Dims the screen except one rounded hole, to point at a part of it (Lesson
## 0's tour). Taps inside the hole reach what's there; the rest is held back.

var _hole := Rect2()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func show_rect(r: Rect2) -> void:
	_hole = r.grow(6.0)
	visible = true
	queue_redraw()


func clear() -> void:
	visible = false


func hole() -> Rect2:
	return _hole


func _has_point(p: Vector2) -> bool:
	return visible and not _hole.has_point(p)


func _draw() -> void:
	var dim := Color(0.1, 0.08, 0.16, 0.42)
	var h := _hole
	draw_rect(Rect2(0, 0, size.x, h.position.y), dim)
	draw_rect(Rect2(0, h.end.y, size.x, size.y - h.end.y), dim)
	draw_rect(Rect2(0, h.position.y, h.position.x, h.size.y), dim)
	draw_rect(Rect2(h.end.x, h.position.y, size.x - h.end.x, h.size.y), dim)
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(3)
	sb.border_color = Palette.color("lavender")
	sb.draw(get_canvas_item(), h)
