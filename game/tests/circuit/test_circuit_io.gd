extends TestCase


func test_round_trip_compact_loop() -> void:
	var c := TestCircuits.compact_loop()
	var back := CircuitIO.from_json(CircuitIO.to_json(c))
	assert_true(back != null)
	assert_eq(CircuitIO.to_dict(back), CircuitIO.to_dict(c))
	assert_eq(back.find_part("L1").rot, 90)
	assert_eq(typeof(back.find_part("L1").x), TYPE_INT)


func test_round_trip_keeps_via_and_tray() -> void:
	var c := TestCircuits.compact_loop()
	var via: Array[Vector2i] = [Vector2i(-4, -6), Vector2i(9, -6)]
	c.wires.append(Wire.make("w_bad", "R1", "a", "L1", "cathode", true, via))
	var s := Part.make("S", "switch", 3, -6, 0, {"label": "S", "closed": true})
	s.tray = 2
	c.parts.append(s)
	var back := CircuitIO.from_json(CircuitIO.to_json(c))
	assert_eq(back.find_wire("w_bad").via, via)
	assert_true(back.find_wire("w_bad").locked)
	assert_eq(back.find_part("S").tray, 2)
	assert_eq(back.find_part("S").props["closed"], true)


func test_rejects_bad_json() -> void:
	assert_eq(CircuitIO.from_json("not json"), null)
	assert_eq(CircuitIO.from_json("[1, 2]"), null)


func test_rejects_unknown_kind() -> void:
	var d := CircuitIO.to_dict(TestCircuits.compact_loop())
	d["parts"][0]["kind"] = "flux_capacitor"
	assert_eq(CircuitIO.from_dict(d), null)


func test_rejects_wrong_format() -> void:
	var d := CircuitIO.to_dict(TestCircuits.compact_loop())
	d["format"] = 99
	assert_eq(CircuitIO.from_dict(d), null)
	d.erase("format")
	assert_eq(CircuitIO.from_dict(d), null)


func test_rejects_bad_pin_and_duplicate_id() -> void:
	var d := CircuitIO.to_dict(TestCircuits.compact_loop())
	d["wires"][0]["a"] = ["B1", "middle"]
	assert_eq(CircuitIO.from_dict(d), null)
	var e := CircuitIO.to_dict(TestCircuits.compact_loop())
	e["parts"][1]["id"] = "B1"
	assert_eq(CircuitIO.from_dict(e), null)
