class_name HudIcons
extends RefCounted
## Simple line icons drawn with the canvas, 2 px strokes, rounded ends.


static func draw(ci: CanvasItem, name: String, r: Rect2, ink: Color) -> void:
	var w := 2.2
	var c := r.get_center()
	var s := r.size.x
	match name:
		"back":
			ci.draw_polyline(PackedVector2Array([c + Vector2(s * 0.15, -s * 0.35), c + Vector2(-s * 0.2, 0), c + Vector2(s * 0.15, s * 0.35)]), ink, w, true)
		"undo", "redo":
			var flip := 1.0 if name == "undo" else -1.0
			var pts := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				pts.append(c + Vector2(cos(a) * flip, sin(a)) * s * 0.32 + Vector2(0, s * 0.14))
			ci.draw_polyline(pts, ink, w, true)
			var tip := pts[0] + Vector2(0, s * 0.08)
			ci.draw_polyline(PackedVector2Array([tip + Vector2(-s * 0.13, -s * 0.13), tip, tip + Vector2(s * 0.13, -s * 0.13)]), ink, w, true)
		"restart":
			# A circle that almost closes, its arrow pointing round: start over.
			var ring := PackedVector2Array()
			for i in 21:
				var a := -PI * 0.35 + 1.7 * PI * i / 20.0
				ring.append(c + Vector2(cos(a), sin(a)) * s * 0.3)
			ci.draw_polyline(ring, ink, w, true)
			var end := ring[ring.size() - 1]
			var along := (end - ring[ring.size() - 2]).normalized()
			var side := Vector2(-along.y, along.x)
			ci.draw_polyline(PackedVector2Array([end - along * s * 0.13 + side * s * 0.1, end, end - along * s * 0.13 - side * s * 0.1]), ink, w, true)
		"calculator":
			_rrect(ci, Rect2(c - Vector2(s * 0.32, s * 0.42), Vector2(s * 0.64, s * 0.84)), ink, w)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.2, -s * 0.3), Vector2(s * 0.4, s * 0.16)), ink, false, w)
			for i in 3:
				for j in 2:
					ci.draw_circle(c + Vector2(-s * 0.16 + i * s * 0.16, s * 0.06 + j * s * 0.17), s * 0.035, ink)
		"book":
			ci.draw_polyline(PackedVector2Array([c + Vector2(0, -s * 0.3), c + Vector2(-s * 0.4, -s * 0.36), c + Vector2(-s * 0.4, s * 0.32), c + Vector2(0, s * 0.38), c + Vector2(s * 0.4, s * 0.32), c + Vector2(s * 0.4, -s * 0.36), c + Vector2(0, -s * 0.3), c + Vector2(0, s * 0.38)]), ink, w, true)
		"gear":
			ci.draw_arc(c, s * 0.16, 0, TAU, 20, ink, w, true)
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(c + Vector2.from_angle(a) * s * 0.27, c + Vector2.from_angle(a) * s * 0.42, ink, w * 1.6, true)
			ci.draw_arc(c, s * 0.3, 0, TAU, 24, ink, w, true)
		"bulb":
			ci.draw_arc(c + Vector2(0, -s * 0.08), s * 0.28, PI * 0.78, PI * 2.22, 24, ink, w, true)
			ci.draw_line(c + Vector2(-s * 0.12, s * 0.2), c + Vector2(s * 0.12, s * 0.2), ink, w, true)
			ci.draw_line(c + Vector2(-s * 0.1, s * 0.32), c + Vector2(s * 0.1, s * 0.32), ink, w, true)
		"close":
			ci.draw_line(c + Vector2(-s, -s) * 0.25, c + Vector2(s, s) * 0.25, ink, w, true)
			ci.draw_line(c + Vector2(s, -s) * 0.25, c + Vector2(-s, s) * 0.25, ink, w, true)
		"test":
			_rrect(ci, Rect2(c - Vector2(s * 0.34, s * 0.4), Vector2(s * 0.68, s * 0.8)), ink, w)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.16, 0), c + Vector2(-s * 0.04, s * 0.13), c + Vector2(s * 0.18, -s * 0.14)]), ink, w, true)
		"info":
			ci.draw_arc(c, s * 0.4, 0, TAU, 24, ink, w, true)
			ci.draw_line(c + Vector2(0, -s * 0.02), c + Vector2(0, s * 0.22), ink, w, true)
			ci.draw_circle(c + Vector2(0, -s * 0.18), s * 0.05, ink)


static func _rrect(ci: CanvasItem, r: Rect2, ink: Color, w: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_border_width_all(int(round(w)))
	sb.border_color = ink
	sb.set_corner_radius_all(int(r.size.x * 0.18))
	sb.anti_aliasing = true
	sb.draw(ci.get_canvas_item(), r)
