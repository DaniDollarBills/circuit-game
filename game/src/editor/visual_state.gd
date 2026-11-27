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
	for p in c.parts:
		for pin in Catalog.pin_names(p.kind):
			var k := Netlist.key(p.id, pin)
			if not sim.net_of.has(k):
				continue
			var net: int = sim.net_of[k]
			if labeled.has(net) or sim.floating.has(net):
				continue
			labeled[net] = true
			out.append({"at": Vector2(CircuitGeometry.pin_position(p, pin)) + Vector2(0.4, -0.4), "text": "%.2f V" % sim.net_volts[net], "part": p.id})
	for p in c.parts:
		if (p.kind == "resistor" or p.kind == "led") and not sim.is_floating(p.id, Catalog.pin_names(p.kind)[0]):
			var amps := absf(float(sim.part_amps.get(p.id, 0.0)))
			out.append({"at": CircuitGeometry.part_rect(p).get_center() + Vector2(0, 0.9), "text": "%.1f mA" % (amps * 1000.0), "part": p.id})
	return out
