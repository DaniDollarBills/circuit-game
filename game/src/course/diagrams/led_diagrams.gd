extends Diagram
## Lesson 2's pictures: an LED lets current through one way only; the
## battery's 5 V is shared between the LED and the resistor; and the LED's
## current falls as the resistance rises, against its datasheet's limits.

const LED_TINT := Color("#FF8F9A")


func _paint(time: float) -> void:
	match id:
		"led_one_way":
			_one_way(time)
		"voltage_budget":
			_budget(time)
		"current_vs_resistance":
			_curve(time)


## Above, current goes in at the + leg and the LED lights; below, the battery
## is turned round, and the LED blocks it.
func _one_way(time: float) -> void:
	for row in 2:
		var forward := row == 0
		var y := 68.0 if forward else 156.0
		var path := PackedVector2Array([Vector2(44, y), Vector2(356, y)])
		line(path, col("ink_soft"), 4.0)
		label(Vector2(28, y), "+" if forward else "−", 24.0, col("ink"), true)
		label(Vector2(372, y), "−" if forward else "+", 24.0, col("ink"), true)
		symbol("led", Vector2(200, y), 0, {"brightness": 1.0 if forward else 0.0, "color": "red"}, 24.0)
		if forward:
			if still:
				arrow(Vector2(80, y - 22), Vector2(140, y - 22), col("ink"), 3.0)
				arrow(Vector2(260, y - 22), Vector2(320, y - 22), col("ink"), 3.0)
			else:
				sparks(path, 6, 70.0, time)
		else:
			# Pushed the wrong way round: stopped at the LED's bar.
			arrow(Vector2(320, y - 22), Vector2(252, y - 22), col("coral"), 3.0)
			_cross(Vector2(238, y - 22))
	label(Vector2(200, 102), "in at the + leg: current flows, and it lights", 14.0, col("ink_soft"))
	label(Vector2(200, 190), "turned round: blocked, almost no current", 14.0, col("ink_soft"))
	speed_note()


func _cross(at: Vector2) -> void:
	var c := col("coral").darkened(0.2)
	line(PackedVector2Array([at + Vector2(-6, -6), at + Vector2(6, 6)]), c, 3.0)
	line(PackedVector2Array([at + Vector2(-6, 6), at + Vector2(6, -6)]), c, 3.0)


## The battery's 5 V push, shared round the loop: about 2 V across the LED,
## the other 3 V across the resistor. The two parts fill in turn.
func _budget(time: float) -> void:
	var x0 := 60.0
	var per_volt := 56.0
	label(Vector2(200, 24), "the battery's 5 V push", 16.0, col("ink"), true)
	box(Rect2(x0, 46, per_volt * 5.0, 34), 6.0, col("mint"), col("ink"), 1.4)
	for v in 6:
		var x := x0 + per_volt * v
		line(PackedVector2Array([Vector2(x, 80), Vector2(x, 88)]), col("ink_soft"), 1.5)
		label(Vector2(x, 98), "%d V" % v if v == 0 or v == 5 else str(v), 12.0, col("ink_soft"))
	var fill := 1.0 if still else clampf(fmod(time, 5.0) / 3.0, 0.0, 1.0)
	var led_v := 2.0 * clampf(fill / 0.4, 0.0, 1.0)
	var res_v := 3.0 * clampf((fill - 0.4) / 0.6, 0.0, 1.0)
	var y := 120.0
	label(Vector2(200, y - 8), "shared round the loop", 13.0, col("ink_soft"))
	if led_v > 0.0:
		box(Rect2(x0, y + 4, per_volt * led_v, 34), 6.0, LED_TINT, col("ink"), 1.4)
	if res_v > 0.0:
		box(Rect2(x0 + per_volt * 2.0, y + 4, per_volt * res_v, 34), 6.0, col("butter"), col("ink"), 1.4)
	if led_v >= 2.0:
		label(Vector2(x0 + per_volt, y + 21), "LED: about 2 V", 13.0, Palette.color("ink"), true, LED_TINT)
	if res_v >= 3.0:
		label(Vector2(x0 + per_volt * 3.5, y + 21), "resistor: the other 3 V", 13.0, Palette.color("ink"), true, col("butter"))
	label(Vector2(200, 186), "together the parts use the whole 5 V", 14.0, col("ink_soft"))


## The LED's current, I = (5 V − 2 V) ÷ R, falling as the resistance rises,
## against the datasheet's 20 mA and its 30 mA most; a marker runs along it.
func _curve(time: float) -> void:
	var plot := Rect2(64, 34, 300, 144)
	var at := func(ohms: float, ma: float) -> Vector2:
		return Vector2(plot.position.x + ohms / 600.0 * plot.size.x, plot.end.y - ma / 60.0 * plot.size.y)
	var y30: float = (at.call(0.0, 30.0) as Vector2).y
	var y20: float = (at.call(0.0, 20.0) as Vector2).y
	# Above 30 mA the LED burns out.
	box(Rect2(plot.position.x, plot.position.y, plot.size.x, y30 - plot.position.y), 4.0, Color(col("coral"), 0.16))
	label(Vector2(plot.end.x - 34, plot.position.y + 14), "pop!", 14.0, col("coral"), true)
	dashes(Vector2(plot.position.x, y30), Vector2(plot.end.x, y30), col("coral"))
	dashes(Vector2(plot.position.x, y20), Vector2(plot.end.x, y20), col("ink_soft"))
	label(Vector2(276, y30 - 10), "30 mA: the most it can take", 12.0, col("coral"))
	label(Vector2(276, y20 + 11), "20 mA: its datasheet's current", 12.0, col("ink_soft"))
	line(PackedVector2Array([plot.position, Vector2(plot.position.x, plot.end.y), plot.end]), col("ink"), 2.0)
	for ohms in [0, 200, 400, 600]:
		label((at.call(float(ohms), 0.0) as Vector2) + Vector2(0, 12), str(ohms), 12.0, col("ink_soft"))
	for ma in [20, 30, 60]:
		label((at.call(0.0, float(ma)) as Vector2) + Vector2(-16, 0), str(ma), 12.0, col("ink_soft"))
	label(Vector2(214, 210), "resistance (Ω)", 13.0, col("ink_soft"))
	label(Vector2(84, 18), "current (mA)", 13.0, col("ink_soft"))
	var curve := PackedVector2Array()
	var r := 50.0
	while r <= 600.0:
		curve.append(at.call(r, 3000.0 / r))
		r += 10.0
	line(curve, Color("#7E68C0"), 3.0)
	label(Vector2(214, 66), "I = (5 V − 2 V) ÷ R", 14.0, col("ink"), true, col("paper").blend(Color(col("coral"), 0.16)))
	var ohms_now := 150.0 if still else 75.0 + 525.0 * (0.5 - 0.5 * cos(time * TAU / 8.0))
	var ma_now := 3000.0 / ohms_now
	var p: Vector2 = at.call(ohms_now, ma_now)
	dot(p, 6.0, col("paper"), Color("#7E68C0"), 2.5)
	# The marker's reading, in a fixed spot above the graph, clear of its labels.
	label(Vector2(300, 18), "%d Ω gives %d mA" % [roundi(ohms_now / 10.0) * 10, roundi(ma_now)], 13.0, Color("#7E68C0"), true)
