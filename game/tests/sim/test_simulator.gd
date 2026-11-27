extends TestCase


func _across_battery(kind: String, props := {}) -> Circuit:
	var c := TestCircuits.battery_only()
	c.parts.append(Part.make("X1", kind, -2, -4, 0, props))
	var pins := Catalog.pin_names(kind)
	c.wires.append(Wire.make("w1", "B1", "pos", "X1", pins[0]))
	c.wires.append(Wire.make("w2", "X1", pins[1], "B1", "neg"))
	return c


func test_loop_wires_carry_loop_current() -> void:
	var r := Simulator.simulate(TestCircuits.compact_loop(220.0)).result
	for w in ["w1", "w2", "w3"]:
		assert_near(r.wire_amps[w], 0.0138, 3e-4, w)


func test_parallel_closed_switches_split_evenly() -> void:
	var c := TestCircuits.compact_loop()
	c.wires = c.wires.filter(func(w: Wire) -> bool: return w.id != "w2")
	c.parts.append(Part.make("A", "switch", 4, -4, 0, {"closed": true}))
	c.parts.append(Part.make("S2", "switch", 4, -7, 0, {"closed": true}))
	c.wires.append(Wire.make("w4", "R1", "b", "A", "a"))
	c.wires.append(Wire.make("w5", "R1", "b", "S2", "a"))
	c.wires.append(Wire.make("w6", "A", "b", "L1", "anode"))
	c.wires.append(Wire.make("w7", "S2", "b", "L1", "anode"))
	var r := Simulator.simulate(c).result
	var led: float = r.part_amps["L1"]
	assert_near(r.connector_amps["A"], led / 2.0, 1e-4)
	assert_near(r.connector_amps["S2"], led / 2.0, 1e-4)
	assert_near(r.connector_amps["A"] + r.connector_amps["S2"], led, 1e-6)
	assert_near(r.part_amps["A"], r.connector_amps["A"], 1e-12)


func test_ammeter_reads_series_current() -> void:
	var r := Simulator.simulate(TestCircuits.meter_loop(500.0)).result
	assert_near(r.meter["M1"], 5.0 / 501.0, 1e-5)
	# With the 0.1 Ω burden and the 10 MΩ voltmeter included: 5 / 501.075 A.
	assert_near(r.meter["M1"], 0.00997854, 1e-7)


func test_voltmeter_reads_resistor_drop() -> void:
	var r := Simulator.simulate(TestCircuits.meter_loop(500.0)).result
	assert_near(r.meter["V1"], 4.98902, 1e-4)


func test_unconnected_meter_unreadable() -> void:
	var c := TestCircuits.compact_loop()
	c.parts.append(Part.make("V9", "voltmeter", 0, 8))
	var r := Simulator.simulate(c).result
	assert_true(is_nan(r.meter["V9"]))


func test_led_burns_without_resistor() -> void:
	var out := Simulator.simulate(_across_battery("led"))
	assert_eq(out.damage.size(), 1)
	assert_eq(out.damage[0]["part"], "X1")
	assert_eq(out.damage[0]["reason"], "overcurrent")
	assert_eq(out.circuit.find_part("X1").props.get("burnt"), true)
	assert_eq(out.result.part_amps.get("X1", 0.0), 0.0)


func test_resistor_overheats() -> void:
	var out := Simulator.simulate(_across_battery("resistor", {"ohms": 47.0}))
	assert_eq(out.damage.size(), 1)
	assert_eq(out.damage[0]["reason"], "overheat")


func test_quarter_watt_resistor_burns_at_half_watt() -> void:
	var out := Simulator.simulate(_across_battery("resistor", {"ohms": 47.0, "watts": 0.25}))
	assert_near(out.damage[0]["ratio"], 0.5100 / 0.25, 1e-3)
	assert_true(out.circuit.find_part("X1").props.get("burnt", false))


func test_one_watt_resistor_survives_half_watt() -> void:
	var out := Simulator.simulate(_across_battery("resistor", {"ohms": 47.0, "watts": 1.0}))
	assert_eq(out.damage.size(), 0)
	assert_near(out.result.part_watts["X1"], 0.510, 1e-3)


func test_ammeter_fuse_blows_across_battery() -> void:
	var out := Simulator.simulate(_across_battery("ammeter"))
	assert_eq(out.damage.size(), 1)
	assert_eq(out.damage[0]["reason"], "fuse")
	assert_near(out.result.part_amps["B1"], 0.0, 1e-9)
	assert_eq(out.result.shorts.size(), 0)


func test_burn_order_highest_ratio_first() -> void:
	var out := Simulator.simulate(TestCircuits.compact_loop(10.0))
	assert_eq(out.damage.size(), 1)
	assert_eq(out.damage[0]["part"], "L1")
	assert_near(out.damage[0]["ratio"], 0.1865 / 0.030, 0.02)
	assert_false(out.circuit.find_part("R1").props.get("burnt", false))


func test_led_over_recommended_but_under_max_not_burnt() -> void:
	var out := Simulator.simulate(TestCircuits.compact_loop(100.0))
	assert_eq(out.damage.size(), 0)
	assert_near(out.result.part_amps["L1"], 0.02906, 1e-4)


func test_short_flagged() -> void:
	var c := TestCircuits.with_wire(TestCircuits.battery_only(), "w1", "B1", "pos", "B1", "neg")
	var r := Simulator.simulate(c).result
	assert_eq(r.shorts, ["B1"] as Array[String])


func test_no_damage_returns_input_circuit() -> void:
	var c := TestCircuits.compact_loop()
	assert_eq(Simulator.simulate(c).circuit, c)


func test_pin_volts_and_floating() -> void:
	var c := TestCircuits.compact_loop()
	c.parts.append(Part.make("R9", "resistor", 0, 8))
	var r := Simulator.simulate(c).result
	assert_near(r.pin_volts("B1", "neg"), 0.0, 1e-12)
	assert_near(r.pin_volts("B1", "pos"), 5.0 - 0.0138, 3e-4)
	assert_true(r.is_floating("R9", "a"))
	assert_true(is_nan(r.pin_volts("R9", "a")))


func test_fuzz_never_nan() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var kinds := ["battery", "resistor", "led", "switch", "ammeter", "voltmeter"]
	var ohms := [10.0, 47.0, 100.0, 220.0, 1000.0, 10000.0]
	var colors := ["red", "yellow", "green", "blue"]
	for trial in 200:
		var c := Circuit.new()
		var pins: Array = []
		for i in rng.randi_range(1, 8):
			var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
			var props := {}
			match kind:
				"resistor":
					props["ohms"] = ohms[rng.randi_range(0, ohms.size() - 1)]
				"led":
					props["color"] = colors[rng.randi_range(0, colors.size() - 1)]
				"switch":
					props["closed"] = rng.randf() < 0.5
			var id := "P%d" % i
			c.parts.append(Part.make(id, kind, i * 5, 0, 0, props))
			for pin in Catalog.pin_names(kind):
				pins.append([id, pin])
		for j in rng.randi_range(0, 10):
			var a: Array = pins[rng.randi_range(0, pins.size() - 1)]
			var b: Array = pins[rng.randi_range(0, pins.size() - 1)]
			if a[0] == b[0] and a[1] == b[1]:
				continue
			c.wires.append(Wire.make("w%d" % j, a[0], a[1], b[0], b[1]))
		var out := Simulator.simulate(c)
		var r := out.result
		var where := "trial %d: %s" % [trial, CircuitIO.to_json(c)]
		assert_true(r.converged, "not converged " + where)
		assert_true(out.damage.size() <= 10, where)
		for i in r.net_volts.size():
			if not r.floating.has(i):
				assert_true(is_finite(r.net_volts[i]), "net %d " % i + where)
		for id in r.part_amps:
			assert_true(is_finite(r.part_amps[id]), "amps %s " % id + where)
		if not failures.is_empty():
			return


func test_empty_board_simulates() -> void:
	var out := Simulator.simulate(Circuit.new())
	assert_true(out.result.converged)
	assert_eq(out.damage.size(), 0)


func test_switch_short_flagged() -> void:
	var c := TestCircuits.battery_only()
	c.parts.append(Part.make("S1", "switch", -2, -4, 0, {"closed": true}))
	c.wires.append(Wire.make("w1", "B1", "pos", "S1", "a"))
	c.wires.append(Wire.make("w2", "S1", "b", "B1", "neg"))
	var r := Simulator.simulate(c).result
	assert_eq(r.shorts, ["B1"] as Array[String])
	assert_near(r.part_amps["B1"], 5.0, 1e-9)


## A wire across the resistor's own pins leaves the LED straight on the battery.
func test_wire_across_resistor_burns_led() -> void:
	var out := Simulator.simulate(TestCircuits.with_wire(TestCircuits.compact_loop(), "w4", "R1", "a", "R1", "b"))
	assert_eq(out.damage.size(), 1)
	assert_eq(out.damage[0]["part"], "L1")


## A wire across the LED's own pins bypasses it: dark, and the resistor sets the current.
func test_wire_across_led_bypasses_it() -> void:
	var out := Simulator.simulate(TestCircuits.with_wire(TestCircuits.compact_loop(220.0), "w4", "L1", "anode", "L1", "cathode"))
	assert_eq(out.damage.size(), 0)
	assert_eq(out.result.part_amps["L1"], 0.0)
	assert_near(out.result.part_amps["R1"], 5.0 / 221.0, 1e-9)


func test_parallel_opposing_batteries_both_flagged() -> void:
	var c := TestCircuits.battery_only()
	c.parts.append(Part.make("B2", "battery", -10, 0))
	c.wires.append(Wire.make("w1", "B1", "pos", "B2", "neg"))
	c.wires.append(Wire.make("w2", "B1", "neg", "B2", "pos"))
	var r := Simulator.simulate(c).result
	assert_true(r.converged)
	assert_eq(r.shorts.size(), 2)
	assert_near(absf(r.part_amps["B1"]), 5.0, 1e-9)
	assert_near(absf(r.part_amps["B2"]), 5.0, 1e-9)


func test_ammeter_bypassed_by_wire_reads_zero() -> void:
	var c := TestCircuits.with_wire(TestCircuits.meter_loop(500.0), "w9", "M1", "a", "M1", "b")
	var r := Simulator.simulate(c).result
	assert_eq(r.meter["M1"], 0.0)


## Eleven LEDs each straight across their own battery: only ten may burn.
func test_burn_cap_stops_at_ten() -> void:
	var c := Circuit.new()
	for i in 11:
		var b := "B%d" % (i + 1)
		var l := "L%d" % (i + 1)
		c.parts.append(Part.make(b, "battery", 6 * i, 0))
		c.parts.append(Part.make(l, "led", 6 * i + 3, 0, 90))
		c.wires.append(Wire.make("wa%d" % i, b, "pos", l, "anode"))
		c.wires.append(Wire.make("wc%d" % i, l, "cathode", b, "neg"))
	assert_eq(Simulator.simulate(c).damage.size(), Simulator.MAX_BURNS)


func test_burn_leaves_input_circuit_unchanged() -> void:
	var c := _across_battery("led")
	var out := Simulator.simulate(c)
	assert_true(out.circuit.find_part("X1").props.get("burnt", false))
	assert_false(c.find_part("X1").props.has("burnt"))


## Closed loops through a battery, with random parts in series and a few random
## extra wires: LEDs light, parts burn, and every result is converged and finite.
func test_fuzz_closed_loops_light_and_burn() -> void:
	var kinds := ["resistor", "resistor", "led", "led", "switch", "ammeter"]
	var ohms := [10.0, 47.0, 100.0, 220.0, 1000.0]
	var colors := ["red", "yellow", "green", "blue"]
	var lit := 0
	var burns := 0
	for run_seed in [7, 42, 2026]:
		var rng := RandomNumberGenerator.new()
		rng.seed = run_seed
		for trial in 40:
			var c := TestCircuits.battery_only()
			var pins: Array = [["B1", "pos"], ["B1", "neg"]]
			var prev := ["B1", "pos"]
			for i in rng.randi_range(1, 5):
				var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
				var props := {}
				match kind:
					"resistor":
						props["ohms"] = ohms[rng.randi_range(0, ohms.size() - 1)]
					"led":
						props["color"] = colors[rng.randi_range(0, colors.size() - 1)]
					"switch":
						props["closed"] = rng.randf() < 0.8
				var id := "P%d" % i
				c.parts.append(Part.make(id, kind, 5 * i, -6, 0, props))
				var names := Catalog.pin_names(kind)
				c.wires.append(Wire.make("s%d" % i, prev[0], prev[1], id, names[0]))
				prev = [id, names[1]]
				for pin in names:
					pins.append([id, pin])
			c.wires.append(Wire.make("s_end", prev[0], prev[1], "B1", "neg"))
			for j in rng.randi_range(0, 3):
				var a: Array = pins[rng.randi_range(0, pins.size() - 1)]
				var b: Array = pins[rng.randi_range(0, pins.size() - 1)]
				if a != b:
					c.wires.append(Wire.make("x%d" % j, a[0], a[1], b[0], b[1]))
			var out := Simulator.simulate(c)
			var r := out.result
			var where := "seed %d trial %d: %s" % [run_seed, trial, CircuitIO.to_json(c)]
			assert_true(r.converged, "not converged " + where)
			for id in r.part_amps:
				assert_true(is_finite(r.part_amps[id]), "amps %s " % id + where)
			burns += out.damage.size()
			for p in out.circuit.parts:
				if p.kind == "led" and not p.props.get("burnt", false) and float(r.part_amps[p.id]) >= Devices.LED_LIT_AMPS:
					lit += 1
			if not failures.is_empty():
				return
	assert_true(lit > 10, "lit LEDs: %d" % lit)
	assert_true(burns > 5, "burns: %d" % burns)
