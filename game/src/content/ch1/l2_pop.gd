extends RefCounted
## Lesson 2, "Pop!": an LED lets current through one way, uses about 2 V of
## the push, and needs a resistor to limit its current. Try it burns one on
## purpose; then the player sizes the resistor from the datasheet.


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
	b.learn_goals(["Why an LED needs a resistor", "How to read an LED's datasheet", "How to work out the right resistor"])
	b.idea("An [[led|LED]] is a light-making [[diode]]: current gets through only one way. It goes in at the longer leg, the + side.",
			"led_one_way", "curious",
			"LED stands for light-emitting diode. Put in backwards, it stays dark: no current flows to light it.")
	b.idea("The battery's 5 V push is shared round the loop. A glowing red LED uses about 2 V of it, leaving 3 V for the rest.",
			"voltage_budget")
	b.idea("With no [[resistor]], only the battery's own 1 Ω holds the current back. That lets through far more than the LED can take.",
			"", "oops", "Then the current is many times the 30 mA the LED can take, and it burns out in a blink.")
	b.real("Engineers read a part's [[datasheet]]. This LED's says 2.0 V at 20 mA, and 30 mA is its [[absolute maximum]].",
			"current_vs_resistance")
	b.idea("Volts ÷ amps gives ohms, the resistance. A [[milliamp]] (mA) is a thousandth of an amp: 20 mA = 0.020 A.", "", "curious",
			"That's [[ohms law|Ohm's law]], and Lesson 3 shows why it works. For now, divide the volts by the amps.")
	b.worked("Work out the resistor: its voltage divided by the current you want.", [
		"The resistor gets what the LED leaves: 5 V − 2.0 V = 3.0 V.",
		"The current you want: 20 mA = 0.020 A.",
		"R = 3.0 V ÷ 0.020 A",
		"R = 150 Ω",
	])
	b.idea("Resistors come in [[standard values]], like 100, 150, 220 and 330 Ω. Pick the nearest one that keeps the current at 20 mA or less.",
			"", "happy", "They're the E12 values: 12 steps from 10 to 100 (10, 12, 15, 18, 22, 27, 33, 39, 47, 56, 68, 82), then ×10, ×100 and on.")
	b.history("In 2014 three scientists won the Nobel Prize for efficient blue LEDs. Blue was the missing color for bright, energy-saving white LED lamps.",
			"The Nobel Prize in Physics 2014: I. Akasaki, H. Amano and S. Nakamura, for the invention of efficient blue light-emitting diodes, which has enabled bright and energy-saving white light sources")
	b.try_it("Here's the LED with no resistor. See what happens, then fix it.")
	b.try_part("B1", "battery", -6, 0).try_part("L1", "led", 6, 0, 90)
	b.try_tray("resistor", {"ohms": 330.0})
	b.poke("Wire the LED straight to the battery: pop!", {"kind": "burnt", "part": "L1"})
	b.poke("Undo, then put the 330 Ω in the loop: less current, so it's safe but dimmer.", {"kind": "led_lit", "part": "L1"})
	b.readout("L1", "mA")
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.add_wire(c, "B1", "pos", "L1", "anode"))
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.add_wire(c, "L1", "cathode", "B1", "neg"))
	b.try_path_edit(func(c: Circuit) -> Circuit:
		var fresh := c
		for w in c.wires.duplicate():
			fresh = CircuitEdits.delete_wire(fresh, w.id)
		fresh.parts.append(Part.make("R1", "resistor", -2, -4, 0, {"ohms": 330.0}, false))
		return fresh)
	b.try_path_edit(func(c: Circuit) -> Circuit:
		var wired := CircuitEdits.add_wire(c, "B1", "pos", "R1", "a")
		wired = CircuitEdits.add_wire(wired, "R1", "b", "L1", "anode")
		return CircuitEdits.add_wire(wired, "L1", "cathode", "B1", "neg"))
	b.step("Tap the LED to read its [[datasheet]].", {"kind": "ui_flag", "flag": "datasheet:L1"})
	b.why("Its datasheet gives the two numbers you need: 2.0 V at 20 mA.")
	b.step("Work out the resistor with the calculator.", {"kind": "ui_flag", "flag": "formula:led_resistor"})
	b.why("The calculator works out (5 V − 2.0 V) ÷ 0.020 A for you.")
	b.step("Place the resistor you picked.", {"kind": "uses", "part_kind": "resistor", "min": 1})
	b.why("A resistor in the loop is what keeps the current safe.")
	b.step("Wire it in and close the loop. Keep it at 20 mA or less.", {"kind": "led_lit", "part": "L1", "max_ma": 20.0})
	b.why("Above 20 mA the LED wears out faster, and past 30 mA it can burn out.")
	b.hint("Too much [[current]] burns an LED. A resistor limits the current.")
	b.hint("The datasheet says 2.0 V at 20 mA. Resistor = (5 V − 2.0 V) ÷ 0.020 A.", [{"part": "L1"}])
	b.hint("Here's a safe circuit. Tap the ghosts to place them.", [], true)
	b.solution_part("R1", "resistor", -2, -4, 0, {"ohms": 150.0})
	b.solution_wire("B1", "pos", "R1", "a").solution_wire("R1", "b", "L1", "anode").solution_wire("L1", "cathode", "B1", "neg")
	b.outro("Safe and glowing! That's the formula engineers use for LEDs like this one.", "wow")
	b.recap("An LED needs a resistor to limit its current.")
	b.recap("R = (5 V − 2.0 V) ÷ 0.020 A = 150 Ω.")
	b.recap("Your LED ran at {L1.mA}.")
	b.question("Why does an LED need a resistor?", [
		{"text": "To limit its current.", "correct": true, "why": "Without one, too much current flows and the LED burns out."},
		{"text": "To make it brighter.", "correct": false, "why": "A resistor lowers the current, so the LED is a little dimmer, but safe."},
		{"text": "To change its color.", "correct": false, "why": "An LED's color comes from its chip. The resistor only sets the current."},
	])
	b.question("Which leg goes toward the battery's +?", [
		{"text": "The longer leg.", "correct": true, "why": "The longer leg is the + side, the anode."},
		{"text": "The shorter leg.", "correct": false, "why": "That's the − side, the cathode, by the flat edge."},
		{"text": "Either leg.", "correct": false, "why": "An LED lets current through only one way, so it matters."},
	])
	b.fact("Stripes on a resistor show its value. Brown, green, brown means 150 ohms.", "IEC 60062 resistor color code")
	return b.done()
