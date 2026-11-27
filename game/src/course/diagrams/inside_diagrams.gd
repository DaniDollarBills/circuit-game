extends Diagram
## Look inside: labeled cutaways of the Chapter 1 parts. Each is drawn from
## how the real part is built: an LED's chip in its reflector cup, a
## resistor's spiral-cut carbon film, a trimmer's track and wiper, an AA
## cell's layers, a switch's springy strip, and the two meters' insides.

const LABEL := 14.0


func _paint(time: float) -> void:
	match id:
		"led_inside":
			_led(time)
		"resistor_inside":
			_resistor()
		"trimmer_inside":
			_trimmer(time)
		"aa_cell_inside":
			_aa_cell(time)
		"switch_inside":
			_switch(time)
		"meter_inside":
			_meters(time)


## A label starting at `at` (ending there when `left`), with a thin leader
## line from the label's nearest edge to the point `to` it names.
func _callout(at: Vector2, to: Vector2, s: String, left := false) -> void:
	var half := s.length() * LABEL * 0.25
	var c := at + Vector2(-half if left else half, 0)
	var box := Rect2(c - Vector2(half + 3.0, 9.0), Vector2(2.0 * half + 6.0, 18.0))
	var from := Vector2(clampf(to.x, box.position.x, box.end.x), clampf(to.y, box.position.y, box.end.y))
	if box.has_point(to):
		from = to
	line(PackedVector2Array([from, to]), Color(col("ink_soft"), 0.8), 1.2)
	dot(to, 2.2, col("ink_soft"))
	label(c, s, LABEL, col("ink"))


func _led(time: float) -> void:
	var cx := 120.0
	var tint := Palette.led_tint("red")
	# The clear dome: a bullet of epoxy on a rim with one flat side.
	var dome := PackedVector2Array()
	for i in 25:
		var a := PI + PI * i / 24.0
		dome.append(Vector2(cx, 78) + Vector2(cos(a), sin(a)) * 42.0)
	dome.append(Vector2(cx + 42, 160))
	dome.append(Vector2(cx - 42, 160))
	DrawKit.poly(self, dome, Color(tint, 0.28), Color(tint.darkened(0.35), 0.9), 1.6, _k)
	DrawKit.poly(self, PackedVector2Array([Vector2(cx - 52, 160), Vector2(cx + 44, 160), Vector2(cx + 44, 170), Vector2(cx - 52, 170)]),
			Color(tint, 0.35), Color(tint.darkened(0.35), 0.9), 1.4, _k)
	# Legs: the anode post (left, long) and the cathode anvil (right, short).
	var metal := Color("#B9BCC6")
	line(PackedVector2Array([Vector2(cx - 14, 100), Vector2(cx - 14, 214)]), metal, 3.0)
	line(PackedVector2Array([Vector2(cx + 14, 112), Vector2(cx + 14, 200)]), metal, 3.0)
	DrawKit.poly(self, PackedVector2Array([Vector2(cx + 2, 96), Vector2(cx + 30, 96), Vector2(cx + 24, 112), Vector2(cx + 8, 112)]),
			metal, Color(metal.darkened(0.3)), 1.0, _k)
	# The chip in its cup, glowing, and the hair-thin wire to the post.
	var glow := 0.6 if still else 0.45 + 0.35 * (0.5 + 0.5 * sin(time * 3.0))
	DrawKit.glow(self, Vector2(cx + 16, 98), 22.0, Color(tint, glow), _k)
	box(Rect2(cx + 12, 94, 8, 6), 1.0, Color("#FF6A5A"), col("ink"), 0.8)
	var bond := PackedVector2Array()
	for i in 13:
		var s := i / 12.0
		bond.append(Vector2(lerpf(cx + 16, cx - 14, s), 94.0 - sin(s * PI) * 14.0 + s * 6.0))
	line(bond, Color("#D4AF37"), 1.2)
	_callout(Vector2(214, 34), Vector2(cx + 30, 52), "clear plastic lens")
	_callout(Vector2(214, 66), Vector2(cx + 18, 96), "tiny chip that glows")
	_callout(Vector2(214, 96), Vector2(cx, 84), "hair-thin wire")
	_callout(Vector2(214, 126), Vector2(cx + 26, 104), "cup that reflects light")
	_callout(Vector2(214, 158), Vector2(cx + 44, 165), "flat edge: − side")
	_callout(Vector2(214, 186), Vector2(cx + 14, 190), "short leg: − (cathode)")
	_callout(Vector2(214, 212), Vector2(cx - 14, 208), "long leg: + (anode)")


func _resistor() -> void:
	var body := Rect2(96, 82, 208, 56)
	var metal := Color("#B9BCC6")
	line(PackedVector2Array([Vector2(36, 110), Vector2(96, 110)]), metal, 3.0)
	line(PackedVector2Array([Vector2(304, 110), Vector2(364, 110)]), metal, 3.0)
	# The painted lower half with its stripes.
	box(body, 24.0, Color("#E9D8B4"), col("ink"), 1.4)
	for s in [[136.0, "#7A4A2A"], [164.0, "#3FA34D"], [192.0, "#7A4A2A"], [262.0, "#C9A227"]]:
		DrawKit.rrect(self, Rect2(float(s[0]) - 6.0, 110, 12, 27), 2.0, Color(s[1]), Color(0, 0, 0, 0), 0.0, _k)
	# The upper half cut away: ceramic rod, spiral-cut carbon film, end caps.
	DrawKit.rrect(self, Rect2(104, 86, 192, 24), 6.0, Color("#F4F1EA"), Color(col("ink"), 0.5), 1.0, _k)
	var x := 116.0
	while x < 286.0:
		DrawKit.poly(self, PackedVector2Array([Vector2(x, 86), Vector2(x + 9, 86), Vector2(x + 3, 110), Vector2(x - 6, 110)]),
				Color("#3A3330"), Color(0, 0, 0, 0), 0.0, _k)
		x += 14.0
	for cap_x in [96.0, 284.0]:
		DrawKit.rrect(self, Rect2(cap_x, 84, 20, 52), 5.0, metal, col("ink"), 1.0, _k)
	_callout(Vector2(36, 40), Vector2(150, 98), "carbon film, cut in a spiral")
	_callout(Vector2(250, 40), Vector2(240, 104), "ceramic rod")
	_callout(Vector2(36, 190), Vector2(106, 130), "metal end cap")
	_callout(Vector2(210, 190), Vector2(164, 130), "paint and colored stripes")


func _trimmer(time: float) -> void:
	var c := Vector2(150, 112)
	var r := 62.0
	var start := deg_to_rad(135.0)
	var sweep := deg_to_rad(270.0)
	var track := PackedVector2Array()
	for i in 41:
		track.append(c + Vector2.from_angle(start + sweep * i / 40.0) * r)
	line(track, Color("#55505A"), 12.0)
	var turn := 0.65 if still else 0.5 + 0.4 * sin(time * 0.9)
	var used := PackedVector2Array()
	for i in int(40 * turn) + 1:
		used.append(c + Vector2.from_angle(start + sweep * i / 40.0) * r)
	if used.size() >= 2:
		line(used, col("signal_high"), 6.0)
	var tip := c + Vector2.from_angle(start + sweep * turn) * r
	line(PackedVector2Array([c, tip]), Color("#B9BCC6"), 5.0)
	dot(c, 14.0, Color("#EDE6D6"), col("ink"), 1.2)
	line(PackedVector2Array([c + Vector2(-9, 0), c + Vector2(9, 0)]), col("ink"), 2.0)
	dot(track[0], 6.0, Color("#B9BCC6"), col("ink"), 1.0)
	_callout(Vector2(250, 44), track[20] + Vector2(0, -6), "the track")
	_callout(Vector2(250, 112), tip, "the wiper")
	_callout(Vector2(250, 150), track[0], "one end (leg)")
	_callout(Vector2(250, 186), c + Vector2(10, 12), "turn the dial")
	label(Vector2(150, 206), "longer path: more resistance", LABEL, col("ink_soft"))


func _aa_cell(time: float) -> void:
	var can := Rect2(70, 72, 250, 80)
	# The steel can (the + end) with its nub on the right.
	box(Rect2(can.end.x - 2, 98, 14, 28), 3.0, Color("#B9BCC6"), col("ink"), 1.0)
	box(can, 10.0, Color("#B9BCC6"), col("ink"), 1.4)
	# Manganese dioxide paste lining the can, the separator, the zinc gel core.
	box(can.grow(-6), 8.0, Color("#3B3A40"))
	box(can.grow(-20), 6.0, Color("#E9E4F2"))
	box(can.grow(-24), 5.0, Color("#9EA3AE"))
	# The brass pin down the middle to the − end cap on the left.
	line(PackedVector2Array([Vector2(can.position.x - 10, 112), Vector2(can.end.x - 40, 112)]), Color("#D4AF37"), 3.0)
	box(Rect2(can.position.x - 14, 96, 10, 32), 2.0, Color("#B9BCC6"), col("ink"), 1.0)
	label(Vector2(can.end.x + 26, 112), "+", 22.0, col("ink"), true)
	label(Vector2(can.position.x - 30, 112), "−", 22.0, col("ink"), true)
	if still:
		arrow(Vector2(130, 112), Vector2(64, 112), Color("#8FB8F0"), 3.0)
	else:
		for i in 4:
			var x := can.end.x - 60.0 - fmod(time * 30.0 + i * 40.0, 160.0)
			dot(Vector2(x, 112), 4.0, Color("#8FB8F0"), col("ink"), 0.8)
	_callout(Vector2(40, 36), Vector2(120, 73), "steel can: the + end")
	_callout(Vector2(214, 36), Vector2(280, 80), "manganese dioxide")
	_callout(Vector2(40, 186), Vector2(140, 130), "separator")
	_callout(Vector2(214, 186), Vector2(250, 122), "zinc gel")
	_callout(Vector2(40, 212), Vector2(76, 116), "brass pin: the − end")
	speed_note()


func _switch(time: float) -> void:
	var closed := true if still else fmod(time, 4.0) < 2.0
	# The case, cut open.
	box(Rect2(80, 92, 240, 90), 10.0, Color(col("lilac"), 0.6), col("ink"), 1.2)
	# The lever on its pivot.
	var pivot := Vector2(200, 92)
	var lean := -0.45 if closed else 0.45
	line(PackedVector2Array([pivot, pivot + Vector2(sin(lean), -cos(lean)) * 56.0]), Color("#B9BCC6"), 9.0)
	dot(pivot, 7.0, col("ink_soft"))
	# Two contacts and the springy strip that joins them when closed.
	var metal := Color("#C9A227")
	box(Rect2(110, 150, 30, 12), 2.0, metal, col("ink"), 1.0)
	box(Rect2(260, 150, 30, 12), 2.0, metal, col("ink"), 1.0)
	var end := Vector2(270, 148) if closed else Vector2(262, 122)
	line(PackedVector2Array([Vector2(126, 148), Vector2(200, 134), end]), Color("#D9D6E6"), 4.0)
	line(PackedVector2Array([Vector2(125, 162), Vector2(125, 210)]), Color("#B9BCC6"), 3.0)
	line(PackedVector2Array([Vector2(275, 162), Vector2(275, 210)]), Color("#B9BCC6"), 3.0)
	label(Vector2(200, 24), "closed: the strip joins both legs" if closed else "open: a gap, so nothing flows", 15.0, col("ink"), true)
	_callout(Vector2(250, 52), pivot + Vector2(sin(lean), -cos(lean)) * 40.0, "lever")
	_callout(Vector2(300, 112), Vector2(232, 134), "springy metal strip", true)


func _meters(time: float) -> void:
	# The current meter: all the current goes through a tiny resistor inside.
	label(Vector2(100, 24), "current meter", 16.0, col("ink"), true)
	line(PackedVector2Array([Vector2(20, 110), Vector2(180, 110)]), col("ink_soft"), 4.0)
	symbol("resistor", Vector2(100, 110), 0, {}, 14.0, {"ohms": 0.1})
	if not still:
		sparks(PackedVector2Array([Vector2(20, 110), Vector2(180, 110)]), 4, 60.0, time)
	label(Vector2(100, 160), "all of it flows through", LABEL, col("ink_soft"))
	label(Vector2(100, 180), "a tiny 0.1 Ω resistor", LABEL, col("ink_soft"))
	# The voltage meter: 10 MΩ across the part, so almost nothing flows in.
	label(Vector2(300, 24), "voltage meter", 16.0, col("ink"), true)
	line(PackedVector2Array([Vector2(220, 80), Vector2(380, 80)]), col("ink_soft"), 4.0)
	line(PackedVector2Array([Vector2(240, 80), Vector2(240, 120), Vector2(260, 120)]), col("ink_soft"), 2.0)
	line(PackedVector2Array([Vector2(340, 120), Vector2(360, 120), Vector2(360, 80)]), col("ink_soft"), 2.0)
	symbol("resistor", Vector2(300, 120), 0, {}, 14.0, {"ohms": 1.0e7})
	label(Vector2(300, 160), "10 MΩ across the part:", LABEL, col("ink_soft"))
	label(Vector2(300, 180), "almost no current goes in", LABEL, col("ink_soft"))
	speed_note(Vector2(200, 210))
