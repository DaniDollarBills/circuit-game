extends TestCase


func _row(rows: Array[Dictionary], label: String) -> String:
	for r in rows:
		if r["label"] == label:
			return r["value"]
	return "<missing %s>" % label


func test_find_part_by_label() -> void:
	var c := TestCircuits.compact_loop()
	c.parts.append(Part.make("p9", "switch", 3, -4, 0, {"label": "A"}))
	assert_eq(c.find_part("L1").id, "L1")
	assert_eq(c.find_part("A").id, "p9")
	assert_eq(c.find_part("nope"), null)


func test_copy_is_deep() -> void:
	var c := TestCircuits.compact_loop()
	var d := c.copy()
	d.find_part("R1").props["ohms"] = 47.0
	d.find_wire("w1").b_pin = "b"
	assert_eq(c.find_part("R1").props["ohms"], 220.0)
	assert_eq(c.find_wire("w1").b_pin, "a")


func test_make_fills_catalog_defaults() -> void:
	var r := Part.make("R1", "resistor", 0, 0)
	assert_eq(r.props["ohms"], 220.0)
	assert_eq(r.props["adjustable"], false)
	assert_eq(Part.make("S", "switch", 0, 0).props["closed"], false)
	assert_eq(Part.make("B1", "battery", 0, 0).props["volts"], 5.0)


func test_resistor_default_watts_quarter() -> void:
	assert_eq(Part.make("R1", "resistor", 0, 0).props["watts"], 0.25)


func test_wires_at() -> void:
	var c := TestCircuits.compact_loop()
	var ws := c.wires_at("B1", "pos")
	assert_eq(ws.size(), 1)
	assert_eq(ws[0].id, "w1")


func test_catalog_pin_order() -> void:
	assert_eq(Catalog.pin_names("battery"), PackedStringArray(["pos", "neg"]))
	assert_eq(Catalog.pin_names("led"), PackedStringArray(["anode", "cathode"]))
	assert_eq(Catalog.title("ammeter"), "Current meter")


func test_datasheet_red_led() -> void:
	var rows := Catalog.datasheet(Part.make("L1", "led", 0, 0))
	assert_eq(_row(rows, "Color"), "Red, 625 nm")
	assert_eq(_row(rows, "Forward voltage"), "2.0 V at 20 mA")
	assert_eq(_row(rows, "Recommended current"), "20 mA")
	assert_eq(_row(rows, "Absolute maximum"), "30 mA")


func test_datasheet_blue_led_voltage() -> void:
	var rows := Catalog.datasheet(Part.make("L1", "led", 0, 0, 0, {"color": "blue"}))
	assert_eq(_row(rows, "Forward voltage"), "3.0 V at 20 mA")


func test_datasheet_resistors() -> void:
	var quarter := Catalog.datasheet(Part.make("R1", "resistor", 0, 0))
	assert_eq(_row(quarter, "Resistance"), "220 Ω")
	assert_eq(_row(quarter, "Power rating"), "0.25 W (¼ W)")
	assert_eq(_row(quarter, "Type"), "Carbon film")
	var kilo := Catalog.datasheet(Part.make("R2", "resistor", 0, 0, 0, {"ohms": 1000.0}))
	assert_eq(_row(kilo, "Resistance"), "1 kΩ")


func test_datasheet_one_watt_resistor() -> void:
	var rows := Catalog.datasheet(Part.make("R1", "resistor", 0, 0, 0, {"ohms": 47.0, "watts": 1.0}))
	assert_eq(_row(rows, "Power rating"), "1 W")
	assert_eq(_row(rows, "Type"), "Metal film")
	var type: Dictionary = rows.filter(func(r: Dictionary) -> bool: return r["label"] == "Type")[0]
	assert_eq(type["term"], "metal film", "the type links to its definition")


func test_datasheet_rows_link_glossary_terms() -> void:
	var rows := Catalog.datasheet(Part.make("V1", "voltmeter", 0, 0))
	assert_eq(_row(rows, "Input resistance"), "10 MΩ")
	for r in rows:
		assert_true(r.has("term"), "row %s has a term field" % r["label"])


## The adjustable resistor on screen is a cermet trimmer (no color bands), so
## its datasheet must describe one: ±10%, ½ W, like real 3386-style trimmers.
func test_datasheet_adjustable_resistor_is_a_cermet_trimmer() -> void:
	var rows := Catalog.datasheet(Part.make("R1", "resistor", 0, 0, 0, {"ohms": 1000.0, "adjustable": true, "watts": 0.5}))
	assert_eq(_row(rows, "Resistance"), "1 kΩ")
	assert_eq(_row(rows, "Tolerance"), "±10%")
	assert_eq(_row(rows, "Power rating"), "0.5 W (½ W)")
	assert_eq(_row(rows, "Type"), "Cermet trimmer")


func test_l3_trimmer_is_rated_like_the_real_part() -> void:
	var r1 := Levels.by_id("ch1.push-and-flow").circuit.find_part("R1")
	assert_true(bool(r1.props["adjustable"]))
	assert_eq(float(r1.props["watts"]), 0.5)
