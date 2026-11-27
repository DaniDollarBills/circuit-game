class_name ResistorBands
extends RefCounted
## The IEC 60062 color code: two digit bands, a multiplier band, and a gold
## band for ±5% tolerance.

const BAND_COLORS := ["#2B2B2B", "#8B5A2B", "#E0605E", "#F29D52", "#F2D35B", "#6CBF84", "#5C9BD6", "#A77BD9", "#9A9AA6", "#F5F5F5"]
const GOLD := "#E8C66A"
const SILVER := "#C4C4CC"


## [first digit, second digit, power of ten], rounded to two significant digits:
## 220 → [2, 2, 1], 1000 → [1, 0, 2], 4.7 → [4, 7, -1].
static func digits(ohms: float) -> Array[int]:
	if not (ohms > 0.0):
		return [0, 0, 0]
	var e := floori(log(ohms) / log(10.0)) - 1
	var m := roundi(ohms / pow(10.0, e))
	if m >= 100:
		m = roundi(m / 10.0)
		e += 1
	elif m < 10:
		m *= 10
		e -= 1
	return [m / 10, m % 10, e]


static func colors(ohms: float) -> Array[Color]:
	var d := digits(ohms)
	var out: Array[Color] = [Color(BAND_COLORS[d[0]]), Color(BAND_COLORS[d[1]]), _multiplier(d[2]), Color(GOLD)]
	return out


static func _multiplier(e: int) -> Color:
	if e == -1:
		return Color(GOLD)
	if e <= -2:
		return Color(SILVER)
	return Color(BAND_COLORS[mini(e, 9)])
