extends RefCounted
## Lesson 6, "Either switch": separate paths (parallel), so either closed
## switch lights the LED: OR. Try it fills in the truth table; then the player
## builds it.

const Layout := preload("res://src/content/ch1/layout.gd")


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.either", "ch1", "Either switch")
	b.summary("Light it when either switch is on.")
	Layout.loop_wires(Layout.wide(b), PackedStringArray(["w1", "w3"]))
	b.tray("switch", {"label": "A"}).tray("switch", {"label": "B"})
	b.goal({"kind": "no_damage"}).goal({"kind": "no_short"}).goal({"kind": "uses", "part_kind": "switch", "min": 2})
	Layout.switch_tests(b, func(a_on: bool, b_on: bool) -> bool: return a_on or b_on)
	b.learn_goals(["What parallel means", "How two switches on separate paths make OR"])
	b.idea("Two separate paths between the same two points are in [[parallel]]. Each path has the same push [[across]] it.",
			"parallel_paths")
	b.idea("Put a switch on each path. Close either one and the current has a way round, so the LED lights.", "", "happy")
	b.idea("Here's the [[truth table]] again. Will it come out the same as with switches one after the other?", "truth_table", "curious")
	b.real("A doorbell often has two buttons, one at the front door and one at the back. Either one rings it.")
	b.history("In 1938 Claude Shannon showed that switches one after the other do AND, and switches on separate paths do OR.",
			"C. E. Shannon, A Symbolic Analysis of Relay and Switching Circuits, Transactions of the AIEE 57, 713–723 (1938)")
	b.try_it("Here are switches A and B on separate paths. Try all four cases and fill in the table.")
	b.try_part("B1", "battery", -6, 0).try_part("R1", "resistor", -2, -4).try_part("L1", "led", 12, 0, 90)
	b.try_part("SW1", "switch", 4, -4, 0, {"label": "A"}).try_part("SW2", "switch", 4, -9, 0, {"label": "B"})
	b.try_wire("w1", "B1", "pos", "R1", "a", true).try_wire("w2", "R1", "b", "SW1", "a", true)
	b.try_wire("w3", "SW1", "a", "SW2", "a", true).try_wire("w4", "SW2", "b", "SW1", "b", true)
	b.try_wire("w5", "SW1", "b", "L1", "anode", true).try_wire("w6", "L1", "cathode", "B1", "neg", true)
	var cases: Array = []
	for row in 4:
		cases.append({"kind": "ui_flag", "flag": "row:%d" % row})
	b.poke("Try all four cases.", {"kind": "all", "goals": cases, "label": "Try all four cases"})
	b.readout("L1", "mA")
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.set_props(c, "SW2", {"closed": true}))
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.set_props(c, "SW1", {"closed": true}))
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.set_props(c, "SW2", {"closed": false}))
	b.step("Place switches A and B.", {"kind": "uses", "part_kind": "switch", "min": 2})
	b.why("Each switch will be one of the two paths.")
	b.step("Connect one leg of each switch to the resistor.", {"kind": "all", "goals": [
			{"kind": "connected", "a": "R1:b", "b": "A:*"}, {"kind": "connected", "a": "R1:b", "b": "B:*"}]})
	b.why("Both paths start from the same point, the resistor.")
	b.step("Connect their other legs to the LED's + side.", {"kind": "all", "goals": [
			{"kind": "connected", "a": "L1:anode", "b": "A:*"}, {"kind": "connected", "a": "L1:anode", "b": "B:*"}]})
	b.why("And both end at the same point, the LED, so either one completes the loop.")
	b.step("Press Test.", {"kind": "ui_flag", "flag": "tested"})
	b.why("Test tries all four cases and checks the LED in each.")
	b.hint("Give the current two paths, one through each switch.")
	b.hint("Give each switch its own path between the resistor and the LED.", [{"part": "A"}, {"part": "B"}])
	b.hint("Here's one way. Tap the ghosts to place them.", [], true)
	b.solution_part("SW1", "switch", 4, -4, 0, {"label": "A"}).solution_part("SW2", "switch", 4, -7, 0, {"label": "B"})
	b.solution_wire("R1", "b", "SW1", "a").solution_wire("SW1", "a", "SW2", "a")
	b.solution_wire("SW2", "b", "SW1", "b").solution_wire("SW1", "b", "L1", "anode")
	b.outro("Separate paths like these are in [[parallel]]. Either path works.", "wow")
	b.outro("This is the idea behind an OR gate.", "happy")
	b.recap("Parallel: two paths, so either one works.")
	b.recap("That's OR: the LED lights for A OR B, or both.")
	b.recap("One switch or both, your LED got {L1.mA@closed}, because the resistor sets it.")
	b.question("Two switches in parallel: which cases light the LED?", [
		{"text": "Either or both closed.", "correct": true, "why": "Each closed switch is a complete path on its own."},
		{"text": "Only both closed.", "correct": false, "why": "That's switches one after the other, in series: Lesson 5."},
		{"text": "Never.", "correct": false, "why": "Close either switch and the loop is complete, so the LED lights."},
	])
	return b.done()
