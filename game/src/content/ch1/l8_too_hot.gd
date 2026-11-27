extends RefCounted
## Level 8, "Too hot to handle": pick the resistor whose power rating can take
## half a watt.


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.too-hot", "ch1", "Too hot to handle")
	b.summary("Pick a resistor that can handle the heat.")
	b.part("B1", "battery", -6, 0)
	b.tray("resistor", {"ohms": 47.0, "watts": 0.25}).tray("resistor", {"ohms": 47.0, "watts": 1.0})
	b.goal({"kind": "resistor_watts", "min": 0.4, "max": 0.6}).goal({"kind": "no_damage"})
	b.formula("power")
	b.intro("Resistors turn electrical energy into heat. That's how toasters work!", "happy")
	b.intro("Make about half a [[watt]] of heat without burning anything. Check each resistor's [[datasheet]] first.", "curious")
	b.step("Read both resistors' datasheets in the tray.", {"kind": "ui_flag", "flag": "datasheet:tray"})
	b.step("Work out the heat with the calculator.", {"kind": "ui_flag", "flag": "formula:power"})
	b.step("Place the resistor that can handle it.", {"kind": "uses", "part_kind": "resistor", "min": 1})
	b.step("Connect it across the battery.", {"kind": "resistor_watts", "min": 0.4, "max": 0.6})
	b.hint("[[power|Power]] = voltage × current. Both resistors are 47 Ω, but they're not the same.")
	b.hint("One is rated ¼ W and the other 1 W. Which one can handle half a watt?")
	b.hint("Here's the circuit. Tap the ghosts to place them.", [], true)
	b.solution_part("R1", "resistor", -2, 0, 90, {"ohms": 47.0, "watts": 1.0})
	b.solution_wire("B1", "pos", "R1", "a").solution_wire("R1", "b", "B1", "neg")
	b.outro("Toasty! That's 0.51 watts of heat, and the 1 W resistor handles it easily.", "wow")
	b.outro("Engineers always check the power rating. A ¼ W resistor here would burn.", "curious")
	b.fact("A hair dryer turns about 1,500 watts into heat, 3,000 times more than your resistor.",
			"U.S. Department of Energy, Energy Saver: Estimating Appliance and Home Electronic Energy Use (hair dryers 1,200–1,875 W); 1,500 ÷ 0.51 ≈ 2,940")
	return b.done()
