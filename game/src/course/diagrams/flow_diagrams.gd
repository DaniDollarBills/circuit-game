extends Diagram
## Lesson 3's pictures: water in a loop of pipe as a picture of a circuit;
## Ohm's law as a triangle; units that come in thousands; and where each
## meter goes.

const WATER := Color("#8FC2EE")
const PIPE := Color("#9AA3B5")
const PROBE_RED := Color("#E0565B")
const PROBE_BLACK := Color("#3D3A4B")
## The water picture: the wide pipe's water width, how far along the loop the
## top pipe starts (its left side is 104 long), and how many drops go round.
const WATER_WIDE := 14.0
const WATER_PATH_TOP := 104.0
const WATER_DOTS := 14


func _paint(time: float) -> void:
	match id:
		"water_analogy":
			_water(time)
		"ohm_triangle":
			_triangle(time)
		"unit_ladder":
			_ladder()
		"meter_placement":
			_meters(time)


## A pump pushes water round a loop of pipe, and a narrow section squeezes
## it. Squeeze harder and the flow slows all the way round, not just there.
## In the narrow part the water moves faster: the same amount passes every
## point each second, and that amount is the current.
func _water(time: float) -> void:
	var l := 70.0
	var r := 330.0
	var t := 62.0
	var b := 166.0
	var squeeze := _squeeze(time)
	var moved := _moved(time)
	var path := PackedVector2Array([Vector2(l, b), Vector2(l, t), Vector2(r, t), Vector2(r, b), Vector2(l, b)])
	line(path, PIPE, 22.0)
	line(path, WATER, 14.0)
	# The narrow section on top, with a funnel at each end.
	var narrow := lerpf(12.0, 3.0, squeeze)
	box(Rect2(156, t - 12, 108, 24), 0.0, col("paper"))
	for side in [-1.0, 1.0]:
		var outer_x: float = 210.0 + side * 54.0
		var inner_x: float = 210.0 + side * 38.0
		DrawKit.poly(self, PackedVector2Array([Vector2(outer_x, t - 11), Vector2(inner_x, t - narrow / 2.0 - 4.0),
				Vector2(inner_x, t + narrow / 2.0 + 4.0), Vector2(outer_x, t + 11)]), PIPE, Color(0, 0, 0, 0), 0.0, _k)
		DrawKit.poly(self, PackedVector2Array([Vector2(outer_x, t - 7), Vector2(inner_x, t - narrow / 2.0),
				Vector2(inner_x, t + narrow / 2.0), Vector2(outer_x, t + 7)]), WATER, Color(0, 0, 0, 0), 0.0, _k)
	line(PackedVector2Array([Vector2(172, t), Vector2(248, t)]), PIPE, narrow + 8.0)
	line(PackedVector2Array([Vector2(172, t), Vector2(248, t)]), WATER, narrow)
	# The water moving round: faster, and thinner, where the pipe is narrow.
	for c in water_dots(time):
		var width := WATER_WIDE
		if absf(c.y - t) < 1.0:
			width = _water_width(c.x, narrow)
		dot(c, minf(3.5, width / 2.0), Color(1, 1, 1, 0.9))
	if still:
		arrow(Vector2(290, b - 24), Vector2(236, b - 24), col("ink"), 3.0)
		arrow(Vector2(r - 24, 92), Vector2(r - 24, 138), col("ink"), 3.0)
	# The pump, turning with the flow.
	var pump := Vector2(l, 114)
	dot(pump, 24.0, Color("#DDEBF7"), col("ink"), 1.6)
	var turn := moved * 0.05
	for k in 3:
		var a := turn + TAU * k / 3.0
		line(PackedVector2Array([pump, pump + Vector2.from_angle(a) * 17.0]), col("ink"), 3.0)
	dot(pump, 4.0, col("ink"))
	label(Vector2(210, 28), "narrow pipe = resistor: it squeezes", 14.0, col("ink"))
	label(Vector2(112, 198), "pump = battery: it pushes", 14.0, col("ink"))
	label(Vector2(300, 198), "flow = current", 14.0, col("ink"))


## The water's width in the pipe (design units): the wide pipe's, or across
## the funnels and the narrow section on top, at `x`.
static func _water_width(x: float, narrow: float) -> float:
	if x <= 156.0 or x >= 264.0:
		return WATER_WIDE
	if x < 172.0:
		return lerpf(WATER_WIDE, narrow, (x - 156.0) / 16.0)
	if x > 248.0:
		return lerpf(narrow, WATER_WIDE, (x - 248.0) / 16.0)
	return narrow


## How hard the narrow section squeezes, 0 (wide) to 1 (tight).
func _squeeze(time: float) -> float:
	return 0.6 if still else 0.5 + 0.5 * sin(time * TAU / 6.0)


## How far the water in the wide pipe has moved: its speed, 37.5 − 22.5 sin(wt),
## falls as the narrow section squeezes, all the way round the loop.
func _moved(time: float) -> float:
	var w := TAU / 6.0
	return 0.0 if still else 37.5 * time + 22.5 / w * cos(time * w)


## Where each drop is at `time`. The same amount of water passes every point
## each second (that's the current), so where the pipe narrows the drops move
## faster and spread out: speed goes as 1 ÷ width.
func water_dots(time: float) -> PackedVector2Array:
	var narrow := lerpf(12.0, 3.0, _squeeze(time))
	var path := PackedVector2Array([Vector2(70, 166), Vector2(70, 62), Vector2(330, 62), Vector2(330, 166), Vector2(70, 166)])
	var length := Diagram.path_length(path)
	# Wide-pipe distance covered by each unit step along the path.
	var steps := int(ceil(length))
	var eq := PackedFloat64Array()
	eq.resize(steps + 1)
	for k in steps:
		var d := float(k) + 0.5
		var width := WATER_WIDE
		if d > WATER_PATH_TOP and d < WATER_PATH_TOP + 260.0:
			width = _water_width(70.0 + d - WATER_PATH_TOP, narrow)
		eq[k + 1] = eq[k] + width / WATER_WIDE
	var total := eq[steps]
	var out := PackedVector2Array()
	for i in WATER_DOTS:
		var e := fmod(_moved(time) + total * i / WATER_DOTS, total)
		var lo := 0
		var hi := steps
		while hi - lo > 1:
			var mid := (lo + hi) / 2
			if eq[mid] <= e:
				lo = mid
			else:
				hi = mid
		var d := lo + (e - eq[lo]) / maxf(eq[hi] - eq[lo], 1e-9)
		out.append(Diagram.along(path, minf(d, length)))
	return out


## V on top, I × R below. Cover the one you want, and the other two show how
## to work it out.
func _triangle(time: float) -> void:
	var apex := Vector2(112, 28)
	var bl := Vector2(24, 184)
	var br := Vector2(200, 184)
	DrawKit.poly(self, PackedVector2Array([apex, br, bl]), col("lilac"), Palette.color("ink"), 2.0, _k)
	var mid := 118.0
	var f := (mid - apex.y) / (bl.y - apex.y)
	line(PackedVector2Array([Vector2(lerpf(apex.x, bl.x, f), mid), Vector2(lerpf(apex.x, br.x, f), mid)]), Palette.color("ink"), 2.0)
	line(PackedVector2Array([Vector2(apex.x, mid), Vector2(apex.x, bl.y)]), Palette.color("ink"), 2.0)
	# Each letter with its quantity's name under it (the units are on the
	# Learn card), so V the voltage isn't mixed up with V the volt.
	var spots := [Vector2(112, 82), Vector2(76, 146), Vector2(150, 146)]
	var letters := ["V", "I", "R"]
	var names := ["voltage", "current", "resistance"]
	var name_at := [Vector2(112, 108), Vector2(76, 172), Vector2(152, 172)]
	var cover := -1 if still else int(fmod(time / 2.5, 3.0))
	for i in 3:
		if i == cover:
			dot(spots[i], 19.0, col("lavender"), Palette.color("ink"), 1.4)
			label(spots[i], "?", 20.0, Palette.color("ink"), true, col("lavender"))
		else:
			label(spots[i], letters[i], 26.0, Palette.color("ink"), true, col("lilac"))
		label(name_at[i], names[i], 13.0, Palette.color("ink"), false, col("lilac"))
	var formulas := ["V = I × R", "I = V ÷ R", "R = V ÷ I"]
	for i in 3:
		var at := Vector2(302, 70 + i * 44)
		if i == cover:
			box(Rect2(at - Vector2(76, 17), Vector2(152, 34)), 10.0, col("lavender"))
			label(at, formulas[i], 20.0, Palette.color("ink"), true, col("lavender"))
		else:
			label(at, formulas[i], 20.0, col("ink") if cover < 0 else col("ink_soft"), cover < 0)
	label(Vector2(302, 30), "cover the one you want", 14.0, col("ink_soft"))


## Units come in thousands: 1 A is 1000 mA, and 1 kΩ is 1000 Ω.
func _ladder() -> void:
	var sides := [
		{"x": 110.0, "big": "A", "big_name": "amps", "small": "mA", "small_name": "milliamps", "example": "0.020 A = 20 mA"},
		{"x": 290.0, "big": "kΩ", "big_name": "kilohms", "small": "Ω", "small_name": "ohms", "example": "2.2 kΩ = 2200 Ω"},
	]
	for s in sides:
		var x: float = s["x"]
		var top := Rect2(x - 48, 26, 96, 48)
		var bottom := Rect2(x - 48, 124, 96, 48)
		box(top, 10.0, col("sky"), Palette.color("ink"), 1.4)
		box(bottom, 10.0, col("butter"), Palette.color("ink"), 1.4)
		label(top.get_center() + Vector2(0, -7), s["big"], 20.0, Palette.color("ink"), true, col("sky"))
		label(top.get_center() + Vector2(0, 13), s["big_name"], 12.0, Palette.color("ink"), false, col("sky"))
		label(bottom.get_center() + Vector2(0, -7), s["small"], 20.0, Palette.color("ink"), true, col("butter"))
		label(bottom.get_center() + Vector2(0, 13), s["small_name"], 12.0, Palette.color("ink"), false, col("butter"))
		arrow(Vector2(x - 22, 80), Vector2(x - 22, 118), col("ink"), 2.5)
		arrow(Vector2(x + 22, 118), Vector2(x + 22, 80), col("ink"), 2.5)
		label(Vector2(x - 58, 99), "× 1000", 12.0, col("ink"), true)
		label(Vector2(x + 58, 99), "÷ 1000", 12.0, col("ink"), true)
		label(Vector2(x, 198), s["example"], 15.0, col("ink"), true)


## A current meter goes in the loop, so all the current flows through it; a
## voltage meter's two probes go across a part, one on each side of it.
func _meters(time: float) -> void:
	var loop := PackedVector2Array([Vector2(60, 80), Vector2(60, 50), Vector2(330, 50), Vector2(330, 190),
			Vector2(60, 190), Vector2(60, 160)])
	line(loop, col("ink_soft"), 4.0)
	# The voltage meter's probes: red to one end of the resistor, black to the other.
	line(PackedVector2Array([Vector2(155, 50), Vector2(155, 126), Vector2(175, 126)]), PROBE_RED, 2.5)
	line(PackedVector2Array([Vector2(235, 50), Vector2(235, 126), Vector2(215, 126)]), PROBE_BLACK.lightened(0.15) if night else PROBE_BLACK, 2.5)
	if still:
		arrow(Vector2(232, 32), Vector2(292, 32), col("ink"), 3.0)
		arrow(Vector2(346, 100), Vector2(346, 150), col("ink"), 3.0)
	else:
		sparks(loop, 8, 60.0, time)
	symbol("battery", Vector2(60, 120), 0, {})
	symbol("resistor", Vector2(195, 50), 0, {}, 20.0, {"ohms": 1000.0})
	symbol("ammeter", Vector2(330, 120), 90, {})
	label(Vector2(288, 120), "5.0 mA", 13.0, col("ink"), true)
	symbol("voltmeter", Vector2(195, 126), 0, {"reading": "5.0 V"})
	label(Vector2(195, 174), "voltage meter: across a part", 13.0, col("ink"))
	label(Vector2(286, 208), "current meter: in the loop", 13.0, col("ink"))
	speed_note(Vector2(40, 208))
