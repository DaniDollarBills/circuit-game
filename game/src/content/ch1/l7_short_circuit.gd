extends RefCounted
## Lesson 7, "Short circuit!": a path from + to − with almost no resistance
## floods the battery and skips the parts. Try it makes one on purpose and
## undoes it; then the player finds the hidden one and deletes it.

const Layout := preload("res://src/content/ch1/layout.gd")


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.short-circuit", "ch1", "Short circuit!")
	b.summary("Find the wire that skips everything.")
	Layout.loop_wires(Layout.compact(b), PackedStringArray(["w1", "w2", "w3"]))
	var detour: Array[Vector2i] = [Vector2i(-4, -6), Vector2i(9, -6), Vector2i(9, 1)]
	b.wire("w_bad", "R1", "a", "L1", "cathode", false, detour)
	b.goal({"kind": "no_short"}).goal({"kind": "led_lit", "part": "L1"})
	b.learn_goals(["What a short circuit is", "Why it makes a battery hot"])
	b.idea("A [[short circuit]] is a path from + to − with almost no resistance.", "short_path", "oops")
	b.idea("Current floods the easy path. The LED's path is skipped, so it goes dark.", "", "curious",
			"Both ends of the LED's path are joined by the short, so there's no push [[across]] it at all.")
	b.worked("How much current flows through a short?", [
		"Only the battery's own 1 Ω is in the way.",
		"I = V ÷ R = 5 V ÷ 1 Ω = 5 A",
		"Heat each second is volts × amps, in [[watt|watts]] (W).",
		"5 V × 5 A = 25 W, all of it inside the battery",
	])
	b.real("A phone battery has its own tiny protection circuit. If something shorts it, that circuit cuts off the current before the battery overheats.", "",
			"IEC 62133-2:2017 (safety of portable lithium cells and batteries, including an external short-circuit test)")
	b.idea("Never join a real battery's + and − with a wire. It can get hot enough to burn you.", "", "oops")
	b.try_it("Here's a working loop. Make a short, watch the battery, then undo it.")
	b.try_part("B1", "battery", -6, 0).try_part("R1", "resistor", -2, -4).try_part("L1", "led", 6, 0, 90)
	b.try_wire("w1", "B1", "pos", "R1", "a", true).try_wire("w2", "R1", "b", "L1", "anode", true)
	b.try_wire("w3", "L1", "cathode", "B1", "neg", true)
	b.poke("Add a wire from + straight to −.", {"kind": "not", "goal": {"kind": "no_short"}})
	b.poke("Undo it: the LED lights again.", {"kind": "all", "goals": [{"kind": "no_short"}, {"kind": "led_lit", "part": "L1"}]})
	b.readout("B1", "heat")
	b.readout("L1", "mA")
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.add_wire(c, "B1", "pos", "B1", "neg"))
	b.try_path_edit(func(c: Circuit) -> Circuit:
		var undone := c
		for w in c.wires:
			if not w.locked:
				undone = CircuitEdits.delete_wire(undone, w.id)
		return undone)
	b.step("Tap the wires to find the one that joins + to − with no part in between.", {"kind": "ui_flag", "flag": "selected:w_bad"})
	b.why("Anything joined to + by plain wire is +, and the same goes for −. This wire joins the two, skipping the resistor and the LED.")
	b.step("Hold it and choose Delete.", {"kind": "no_short"})
	b.why("Without the short, the current has to go through the LED again.")
	b.hint("One wire joins the + side to the − side, skipping the parts.")
	b.hint("It's this wire. Hold it and choose Delete.", [{"wire": "w_bad"}])
	b.hint("Delete the highlighted wire.", [{"wire": "w_bad"}], true)
	b.solution_remove_wire("w_bad")
	b.outro("Fixed! The current goes through the LED again.", "wow")
	b.recap("A short skips your parts and floods the battery.")
	b.recap("Only the battery's 1 Ω limits it: about 5 A.")
	b.recap("Your fixed circuit runs at {L1.mA}.")
	b.question("Why does a shorted battery get hot?", [
		{"text": "A huge current flows through its own resistance.", "correct": true, "why": "About 5 A through its 1 Ω makes 25 W of heat inside it."},
		{"text": "The LED heats it.", "correct": false, "why": "The LED is skipped: almost no current goes through it."},
		{"text": "Wires store heat.", "correct": false, "why": "Wires barely resist, so they make little heat. The battery's own 1 Ω makes it."},
	])
	b.fact("[[fuse|Fuses]] and circuit breakers cut off the current when too much flows, before wires get hot.",
			"IEC 60269 (fuses) and IEC 60898-1 (circuit breakers)")
	return b.done()
