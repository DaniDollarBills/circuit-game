extends TestCase


## Wide layout with switches A and B wired in series (or in parallel).
func _two_switches(series: bool) -> Circuit:
	var c := Circuit.new()
	c.parts.append(Part.make("B1", "battery", -6, 0, 0, {}, true))
	c.parts.append(Part.make("R1", "resistor", -2, -4, 0, {}, true))
	c.parts.append(Part.make("L1", "led", 12, 0, 90, {}, true))
	c.parts.append(Part.make("SW1", "switch", 3, -4, 0, {"label": "A"}))
	c.parts.append(Part.make("SW2", "switch", 8, -4, 0, {"label": "B"}))
	c.wires.append(Wire.make("w1", "B1", "pos", "R1", "a"))
	c.wires.append(Wire.make("w3", "L1", "cathode", "B1", "neg"))
	c.wires.append(Wire.make("w4", "R1", "b", "SW1", "a"))
	if series:
		c.wires.append(Wire.make("w5", "SW1", "b", "SW2", "a"))
		c.wires.append(Wire.make("w6", "SW2", "b", "L1", "anode"))
	else:
		c.wires.append(Wire.make("w5", "R1", "b", "SW2", "a"))
		c.wires.append(Wire.make("w6", "SW1", "b", "L1", "anode"))
		c.wires.append(Wire.make("w7", "SW2", "b", "L1", "anode"))
	return c


func _both_level() -> LevelDef:
	var b := LevelBuilder.new("test.both", "ch1", "Both switches")
	for a_on in [false, true]:
		for b_on in [false, true]:
			var lit: bool = a_on and b_on
			var name := "A %s, B %s: LED %s" % ["on" if a_on else "off", "on" if b_on else "off", "on" if lit else "off"]
			var expect := [{"kind": "led_lit", "part": "L1"}] if lit else [{"kind": "led_dark", "part": "L1"}]
			b.test(name, [{"target": "A", "prop": "closed", "value": a_on}, {"target": "B", "prop": "closed", "value": b_on}], expect)
	return b.done()


func test_level_tests_series_pass() -> void:
	var report := LevelTests.run(_both_level(), _two_switches(true))
	assert_true(report["pass"])
	assert_eq(report["cases"].size(), 4)


func test_level_tests_parallel_fails_both_rule() -> void:
	var report := LevelTests.run(_both_level(), _two_switches(false))
	assert_false(report["pass"])
	var failed: Array = report["cases"].filter(func(k: Dictionary) -> bool: return not k["pass"])
	assert_eq(failed.size(), 2)
	assert_eq(failed[0]["name"], "A off, B on: LED off")
	assert_eq(failed[1]["name"], "A on, B off: LED off")
	assert_eq(failed[0]["messages"], PackedStringArray(["The LED is still on."]))


func test_level_tests_missing_target() -> void:
	var b := LevelBuilder.new("test.missing", "ch1", "Missing")
	b.test("Z on", [{"target": "Z", "prop": "closed", "value": true}], [{"kind": "led_lit", "part": "L1"}])
	var report := LevelTests.run(b.done(), TestCircuits.compact_loop())
	assert_false(report["pass"])
	assert_eq(report["cases"][0]["messages"], PackedStringArray(["Missing part: Z"]))


## Levels without tests are judged by their goals alone, so their report passes.
func test_level_without_tests_passes_vacuously() -> void:
	var report := LevelTests.run(LevelBuilder.new("t.none", "ch1", "None").done(), TestCircuits.compact_loop())
	assert_true(report["pass"])
	assert_eq(report["cases"].size(), 0)


func test_tests_do_not_change_the_players_circuit() -> void:
	var c := _two_switches(true)
	LevelTests.run(_both_level(), c)
	assert_false(c.find_part("SW1").props["closed"])
