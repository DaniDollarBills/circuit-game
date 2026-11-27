extends TestCase


## Compact loop with switch S (open unless `closed`) between R1.b and the LED.
func _switch_loop(closed: bool) -> Circuit:
	var c := TestCircuits.compact_loop()
	c.wires = c.wires.filter(func(w: Wire) -> bool: return w.id != "w2")
	c.parts.append(Part.make("S", "switch", 3, -6, 0, {"closed": closed}))
	c.wires.append(Wire.make("w4", "R1", "b", "S", "a"))
	c.wires.append(Wire.make("w5", "S", "b", "L1", "anode"))
	return c


func _kinds(n: Netlist) -> PackedStringArray:
	var out := PackedStringArray()
	for d in n.devices:
		out.append("%s:%s" % [d["kind"], d["part"].id])
	return out


func test_compact_loop_has_three_nets_and_reference() -> void:
	var n := Netlist.build(TestCircuits.compact_loop())
	assert_eq(n.net_count, 3)
	assert_eq(n.net_of["B1:pos"], 0)
	assert_eq(n.net_of["B1:neg"], 1)
	assert_eq(n.net_of["R1:a"], 0)
	assert_eq(n.net_of["R1:b"], 2)
	assert_eq(n.net_of["L1:anode"], 2)
	assert_eq(n.net_of["L1:cathode"], 1)
	assert_eq(n.reference_net[n.component_of_net[1]], 1)
	assert_true(n.floating.is_empty())
	assert_eq(_kinds(n), PackedStringArray(["battery:B1", "resistor:R1", "led:L1"]))
	assert_eq(n.connectors.size(), 3)


func test_open_switch_separates_nets() -> void:
	var n := Netlist.build(_switch_loop(false))
	assert_true(n.net_of["S:a"] != n.net_of["S:b"])
	for k in n.connectors:
		assert_true(k["kind"] != "switch")


func test_closed_switch_merges() -> void:
	var n := Netlist.build(_switch_loop(true))
	assert_eq(n.net_of["S:a"], n.net_of["S:b"])
	var sw := n.connectors.filter(func(k: Dictionary) -> bool: return k["kind"] == "switch")
	assert_eq(sw.size(), 1)
	assert_eq(sw[0]["g"], 1000.0)
	assert_eq(sw[0]["a"], "S:a")


func test_ammeter_is_a_0_1_ohm_device() -> void:
	var c := TestCircuits.compact_loop()
	c.wires = c.wires.filter(func(w: Wire) -> bool: return w.id != "w3")
	c.parts.append(Part.make("M1", "ammeter", 2, 4))
	c.wires.append(Wire.make("w6", "L1", "cathode", "M1", "a"))
	c.wires.append(Wire.make("w7", "M1", "b", "B1", "neg"))
	var n := Netlist.build(c)
	assert_true("ammeter:M1" in _kinds(n))
	assert_true(n.net_of["M1:a"] != n.net_of["M1:b"])
	for k in n.connectors:
		assert_true(k["id"] != "M1")


func test_burnt_resistor_not_a_device() -> void:
	var c := CircuitEdits.set_props(TestCircuits.compact_loop(), "R1", {"burnt": true})
	assert_false("resistor:R1" in _kinds(Netlist.build(c)))


func test_burnt_ammeter_is_open() -> void:
	var c := TestCircuits.compact_loop()
	c.parts.append(Part.make("M1", "ammeter", 2, 4, 0, {"burnt": true}))
	var n := Netlist.build(c)
	assert_false("ammeter:M1" in _kinds(n))
	assert_true(n.net_of["M1:a"] != n.net_of["M1:b"])


func test_isolated_resistor_nets_floating() -> void:
	var c := TestCircuits.compact_loop()
	c.parts.append(Part.make("R9", "resistor", 0, 8))
	var n := Netlist.build(c)
	assert_true(n.floating.has(n.net_of["R9:a"]))
	assert_true(n.floating.has(n.net_of["R9:b"]))
	assert_false(n.floating.has(n.net_of["B1:pos"]))


func test_two_battery_loops_two_references() -> void:
	var c := TestCircuits.compact_loop()
	c.parts.append(Part.make("B2", "battery", -6, 12))
	c.parts.append(Part.make("R2", "resistor", -2, 8))
	c.wires.append(Wire.make("w8", "B2", "pos", "R2", "a"))
	c.wires.append(Wire.make("w9", "R2", "b", "B2", "neg"))
	var n := Netlist.build(c)
	assert_eq(n.reference_net.size(), 2)
	assert_true(n.component_of_net[n.net_of["B1:pos"]] != n.component_of_net[n.net_of["B2:pos"]])
	assert_eq(n.reference_net[n.component_of_net[n.net_of["B2:pos"]]], n.net_of["B2:neg"])


func test_voltmeter_is_10m_device() -> void:
	var c := TestCircuits.compact_loop()
	c.parts.append(Part.make("R9", "resistor", 0, 8))
	c.parts.append(Part.make("V1", "voltmeter", 4, 8))
	c.wires.append(Wire.make("w10", "R9", "b", "V1", "pos"))
	c.wires.append(Wire.make("w11", "V1", "neg", "B1", "neg"))
	var n := Netlist.build(c)
	assert_true("voltmeter:V1" in _kinds(n))
	assert_eq(n.voltmeters.size(), 1)
	assert_false(n.floating.has(n.net_of["R9:b"]))
	assert_false(n.floating.has(n.net_of["R9:a"]))
