extends TestCase


func _vis(extra := {}) -> Dictionary:
	var v := {"brightness": 0.0, "burnt": false, "hot": false, "reading": "", "closed": false, "color": "red", "label": ""}
	v.merge(extra, true)
	return v


func _tagged(ops: Array[Dictionary], tag: String) -> Array[Dictionary]:
	return ops.filter(func(o: Dictionary) -> bool: return o.get("tag", "") == tag)


func _types(ops: Array[Dictionary]) -> Array:
	return ops.map(func(o: Dictionary) -> String: return o["type"])


func test_lit_led_has_glow_op() -> void:
	var ops := PartArt.ops(Part.make("L1", "led", 0, 0), _vis({"brightness": 0.7}), false, false)
	assert_true("glow" in _types(ops))
	assert_false("glow" in _types(PartArt.ops(Part.make("L1", "led", 0, 0), _vis(), false, false)), "dark LEDs don't glow")


func test_burnt_part_has_scorch_and_no_glow() -> void:
	var ops := PartArt.ops(Part.make("L1", "led", 0, 0), _vis({"brightness": 0.7, "burnt": true}), false, false)
	assert_eq(_tagged(ops, "scorch").size(), 1)
	assert_false("glow" in _types(ops))


func test_switch_lever_differs_open_closed() -> void:
	var open := _tagged(PartArt.ops(Part.make("S1", "switch", 0, 0), _vis(), false, false), "lever")
	var closed := _tagged(PartArt.ops(Part.make("S1", "switch", 0, 0), _vis({"closed": true}), false, false), "lever")
	assert_eq(open.size(), 1)
	assert_eq(closed.size(), 1)
	assert_true(open[0]["points"] != closed[0]["points"])
	var p: PackedVector2Array = closed[0]["points"]
	assert_near(p[0].y, p[p.size() - 1].y, 1e-6, "a closed lever lies flat")


func test_meter_has_reading_text_op() -> void:
	var ops := PartArt.ops(Part.make("M1", "ammeter", 0, 0), _vis({"reading": "13.8 mA"}), false, false)
	var reading := _tagged(ops, "reading")
	assert_eq(reading.size(), 1)
	assert_eq(reading[0]["text"], "13.8 mA")
	var letters := ops.filter(func(o: Dictionary) -> bool: return o["type"] == "text" and o["text"] == "A")
	assert_eq(letters.size(), 1)


func test_selected_adds_outline() -> void:
	var plain := PartArt.ops(Part.make("R1", "resistor", 0, 0), _vis(), false, false)
	var selected := PartArt.ops(Part.make("R1", "resistor", 0, 0), _vis(), true, false)
	assert_eq(selected.size(), plain.size() + 1)
	assert_eq(_tagged(selected, "selected").size(), 1)
	assert_eq(_tagged(PartArt.ops(Part.make("R1", "resistor", 0, 0), _vis(), false, true), "highlight").size(), 1)


func test_schematic_resistor_is_zigzag_polyline() -> void:
	var zig := _tagged(PartArt.ops(Part.make("R1", "resistor", 0, 0), _vis(), false, false), "zigzag")
	assert_eq(zig.size(), 1)
	assert_eq(zig[0]["type"], "polyline")
	var peaks := 0
	for v in (zig[0]["points"] as PackedVector2Array):
		if absf(v.y) > 0.1:
			peaks += 1
	assert_eq(peaks, 6)


func test_schematic_led_has_triangle_poly() -> void:
	var body := _tagged(PartArt.ops(Part.make("L1", "led", 0, 0), _vis(), false, false), "body")
	assert_eq(body.size(), 1)
	assert_eq(body[0]["type"], "poly")
	assert_eq((body[0]["points"] as PackedVector2Array).size(), 3)


## Every pin gets a metal dot exactly at its local offset.
func test_pins_are_metal_dots() -> void:
	for kind in Catalog.PARTS:
		var p := Part.make("X1", kind, 0, 0)
		var dots := _tagged(PartArt.ops(p, _vis(), false, false), "pin")
		assert_eq(dots.size(), Catalog.pin_names(kind).size(), kind)
		for pin in Catalog.pin_names(kind):
			var at := Vector2(CircuitGeometry.pin_offset(p, pin))
			assert_true(dots.any(func(d: Dictionary) -> bool: return (d["c"] as Vector2).is_equal_approx(at)), "%s %s" % [kind, pin])


func test_resistor_value_text_and_one_watt() -> void:
	var quarter := PartArt.ops(Part.make("R1", "resistor", 0, 0, 0, {"ohms": 220.0}), _vis(), false, false)
	assert_eq(_tagged(quarter, "value")[0]["text"], "220 Ω")
	var one := PartArt.ops(Part.make("R1", "resistor", 0, 0, 0, {"ohms": 47.0, "watts": 1.0}), _vis(), false, false)
	assert_eq(_tagged(one, "value")[0]["text"], "47 Ω · 1 W")
	var adj := PartArt.ops(Part.make("R1", "resistor", 0, 0, 0, {"adjustable": true}), _vis(), false, false)
	assert_eq(_tagged(adj, "adjust").size(), 2, "an arrow: shaft and head")
