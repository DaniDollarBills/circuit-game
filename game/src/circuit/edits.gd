class_name CircuitEdits
extends RefCounted
## Pure editing operations. Each returns a new Circuit and never changes its
## input. A refused edit (locked part or wire, unknown id) returns the input
## itself, so the undo history can tell nothing happened.


static func add_part(c: Circuit, p: Part) -> Circuit:
	var out := c.copy()
	out.parts.append(p.copy())
	return out


static func move_part(c: Circuit, id: String, x: int, y: int) -> Circuit:
	var p := c.find_part(id)
	if p == null or p.id != id or p.locked:
		return c
	var out := c.copy()
	var q := out.find_part(id)
	q.x = x
	q.y = y
	return out


static func rotate_part(c: Circuit, id: String) -> Circuit:
	var p := c.find_part(id)
	if p == null or p.id != id or p.locked:
		return c
	var out := c.copy()
	var q := out.find_part(id)
	q.rot = (q.rot + 90) % 360
	return out


## Also removes every wire attached to the part.
static func delete_part(c: Circuit, id: String) -> Circuit:
	var p := c.find_part(id)
	if p == null or p.id != id or p.locked:
		return c
	var out := Circuit.new()
	for q in c.parts:
		if q.id != id:
			out.parts.append(q.copy())
	for w in c.wires:
		if w.a_part != id and w.b_part != id:
			out.wires.append(w.copy())
	return out


## Allowed on locked parts (a locked switch still toggles, a burnt part can be replaced).
static func set_props(c: Circuit, id: String, patch: Dictionary) -> Circuit:
	var p := c.find_part(id)
	if p == null or p.id != id:
		return c
	var out := c.copy()
	out.find_part(id).props.merge(patch.duplicate(true), true)
	return out


## "" when the wire is allowed; otherwise "same pin", "unknown pin" or "duplicate".
static func can_add_wire(c: Circuit, a_part: String, a_pin: String, b_part: String, b_pin: String) -> String:
	var pa := c.find_part(a_part)
	var pb := c.find_part(b_part)
	if pa == null or pb == null or pa.id != a_part or pb.id != b_part:
		return "unknown pin"
	if not Catalog.has_pin(pa.kind, a_pin) or not Catalog.has_pin(pb.kind, b_pin):
		return "unknown pin"
	if a_part == b_part and a_pin == b_pin:
		return "same pin"
	for w in c.wires:
		var same := w.a_part == a_part and w.a_pin == a_pin and w.b_part == b_part and w.b_pin == b_pin
		var swapped := w.a_part == b_part and w.a_pin == b_pin and w.b_part == a_part and w.b_pin == a_pin
		if same or swapped:
			return "duplicate"
	return ""


static func add_wire(c: Circuit, a_part: String, a_pin: String, b_part: String, b_pin: String) -> Circuit:
	assert(can_add_wire(c, a_part, a_pin, b_part, b_pin) == "", "add_wire called with an invalid wire")
	var out := c.copy()
	out.wires.append(Wire.make(next_id(c, "w"), a_part, a_pin, b_part, b_pin))
	return out


static func delete_wire(c: Circuit, id: String) -> Circuit:
	var w := c.find_wire(id)
	if w == null or w.locked:
		return c
	var out := Circuit.new()
	for p in c.parts:
		out.parts.append(p.copy())
	for x in c.wires:
		if x.id != id:
			out.wires.append(x.copy())
	return out


## The prefix followed by one more than the largest number already used with it
## (ids are never reused, so flags and history stay unambiguous).
static func next_id(c: Circuit, prefix: String) -> String:
	var highest := 0
	var ids := PackedStringArray()
	for p in c.parts:
		ids.append(p.id)
	for w in c.wires:
		ids.append(w.id)
	for id in ids:
		if id.begins_with(prefix):
			var rest := id.substr(prefix.length())
			if rest.is_valid_int():
				highest = maxi(highest, rest.to_int())
	return "%s%d" % [prefix, highest + 1]
