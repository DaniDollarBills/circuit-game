extends RefCounted
## The two board layouts Chapter 1 uses, so every level places its parts the
## same way. Compact: battery B1 (−6,0), resistor R1 (−2,−4) and LED L1 (6,0)
## turned 90°. Wide: the same, with the LED at (12,0) to leave room for switches.


static func compact(b: LevelBuilder, resistor_props := {}) -> LevelBuilder:
	return b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4, 0, resistor_props).part("L1", "led", 6, 0, 90)


static func wide(b: LevelBuilder) -> LevelBuilder:
	return b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4).part("L1", "led", 12, 0, 90)


## The locked loop wires w1 (B1.pos→R1.a), w2 (R1.b→L1.anode) and
## w3 (L1.cathode→B1.neg) named in `ids`.
static func loop_wires(b: LevelBuilder, ids: PackedStringArray) -> LevelBuilder:
	if "w1" in ids:
		b.wire("w1", "B1", "pos", "R1", "a")
	if "w2" in ids:
		b.wire("w2", "R1", "b", "L1", "anode")
	if "w3" in ids:
		b.wire("w3", "L1", "cathode", "B1", "neg")
	return b


## The four switch combinations for A and B, named like "A on, B off: LED off".
static func switch_tests(b: LevelBuilder, lit: Callable) -> LevelBuilder:
	for a_on in [false, true]:
		for b_on in [false, true]:
			var on: bool = lit.call(a_on, b_on)
			var name := "A %s, B %s: LED %s" % ["on" if a_on else "off", "on" if b_on else "off", "on" if on else "off"]
			var expect := [{"kind": "led_lit", "part": "L1"}] if on else [{"kind": "led_dark", "part": "L1"}]
			b.test(name, [{"target": "A", "prop": "closed", "value": a_on}, {"target": "B", "prop": "closed", "value": b_on}], expect)
	return b
