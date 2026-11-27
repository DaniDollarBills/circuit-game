class_name HandArt
extends RefCounted
## The moving hand's look: a fingertip for touch screens, a pointer for the
## mouse, drawn with the canvas so it stays crisp. `at` is the point it
## presses; `scale` 1 is about 40 px tall.


static func draw(ci: CanvasItem, at: Vector2, mode: String, pressed: bool, scale := 1.0) -> void:
	var ink := Palette.color("ink")
	if pressed:
		ci.draw_circle(at, 16.0 * scale, Color(Palette.color("lavender"), 0.45), true, -1.0, true)
	if mode == "touch":
		_finger(ci, at, ink, pressed, scale)
	else:
		_pointer(ci, at, ink, scale)


## A finger reaching in from the lower right, its tip on `at`.
static func _finger(ci: CanvasItem, at: Vector2, ink: Color, pressed: bool, s: float) -> void:
	var dir := Vector2(0.55, 1.0).normalized()
	var tip := at + dir * (2.0 if pressed else 6.0) * s
	var base := tip + dir * 46.0 * s
	var side := Vector2(-dir.y, dir.x) * 9.0 * s
	var skin := Color("#F6D2B8")
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(tip + (side * cos(a)) + dir * sin(a) * 9.0 * s)
	pts.append(base + side)
	pts.append(base - side)
	pts.reverse()
	ci.draw_colored_polygon(pts, skin)
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, ink, 2.0 * s, true)
	# The nail.
	var nail := tip + dir * 9.0 * s
	ci.draw_circle(nail, 4.5 * s, Color("#FBE6D8"), true, -1.0, true)
	ci.draw_arc(nail, 4.5 * s, 0, TAU, 16, Color(ink, 0.5), 1.2 * s, true)


## A classic arrow pointer with its tip on `at`.
static func _pointer(ci: CanvasItem, at: Vector2, ink: Color, s: float) -> void:
	var pts := PackedVector2Array([
		Vector2(0, 0), Vector2(0, 28), Vector2(7, 21), Vector2(12, 32), Vector2(17, 30), Vector2(12, 19), Vector2(21, 19),
	])
	for i in pts.size():
		pts[i] = at + pts[i] * s
	ci.draw_colored_polygon(pts, Color.WHITE)
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, ink, 2.0 * s, true)
