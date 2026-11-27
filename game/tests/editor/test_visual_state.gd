extends TestCase


func _vis(c: Circuit, id: String) -> Dictionary:
	var out := Simulator.simulate(c)
	return VisualState.for_part(out.circuit.find_part(id), out.result, {})


func test_reading_formats() -> void:
	assert_eq(_vis(TestCircuits.meter_loop(500.0), "M1")["reading"], "10.0 mA")
	assert_eq(_vis(TestCircuits.meter_loop(500.0), "V1")["reading"], "4.99 V")
	var loose := TestCircuits.compact_loop()
	loose.parts.append(Part.make("V9", "voltmeter", 0, 8))
	assert_eq(_vis(loose, "V9")["reading"], "—")


func test_brightness_clamped() -> void:
	assert_near(_vis(TestCircuits.compact_loop(220.0), "L1")["brightness"], 0.690, 0.001)
	assert_eq(_vis(TestCircuits.compact_loop(100.0), "L1")["brightness"], 1.0)
	var burnt := CircuitEdits.set_props(TestCircuits.compact_loop(), "L1", {"burnt": true})
	var v := _vis(burnt, "L1")
	assert_true(v["burnt"])
	assert_eq(v["brightness"], 0.0)


func test_hot_closed_color_label() -> void:
	var shorted := TestCircuits.with_wire(TestCircuits.compact_loop(), "w9", "B1", "pos", "B1", "neg")
	assert_true(_vis(shorted, "B1")["hot"])
	assert_false(_vis(TestCircuits.compact_loop(), "B1")["hot"])
	assert_eq(_vis(TestCircuits.compact_loop(220.0, "blue"), "L1")["color"], "blue")
	var c := TestCircuits.compact_loop()
	c.parts.append(Part.make("S1", "switch", 0, 8, 0, {"closed": true, "label": "A"}))
	var s := _vis(c, "S1")
	assert_true(s["closed"])
	assert_eq(s["label"], "A")


func test_engineer_labels_volts_and_amps() -> void:
	var c := TestCircuits.compact_loop(220.0)
	var out := Simulator.simulate(c)
	var labels := VisualState.engineer_labels(out.circuit, out.result)
	var texts: Array = labels.map(func(l: Dictionary) -> String: return l["text"])
	assert_true("4.99 V" in texts, str(texts))
	assert_true("1.95 V" in texts, str(texts))
	assert_true("0.00 V" in texts, str(texts))
	assert_eq(texts.count("13.8 mA"), 2, "one on R1 and one on L1")
	var plus: Dictionary = labels[texts.find("4.99 V")]
	assert_eq(plus["at"], Vector2(CircuitGeometry.pin_position(c.find_part("B1"), "pos")) + Vector2(0.4, -0.4))
	var r1: Dictionary = labels[texts.find("13.8 mA")]
	assert_eq(r1["at"], CircuitGeometry.part_rect(c.find_part("R1")).get_center() + Vector2(0, 0.9))


func test_engineer_labels_skip_floating() -> void:
	var c := TestCircuits.compact_loop()
	c.parts.append(Part.make("R9", "resistor", 0, 8))
	var out := Simulator.simulate(c)
	assert_eq(VisualState.engineer_labels(out.circuit, out.result).size(), 3 + 2)
