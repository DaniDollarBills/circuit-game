class_name Circuit
extends RefCounted
## A board: parts plus the wires between their pins.

var parts: Array[Part] = []
var wires: Array[Wire] = []


func copy() -> Circuit:
	var c := Circuit.new()
	for p in parts:
		c.parts.append(p.copy())
	for w in wires:
		c.wires.append(w.copy())
	return c


## Matches a part id first, then a part's `label` prop. Returns null if none.
func find_part(id_or_label: String) -> Part:
	for p in parts:
		if p.id == id_or_label:
			return p
	if id_or_label.is_empty():
		return null
	for p in parts:
		if str(p.props.get("label", "")) == id_or_label:
			return p
	return null


func find_wire(wire_id: String) -> Wire:
	for w in wires:
		if w.id == wire_id:
			return w
	return null


func wires_at(part_id: String, pin: String) -> Array[Wire]:
	var out: Array[Wire] = []
	for w in wires:
		if (w.a_part == part_id and w.a_pin == pin) or (w.b_part == part_id and w.b_pin == pin):
			out.append(w)
	return out
