class_name RecapText
extends RefCounted
## Fills a recap point's {part.quantity} templates ({L1.mA}, {R1.ohms},
## {R1.W}, {B1.V}, {M1.reading}) with the player's own simulated values. A
## part can be named by its kind ({resistor.W}): the working one doing the
## most, since a tray part's id depends on the order it was placed. A part
## that isn't there reads "—"; braces that aren't a template stay.
## {L1.mA@closed} reads the player's circuit with every switch closed: the
## "on" case of the switch lessons, whatever the switches were left at.

static var _template := RegEx.create_from_string("\\{([A-Za-z0-9_]+)\\.(mA|V|W|heat|ohms|reading)(@closed)?\\}")


static func fill(text: String, circuit: Circuit, sim: SimResult) -> String:
	var out := text
	var closed: SimOutcome = null
	for m in _template.search_all(text):
		var c := circuit
		var r := sim
		if m.get_string(3) != "" and circuit != null:
			if closed == null:
				closed = Simulator.simulate(_switches_closed(circuit))
			c = closed.circuit
			r = closed.result
		var id := _resolve(m.get_string(1), c, r)
		out = out.replace(m.get_string(0), Readouts.text_value(id, m.get_string(2), c, r))
	return out


static func _switches_closed(c: Circuit) -> Circuit:
	var out := c
	for p in c.parts:
		if p.kind == "switch" and not bool(p.props.get("closed", false)):
			out = CircuitEdits.set_props(out, p.id, {"closed": true})
	return out


## A part id, or for a kind ("resistor") the part of that kind that isn't
## burnt and takes the most power.
static func _resolve(name: String, circuit: Circuit, sim: SimResult) -> String:
	if circuit == null or circuit.find_part(name) != null or not Catalog.has_kind(name):
		return name
	var best := ""
	var most := -1.0
	for p in circuit.parts:
		if p.kind != name or bool(p.props.get("burnt", false)):
			continue
		var watts := absf(float(sim.part_watts.get(p.id, 0.0))) if sim != null else 0.0
		if watts > most:
			most = watts
			best = p.id
	return best if best != "" else name
