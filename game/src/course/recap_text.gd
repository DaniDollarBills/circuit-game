class_name RecapText
extends RefCounted
## Fills a recap point's {part.quantity} templates ({L1.mA}, {R1.ohms},
## {R1.W}, {B1.V}, {M1.reading}) with the player's own simulated values. A
## part that isn't there reads "—"; braces that aren't a template stay.

static var _template := RegEx.create_from_string("\\{([A-Za-z0-9_]+)\\.(mA|V|W|ohms|reading)\\}")


static func fill(text: String, circuit: Circuit, sim: SimResult) -> String:
	var out := text
	for m in _template.search_all(text):
		out = out.replace(m.get_string(0), Readouts.text_value(m.get_string(1), m.get_string(2), circuit, sim))
	return out
