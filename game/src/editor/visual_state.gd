class_name VisualState
extends RefCounted
## What each part should look like right now, from the simulation, plus the
## engineer's value labels shown on the board by default.


static func for_part(p: Part, sim: SimResult, _settings: Dictionary) -> Dictionary:
	var burnt := bool(p.props.get("burnt", false))
	var amps := float(sim.part_amps.get(p.id, 0.0))
	var v := {
		"brightness": 0.0, "burnt": burnt, "hot": p.id in sim.shorts, "reading": "",
		"closed": bool(p.props.get("closed", false)), "color": str(p.props.get("color", "red")),
		"label": str(p.props.get("label", "")),
	}
	if p.kind == "led" and not burnt:
		v["brightness"] = clampf(amps / Devices.LED_FULL_AMPS, 0.0, 1.0)
	elif p.kind == "ammeter" or p.kind == "voltmeter":
		var r := float(sim.meter.get(p.id, NAN))
		if is_nan(r):
			v["reading"] = "—"
		elif p.kind == "ammeter":
			v["reading"] = "%.1f mA" % (absf(r) * 1000.0)
		else:
			v["reading"] = "%.2f V" % r
	return v


## One "%.2f V" label per powered net at its first pin (offset up and right),
## and one "%.1f mA" label under each resistor and LED.
static func engineer_labels(c: Circuit, sim: SimResult) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var labeled := {}
	var anchored := anchored_nets(c, sim)
	for p in c.parts:
		for pin in Catalog.pin_names(p.kind):
			var k := Netlist.key(p.id, pin)
			if not sim.net_of.has(k):
				continue
			var net: int = sim.net_of[k]
			if labeled.has(net) or sim.floating.has(net) or not anchored.has(net):
				continue
			labeled[net] = true
			out.append({"at": Vector2(CircuitGeometry.pin_position(p, pin)) + Vector2(0.4, -0.4), "text": "%.2f V" % sim.net_volts[net], "part": p.id})
	for p in c.parts:
		if (p.kind == "resistor" or p.kind == "led") and not sim.is_floating(p.id, Catalog.pin_names(p.kind)[0]):
			var amps := absf(float(sim.part_amps.get(p.id, 0.0)))
			out.append({"at": CircuitGeometry.part_rect(p).get_center() + Vector2(0, 0.9), "text": "%.1f mA" % (amps * 1000.0), "part": p.id})
	return out


## Nets whose voltage the circuit really sets: a battery terminal, or joined
## to one through parts that conduct (resistors, a meter's current path, closed
## switches, LEDs carrying at least 1 µA). A net reached only through an LED
## that is off sits at whatever its leakage gives, which a real circuit
## doesn't define, so it isn't labeled.
static func anchored_nets(c: Circuit, sim: SimResult) -> Dictionary:
	var links := {}
	var seen := {}
	var queue: Array[int] = []
	for p in c.parts:
		var pins := Catalog.pin_names(p.kind)
		if pins.size() < 2:
			continue
		var ka := Netlist.key(p.id, pins[0])
		var kb := Netlist.key(p.id, pins[1])
		if not sim.net_of.has(ka) or not sim.net_of.has(kb):
			continue
		var a: int = sim.net_of[ka]
		var b: int = sim.net_of[kb]
		if p.kind == "battery":
			for n in [a, b]:
				if not seen.has(n):
					seen[n] = true
					queue.append(n)
			continue
		if not _conducts(p, sim):
			continue
		for pair in [[a, b], [b, a]]:
			if not links.has(pair[0]):
				links[pair[0]] = []
			(links[pair[0]] as Array).append(pair[1])
	while not queue.is_empty():
		var n: int = queue.pop_back()
		for m in links.get(n, []):
			if not seen.has(m):
				seen[m] = true
				queue.append(m)
	return seen


static func _conducts(p: Part, sim: SimResult) -> bool:
	if bool(p.props.get("burnt", false)):
		return false
	match p.kind:
		"resistor", "ammeter":
			return true
		"switch":
			return bool(p.props.get("closed", false))
		"led":
			return absf(float(sim.part_amps.get(p.id, 0.0))) >= 1e-6
	return false
