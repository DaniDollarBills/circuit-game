class_name WireArt
extends RefCounted
## How a wire shows its voltage (color), its current (moving dots) and, for
## color-blind players, high voltage as dashes.

const DOT_SPACING := 0.6
const DASH := 0.3


## From soft grey-violet at 0 V to pink at 5 V; floating wires are plain.
static func color_for_volts(v: float, floating: bool, night := false) -> Color:
	if floating or is_nan(v):
		return Palette.color("line", night)
	return Palette.color("signal_low", night).lerp(Palette.color("signal_high", night), clampf(v / 5.0, 0.0, 1.0))


## Units per second: none below 10 µA, then faster for every factor of ten.
static func dot_speed(amps: float) -> float:
	var a := absf(amps)
	if a < 1e-5:
		return 0.0
	return clampf(0.8 * log(a / 1e-5) / log(10.0), 0.3, 4.0)


## Dots every 0.6 units, moving along the path for positive current and
## against it for negative.
static func dots(path: PackedVector2Array, amps: float, t: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var speed := dot_speed(amps)
	if speed == 0.0 or path.size() < 2:
		return out
	var length := _length(path)
	var start := fposmod(speed * t * signf(amps), DOT_SPACING)
	for k in _count(start, length):
		out.append(_point_at(path, start + k * DOT_SPACING))
	return out


## Electron-flow mode shows the dots moving the way electrons really go.
static func display_amps(amps: float, settings: Dictionary) -> float:
	return -amps if bool(settings.get("electron_flow", false)) else amps


## 0.3-unit dashes every 0.6 units, for wires above 2.5 V when patterns are on.
static func pattern_dashes(path: PackedVector2Array, volts: float, enabled: bool) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	if not enabled or not (volts > 2.5) or path.size() < 2:
		return out
	var length := _length(path)
	for k in _count(0.0, length):
		var d := k * DOT_SPACING
		out.append(_slice(path, d, minf(d + DASH, length)))
	return out


## How many marks fit from `start`, one every DOT_SPACING, strictly before the
## end (a mark exactly on the end belongs to the next wire).
static func _count(start: float, length: float) -> int:
	return maxi(0, ceili((length - start) / DOT_SPACING - 1e-9))


static func _length(path: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i - 1].distance_to(path[i])
	return total


static func _point_at(path: PackedVector2Array, d: float) -> Vector2:
	var left := d
	for i in range(1, path.size()):
		var seg := path[i - 1].distance_to(path[i])
		if left <= seg and seg > 0.0:
			return path[i - 1].lerp(path[i], left / seg)
		left -= seg
	return path[path.size() - 1]


## The part of the path between distances d0 and d1, corners included.
static func _slice(path: PackedVector2Array, d0: float, d1: float) -> PackedVector2Array:
	var out := PackedVector2Array([_point_at(path, d0)])
	var walked := 0.0
	for i in range(1, path.size()):
		walked += path[i - 1].distance_to(path[i])
		if walked > d0 and walked < d1:
			out.append(path[i])
	out.append(_point_at(path, d1))
	return out
