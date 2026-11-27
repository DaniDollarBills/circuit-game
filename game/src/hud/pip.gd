class_name Pip
extends Control
## Pip, the guide: a little spark with a face, drawn rather than imported so it
## stays crisp at any size. Moods: happy, curious, wow, oops.

var mood := "happy":
	set(value):
		mood = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.4
	var c := size / 2.0 + Vector2(0, r * 0.1)
	var ink := Palette.color("ink")
	var butter := Palette.color("butter")
	var peach := Palette.color("peach")
	draw_circle(c, r * 1.2, Color(Palette.color("spark"), 0.35), true, -1.0, true)
	# The tuft: a small four-pointed spark on top.
	var t := c + Vector2(0, -r * 1.02)
	var tuft := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2.0
		tuft.append(t + Vector2.from_angle(a) * (r * 0.32 if i % 2 == 0 else r * 0.1))
	draw_colored_polygon(tuft, Palette.color("spark"))
	# The body, butter at the top fading to peach at the bottom.
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 48:
		var p := c + Vector2.from_angle(TAU * i / 48.0) * r
		pts.append(p)
		cols.append(butter.lerp(peach, clampf((p.y - (c.y - r)) / (2.0 * r), 0.0, 1.0)))
	draw_polygon(pts, cols)
	draw_arc(c, r, 0, TAU, 48, Color(ink, 0.18), 1.5, true)
	# Cheeks.
	var rose := Color(Palette.color("rose"), 0.8)
	draw_circle(c + Vector2(-r * 0.56, r * 0.18), r * 0.14, rose, true, -1.0, true)
	draw_circle(c + Vector2(r * 0.56, r * 0.18), r * 0.14, rose, true, -1.0, true)
	# Eyes.
	var eye := r * (0.13 if mood == "wow" else 0.1)
	for side in [-1.0, 1.0]:
		var e := c + Vector2(side * r * 0.32, -r * 0.08)
		if mood == "oops":
			# Squeezed shut: > <
			var tip := e + Vector2(-side * eye, 0)
			draw_line(e + Vector2(side * eye, -eye * 0.7), tip, ink, 2.0, true)
			draw_line(e + Vector2(side * eye, eye * 0.7), tip, ink, 2.0, true)
		else:
			draw_circle(e, eye, ink, true, -1.0, true)
			draw_circle(e + Vector2(-eye * 0.35, -eye * 0.35), eye * 0.35, Color.WHITE, true, -1.0, true)
	# Mouth.
	var m := c + Vector2(0, r * 0.3)
	match mood:
		"happy":
			draw_arc(m + Vector2(0, -r * 0.12), r * 0.22, PI * 0.15, PI * 0.85, 12, ink, 2.0, true)
		"curious":
			draw_arc(m + Vector2(r * 0.08, 0), r * 0.08, 0, TAU, 12, ink, 2.0, true)
		"wow":
			draw_circle(m + Vector2(0, r * 0.02), r * 0.13, ink, true, -1.0, true)
		"oops":
			var wave := PackedVector2Array()
			for i in 9:
				wave.append(m + Vector2(-r * 0.2 + i * r * 0.05, sin(i * PI / 2.0) * r * 0.04))
			draw_polyline(wave, ink, 2.0, true)
			draw_circle(c + Vector2(r * 0.82, -r * 0.5), r * 0.09, Palette.color("sky"), true, -1.0, true)
