extends RefCounted
## Lesson 5, "Both switches": parts in a row (series) share one path, so two
## switches in a row light the LED only when both are closed: AND. Try it
## fills in the truth table; then the player builds it.

const Layout := preload("res://src/content/ch1/layout.gd")


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.both", "ch1", "Both switches")
	b.summary("Light it only when both switches are on.")
	Layout.loop_wires(Layout.wide(b), PackedStringArray(["w1", "w3"]))
	b.tray("switch", {"label": "A"}).tray("switch", {"label": "B"})
	b.goal({"kind": "no_damage"}).goal({"kind": "no_short"}).goal({"kind": "uses", "part_kind": "switch", "min": 2})
	Layout.switch_tests(b, func(a_on: bool, b_on: bool) -> bool: return a_on and b_on)
	b.learn_goals(["What series means", "How two switches in a row make AND"])
	b.idea("Parts in a row are in [[series]]. There's only one path, so the same current flows through every part.",
			"series_paths")
	b.idea("A [[truth table]] lists every case. With two switches there are four: each one open or closed.", "truth_table")
	b.real("Some safes need two keys turned at once. Some machines run only while a worker presses two buttons, one with each hand.", "",
			"ISO 13851 (safety of machinery: two-hand control devices)")
	b.idea("Two switches in a row light the LED only when both are closed: A [[logic gate|AND]] B.", "", "wow")
	b.history("In 1854 George Boole wrote down the logic of AND and OR. Every computer chip still runs on it.",
			"G. Boole, An Investigation of the Laws of Thought, Walton and Maberly, London (1854)")
	b.try_it("Here are switches A and B in a row. Try all four cases and fill in the table.")
	b.try_part("B1", "battery", -6, 0).try_part("R1", "resistor", -2, -4).try_part("L1", "led", 12, 0, 90)
	b.try_part("SW1", "switch", 3, -4, 0, {"label": "A"}).try_part("SW2", "switch", 8, -4, 0, {"label": "B"})
	b.try_wire("w1", "B1", "pos", "R1", "a", true).try_wire("w2", "R1", "b", "SW1", "a", true)
	b.try_wire("w3", "SW1", "b", "SW2", "a", true).try_wire("w4", "SW2", "b", "L1", "anode", true)
	b.try_wire("w5", "L1", "cathode", "B1", "neg", true)
	var cases: Array = []
	for row in 4:
		cases.append({"kind": "ui_flag", "flag": "row:%d" % row})
	b.poke("Try all four cases.", {"kind": "all", "goals": cases, "label": "Try all four cases"})
	b.readout("L1", "mA")
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.set_props(c, "SW2", {"closed": true}))
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.set_props(c, "SW1", {"closed": true}))
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.set_props(c, "SW2", {"closed": false}))
	b.step("Place switches A and B.", {"kind": "uses", "part_kind": "switch", "min": 2})
	b.why("Each switch is a gap you can close.")
	b.step("Connect the resistor to A.", {"kind": "connected", "a": "R1:b", "b": "A:*"})
	b.why("The current has to pass through A first.")
	b.step("Connect A to B.", {"kind": "connected", "a": "A:*", "b": "B:*"})
	b.why("In a row, the current goes through A, then B.")
	b.step("Connect B to the LED's + side.", {"kind": "connected", "a": "B:*", "b": "L1:anode"})
	b.why("That closes the loop through both switches.")
	b.step("Press Test.", {"kind": "ui_flag", "flag": "tested"})
	b.why("Test tries all four cases and checks the LED in each.")
	b.hint("Current has to pass through both switches, one after the other.")
	b.hint("Connect the resistor to A, A to B, and B to the LED.", [{"part": "A"}, {"part": "B"}])
	b.hint("Here's one way. Tap the ghosts to place them.", [], true)
	b.solution_part("SW1", "switch", 3, -4, 0, {"label": "A"}).solution_part("SW2", "switch", 8, -4, 0, {"label": "B"})
	b.solution_wire("R1", "b", "SW1", "a").solution_wire("SW1", "b", "SW2", "a").solution_wire("SW2", "b", "L1", "anode")
	b.outro("Parts in a row are in [[series]]. Every switch must be on.", "wow")
	b.recap("Series: one path, so both must be closed.")
	b.recap("That's AND: the LED lights only for A AND B.")
	b.recap("Both closed, the loop is complete, just like Lesson 1's.")
	b.question("Two switches in series: which cases light the LED?", [
		{"text": "Only both closed.", "correct": true, "why": "One path: a gap at either switch stops the current."},
		{"text": "Either one closed.", "correct": false, "why": "That's two switches side by side, in parallel. Lesson 6!"},
		{"text": "Always.", "correct": false, "why": "An open switch leaves a gap, and a gap stops everything."},
	])
	return b.done()
