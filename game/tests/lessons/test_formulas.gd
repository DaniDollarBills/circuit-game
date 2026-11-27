extends TestCase


func test_e12_values_and_at_or_above() -> void:
	var v := E12.values()
	assert_eq(v.size(), 37)
	assert_eq(v[0], 10.0)
	assert_eq(v[1], 12.0)
	assert_eq(v[v.size() - 1], 10000.0)
	assert_eq(E12.at_or_above(350.0), 390.0)
	assert_eq(E12.at_or_above(150.0), 150.0)
	assert_eq(E12.at_or_above(500.0), 560.0)
	assert_eq(E12.at_or_above(149.99999999999997), 150.0)
	assert_eq(E12.at_or_above(150.00000000000003), 150.0)


func test_led_resistor_formula_150() -> void:
	var r := Formulas.led_resistor(5.0, 2.0, 0.020)
	assert_near(r["exact"], 150.0, 1e-9)
	assert_eq(r["standard"], 150.0)
	assert_eq(r["steps"], PackedStringArray([
		"R = (supply − LED voltage) ÷ current",
		"R = (5.0 V − 2.0 V) ÷ 0.020 A",
		"R = 150 Ω",
		"Nearest standard value at or above: 150 Ω",
	]))


func test_led_resistor_rounds_up_to_standard() -> void:
	var r := Formulas.led_resistor(9.0, 2.0, 0.020)
	assert_near(r["exact"], 350.0, 1e-9)
	assert_eq(r["standard"], 390.0)


func test_ohms_law_solves_missing() -> void:
	var i := Formulas.ohms_law(5.0, NAN, 500.0)
	assert_near(i["value"], 0.010, 1e-12)
	assert_eq(i["unit"], "A")
	assert_eq(i["steps"][i["steps"].size() - 1], "I = 5.0 V ÷ 500 Ω = 0.010 A (10 mA)")
	var r := Formulas.ohms_law(5.0, 0.010, NAN)
	assert_near(r["value"], 500.0, 1e-9)
	assert_eq(r["unit"], "Ω")
	var v := Formulas.ohms_law(NAN, 0.010, 500.0)
	assert_near(v["value"], 5.0, 1e-12)
	assert_eq(v["unit"], "V")
	assert_true(is_nan(Formulas.ohms_law(5.0, 0.01, 500.0)["value"]))


func test_power_from_r_47() -> void:
	var p := Formulas.power_from_r(5.0, 47.0)
	assert_near(p["value"], 0.5319, 1e-4)
	# Lesson 8 teaches P = V × I, so the working goes through the current.
	assert_eq(p["steps"], PackedStringArray(["P = V × I, and I = V ÷ R", "I = 5.0 V ÷ 47 Ω = 0.106 A",
			"P = 5.0 V × 0.106 A = 0.53 W"]))


## The calculator's fields are editable, so impossible inputs get an explanation
## instead of "inf" or "nan".
func test_formulas_refuse_impossible_inputs() -> void:
	var r := Formulas.led_resistor(2.0, 2.0, 0.020)
	assert_true(is_nan(r["exact"]) and is_nan(r["standard"]))
	assert_eq(r["steps"][r["steps"].size() - 1], "This can't work: the supply must be higher than the LED voltage, and the current more than 0 A.")
	var i := Formulas.ohms_law(5.0, NAN, 0.0)
	assert_true(is_nan(i["value"]))
	assert_eq(i["steps"][i["steps"].size() - 1], "The resistance must be more than 0 Ω.")
	var r2 := Formulas.ohms_law(5.0, 0.0, NAN)
	assert_eq(r2["steps"][r2["steps"].size() - 1], "The current must be more than 0 A.")
	var p := Formulas.power_from_r(5.0, 0.0)
	assert_true(is_nan(p["value"]))
	assert_eq(p["steps"][p["steps"].size() - 1], "The resistance must be more than 0 Ω.")
