class_name TestCircuits
extends RefCounted
## Ready-made circuits for tests.


## Battery B1 at (-6,0); resistor R1 at (-2,-4); LED L1 at (6,0) rot 90;
## wires w1 B1.pos→R1.a, w2 R1.b→L1.anode, w3 L1.cathode→B1.neg.
static func compact_loop(ohms := 220.0, color := "red") -> Circuit:
	var c := Circuit.new()
	c.parts.append(Part.make("B1", "battery", -6, 0))
	c.parts.append(Part.make("R1", "resistor", -2, -4, 0, {"ohms": ohms}))
	c.parts.append(Part.make("L1", "led", 6, 0, 90, {"color": color}))
	c.wires.append(Wire.make("w1", "B1", "pos", "R1", "a"))
	c.wires.append(Wire.make("w2", "R1", "b", "L1", "anode"))
	c.wires.append(Wire.make("w3", "L1", "cathode", "B1", "neg"))
	return c


static func battery_only() -> Circuit:
	var c := Circuit.new()
	c.parts.append(Part.make("B1", "battery", -6, 0))
	return c


## Returns a copy of `c` with one more wire.
static func with_wire(c: Circuit, id: String, a_part: String, a_pin: String, b_part: String, b_pin: String) -> Circuit:
	var out := c.copy()
	out.wires.append(Wire.make(id, a_part, a_pin, b_part, b_pin))
	return out
