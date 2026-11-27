extends RefCounted
## Level 2, "Pop!": burn an LED, then size its resistor from the datasheet.


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.pop", "ch1", "Pop!")
	b.summary("Work out the right resistor from the LED's datasheet.")
	b.part("B1", "battery", -6, 0).part("L1", "led", 6, 0, 90)
	for ohms in [47.0, 100.0, 150.0, 220.0, 330.0, 1000.0]:
		b.tray("resistor", {"ohms": ohms})
	b.goal({"kind": "led_lit", "part": "L1", "max_ma": 20.0}).goal({"kind": "no_damage"})
	b.goal({"kind": "uses", "part_kind": "resistor", "min": 1})
	b.star({"kind": "led_lit", "part": "L1", "min_ma": 18.0, "max_ma": 20.0}, "Brightest glow within spec (18–20 mA)")
	b.formula("led_resistor")
	b.intro("This LED has no [[resistor]]. What could go wrong?", "curious")
	b.intro("Try connecting it straight to the battery and watch closely.", "happy")
	b.step("Tap the LED to read its [[datasheet]].", {"kind": "ui_flag", "flag": "datasheet:L1"})
	b.step("Work out the resistor with the calculator.", {"kind": "ui_flag", "flag": "formula:led_resistor"})
	b.step("Place the resistor you picked.", {"kind": "uses", "part_kind": "resistor", "min": 1})
	b.step("Wire it in and close the loop. Keep it at 20 mA or less.", {"kind": "led_lit", "part": "L1", "max_ma": 20.0})
	b.hint("Too much [[current]] burns an LED. A resistor limits the current.")
	b.hint("The datasheet says 2.0 V at 20 mA. Resistor = (5 V − 2.0 V) ÷ 0.020 A.", [{"part": "L1"}])
	b.hint("Here's a safe circuit. Tap the ghosts to place them.", [], true)
	b.solution_part("R1", "resistor", -2, -4, 0, {"ohms": 150.0})
	b.solution_wire("B1", "pos", "R1", "a").solution_wire("R1", "b", "L1", "anode").solution_wire("L1", "cathode", "B1", "neg")
	b.outro("Safe and glowing! That's the exact formula engineers use for LEDs like this one.", "wow")
	b.outro("Resistors come in [[standard values]]. 150 Ω is exactly right here.", "happy")
	b.fact("Stripes on a resistor show its value. Brown, green, brown means 150 ohms.", "IEC 60062 resistor color code")
	return b.done()
