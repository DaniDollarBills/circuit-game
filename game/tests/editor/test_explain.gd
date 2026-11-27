extends TestCase


func _explain(c: Circuit, id: String) -> PackedStringArray:
	var out := Simulator.simulate(c)
	return Explain.part(out.circuit.find_part(id), out.result)


func test_explain_resistor_led_battery_220() -> void:
	var c := TestCircuits.compact_loop(220.0)
	assert_eq(_explain(c, "R1"), PackedStringArray([
		"Voltage across R1: 3.04 V",
		"Current = 3.04 V ÷ 220 Ω = 13.8 mA",
		"Heat = 3.04 V × 13.8 mA = 0.042 W (rated 0.25 W)",
	]))
	assert_eq(_explain(c, "L1"), PackedStringArray([
		"Voltage across L1: 1.95 V",
		"Current: 13.8 mA (recommended up to 20 mA)",
		"Brightness: 69%",
	]))
	assert_eq(_explain(c, "B1"), PackedStringArray([
		"Voltage at the terminals: 5.0 V − 13.8 mA × 1 Ω = 4.99 V",
		"Power delivered: 4.99 V × 13.8 mA = 0.069 W",
	]))


func test_explain_floating_and_burnt() -> void:
	var c := TestCircuits.compact_loop()
	c.parts.append(Part.make("R9", "resistor", 0, 8))
	assert_eq(_explain(c, "R9"), PackedStringArray(["Not connected to the battery yet."]))
	var led := TestCircuits.battery_only()
	led.parts.append(Part.make("L1", "led", 6, 0, 90))
	led.wires.append(Wire.make("w1", "B1", "pos", "L1", "anode"))
	led.wires.append(Wire.make("w2", "L1", "cathode", "B1", "neg"))
	assert_eq(_explain(led, "L1"), PackedStringArray(["LED burned out: more than its 30 mA maximum."]))
	var hot := TestCircuits.battery_only()
	hot.parts.append(Part.make("R1", "resistor", -2, 0, 90, {"ohms": 47.0}))
	hot.wires.append(Wire.make("w1", "B1", "pos", "R1", "a"))
	hot.wires.append(Wire.make("w2", "R1", "b", "B1", "neg"))
	assert_eq(_explain(hot, "R1"), PackedStringArray(["Resistor burned out: more heat than its 0.25 W rating."]))
	var fuse := TestCircuits.battery_only()
	fuse.parts.append(Part.make("M1", "ammeter", 0, 0))
	fuse.wires.append(Wire.make("w1", "B1", "pos", "M1", "a"))
	fuse.wires.append(Wire.make("w2", "M1", "b", "B1", "neg"))
	assert_eq(_explain(fuse, "M1"), PackedStringArray(["Current meter burned out: its 500 mA fuse blew."]))


func test_explain_meters_and_switch() -> void:
	var c := TestCircuits.meter_loop(500.0)
	assert_eq(_explain(c, "M1"), PackedStringArray([
		"Current through M1: 10.0 mA",
		"A current meter goes in series, so all the current flows through it.",
	]))
	assert_eq(_explain(c, "V1"), PackedStringArray([
		"Voltage between the probes: 4.99 V",
		"A voltage meter has 10 MΩ inside, so it barely changes the circuit.",
	]))
	var s := TestCircuits.compact_loop()
	s.wires = s.wires.filter(func(w: Wire) -> bool: return w.id != "w2")
	s.parts.append(Part.make("S1", "switch", 2, -4, 0, {"label": "S"}))
	s.wires.append(Wire.make("w4", "R1", "b", "S1", "a"))
	s.wires.append(Wire.make("w5", "S1", "b", "L1", "anode"))
	assert_eq(_explain(s, "S1"), PackedStringArray(["S is open, so the loop is broken."]))
	assert_eq(_explain(CircuitEdits.set_props(s, "S1", {"closed": true}), "S1"), PackedStringArray(["S is closed, so current can flow."]))
