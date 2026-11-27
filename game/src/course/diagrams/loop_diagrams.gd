extends Diagram
## Lesson 1's pictures: charges in a wire, the battery's push, the loop, the
## loop with a gap, and which way current is drawn.

## The loop: battery on the left (+ at the top), resistor along the top, LED
## down the right side; sparks run clockwise from +.
const LOOP_L := 70.0
const LOOP_R := 330.0
const LOOP_T := 45.0
const LOOP_B := 175.0
const COPPER := Color("#E3A070")
const COPPER_DARK := Color("#B87444")
const ELECTRON := Color("#8FB8F0")


func _paint(time: float) -> void:
	match id:
		"charges_in_wire":
			_charges_in_wire(time)
		"battery_push":
			_battery_push(time)
		"loop_flow":
			_loop(time, true)
		"loop_gap":
			_loop(time, false)
		"current_direction":
			_current_direction(time)


func _wire_color() -> Color:
	return col("ink_soft")


## A copper wire with charges inside, all moving along together.
func _charges_in_wire(time: float) -> void:
	var a := Vector2(40, 112)
	var b := Vector2(360, 112)
	DrawKit.capsule(self, a, b, 30.0, COPPER_DARK, _k)
	DrawKit.capsule(self, a, b, 26.0, COPPER, _k)
	var spacing := 40.0
	var shift := 0.0 if still else fmod(time * 22.0, spacing)
	for row in 2:
		var y := 100.0 + row * 24.0
		var x := 50.0 + row * spacing / 2.0 + shift
		while x < 352.0:
			dot(Vector2(x, y), 8.0, ELECTRON, col("ink"), 1.2)
			label(Vector2(x, y - 0.5), "−", 13.0, col("ink"), true)
			x += spacing
	if still:
		for x in [110.0, 200.0, 290.0]:
			arrow(Vector2(x - 18.0, 62.0), Vector2(x + 18.0, 62.0), col("ink"), 3.0)
	label(Vector2(200, 40), "a metal wire", 17.0, col("ink"), true)
	label(Vector2(200, 180), "full of charges that can move", 16.0, col("ink_soft"))


## The battery pushing: out of +, round, and back into −.
func _battery_push(time: float) -> void:
	var c := Vector2(130, 112)
	var unit := 26.0
	var pos := c + Vector2(0, -2) * unit
	var neg := c + Vector2(0, 2) * unit
	var path := PackedVector2Array([pos, pos + Vector2(0, -26), Vector2(330, pos.y - 26), Vector2(330, neg.y + 26),
			neg + Vector2(0, 26), neg])
	line(path, _wire_color(), 4.0)
	symbol("battery", c, 0, {}, unit)
	if still:
		arrow(Vector2(200, pos.y - 26), Vector2(270, pos.y - 26), col("ink"), 4.0)
		arrow(Vector2(270, neg.y + 26), Vector2(200, neg.y + 26), col("ink"), 4.0)
	else:
		sparks(path, 7, 70.0, time)
	label(pos + Vector2(-34, 0), "+", 26.0, col("ink"), true)
	label(neg + Vector2(-34, 0), "−", 26.0, col("ink"), true)
	label(Vector2(262, 112), "the push goes", 15.0, col("ink_soft"))
	label(Vector2(262, 132), "out of +, round,", 15.0, col("ink_soft"))
	label(Vector2(262, 152), "back into −", 15.0, col("ink_soft"))


## The loop, whole (sparks and a lit LED) or with a gap (nothing anywhere).
func _loop(time: float, whole: bool) -> void:
	var path := PackedVector2Array([Vector2(LOOP_L, 70), Vector2(LOOP_L, LOOP_T), Vector2(LOOP_R, LOOP_T),
			Vector2(LOOP_R, LOOP_B), Vector2(LOOP_L, LOOP_B), Vector2(LOOP_L, 70)])
	if whole:
		line(path, _wire_color(), 4.0)
	else:
		line(PackedVector2Array([Vector2(LOOP_L, 70), Vector2(LOOP_L, LOOP_T), Vector2(236, LOOP_T)]), _wire_color(), 4.0)
		line(PackedVector2Array([Vector2(272, LOOP_T), Vector2(LOOP_R, LOOP_T), Vector2(LOOP_R, LOOP_B),
				Vector2(LOOP_L, LOOP_B), Vector2(LOOP_L, 70)]), _wire_color(), 4.0)
	if whole:
		if still:
			arrow(Vector2(232, LOOP_T - 16), Vector2(292, LOOP_T - 16), col("ink"), 3.0)
			arrow(Vector2(232, LOOP_B + 16), Vector2(172, LOOP_B + 16), col("ink"), 3.0)
		else:
			sparks(path, 9, 60.0, time)
	symbol("battery", Vector2(LOOP_L, 110), 0, {})
	symbol("resistor", Vector2(150, LOOP_T), 0, {}, 20.0, {"ohms": 220.0})
	symbol("led", Vector2(LOOP_R, 110), 90, {"brightness": 1.0 if whole else 0.0, "color": "red"})
	if whole:
		label(Vector2(200, 112), "a complete loop", 18.0, col("ink"), true)
	else:
		label(Vector2(254, LOOP_T - 18), "gap", 16.0, col("coral"), true)
		label(Vector2(200, 112), "one gap stops it all", 18.0, col("ink"), true)


## Current as we draw it (+ to −), and the electrons drifting the other way.
func _current_direction(time: float) -> void:
	var a := Vector2(70, 120)
	var b := Vector2(330, 120)
	DrawKit.capsule(self, a, b, 16.0, COPPER, _k)
	label(Vector2(40, 120), "+", 28.0, col("ink"), true)
	label(Vector2(360, 120), "−", 28.0, col("ink"), true)
	if still:
		arrow(Vector2(120, 66), Vector2(280, 66), col("signal_high"), 5.0)
		arrow(Vector2(260, 176), Vector2(140, 176), ELECTRON.darkened(0.2), 3.0)
	else:
		for i in 4:
			var x := 90.0 + fmod(time * 60.0 + i * 60.0, 220.0)
			arrow(Vector2(x, 66), Vector2(x + 26.0, 66), col("signal_high"), 4.0)
	var drift := 0.0 if still else fmod(time * 10.0, 32.0)
	var x := 314.0 - drift
	while x > 80.0:
		dot(Vector2(x, 120), 5.0, ELECTRON, col("ink"), 1.0)
		x -= 32.0
	label(Vector2(200, 38), "current: drawn from + to −", 16.0, col("ink"), true)
	label(Vector2(200, 200), "electrons drift slowly the other way", 15.0, col("ink_soft"))
