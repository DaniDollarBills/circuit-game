class_name ScaleFormat
extends RefCounted
## Real distances for the zoom's scale readout, in the unit a person would use.

const UNITS := [[1000.0, "km"], [1.0, "m"], [0.01, "cm"], [0.001, "mm"], [1e-6, "µm"], [1e-9, "nm"], [1e-12, "pm"]]
## Absorbs float noise, so 0.001 m is "1 mm" and not "1,000 µm".
const EPS := 1e-9


## 12742000 → "12,742 km", 2.5 → "2.5 m", 0.0005 → "500 µm", 4e-10 → "400 pm".
static func meters(m: float) -> String:
	var unit: Array = UNITS[UNITS.size() - 1]
	for u in UNITS:
		if m * (1.0 + EPS) >= u[0]:
			unit = u
			break
	return "%s %s" % [_number(m / unit[0]), unit[1]]


## "Skipping ahead ×830": two significant digits.
static func jump(x: float) -> String:
	var digits := floori(log(x) / log(10.0))
	var step := pow(10.0, digits - 1)
	return "Skipping ahead ×%s" % _number(roundf(x / step) * step)


## Whole numbers with thousands separators from 10 up; below that one decimal,
## dropping a trailing ".0".
static func _number(v: float) -> String:
	if v >= 10.0:
		return _grouped(roundi(v))
	return ("%.1f" % v).trim_suffix(".0")


static func _grouped(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
