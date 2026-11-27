extends RefCounted
## Lesson 1, "Light it up": why electricity needs a loop, and what the battery,
## wire, resistor and LED do. Try it breaks and fixes a working loop; then the
## player closes the loop to light the LED.

const Layout := preload("res://src/content/ch1/layout.gd")


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.light-it-up", "ch1", "Light it up")
	b.summary("Why electricity needs a loop.")
	Layout.compact(b, {"ohms": 220.0})
	b.goal({"kind": "led_lit", "part": "L1"}).goal({"kind": "no_short"})
	b.learn_goals(["Why electricity needs a loop", "What the battery, wire, resistor and LED do"])
	b.idea("[[electricity|Electricity]] is [[charge|charges]] on the move. Metal wires are already full of charges that can move.",
			"charges_in_wire", "curious")
	b.idea("A [[battery]] pushes on the charges all the way round the [[circuit]]. We say the [[current]] flows out of its + end and back into its − end.",
			"battery_push")
	b.idea("In a wire, the charges that move are [[electron|electrons]]. They [[drift]] the other way, from − to +, but we still draw current from + to −.",
			"current_direction", "curious",
			"People chose + to − in the 1700s, before anyone knew about electrons. Both directions give the same answers, so the old arrows stayed.",
			"B. Franklin, letter to P. Collinson, 25 May 1747 (+ and −); J. J. Thomson, Philosophical Magazine 44, 293 (1897) (the electron)")
	b.idea("So a circuit is a complete loop. The charges all move round it together, like the links of a bike chain.", "loop_flow", "happy")
	b.idea("A gap anywhere stops everything. Like a bike chain, if one link can't move, none of them can.", "loop_gap", "oops",
			"In a few billionths of a second, charges pile up on each side of the gap. Their push cancels the battery's, so the current stops everywhere.")
	b.meet("battery").meet("wire").meet("resistor").meet("led")
	b.history("In 1800 Alessandro Volta built the first battery: a pile of metal discs with salty cloth between them.",
			"A. Volta, Philosophical Transactions of the Royal Society 90, 403–431 (1800)")
	b.try_it("Here's a working loop. Break it, then fix it.")
	b.try_part("B1", "battery", -6, 0).try_part("R1", "resistor", -2, -4, 0, {"ohms": 220.0}).try_part("L1", "led", 6, 0, 90)
	b.try_wire("w1", "B1", "pos", "R1", "a").try_wire("w2", "R1", "b", "L1", "anode").try_wire("w3", "L1", "cathode", "B1", "neg")
	b.poke("Delete a wire: the light goes out.", {"kind": "not", "goal": {"kind": "led_lit", "part": "L1"}})
	b.poke("Undo it: the light comes back.", {"kind": "led_lit", "part": "L1"})
	b.readout("L1", "mA")
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.delete_wire(c, "w2"))
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.add_wire(c, "R1", "b", "L1", "anode"))
	b.step("Connect the battery's + to the resistor's left end.", {"kind": "connected", "a": "B1:pos", "b": "R1:a"})
	b.why("We draw current leaving the battery's + end, so the loop starts there.")
	b.step("Connect the resistor's right end to the LED's + side.", {"kind": "connected", "a": "R1:b", "b": "L1:anode"})
	b.why("The resistor limits the current all the way round the loop, LED included.")
	b.step("Connect the LED's − side back to the battery's −.", {"kind": "connected", "a": "L1:cathode", "b": "B1:neg"})
	b.why("The loop must come back to the − end to be complete.")
	b.hint("Current leaves the battery's + end. Where should it go first?")
	b.hint("Connect the battery's + to the resistor, the resistor to the LED, and the LED back to −.",
			[{"part": "B1", "pin": "pos"}, {"part": "R1", "pin": "a"}])
	b.hint("Here's one way to do it. Tap the ghost wires to place them.", [], true)
	b.solution_wire("B1", "pos", "R1", "a").solution_wire("R1", "b", "L1", "anode").solution_wire("L1", "cathode", "B1", "neg")
	b.outro("You made light!", "wow")
	b.recap("Electricity only flows around a complete loop.")
	b.recap("Your loop carried {L1.mA}, a safe current for this LED.")
	b.recap("The resistor keeps the current low, so the LED doesn't burn out.")
	b.question("What happens if one wire in the loop is removed?", [
		{"text": "Everything stops.", "correct": true, "why": "A loop with a gap carries no current at all, anywhere."},
		{"text": "The LED gets dimmer.", "correct": false, "why": "With a gap, no current flows anywhere, so the LED goes out."},
		{"text": "Only the parts after the gap stop.", "correct": false, "why": "Like a bike chain, the whole loop stops at once, not just after the gap."},
	])
	b.question("Which way do we draw current going round a circuit?", [
		{"text": "Out of + and back into −.", "correct": true, "why": "We draw current leaving the + end and coming back into the − end."},
		{"text": "Out of − and back into +.", "correct": false, "why": "That's the way electrons drift. We draw current the other way, out of +."},
		{"text": "Both ways at once.", "correct": false, "why": "In a loop like this, the current goes one way round."},
	])
	b.fact("The first practical visible-light LED, made in 1962, could only glow red.",
			"N. Holonyak Jr. and S. F. Bevacqua, Applied Physics Letters 1, 82 (1962). Earlier LEDs were infrared (J. R. Biard and G. Pittman, Texas Instruments, 1961) or far too dim to use (H. J. Round, Electrical World 49, 309 (1907)).")
	return b.done()
