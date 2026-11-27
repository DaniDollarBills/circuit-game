extends TestCase


func _solve(c: Circuit) -> DcSolution:
	return DcSolver.solve(Netlist.build(c))


func _battery_resistor(ohms: float) -> Circuit:
	var c := TestCircuits.battery_only()
	c.parts.append(Part.make("R1", "resistor", -2, -4, 0, {"ohms": ohms}))
	c.wires.append(Wire.make("w1", "B1", "pos", "R1", "a"))
	c.wires.append(Wire.make("w2", "R1", "b", "B1", "neg"))
	return c


func _led_current(ohms: float, color := "red") -> float:
	var s := _solve(TestCircuits.compact_loop(ohms, color))
	assert_true(s.converged, "converged")
	return s.device_amps["L1"]


func test_battery_1k() -> void:
	var s := _solve(_battery_resistor(1000.0))
	assert_true(s.converged)
	assert_near(s.device_amps["R1"], 5.0 / 1001.0, 1e-9)
	assert_near(s.device_amps["B1"], 5.0 / 1001.0, 1e-9)


func test_divider_midpoint() -> void:
	var c := TestCircuits.battery_only()
	c.parts.append(Part.make("R1", "resistor", -2, -4, 0, {"ohms": 1000.0}))
	c.parts.append(Part.make("R2", "resistor", 4, -4, 0, {"ohms": 1000.0}))
	c.wires.append(Wire.make("w1", "B1", "pos", "R1", "a"))
	c.wires.append(Wire.make("w2", "R1", "b", "R2", "a"))
	c.wires.append(Wire.make("w3", "R2", "b", "B1", "neg"))
	var n := Netlist.build(c)
	var s := DcSolver.solve(n)
	assert_near(s.net_volts[n.net_of["R1:b"]], 2.49875, 1e-6)
	assert_near(s.net_volts[n.net_of["B1:neg"]], 0.0, 1e-12)


func test_red_led_150_ohm() -> void:
	assert_between(_led_current(150.0), 0.0195, 0.0202)


func test_red_led_220_ohm() -> void:
	assert_between(_led_current(220.0), 0.0135, 0.0141)


func test_red_led_1k() -> void:
	assert_between(_led_current(1000.0), 0.0030, 0.0034)


func test_blue_led_220_ohm() -> void:
	assert_between(_led_current(220.0, "blue"), 0.0090, 0.0099)


func test_led_reversed_dark() -> void:
	var c := TestCircuits.compact_loop()
	c.wires = c.wires.filter(func(w: Wire) -> bool: return w.id == "w1")
	c.wires.append(Wire.make("w2", "R1", "b", "L1", "cathode"))
	c.wires.append(Wire.make("w3", "L1", "anode", "B1", "neg"))
	var s := _solve(c)
	assert_true(s.converged)
	assert_true(absf(s.device_amps["L1"]) < 1e-9, "reverse current %s" % s.device_amps["L1"])


func test_led_direct_on_battery() -> void:
	var c := TestCircuits.battery_only()
	c.parts.append(Part.make("L1", "led", 6, 0, 90))
	c.wires.append(Wire.make("w1", "B1", "pos", "L1", "anode"))
	c.wires.append(Wire.make("w2", "L1", "cathode", "B1", "neg"))
	var s := _solve(c)
	assert_true(s.converged)
	assert_between(s.device_amps["L1"], 0.4, 0.6)


func test_two_batteries_series_1k() -> void:
	var c := TestCircuits.battery_only()
	c.parts.append(Part.make("B2", "battery", -10, 0))
	c.parts.append(Part.make("R1", "resistor", -2, -4, 0, {"ohms": 1000.0}))
	c.wires.append(Wire.make("w1", "B1", "pos", "B2", "neg"))
	c.wires.append(Wire.make("w2", "B2", "pos", "R1", "a"))
	c.wires.append(Wire.make("w3", "R1", "b", "B1", "neg"))
	var s := _solve(c)
	assert_near(s.device_amps["R1"], 10.0 / 1002.0, 1e-6)


func test_opposing_batteries_no_current() -> void:
	var c := TestCircuits.battery_only()
	c.parts.append(Part.make("B2", "battery", -10, 0))
	c.parts.append(Part.make("R1", "resistor", -2, -4, 0, {"ohms": 1000.0}))
	c.wires.append(Wire.make("w1", "B1", "pos", "R1", "a"))
	c.wires.append(Wire.make("w2", "R1", "b", "B2", "pos"))
	c.wires.append(Wire.make("w3", "B2", "neg", "B1", "neg"))
	var s := _solve(c)
	assert_true(absf(s.device_amps["R1"]) < 1e-9, "current %s" % s.device_amps["R1"])


func test_shorted_battery_current_5a() -> void:
	var c := TestCircuits.with_wire(TestCircuits.battery_only(), "w1", "B1", "pos", "B1", "neg")
	var s := _solve(c)
	assert_true(s.converged)
	assert_near(s.device_amps["B1"], 5.0, 1e-9)


func test_floating_part_nan_no_crash() -> void:
	var c := TestCircuits.compact_loop()
	c.parts.append(Part.make("R9", "resistor", 0, 8))
	var n := Netlist.build(c)
	var s := DcSolver.solve(n)
	assert_true(s.converged)
	assert_true(is_nan(s.net_volts[n.net_of["R9:a"]]))
	assert_eq(s.device_amps["R9"], 0.0)
	assert_between(s.device_amps["L1"], 0.0135, 0.0141)


func test_no_battery_all_floating_converged() -> void:
	var c := Circuit.new()
	c.parts.append(Part.make("R1", "resistor", 0, 0))
	c.parts.append(Part.make("L1", "led", 4, 0))
	c.wires.append(Wire.make("w1", "R1", "b", "L1", "anode"))
	var n := Netlist.build(c)
	var s := DcSolver.solve(n)
	assert_true(s.converged)
	for i in n.net_count:
		assert_true(is_nan(s.net_volts[i]))
	assert_eq(s.device_amps["L1"], 0.0)


func test_voltmeter_draws_half_microamp() -> void:
	var c := TestCircuits.battery_only()
	c.parts.append(Part.make("V1", "voltmeter", 0, 0))
	c.wires.append(Wire.make("w1", "B1", "pos", "V1", "pos"))
	c.wires.append(Wire.make("w2", "V1", "neg", "B1", "neg"))
	var s := _solve(c)
	assert_near(s.device_amps["V1"], 5e-7, 1e-9)


func test_led_power_is_current_times_voltage() -> void:
	var c := TestCircuits.compact_loop(220.0)
	var s := _solve(c)
	var i: float = s.device_amps["L1"]
	assert_near(s.device_watts["R1"], i * i * 220.0, 1e-9)
	assert_between(s.device_watts["L1"], i * 1.9, i * 2.0)
