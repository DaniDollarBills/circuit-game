class_name Goals
extends RefCounted
## Checks one level goal against the simulated circuit and, when it fails, says
## in plain words what is wrong. ctx = {circuit, sim, zoom_layer, zoom_seen,
## ui_flags}; every result is {pass, message}. A goal's `part` matches a part id
## or a label.

const KINDS: PackedStringArray = ["led_lit", "led_dark", "no_damage", "no_short", "meter_reads", "uses",
		"zoom_reached", "connected", "all", "ui_flag", "resistor_watts", "not", "burnt"]
## Less than this through an LED is only solver leakage (picoamps): no current.
const NO_CURRENT_AMPS := 1e-9
## A reverse voltage above this means the LED is in backwards.
const REVERSED_VOLTS := 0.5
## Under this across an LED that carries nothing, a wire is going around it.
const BYPASS_VOLTS := 0.1


static func evaluate(goal: Dictionary, ctx: Dictionary) -> Dictionary:
	match str(goal.get("kind", "")):
		"led_lit":
			return _led_lit(goal, ctx)
		"led_dark":
			return _led_dark(goal, ctx)
		"no_damage":
			return _no_damage(ctx)
		"no_short":
			var clear: bool = (ctx["sim"] as SimResult).shorts.is_empty()
			return _result(clear, "No short circuits." if clear else "Short circuit! Find the wire that skips your parts.")
		"meter_reads":
			return _meter_reads(goal, ctx)
		"uses":
			return _uses(goal, ctx)
		"zoom_reached":
			var layer := str(goal.get("layer", ""))
			var seen: Dictionary = ctx.get("zoom_seen", {})
			var there := str(ctx.get("zoom_layer", "")) == layer or seen.has(layer)
			return _result(there, "You made it inside!" if there else "Keep zooming in.")
		"connected":
			return _connected(goal, ctx)
		"all":
			for g in goal.get("goals", []):
				var r := evaluate(g, ctx)
				if not r["pass"]:
					return r
			return _result(true, "")
		"not":
			var inner := evaluate(goal.get("goal", {}), ctx)
			return _result(not bool(inner["pass"]), "Done." if not bool(inner["pass"]) else "Not yet.")
		"burnt":
			var p := (ctx["circuit"] as Circuit).find_part(str(goal.get("part", "")))
			var gone := p != null and bool(p.props.get("burnt", false))
			return _result(gone, "It burned out." if gone else "Not burnt.")
		"ui_flag":
			var flags: Dictionary = ctx.get("ui_flags", {})
			var done := flags.has(str(goal.get("flag", "")))
			return _result(done, "Done." if done else "Not yet.")
		"resistor_watts":
			return _resistor_watts(goal, ctx)
	push_error("Unknown goal kind: %s" % goal.get("kind", ""))
	return _result(false, "")


static func evaluate_all(goals: Array, ctx: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in goals:
		out.append(evaluate(g, ctx))
	return out


## Diagnoses in a fixed order, so the player hears about the most basic
## problem first.
static func _led_lit(goal: Dictionary, ctx: Dictionary) -> Dictionary:
	var c: Circuit = ctx["circuit"]
	var sim: SimResult = ctx["sim"]
	var p := c.find_part(str(goal.get("part", "")))
	if p == null:
		return _missing(goal.get("part", ""))
	if bool(p.props.get("burnt", false)):
		return _result(false, "Pop! Too much current burned out the LED, so replace it and put a resistor in its loop.")
	if not sim.shorts.is_empty():
		return _result(false, "Short circuit! The current is taking a shortcut around your parts.")
	var amps := float(sim.part_amps.get(p.id, 0.0))
	var reverse := sim.pin_volts(p.id, "cathode") - sim.pin_volts(p.id, "anode")
	var backwards := reverse > REVERSED_VOLTS
	var floating := sim.is_floating(p.id, "anode") or sim.is_floating(p.id, "cathode")
	if not floating and absf(amps) < NO_CURRENT_AMPS and absf(reverse) < BYPASS_VOLTS and _battery_drives(p, ctx):
		return _result(false, "Current is flowing, but around the LED instead of through it. Make the path go through the LED.")
	if floating or (absf(amps) < NO_CURRENT_AMPS and not backwards):
		return _result(false, "The loop isn't closed yet. Current needs a full path from + back to −.")
	if backwards:
		return _result(false, "The LED is backwards. Swap its wires so its + side connects toward the battery's +.")
	if amps < Devices.LED_LIT_AMPS:
		return _result(false, "A little current flows, but not enough to see. Try a smaller resistor.")
	var ma := amps * 1000.0
	if goal.has("max_ma") and ma > float(goal["max_ma"]):
		return _result(false, "Careful: %.1f mA is more than this LED's recommended %s mA. It glows, but it won't last."
				% [ma, _num(goal["max_ma"])])
	if goal.has("min_ma") and ma < float(goal["min_ma"]):
		return _result(false, "It's glowing, but dimly (%.1f mA). Can you make it brighter?" % ma)
	return _result(true, "Lit! %.1f mA flowing." % ma)


## True when a battery in the LED's part of the circuit delivers real current
## (more than leakage), so the loop around the LED is closed somewhere else.
static func _battery_drives(led: Part, ctx: Dictionary) -> bool:
	var sim: SimResult = ctx["sim"]
	var k := Netlist.key(led.id, "anode")
	if not sim.net_of.has(k):
		return false
	var comp := sim.component_of_net[sim.net_of[k]]
	for p in (ctx["circuit"] as Circuit).parts:
		var pk := Netlist.key(p.id, "pos")
		if p.kind == "battery" and sim.net_of.has(pk) and sim.component_of_net[sim.net_of[pk]] == comp \
				and absf(float(sim.part_amps.get(p.id, 0.0))) > NO_CURRENT_AMPS:
			return true
	return false


static func _led_dark(goal: Dictionary, ctx: Dictionary) -> Dictionary:
	var sim: SimResult = ctx["sim"]
	var p := (ctx["circuit"] as Circuit).find_part(str(goal.get("part", "")))
	if p == null:
		return _missing(goal.get("part", ""))
	var lit := not bool(p.props.get("burnt", false)) and float(sim.part_amps.get(p.id, 0.0)) >= Devices.LED_LIT_AMPS
	return _result(not lit, "The LED is still on." if lit else "The LED is off.")


static func _no_damage(ctx: Dictionary) -> Dictionary:
	for p in (ctx["circuit"] as Circuit).parts:
		if bool(p.props.get("burnt", false)):
			return _result(false, "Something burned out. Replace it to continue.")
	return _result(true, "Nothing is burned.")


## Ammeters read in mA with 1 decimal, voltmeters in V with 2 decimals.
static func _meter_reads(goal: Dictionary, ctx: Dictionary) -> Dictionary:
	var sim: SimResult = ctx["sim"]
	var p := (ctx["circuit"] as Circuit).find_part(str(goal.get("part", "")))
	if p == null or is_nan(float(sim.meter.get(p.id, NAN))):
		return _result(false, "The meter isn't connected yet.")
	var reading := float(sim.meter[p.id])
	var target := float(goal.get("target", 0.0))
	var tolerance := float(goal.get("tolerance", 0.0))
	var amps := p.kind == "ammeter"
	if absf(reading - target) <= tolerance:
		return _result(true, "The meter reads %s." % _meter_text(reading, amps))
	return _result(false, "The meter reads %s. Aim for %s (±%s)."
			% [_meter_text(reading, amps), _meter_text(target, amps), _meter_text(tolerance, amps)])


static func _uses(goal: Dictionary, ctx: Dictionary) -> Dictionary:
	var kind := str(goal.get("part_kind", ""))
	var count := 0
	for p in (ctx["circuit"] as Circuit).parts:
		if p.kind == kind:
			count += 1
	var noun := _noun(kind)
	if goal.has("min") and count < int(goal["min"]):
		return _result(false, "Add %s %s from the tray." % [_article(noun), noun])
	if goal.has("max") and count > int(goal["max"]):
		return _result(false, "Use at most %d of the %s part." % [int(goal["max"]), noun])
	return _result(true, "")


static func _connected(goal: Dictionary, ctx: Dictionary) -> Dictionary:
	var a := _pin_nets(str(goal.get("a", "")), ctx)
	var b := _pin_nets(str(goal.get("b", "")), ctx)
	for net in a:
		if net in b:
			return _result(true, "Connected.")
	return _result(false, "Not connected yet.")


## The nets of "<part>:<pin>", or of every pin for "<part>:*".
static func _pin_nets(spec: String, ctx: Dictionary) -> Array[int]:
	var out: Array[int] = []
	var cut := spec.rfind(":")
	var p := (ctx["circuit"] as Circuit).find_part(spec.substr(0, cut)) if cut > 0 else null
	if p == null:
		return out
	var pin := spec.substr(cut + 1)
	var pins := Catalog.pin_names(p.kind) if pin == "*" else PackedStringArray([pin])
	var net_of: Dictionary = (ctx["sim"] as SimResult).net_of
	for name in pins:
		var k := Netlist.key(p.id, name)
		if net_of.has(k):
			out.append(int(net_of[k]))
	return out


static func _resistor_watts(goal: Dictionary, ctx: Dictionary) -> Dictionary:
	var sim: SimResult = ctx["sim"]
	var lo := float(goal.get("min", 0.0))
	var hi := float(goal.get("max", INF))
	for p in (ctx["circuit"] as Circuit).parts:
		if p.kind == "resistor" and not bool(p.props.get("burnt", false)):
			var watts := float(sim.part_watts.get(p.id, 0.0))
			if watts >= lo and watts <= hi:
				return _result(true, "%.2f W of heat. Toasty!" % watts)
	return _result(false, "Aim for %s–%s W of heat from a resistor." % [_num(lo), _num(hi)])


static func _result(passed: bool, message: String) -> Dictionary:
	return {"pass": passed, "message": message}


static func _missing(part_name: Variant) -> Dictionary:
	return _result(false, "Missing part: %s" % part_name)


static func _meter_text(x: float, amps: bool) -> String:
	return "%.1f mA" % (x * 1000.0) if amps else "%.2f V" % x


## 20.0 → "20", 0.4 → "0.4", 0.25 → "0.25".
static func _num(v: Variant) -> String:
	return ("%.2f" % float(v)).rstrip("0").rstrip(".")


## A part's title as it reads mid-sentence: "switch", "battery pack (4 × AA)",
## but acronyms such as "LED" stay in capitals.
static func _noun(kind: String) -> String:
	var t := Catalog.title(kind)
	var first := t.get_slice(" ", 0)
	if first.length() > 1 and first == first.to_upper():
		return t
	return t.substr(0, 1).to_lower() + t.substr(1)


## "an" before a vowel sound: "an LED" (el-ee-dee), "an ammeter", "a switch".
static func _article(noun: String) -> String:
	var first := noun.get_slice(" ", 0)
	var initial := noun.substr(0, 1).to_upper()
	var acronym := first.length() > 1 and first == first.to_upper()
	var vowel_sound := "AEFHILMNORSX".contains(initial) if acronym else "AEIOU".contains(initial)
	return "an" if vowel_sound else "a"
