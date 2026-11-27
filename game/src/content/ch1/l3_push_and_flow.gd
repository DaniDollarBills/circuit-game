extends RefCounted
## Lesson 3, "Push and flow": voltage, current and resistance, their units,
## Ohm's law, and the two meters. Try it turns a trimmer's dial and watches
## the current halve; then the player sets exactly 10 mA.


static func _meter_loop(b: LevelBuilder, ohms: float, try_circuit := false) -> void:
	var props := {"ohms": ohms, "adjustable": true, "watts": 0.5}
	if try_circuit:
		b.try_part("B1", "battery", -6, 0).try_part("R1", "resistor", -2, -4, 0, props)
		b.try_part("M1", "ammeter", 6, 0, 90).try_part("V1", "voltmeter", -2, -7)
		b.try_wire("w1", "B1", "pos", "R1", "a", true).try_wire("w2", "R1", "b", "M1", "a", true)
		b.try_wire("w3", "M1", "b", "B1", "neg", true)
		b.try_wire("w4", "V1", "pos", "R1", "a", true).try_wire("w5", "V1", "neg", "R1", "b", true)
		return
	b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4, 0, props)
	b.part("M1", "ammeter", 6, 0, 90).part("V1", "voltmeter", -2, -7)
	b.wire("w1", "B1", "pos", "R1", "a").wire("w2", "R1", "b", "M1", "a").wire("w3", "M1", "b", "B1", "neg")
	b.wire("w4", "V1", "pos", "R1", "a").wire("w5", "V1", "neg", "R1", "b")


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.push-and-flow", "ch1", "Push and flow")
	b.summary("Use Ohm's law to set exactly 10 mA.")
	_meter_loop(b, 1000.0)
	b.goal({"kind": "meter_reads", "part": "M1", "target": 0.010, "tolerance": 0.0005}).goal({"kind": "no_damage"})
	b.formula("ohms_law")
	b.learn_goals(["What voltage, current and resistance are", "How to use Ohm's law", "How to measure current and voltage"])
	b.analogy("Think of water in pipes. The pump is the battery's push, the flow is the current, and a narrow pipe is a resistor.",
			"A cut pipe spills water, but a cut wire spills nothing: the charges just stop.",
			"water_analogy")
	b.idea("[[voltage|Voltage]] is measured in [[volt|volts]] (V), [[current]] in [[amp|amps]] (A) and [[resistance]] in [[ohm|ohms]] (Ω). One [[milliamp]] is a thousandth of an amp: 1 mA = 0.001 A.",
			"unit_ladder")
	b.idea("[[ohms law|Ohm's law]] links them: V = I × R. V is voltage, I is current and R is resistance.",
			"ohm_triangle", "happy",
			"I stands for intensité, French for the strength of a current. The amp is named after the French scientist André-Marie Ampère.")
	b.worked("How much current flows through 500 Ω?", ["I = V ÷ R", "I = 5 V ÷ 500 Ω", "I = 0.010 A", "0.010 A = 10 mA"], "",
			"The battery's own 1 Ω and the meter's 0.1 Ω make it 9.98 mA. That's close enough to call it 10.")
	b.meet("ammeter").meet("voltmeter")
	b.idea("A current meter goes in the loop, so the current flows through it. A voltage meter's [[probe|probes]] touch each side of a part.",
			"meter_placement")
	b.meet("trimmer")
	b.control("To set a trimmer, tap it, then slide its value.", "control_dial")
	b.history("Georg [[=Ohm]] was a German schoolteacher. In 1827 he showed that the current grows in step with the voltage.",
			"G. S. Ohm, Die galvanische Kette, mathematisch bearbeitet, 1827")
	b.try_it("Here's a loop with a dial and two meters. Turn the dial and watch both meters: which reading changes?")
	_meter_loop(b, 1500.0, true)
	b.poke("Set the dial to 1 kΩ.", {"kind": "meter_reads", "part": "M1", "target": 0.005, "tolerance": 0.0002})
	b.poke("Now 2 kΩ: what happens to the current?", {"kind": "meter_reads", "part": "M1", "target": 0.0025, "tolerance": 0.0002})
	b.readout("M1", "reading")
	b.readout("V1", "reading")
	b.readout("R1", "ohms")
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.set_props(c, "R1", {"ohms": 1000.0}))
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.set_props(c, "R1", {"ohms": 2000.0}))
	b.step("Tap the resistor to open its dial.", {"kind": "ui_flag", "flag": "value:R1"})
	b.why("The dial sets how much this trimmer resists the current.")
	b.step("Use Ohm's law: R = 5 V ÷ 0.010 A.", {"kind": "ui_flag", "flag": "formula:ohms_law"})
	b.why("Ohm's law turned round gives the resistance for the current you want.")
	b.step("Turn the dial until the meter reads 10 mA.", {"kind": "meter_reads", "part": "M1", "target": 0.010, "tolerance": 0.0005})
	b.why("The current meter shows the current round the loop. The voltage meter shows the push [[across]] the dial, about 5 V.")
	b.hint("More resistance means less current. Is the meter too high or too low?")
	b.hint("Try about 500 ohms.", [{"part": "R1"}])
	b.hint("Set the resistor to 500 ohms.", [], true)
	b.solution_props("R1", {"ohms": 500.0})
	b.outro("That's [[ohms law|Ohm's law]]: current equals voltage divided by resistance.", "wow")
	b.recap("Voltage pushes, current flows, resistance slows it.")
	b.recap("V = I × R.")
	b.recap("Your dial: {R1.ohms} gave {M1.reading}.")
	b.question("Double the resistance. What happens to the current?", [
		{"text": "It halves.", "correct": true, "why": "I = V ÷ R, so twice the R means half the I."},
		{"text": "It doubles.", "correct": false, "why": "More resistance makes flowing harder, so the current falls."},
		{"text": "It stays the same.", "correct": false, "why": "The push is the same, but the loop resists twice as much, so less flows."},
	])
	b.question("Where does a current meter go?", [
		{"text": "In the loop.", "correct": true, "why": "All the current must flow through it to be measured."},
		{"text": "[[across|Across]] a part.", "correct": false, "why": "That's where a voltage meter goes, a probe on each side."},
		{"text": "Anywhere nearby.", "correct": false, "why": "It has to be part of the loop, so the current passes through it."},
	])
	b.fact("Engineers' shortcut: milliamps × kilohms = volts. Your loop's 10 mA through 0.5 kΩ is 5 V.",
			"Ohm's law, V = I × R: 0.010 A × 500 Ω = 5 V")
	return b.done()
