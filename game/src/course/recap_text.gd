class_name RecapText
extends RefCounted
## Fills a recap point's {part.quantity} templates ({L1.mA}, {R1.ohms},
## {R1.W}, {B1.V}, {M1.reading}) with the player's own simulated values. A
## part can be named by its kind ({resistor.W}): the working one doing the
## most, since a tray part's id depends on the order it was placed. A part
## that isn't there reads "—"; braces that aren't a template stay.

static var _template := RegEx.create_from_string("\\{([A-Za-z0-9_]+)\\.(mA|V|W|heat|ohms|reading)\\}")


static func fill(text: String, circuit: Circuit, sim: SimResult) -> String:
	var out := text
	for m in _template.search_all(text):
		var id := _resolve(m.get_string(1), circuit, sim)
		out = out.replace(m.get_string(0), Readouts.text_value(id, m.get_string(2), circuit, sim))
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
