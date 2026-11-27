extends TestCase


func _ctx(c: Circuit, extra := {}) -> Dictionary:
	var out := Simulator.simulate(c)
	var ctx := {"circuit": out.circuit, "sim": out.result, "zoom_layer": "editor", "zoom_seen": {}, "ui_flags": {}}
	ctx.merge(extra, true)
	return ctx


func _msg(goal: Dictionary, c: Circuit, extra := {}) -> String:
	return Goals.evaluate(goal, _ctx(c, extra))["message"]


func _without(c: Circuit, wire_id: String) -> Circuit:
	var d := c.copy()
	d.wires = d.wires.filter(func(w: Wire) -> bool: return w.id != wire_id)
	return d


func test_led_lit_each_diagnosis() -> void:
	var lit := {"kind": "led_lit", "part": "L1"}
	var burnt := CircuitEdits.set_props(TestCircuits.compact_loop(), "L1", {"burnt": true})
	assert_eq(_msg(lit, burnt), "Pop! The LED burned out from too much current. Hold it to replace it, then add a resistor.")
	var shorted := TestCircuits.with_wire(TestCircuits.compact_loop(), "w9", "B1", "pos", "B1", "neg")
	assert_eq(_msg(lit, shorted), "Short circuit! The current is taking a shortcut around your parts.")
	var open := _without(TestCircuits.compact_loop(), "w3")
	assert_eq(_msg(lit, open), "The loop isn't closed yet. Current needs a full path from + back to −.")
	var reversed := _without(_without(TestCircuits.compact_loop(), "w2"), "w3")
	reversed.wires.append(Wire.make("w2", "R1", "b", "L1", "cathode"))
	reversed.wires.append(Wire.make("w3", "L1", "anode", "B1", "neg"))
	assert_eq(_msg(lit, reversed), "The LED is backwards. Flip it so its + side points toward the battery's +.")
	assert_eq(_msg(lit, TestCircuits.compact_loop(1.0e6)), "A little current flows, but not enough to see. Try a smaller resistor.")
	var dim := {"kind": "led_lit", "part": "L1", "min_ma": 10.0}
	assert_eq(_msg(dim, TestCircuits.compact_loop(1000.0)), "It's glowing, but dimly (3.2 mA). Can you make it brighter?")
	assert_eq(_msg(lit, TestCircuits.compact_loop(220.0)), "Lit! 13.8 mA flowing.")
	assert_true(Goals.evaluate(lit, _ctx(TestCircuits.compact_loop(220.0)))["pass"])


func test_led_over_max_message() -> void:
	var g := {"kind": "led_lit", "part": "L1", "max_ma": 20.0}
	var r := Goals.evaluate(g, _ctx(TestCircuits.compact_loop(100.0)))
	assert_false(r["pass"])
	assert_eq(r["message"], "Careful: 29.1 mA is more than this LED's recommended 20 mA. It glows, but it won't last.")


func test_led_dark() -> void:
	var g := {"kind": "led_dark", "part": "L1"}
	assert_eq(_msg(g, _without(TestCircuits.compact_loop(), "w3")), "The LED is off.")
	assert_eq(_msg(g, TestCircuits.compact_loop()), "The LED is still on.")


func test_no_damage_and_no_short() -> void:
	var burnt := CircuitEdits.set_props(TestCircuits.compact_loop(), "L1", {"burnt": true})
	assert_eq(_msg({"kind": "no_damage"}, TestCircuits.compact_loop()), "Nothing is burned.")
	assert_eq(_msg({"kind": "no_damage"}, burnt), "Something burned out. Replace it to continue.")
	var shorted := TestCircuits.with_wire(TestCircuits.compact_loop(), "w9", "B1", "pos", "B1", "neg")
	assert_eq(_msg({"kind": "no_short"}, TestCircuits.compact_loop()), "No short circuits.")
	assert_eq(_msg({"kind": "no_short"}, shorted), "Short circuit! Find the wire that skips your parts.")


func test_meter_reads_formats_units() -> void:
	var amp := {"kind": "meter_reads", "part": "M1", "target": 0.010, "tolerance": 0.0005}
	assert_eq(_msg(amp, TestCircuits.meter_loop(500.0)), "The meter reads 10.0 mA.")
	assert_eq(_msg(amp, TestCircuits.meter_loop(1000.0)), "The meter reads 5.0 mA. Aim for 10.0 mA (±0.5 mA).")
	var volt := {"kind": "meter_reads", "part": "V1", "target": 5.0, "tolerance": 0.1}
	assert_eq(_msg(volt, TestCircuits.meter_loop(500.0)), "The meter reads 4.99 V.")
	var loose := TestCircuits.compact_loop()
	loose.parts.append(Part.make("V9", "voltmeter", 0, 8))
	var g9 := {"kind": "meter_reads", "part": "V9", "target": 5.0, "tolerance": 0.1}
	assert_eq(_msg(g9, loose), "The meter isn't connected yet.")


func test_uses_min_max() -> void:
	var c := TestCircuits.compact_loop()
	assert_true(Goals.evaluate({"kind": "uses", "part_kind": "resistor", "min": 1}, _ctx(c))["pass"])
	assert_eq(_msg({"kind": "uses", "part_kind": "switch", "min": 1}, c), "Add a switch from the tray.")
	assert_eq(_msg({"kind": "uses", "part_kind": "led", "min": 2}, c), "Add an LED from the tray.")
	assert_eq(_msg({"kind": "uses", "part_kind": "resistor", "max": 0}, c), "Use at most 0 of the resistor part.")


func test_zoom_reached_reads_ctx() -> void:
	var g := {"kind": "zoom_reached", "layer": "wire.copper"}
	var c := TestCircuits.compact_loop()
	assert_eq(_msg(g, c), "Keep zooming in.")
	assert_eq(_msg(g, c, {"zoom_layer": "wire.copper"}), "You made it inside!")


func test_ui_flag_and_zoom_seen() -> void:
	var c := TestCircuits.compact_loop()
	assert_eq(_msg({"kind": "ui_flag", "flag": "tested"}, c), "Not yet.")
	assert_eq(_msg({"kind": "ui_flag", "flag": "tested"}, c, {"ui_flags": {"tested": true}}), "Done.")
	var g := {"kind": "zoom_reached", "layer": "wire.closeup"}
	assert_true(Goals.evaluate(g, _ctx(c, {"zoom_layer": "wire.copper", "zoom_seen": {"wire.closeup": true}}))["pass"])


func test_connected_any_pin_wildcard() -> void:
	var c := TestCircuits.compact_loop()
	assert_true(Goals.evaluate({"kind": "connected", "a": "B1:pos", "b": "R1:a"}, _ctx(c))["pass"])
	assert_true(Goals.evaluate({"kind": "connected", "a": "R1:*", "b": "L1:anode"}, _ctx(c))["pass"])
	assert_eq(_msg({"kind": "connected", "a": "B1:pos", "b": "L1:cathode"}, c), "Not connected yet.")
	assert_eq(_msg({"kind": "connected", "a": "B1:pos", "b": "R1:a"}, c), "Connected.")


func test_all_requires_every_goal() -> void:
	var c := TestCircuits.compact_loop()
	var g := {"kind": "all", "goals": [{"kind": "no_short"}, {"kind": "uses", "part_kind": "switch", "min": 1}]}
	var r := Goals.evaluate(g, _ctx(c))
	assert_false(r["pass"])
	assert_eq(r["message"], "Add a switch from the tray.")
	var ok := Goals.evaluate({"kind": "all", "goals": [{"kind": "no_short"}]}, _ctx(c))
	assert_true(ok["pass"])
	assert_eq(ok["message"], "")


func test_resistor_watts_range() -> void:
	var heater := TestCircuits.battery_only()
	heater.parts.append(Part.make("R1", "resistor", -2, 0, 90, {"ohms": 47.0, "watts": 1.0}))
	heater.wires.append(Wire.make("w1", "B1", "pos", "R1", "a"))
	heater.wires.append(Wire.make("w2", "R1", "b", "B1", "neg"))
	var g := {"kind": "resistor_watts", "min": 0.4, "max": 0.6}
	assert_eq(_msg(g, heater), "0.51 W of heat. Toasty!")
	assert_eq(_msg(g, TestCircuits.compact_loop()), "Aim for 0.4–0.6 W of heat from a resistor.")


func test_part_matched_by_label() -> void:
	var c := TestCircuits.compact_loop()
	c.find_part("L1").props["label"] = "Lamp"
	assert_true(Goals.evaluate({"kind": "led_lit", "part": "Lamp"}, _ctx(c))["pass"])


func test_evaluate_all_returns_one_result_per_goal() -> void:
	var rs := Goals.evaluate_all([{"kind": "no_short"}, {"kind": "no_damage"}], _ctx(TestCircuits.compact_loop()))
	assert_eq(rs.size(), 2)
	assert_true(rs[0]["pass"] and rs[1]["pass"])
