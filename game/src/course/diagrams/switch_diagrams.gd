extends Diagram
## Lessons 4 to 6: a switch open and closed (a drawbridge for current), on
## and off as bits, and two switches in a row (series) or side by side
## (parallel). Each loop keeps its resistor, as a real LED circuit must.

const LED_TINT := Color("#FF8F9A")


func _paint(time: float) -> void:
	match id:
		"switch_states":
			_states(time)
		"bits":
			_bits(time)
		"series_paths":
			_series(time)
		"parallel_paths":
			_parallel(time)


## Open and closed side by side: the drawbridge above, the switch below.
func _states(time: float) -> void:
	for side in 2:
		var closed := side == 1
		var cx := 105.0 if side == 0 else 295.0
		label(Vector2(cx, 16), "closed: on" if closed else "open: off", 16.0, col("ink"), true)
		# The drawbridge: two banks, the river, and the bridge on its hinge.
		box(Rect2(cx - 32, 78, 64, 16), 3.0, col("sky"))
		box(Rect2(cx - 86, 72, 58, 22), 4.0, col("mint"), Palette.color("ink"), 1.2)
		box(Rect2(cx + 28, 72, 58, 22), 4.0, col("mint"), Palette.color("ink"), 1.2)
		var hinge := Vector2(cx - 28, 72)
		var tip := hinge + (Vector2(56, 0) if closed else Vector2.from_angle(deg_to_rad(-48.0)) * 56.0)
		line(PackedVector2Array([hinge, tip]), Color("#C98B5E"), 7.0)
		# Cars: across the closed bridge; waiting at the edge of the open one.
		if closed:
			for i in 3:
				var x := cx - 80.0 + (80.0 if still and i == 0 else fmod((0.0 if still else time) * 40.0 + i * 56.0, 168.0))
				if not still or i == 0:
					box(Rect2(x - 6, 61, 12, 7), 2.0, col("coral"), Palette.color("ink"), 1.0)
		else:
			for i in 2:
				box(Rect2(cx - 48 - i * 18, 61, 12, 7), 2.0, col("coral"), Palette.color("ink"), 1.0)
		# The switch, in its wire.
		var y := 146.0
		var wire := PackedVector2Array([Vector2(cx - 86, y), Vector2(cx + 86, y)])
		line(PackedVector2Array([wire[0], Vector2(cx - 40, y)]), col("ink_soft"), 4.0)
		line(PackedVector2Array([Vector2(cx + 40, y), wire[1]]), col("ink_soft"), 4.0)
		if closed:
			if still:
				arrow(Vector2(cx - 30, y - 22), Vector2(cx + 30, y - 22), col("ink"), 3.0)
			else:
				sparks(wire, 4, 50.0, time)
		symbol("switch", Vector2(cx, y), 0, {"closed": closed})
		label(Vector2(cx, 192), "joined: current flows" if closed else "a gap: nothing flows", 14.0, col("ink_soft"))
	speed_note(Vector2(200, 208))


## Four lights, each on or off: four bits, 1 for on and 0 for off.
func _bits(time: float) -> void:
	var patterns := [[1, 0, 1, 1], [0, 1, 1, 0], [1, 1, 0, 1], [0, 0, 1, 0]]
	var p: Array = patterns[0] if still else patterns[int(fmod(time / 1.6, 4.0))]
	label(Vector2(200, 24), "each light, on or off, is one bit", 16.0, col("ink"), true)
	for i in 4:
		var x := 80.0 + 80.0 * i
		var on := int(p[i]) == 1
		symbol("led", Vector2(x, 80), 0, {"brightness": 1.0 if on else 0.0, "color": "red"}, 26.0)
		label(Vector2(x, 138), "1" if on else "0", 34.0, col("ink"), true)
		label(Vector2(x, 174), "on" if on else "off", 14.0, col("ink_soft"))
	label(Vector2(200, 204), "four bits: four on-or-off answers", 13.0, col("ink_soft"))


## One path: through switch A, then switch B, round to the LED. The LED
## lights only while both are closed.
func _series(time: float) -> void:
	var states := [[true, true], [true, false], [true, true], [false, true]]
	var s: Array = [true, true] if still else states[int(fmod(time / 1.8, 4.0))]
	var a: bool = s[0]
	var b: bool = s[1]
	var on := a and b
	var path := PackedVector2Array([Vector2(60, 75), Vector2(60, 45), Vector2(330, 45), Vector2(330, 185),
			Vector2(60, 185), Vector2(60, 155)])
	line(path, col("ink_soft"), 4.0)
	if on:
		if still:
			arrow(Vector2(348, 62), Vector2(348, 92), col("ink"), 3.0)
			arrow(Vector2(300, 203), Vector2(256, 203), col("ink"), 3.0)
		else:
			sparks(path, 9, 60.0, time)
	symbol("battery", Vector2(60, 115), 0, {})
	symbol("switch", Vector2(140, 45), 0, {"closed": a, "label": "A"})
	symbol("switch", Vector2(250, 45), 0, {"closed": b, "label": "B"})
	symbol("resistor", Vector2(195, 185), 0, {}, 20.0, {"ohms": 220.0})
	symbol("led", Vector2(330, 115), 90, {"brightness": 1.0 if on else 0.0, "color": "red"})
	label(Vector2(195, 106), "one path:", 16.0, col("ink"), true)
	label(Vector2(195, 126), "both must be closed", 16.0, col("ink"), true)
	if on:
		speed_note()


## Two paths side by side, switch A on one and switch B on the other. Either
## closed switch gets the current round; with both closed, it splits.
func _parallel(time: float) -> void:
	var states := [[true, false], [false, true], [true, true], [false, false]]
	var s: Array = [true, false] if still else states[int(fmod(time / 1.8, 4.0))]
	var a: bool = s[0]
	var b: bool = s[1]
	var on := a or b
	var start := PackedVector2Array([Vector2(55, 80), Vector2(55, 56), Vector2(110, 56)])
	var upper := PackedVector2Array([Vector2(110, 56), Vector2(110, 30), Vector2(290, 30), Vector2(290, 56)])
	var lower := PackedVector2Array([Vector2(110, 56), Vector2(110, 82), Vector2(290, 82), Vector2(290, 56)])
	var rest := PackedVector2Array([Vector2(290, 56), Vector2(345, 56), Vector2(345, 190), Vector2(55, 190), Vector2(55, 160)])
	for p in [start, upper, lower, rest]:
		line(p, col("ink_soft"), 4.0)
	dot(Vector2(110, 56), 4.5, col("ink_soft"))
	dot(Vector2(290, 56), 4.5, col("ink_soft"))
	if on:
		if still:
			arrow(Vector2(150, 14), Vector2(196, 14), col("ink"), 3.0)
			arrow(Vector2(330, 206), Vector2(282, 206), col("ink"), 3.0)
		else:
			for branch in [[a, upper], [b, lower]]:
				if branch[0]:
					var full := PackedVector2Array()
					full.append_array(start)
					full.append_array(branch[1])
					full.append_array(rest)
					sparks(full, 10, 60.0, time)
	symbol("battery", Vector2(55, 120), 0, {})
	symbol("switch", Vector2(200, 30), 0, {"closed": a, "label": "A"})
	symbol("switch", Vector2(200, 82), 0, {"closed": b, "label": "B"})
	symbol("resistor", Vector2(200, 190), 0, {}, 20.0, {"ohms": 220.0})
	symbol("led", Vector2(345, 124), 90, {"brightness": 1.0 if on else 0.0, "color": "red"})
	label(Vector2(200, 132), "two paths:", 16.0, col("ink"), true)
	label(Vector2(200, 152), "either one will do", 16.0, col("ink"), true)
	if on:
		speed_note()
