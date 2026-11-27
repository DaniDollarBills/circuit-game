extends Diagram
## Lesson 9's pictures: round a loop, the current arrows go one way while the
## electrons in the wire drift the other; and inside copper, atoms held in a
## crystal with free electrons zipping about and slowly drifting toward +.

const COPPER := Color("#E3A070")
const COPPER_DARK := Color("#B87444")
const ELECTRON := Color("#8FB8F0")
const CURRENT := Color("#E2557A")


func _paint(time: float) -> void:
	match id:
		"electron_vs_current":
			_both_ways(time)
		"copper_lattice":
			_lattice(time)


## Current arrows outside the loop, from + round to −; electrons inside the
## copper, from − round to +.
func _both_ways(time: float) -> void:
	var l := 70.0
	var r := 330.0
	var t := 52.0
	var b := 170.0
	var wire := PackedVector2Array([Vector2(l, 72), Vector2(l, t), Vector2(r, t), Vector2(r, b), Vector2(l, b), Vector2(l, 148)])
	line(wire, COPPER_DARK, 12.0)
	line(wire, COPPER, 8.0)
	# The electrons: from the − end, round the other way.
	var back := wire.duplicate()
	back.reverse()
	var length := Diagram.path_length(back)
	for i in 16:
		var d := fmod((0.0 if still else time * 14.0) + length * i / 16.0, length)
		dot(Diagram.along(back, d), 3.2, ELECTRON, Palette.color("ink"), 0.8)
	symbol("battery", Vector2(l, 110), 0, {})
	symbol("resistor", Vector2(200, t), 0, {}, 20.0, {"ohms": 220.0})
	symbol("led", Vector2(r, 111), 90, {"brightness": 1.0, "color": "red"})
	# The current, as we draw it: outside the loop, from + round to −.
	if still:
		arrow(Vector2(120, t - 22), Vector2(170, t - 22), CURRENT, 3.5)
		arrow(Vector2(280, b + 22), Vector2(230, b + 22), CURRENT, 3.5)
		arrow(Vector2(270, b - 16), Vector2(310, b - 16), ELECTRON.darkened(0.35), 2.5)
	else:
		var outside := PackedVector2Array([Vector2(l - 20, 72), Vector2(l - 20, t - 20), Vector2(r + 20, t - 20),
				Vector2(r + 20, b + 20), Vector2(l - 20, b + 20), Vector2(l - 20, 148)])
		var around := Diagram.path_length(outside)
		for i in 7:
			var d := fmod(time * 60.0 + around * i / 7.0, around)
			var p := Diagram.along(outside, d)
			var ahead := Diagram.along(outside, minf(d + 14.0, around))
			if p.distance_to(ahead) > 4.0:
				arrow(p, ahead, CURRENT, 3.0)
	label(Vector2(200, 10), "current: drawn from + round to −", 13.0, CURRENT, true)
	label(Vector2(200, 112), "electrons: from − round to +", 14.0, col("ink"), true)
	label(Vector2(200, 132), "(they drift the other way)", 13.0, col("ink_soft"))
	speed_note(Vector2(200, 210))


## Copper inside: atoms locked in a crystal (each lent one electron to the
## sea), free electrons zipping about at random and, pushed by the battery,
## drifting slowly toward the + end.
func _lattice(time: float) -> void:
	label(Vector2(200, 16), "inside copper", 16.0, col("ink"), true)
	label(Vector2(20, 112), "+", 26.0, col("ink"), true)
	label(Vector2(380, 112), "−", 26.0, col("ink"), true)
	for row in 4:
		for c in 7:
			var at := Vector2(62 + c * 46, 52 + row * 40)
			dot(at, 12.0, COPPER, COPPER_DARK, 1.4)
			label(at, "+", 13.0, Palette.color("ink"), true, COPPER)
	# Free electrons: a fast random jiggle and a slow drift toward + (left).
	var drift := 0.0 if still else time * 9.0
	for i in 18:
		var base := Vector2(fposmod(40.0 + i * 61.7 - drift, 320.0) + 40.0, 40.0 + fmod(i * 37.3, 140.0))
		var jiggle := Vector2.ZERO
		if not still:
			jiggle = Vector2(sin(time * (2.3 + 0.17 * i) + i), cos(time * (1.9 + 0.13 * i) + 2.0 * i)) * 15.0
		dot(base + jiggle, 4.0, ELECTRON, Palette.color("ink"), 0.8)
	if still:
		arrow(Vector2(250, 206), Vector2(150, 206), ELECTRON.darkened(0.35), 3.0)
	label(Vector2(200, 206) if not still else Vector2(200, 192), "free electrons drift slowly toward +", 13.0, col("ink_soft"))
	speed_note(Vector2(338, 16), "speeds not to scale")
