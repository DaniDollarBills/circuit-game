class_name Explain
extends RefCounted
## The "why" behind a part, worked out with its real numbers.


static func part(p: Part, sim: SimResult) -> PackedStringArray:
	var name := str(p.props.get("label", "")) if str(p.props.get("label", "")) != "" else p.id
	if bool(p.props.get("burnt", false)):
		return PackedStringArray(["%s burned out: %s." % [Catalog.title(p.kind), _why_burnt(p)]])
	if sim.is_floating(p.id, Catalog.pin_names(p.kind)[0]):
		return PackedStringArray(["Not connected to the battery yet."])
	var pins := Catalog.pin_names(p.kind)
	var across := sim.pin_volts(p.id, pins[0]) - sim.pin_volts(p.id, pins[1])
	var amps := float(sim.part_amps.get(p.id, 0.0))
	var ma := "%.1f mA" % (absf(amps) * 1000.0)
	match p.kind:
		"resistor":
			var ohms := float(p.props.get("ohms", 220.0))
			return PackedStringArray([
				"Voltage across %s: %.2f V" % [name, across],
				"Current = %.2f V ÷ %s = %s" % [across, Catalog.format_ohms(ohms), ma],
				"Heat = %.2f V × %s = %.3f W (rated %s W)" % [across, ma, absf(across * amps), _trim(float(p.props.get("watts", 0.25)))],
			])
		"led":
			return PackedStringArray([
				"Voltage across %s: %.2f V" % [name, across],
				"Current: %s (recommended up to 20 mA)" % ma,
				"Brightness: %d%%" % roundi(clampf(amps / Devices.LED_FULL_AMPS, 0.0, 1.0) * 100.0),
			])
		"battery":
			var emf := DcSolver.battery_volts(p)
			var terminal := emf - amps * Devices.BATTERY_OHMS
			return PackedStringArray([
				"Voltage at the terminals: %.1f V − %s × %s Ω = %.2f V" % [emf, ma, _trim(Devices.BATTERY_OHMS), terminal],
				"Power delivered: %.2f V × %s = %.3f W" % [terminal, ma, absf(terminal * amps)],
			])
		"ammeter":
			return PackedStringArray([
				"Current through %s: %s" % [name, ma],
				"A current meter goes in series, so all the current flows through it.",
			])
		"voltmeter":
			return PackedStringArray([
				"Voltage between the probes: %.2f V" % across,
				"A voltage meter has 10 MΩ inside, so it barely changes the circuit.",
			])
		"switch":
			if bool(p.props.get("closed", false)):
				return PackedStringArray(["%s is closed, so current can flow." % name])
			return PackedStringArray(["%s is open, so the loop is broken." % name])
	return PackedStringArray()


static func _why_burnt(p: Part) -> String:
	match p.kind:
		"led":
			return "more than its 30 mA maximum"
		"resistor":
			return "more heat than its %s W rating" % _trim(float(p.props.get("watts", 0.25)))
		"ammeter":
			return "its 500 mA fuse blew"
	return "too much current"


## 0.25 → "0.25", 1.0 → "1".
static func _trim(v: float) -> String:
	return ("%.2f" % v).rstrip("0").rstrip(".")
