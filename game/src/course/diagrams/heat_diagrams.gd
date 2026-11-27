extends Diagram
## Lessons 7 and 8: a short circuit, where the current floods the easy path
## and the battery heats up; and power in watts against a part's rating.

const LED_TINT := Color("#FF8F9A")


func _paint(time: float) -> void:
	match id:
		"short_path":
			_short(time)
		"power_heat":
			_power(time)


## A wire straight from + to −: the current floods through it, skipping the
## LED (dark), and only the battery's own 1 Ω holds it back, so it heats up.
func _short(time: float) -> void:
	var loop := PackedVector2Array([Vector2(60, 75), Vector2(60, 45), Vector2(330, 45), Vector2(330, 185),
			Vector2(60, 185), Vector2(60, 155)])
	var short := PackedVector2Array([Vector2(60, 75), Vector2(60, 45), Vector2(120, 45), Vector2(120, 185),
			Vector2(60, 185), Vector2(60, 155)])
	line(loop, col("ink_soft"), 4.0)
	line(PackedVector2Array([Vector2(120, 45), Vector2(120, 185)]), col("coral").darkened(0.15), 5.0)
	if still:
		arrow(Vector2(136, 80), Vector2(136, 150), col("coral").darkened(0.25), 4.0)
	else:
		sparks(short, 14, 170.0, time)
	symbol("battery", Vector2(60, 115), 0, {"hot": true})
	symbol("resistor", Vector2(225, 45), 0, {}, 20.0, {"ohms": 220.0})
	symbol("led", Vector2(330, 115), 90, {"brightness": 0.0, "color": "red"})
	if not still:
		# Heat rising off the battery.
		for i in 3:
			var x := 22.0 + i * 9.0
			var wave := PackedVector2Array()
			for k in 9:
				var y := 150.0 - k * 9.0
				wave.append(Vector2(x + sin(time * 4.0 + k * 0.9 + i) * 3.0, y))
			line(wave, Color(col("coral"), 0.7), 1.6)
	label(Vector2(224, 102), "a short: an easy path", 15.0, col("ink"), true)
	label(Vector2(224, 120), "straight from + to −", 15.0, col("ink"), true)
	label(Vector2(268, 158), "the LED is skipped", 13.0, col("ink_soft"))
	label(Vector2(94, 206), "the battery heats up", 13.0, col("coral"), true)
	speed_note()


## Power in watts against two ratings: 220 Ω across 5 V makes 0.11 W, fine
## for a ¼ W resistor; 47 Ω makes 0.51 W, too much for ¼ W, fine for 1 W.
func _power(time: float) -> void:
	var x0 := 60.0
	var per_watt := 250.0
	var grow := 1.0 if still else clampf(fmod(time, 5.0) / 1.6, 0.0, 1.0)
	label(Vector2(200, 18), "power: watts of heat", 16.0, col("ink"), true)
	var bars := [[0.1126, "220 Ω across 5 V: 0.11 W", 68.0], [0.5100, "47 Ω across 5 V: 0.51 W", 128.0]]
	for rating in [[0.25, "¼ W rating"], [1.0, "1 W rating"]]:
		var x: float = x0 + per_watt * float(rating[0])
		for b in bars:
			dashes(Vector2(x, float(b[2]) - 8.0), Vector2(x, float(b[2]) + 26.0), col("ink_soft"), 2.0, 5.0, 4.0)
		line(PackedVector2Array([Vector2(x, 170), Vector2(x, 180)]), col("ink_soft"), 2.0)
		label(Vector2(x, 194), rating[1], 12.0, col("ink"), true)
	line(PackedVector2Array([Vector2(x0, 180), Vector2(x0 + per_watt * 1.2, 180)]), col("ink_soft"), 1.5)
	for b in bars:
		var watts: float = float(b[0]) * grow
		var y: float = b[2]
		label(Vector2(200, y - 18), b[1], 13.0, col("ink"))
		box(Rect2(x0, y - 4, per_watt * minf(watts, 0.25), 22), 5.0, col("mint"), Palette.color("ink"), 1.2)
		if watts > 0.25:
			box(Rect2(x0 + per_watt * 0.25, y - 4, per_watt * (watts - 0.25), 22), 5.0, col("coral"), Palette.color("ink"), 1.2)
	if grow >= 1.0:
		label(Vector2(250, 160), "too hot for ¼ W, fine for 1 W", 13.0, col("coral").darkened(0.2), true)
	label(Vector2(x0, 194), "0 W", 12.0, col("ink_soft"))
