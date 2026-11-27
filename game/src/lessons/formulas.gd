class_name Formulas
extends RefCounted
## The calculator: real formulas worked step by step. Numbers in steps use the
## game's formats: volts 1 decimal, amps 3 decimals, ohms whole, watts 2 decimals.


static func led_resistor(supply_v: float, led_v: float, led_a: float) -> Dictionary:
	var steps := PackedStringArray(["R = (supply − LED voltage) ÷ current"])
	if not (supply_v > led_v) or not (led_a > 0.0):
		steps.append("This can't work: the supply must be higher than the LED voltage, and the current more than 0 A.")
		return {"exact": NAN, "standard": NAN, "steps": steps}
	var exact := (supply_v - led_v) / led_a
	var standard := E12.at_or_above(exact)
	steps.append("R = (%s − %s) ÷ %s" % [_volts(supply_v), _volts(led_v), _amps(led_a)])
	steps.append("R = %s" % _ohms(exact))
	steps.append("Nearest standard value at or above: %s" % _ohms(standard))
	return {"exact": exact, "standard": standard, "steps": steps}


## Exactly one of v, i and r must be NAN; that one is solved for.
static func ohms_law(v: float, i: float, r: float) -> Dictionary:
	var unknowns := int(is_nan(v)) + int(is_nan(i)) + int(is_nan(r))
	if unknowns != 1:
		return {"value": NAN, "unit": "", "steps": PackedStringArray()}
	if is_nan(i):
		var steps := PackedStringArray(["I = V ÷ R"])
		if not (r > 0.0):
			steps.append("The resistance must be more than 0 Ω.")
			return {"value": NAN, "unit": "A", "steps": steps}
		var amps := v / r
		steps.append("I = %s ÷ %s = %s (%s)" % [_volts(v), _ohms(r), _amps(amps), _milliamps(amps)])
		return {"value": amps, "unit": "A", "steps": steps}
	if is_nan(r):
		var steps := PackedStringArray(["R = V ÷ I"])
		if not (i > 0.0):
			steps.append("The current must be more than 0 A.")
			return {"value": NAN, "unit": "Ω", "steps": steps}
		var ohms := v / i
		steps.append("R = %s ÷ %s = %s" % [_volts(v), _amps(i), _ohms(ohms)])
		return {"value": ohms, "unit": "Ω", "steps": steps}
	var volts := i * r
	var lines := PackedStringArray(["V = I × R", "V = %s × %s = %s" % [_amps(i), _ohms(r), _volts(volts)]])
	return {"value": volts, "unit": "V", "steps": lines}


static func power_from_r(v: float, r: float) -> Dictionary:
	var steps := PackedStringArray(["P = V × I, and I = V ÷ R"])
	if not (r > 0.0):
		steps.append("The resistance must be more than 0 Ω.")
		return {"value": NAN, "unit": "W", "steps": steps}
	var amps := v / r
	var watts := v * amps
	steps.append("I = %s ÷ %s = %s" % [_volts(v), _ohms(r), _amps(amps)])
	steps.append("P = %s × %s = %s" % [_volts(v), _amps(amps), _watts(watts)])
	return {"value": watts, "unit": "W", "steps": steps}


static func _volts(x: float) -> String:
	return "%.1f V" % x


static func _amps(x: float) -> String:
	return "%.3f A" % x


static func _ohms(x: float) -> String:
	return "%d Ω" % roundi(x)


static func _watts(x: float) -> String:
	return "%.2f W" % x


## 0.010 → "10 mA", 0.0125 → "12.5 mA".
static func _milliamps(x: float) -> String:
	return ("%.1f" % (x * 1000.0)).trim_suffix(".0") + " mA"
