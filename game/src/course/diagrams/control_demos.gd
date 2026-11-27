extends Diagram
## New controls, shown by the moving hand on a small copy of the bench: set a
## trimmer's value, flip a switch, and press Test. Reduced motion holds each
## on its key moment, with an arrow for any drag.

const LED_TINT := Color("#FF8F9A")
const REST := Vector2(340, 204)


func _paint(time: float) -> void:
	match id:
		"control_dial":
			_dial(time)
		"control_switch":
			_switch(time)
		"control_test":
			_test(time)


static func _ease(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)


## Tap the trimmer, and a slider opens; drag it to set the value (here from
## 1.0 kΩ to 2.0 kΩ, as Lesson 3 asks).
func _dial(time: float) -> void:
	var s := 1.9 if still else fmod(time, 5.0)
	var trimmer := Vector2(100, 104)
	var open := s >= 0.8 and s < 4.6
	var drag := clampf((s - 1.6) / 1.4, 0.0, 1.0)
	var ohms := snappedf(lerpf(1000.0, 2000.0, _ease(drag)), 10.0)
	label(Vector2(200, 22), "tap the trimmer, then slide its value", 15.0, col("ink"), true)
	line(PackedVector2Array([Vector2(30, trimmer.y), Vector2(170, trimmer.y)]), col("ink_soft"), 3.0)
	symbol("resistor", trimmer, 0, {}, 20.0, {"ohms": ohms, "adjustable": true})
	var track_a := Vector2(214, 120)
	var track_b := Vector2(360, 120)
	var knob := track_a.lerp(track_b, (ohms - 100.0) / 1900.0)
	if open:
		var panel := Rect2(198, 70, 178, 96)
		box(panel, 12.0, col("paper"), col("ink"), 1.4)
		label(Vector2(panel.get_center().x, 88), "Resistance of R1", 12.0, col("ink_soft"))
		line(PackedVector2Array([track_a, track_b]), col("line").darkened(0.12), 6.0)
		line(PackedVector2Array([track_a, knob]), col("lavender"), 6.0)
		dot(knob, 10.0, col("paper"), col("ink"), 1.6)
		label(Vector2(panel.get_center().x, 150), Catalog.format_ohms(ohms), 15.0, col("ink"), true)
	var start_knob := track_a.lerp(track_b, 900.0 / 1900.0)
	var at := REST
	var pressed := false
	if s < 0.5:
		at = REST.lerp(trimmer, _ease(s / 0.5))
	elif s < 0.8:
		at = trimmer
		pressed = s < 0.7
	elif s < 1.6:
		at = trimmer.lerp(start_knob, _ease((s - 0.8) / 0.8))
	elif s < 3.0:
		at = knob
		pressed = true
	elif s < 4.0:
		at = knob
	else:
		at = knob.lerp(REST, _ease((s - 4.0) / 0.6))
	if still:
		arrow(knob + Vector2(16, 0), knob + Vector2(54, 0), col("ink"), 2.5)
	hand(at, pressed)


## Tap a switch to flip it: closed, the LED lights; tap again, it opens.
func _switch(time: float) -> void:
	var s := 1.2 if still else fmod(time, 3.6)
	var closed := still or (s >= 0.9 and s < 2.7)
	var sw := Vector2(124, 108)
	label(Vector2(200, 22), "tap a switch to flip it", 15.0, col("ink"), true)
	var wire := PackedVector2Array([Vector2(36, sw.y), Vector2(364, sw.y)])
	line(wire, col("ink_soft"), 3.0)
	if closed and not still:
		sparks(wire, 6, 60.0, time)
	label(Vector2(22, sw.y), "+", 22.0, col("ink"), true)
	label(Vector2(378, sw.y), "−", 22.0, col("ink"), true)
	symbol("switch", sw, 0, {"closed": closed}, 18.0)
	symbol("resistor", Vector2(220, sw.y), 0, {}, 16.0, {"ohms": 220.0})
	symbol("led", Vector2(314, sw.y), 0, {"brightness": 1.0 if closed else 0.0, "color": "red"}, 18.0)
	label(Vector2(200, 170), "closed: the LED is on" if closed else "open: the LED is off", 14.0, col("ink_soft"))
	var tap := sw + Vector2(4, -4)
	var at := REST
	var pressed := false
	if still:
		at = tap
		pressed = true
	elif s < 0.6:
		at = REST.lerp(tap, _ease(s / 0.6))
	elif s < 2.4:
		at = tap
		pressed = s < 0.9
	elif s < 2.7:
		at = tap
		pressed = true
	else:
		at = tap.lerp(REST, _ease((s - 2.7) / 0.6))
	hand(at, pressed)
	if not still:
		speed_note(Vector2(200, 206))


## Press Test, and it tries every switch setting and ticks each one that
## works.
func _test(time: float) -> void:
	var s := 1.6 if still else fmod(time, 4.2)
	var button := Rect2(40, 82, 116, 52)
	var pressed := still or (s >= 0.6 and s < 0.9)
	label(Vector2(200, 22), "press Test: it tries every switch setting", 15.0, col("ink"), true)
	var fill := col("lavender") if pressed else col("lilac")
	box(button, 16.0, fill, Palette.color("ink"), 1.2)
	label(button.get_center(), "Test", 18.0, Palette.color("ink"), true, fill)
	if s >= 0.9 or still:
		var panel := Rect2(180, 64, 200, 92)
		box(panel, 12.0, col("paper"), col("ink"), 1.4)
		var rows := ["Switch off: LED off", "Switch on: LED on"]
		for i in rows.size():
			if still or s >= 1.1 + i * 0.4:
				var y := 92.0 + i * 34.0
				label(Vector2(200, y), "✓", 18.0, Color("#2E8B57"), true)
				label(Vector2(294, y), rows[i], 13.0, col("ink"))
	var target := button.get_center() + Vector2(10, 4)
	var at := REST
	if still:
		at = target
	elif s < 0.6:
		at = REST.lerp(target, _ease(s / 0.6))
	elif s < 2.6:
		at = target
	else:
		at = target.lerp(REST, _ease((s - 2.6) / 0.8))
	hand(at, pressed)
