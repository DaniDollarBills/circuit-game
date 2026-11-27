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


## Exact values come from an independent bisection solve of the same model
## (battery 1 Ω, LED 5 Ω plus junction with n = 2, Vt = 25.852 mV).
func test_red_led_150_ohm() -> void:
	assert_near(_led_current(150.0), 0.019873891, 1e-7)


func test_red_led_220_ohm() -> void:
	assert_near(_led_current(220.0), 0.013801678, 1e-7)


func test_red_led_1k() -> void:
	assert_near(_led_current(1000.0), 0.003176083, 1e-7)


func test_blue_led_220_ohm() -> void:
	assert_near(_led_current(220.0, "blue"), 0.009463235, 1e-7)


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
	assert_near(s.device_amps["L1"], 0.489118157, 1e-7)


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
	assert_near(s.device_amps["L1"], 0.013801678, 1e-7)


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


## Regression (found by the fuzz test): LEDs leading to a dead end carry only
## leakage-sized currents, and their node voltages carry ~1e-7 V of rounding
## noise between iterations. The solver must still report convergence.
func test_dead_end_leds_converge() -> void:
	var c := TestCircuits.battery_only()
	c.parts.append(Part.make("L1", "led", 0, -6, 0, {"color": "green"}))
	c.parts.append(Part.make("L2", "led", 4, -6, 0, {"color": "red"}))
	c.wires.append(Wire.make("w1", "B1", "pos", "L1", "anode"))
	c.wires.append(Wire.make("w2", "L1", "cathode", "L2", "anode"))
	var s := _solve(c)
	assert_true(s.converged, "converged")
	assert_true(absf(s.device_amps["L1"]) < 1e-9, "leakage only")


## Regression (checkpoint review A): a battery held to the reference only by
## picoamp leakage left its node voltages bouncing at the rounding-noise floor,
## so Newton never settled and fell back to source stepping. The noise depends
## on how the nets are numbered, so every part order is tried (10 of the 24
## used to fail).
func test_leakage_held_battery_converges() -> void:
	var parts := {
		"B1": Part.make("B1", "battery", 0, 0), "B2": Part.make("B2", "battery", 8, 0),
		"R1": Part.make("R1", "resistor", 4, -4, 0, {"ohms": 10000.0}),
		"L1": Part.make("L1", "led", 4, 4, 0, {"color": "blue"}),
	}
	for order in _orders(["B1", "B2", "R1", "L1"]):
		var c := Circuit.new()
		for id in order:
			c.parts.append((parts[id] as Part).copy())
		c.wires.append(Wire.make("w1", "L1", "anode", "B1", "pos"))
		c.wires.append(Wire.make("w2", "B1", "neg", "L1", "anode"))
		c.wires.append(Wire.make("w3", "L1", "cathode", "R1", "a"))
		c.wires.append(Wire.make("w4", "B2", "neg", "R1", "a"))
		var s := _solve(c)
		assert_true(s.converged, str(order))
		assert_false(s.stepped, "plain Newton settles: %s" % [order])
		assert_true(absf(s.device_amps["L1"]) < 1e-9, str(order))


func _orders(ids: Array) -> Array:
	if ids.size() <= 1:
		return [ids]
	var out := []
	for i in ids.size():
		var rest := ids.duplicate()
		var first: Variant = rest.pop_at(i)
		for tail in _orders(rest):
			out.append([first] + tail)
	return out


## Regression (checkpoint review A): even with SPICE's tolerances this circuit
## settled into a 4-step cycle of about 35 µV on a leakage-held node near 0 V.
func test_noise_floor_cycle_converges() -> void:
	var c := Circuit.new()
	var kinds := ["battery", "resistor", "ammeter", "ammeter", "led", "led", "battery"]
	var props := [{}, {"ohms": 2000.0}, {}, {}, {"color": "red"}, {"color": "blue"}, {}]
	for i in kinds.size():
		c.parts.append(Part.make("P%d" % i, kinds[i], i * 5, 0, 0, props[i]))
	for w in [["P3", "a", "P5", "anode"], ["P3", "b", "P2", "a"], ["P6", "neg", "P5", "anode"], ["P0", "neg", "P4", "anode"],
			["P3", "a", "P3", "b"], ["P4", "cathode", "P1", "b"], ["P6", "neg", "P1", "a"]]:
		c.wires.append(Wire.make("w%d" % c.wires.size(), w[0], w[1], w[2], w[3]))
	var s := _solve(c)
	assert_true(s.converged)
	assert_false(s.stepped)


func _dead_end_chain(batteries: int, leds: int, meters: bool, color: String) -> Circuit:
	var c := Circuit.new()
	for i in batteries:
		c.parts.append(Part.make("B%d" % (i + 1), "battery", -6 - 4 * i, 0))
		if i > 0:
			c.wires.append(Wire.make("wb%d" % i, "B%d" % i, "pos", "B%d" % (i + 1), "neg"))
	var prev := ["B%d" % batteries, "pos"]
	for k in leds:
		if meters:
			var m := "M%d" % (k + 1)
			c.parts.append(Part.make(m, "ammeter", 6 * k, -6, 0))
			c.wires.append(Wire.make("wm%d" % k, prev[0], prev[1], m, "a"))
			prev = [m, "b"]
		var l := "L%d" % (k + 1)
		c.parts.append(Part.make(l, "led", 6 * k + 3, -6, 0, {"color": color}))
		c.wires.append(Wire.make("wl%d" % k, prev[0], prev[1], l, "anode"))
		prev = [l, "cathode"]
	return c


## Regression (checkpoint review A): B1.pos → M1 → L1 → M2 → L2 → M3 → L3,
## with the last cathode left open.
func test_dead_end_chain_with_meters_converges() -> void:
	var s := _solve(_dead_end_chain(1, 3, true, "blue"))
	assert_true(s.converged)
	assert_false(s.stepped)


## Stacked batteries feeding dead-end LED chains, with and without meters.
func test_dead_end_chains_sweep_converges() -> void:
	for batteries in [1, 2, 4, 8]:
		for leds in [1, 3, 6]:
			for meters in [false, true]:
				for color in ["red", "blue"]:
					var what := "%d batteries, %d %s LEDs, meters %s" % [batteries, leds, color, meters]
					var s := _solve(_dead_end_chain(batteries, leds, meters, color))
					assert_true(s.converged, what)
					assert_false(s.stepped, what)
					for id in s.device_amps:
						assert_true(is_finite(s.device_amps[id]), what)


## The fallback must reach the same answer as plain Newton.
func test_source_stepping_matches_newton() -> void:
	for c in [TestCircuits.compact_loop(220.0), TestCircuits.compact_loop(150.0, "blue"), TestCircuits.meter_loop(500.0)]:
		var n := Netlist.build(c)
		var plain := DcSolver.solve(n)
		var stepped := DcSolver.solve_by_source_stepping(n)
		assert_false(plain.stepped)
		assert_true(stepped.converged and stepped.stepped)
		for id in plain.device_amps:
			assert_near(stepped.device_amps[id], plain.device_amps[id], 1e-9, id)


func test_identical_parallel_leds_share_current() -> void:
	var c := TestCircuits.compact_loop(220.0)
	c.parts.append(Part.make("L2", "led", 9, 0, 90))
	c.wires.append(Wire.make("w4", "R1", "b", "L2", "anode"))
	c.wires.append(Wire.make("w5", "L2", "cathode", "B1", "neg"))
	var s := _solve(c)
	assert_near(s.device_amps["L1"], 0.007055639, 1e-7)
	assert_near(s.device_amps["L2"], 0.007055639, 1e-7)


func test_empty_board_converges() -> void:
	var s := _solve(Circuit.new())
	assert_true(s.converged)
	assert_eq(s.device_amps.size(), 0)


## Bad numbers (from a damaged save, say) never turn into NaN or infinite currents.
func test_non_finite_props_stay_finite() -> void:
	for volts in [NAN, INF, -INF]:
		var c := TestCircuits.compact_loop()
		c.find_part("B1").props["volts"] = volts
		var s := _solve(c)
		for id in s.device_amps:
			assert_true(is_finite(s.device_amps[id]), "volts %s: %s" % [volts, id])
	for ohms in [NAN, INF, 0.0, -50.0]:
		var s := _solve(TestCircuits.compact_loop(ohms))
		for id in s.device_amps:
			assert_true(is_finite(s.device_amps[id]), "ohms %s: %s" % [ohms, id])
