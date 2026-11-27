extends RefCounted
## Lesson 8, "Too hot to handle": power in watts, resistors turning energy
## into heat, and power ratings. Try it heats a ¼ W resistor safely, then
## burns one; then the player picks the resistor that can take half a watt.


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.too-hot", "ch1", "Too hot to handle")
	b.summary("Pick a resistor that can handle the heat.")
	b.part("B1", "battery", -6, 0)
	b.tray("resistor", {"ohms": 47.0, "watts": 0.25}).tray("resistor", {"ohms": 47.0, "watts": 1.0})
	b.goal({"kind": "resistor_watts", "min": 0.4, "max": 0.6}).goal({"kind": "no_damage"})
	b.formula("power")
	b.learn_goals(["What power is, in watts", "Why parts have a power rating"])
	b.idea("[[power|Power]] is how fast energy is turned into something else. Volts × amps gives it, in [[watt|watts]] (W).",
			"power_heat", "curious")
	b.idea("Resistors turn electrical energy into heat. That's how toasters work!", "", "happy")
	b.meet("resistor_1w")
	b.worked("How hot does a 47 Ω resistor across the battery get?", [
		"I = 5 V ÷ 48 Ω (its 47 Ω and the battery's 1 Ω)",
		"I = 0.104 A",
		"P = I × I × R = 0.104 A × 0.104 A × 47 Ω",
		"P = 0.51 W",
	])
	b.real("A toaster's glowing wires are resistors too, made to turn hundreds of watts into heat without burning out.")
	b.try_it("Here's the battery and two ¼ W resistors. Try each one across it.")
	b.try_part("B1", "battery", -6, 0)
	b.try_tray("resistor", {"ohms": 220.0, "watts": 0.25}).try_tray("resistor", {"ohms": 47.0, "watts": 0.25})
	b.poke("Put the 220 Ω across the battery: 0.11 W, fine.", {"kind": "resistor_watts", "min": 0.09, "max": 0.13})
	b.poke("Swap in the 47 Ω: 0.51 W scorches it.", {"kind": "not", "goal": {"kind": "no_damage"}})
	b.readout("R1", "W")
	b.readout("R2", "W")
	b.try_path_edit(func(c: Circuit) -> Circuit:
		c.parts.append(Part.make("R1", "resistor", -2, 0, 90, {"ohms": 220.0, "watts": 0.25}, false))
		return CircuitEdits.add_wire(CircuitEdits.add_wire(c, "B1", "pos", "R1", "a"), "R1", "b", "B1", "neg"))
	b.try_path_edit(func(c: Circuit) -> Circuit:
		var swapped := c
		for w in c.wires.duplicate():
			swapped = CircuitEdits.delete_wire(swapped, w.id)
		swapped.parts = swapped.parts.filter(func(p: Part) -> bool: return p.id != "R1")
		swapped.parts.append(Part.make("R2", "resistor", -2, 0, 90, {"ohms": 47.0, "watts": 0.25}, false))
		return CircuitEdits.add_wire(CircuitEdits.add_wire(swapped, "B1", "pos", "R2", "a"), "R2", "b", "B1", "neg"))
	b.step("Read both resistors' datasheets in the tray.", {"kind": "ui_flag", "flag": "datasheet:tray"})
	b.why("Each datasheet gives its power rating: the most heat it can take.")
	b.step("Work out the heat with the calculator.", {"kind": "ui_flag", "flag": "formula:power"})
	b.why("Both are 47 Ω, so both make the same 0.51 W. Only one can take it.")
	b.step("Place the resistor that can handle it.", {"kind": "uses", "part_kind": "resistor", "min": 1})
	b.why("0.51 W is twice a ¼ W rating, but only half of 1 W.")
	b.step("Connect it across the battery.", {"kind": "resistor_watts", "min": 0.4, "max": 0.6})
	b.why("Across the battery, the full 5 V pushes current through it.")
	b.hint("[[power|Power]] = voltage × current. Both resistors are 47 Ω, but they're not the same.")
	b.hint("One is rated ¼ W and the other 1 W. Which one can handle half a watt?")
	b.hint("Here's the circuit. Tap the ghosts to place them.", [], true)
	b.solution_part("R1", "resistor", -2, 0, 90, {"ohms": 47.0, "watts": 1.0})
	b.solution_wire("B1", "pos", "R1", "a").solution_wire("R1", "b", "B1", "neg")
	b.outro("Toasty! That's 0.51 watts of heat, and the 1 W resistor handles it easily.", "wow")
	b.recap("Power is volts × amps, in watts.")
	b.recap("A part burns above its power rating.")
	b.recap("Your resistor made {resistor.W} of heat.")
	b.question("A ¼ W resistor asked for 0.5 W will…", [
		{"text": "Burn.", "correct": true, "why": "0.5 W is twice its ¼ W rating, so it overheats."},
		{"text": "Stay cool.", "correct": false, "why": "It has to turn 0.5 W into heat, twice what it's made for."},
		{"text": "Glow like an LED.", "correct": false, "why": "A small resistor overheats and burns long before it could get hot enough to glow."},
	])
	b.fact("A hair dryer turns about 1,500 watts into heat, 3,000 times more than your resistor.",
			"U.S. Department of Energy, Energy Saver: Estimating Appliance and Home Electronic Energy Use (hair dryers 1,200–1,875 W); 1,500 ÷ 0.51 ≈ 2,940")
	return b.done()
