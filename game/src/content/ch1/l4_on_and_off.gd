extends RefCounted
## Lesson 4, "On and off": a switch opens and closes the loop, and on and off
## make a bit. Try it flips a switch in a working loop; then the player adds
## one and tests it.

const Layout := preload("res://src/content/ch1/layout.gd")


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.on-and-off", "ch1", "On and off")
	b.summary("Control the light with a switch.")
	Layout.loop_wires(Layout.wide(b), PackedStringArray(["w1", "w3"]))
	b.tray("switch", {"label": "S"})
	b.goal({"kind": "no_damage"}).goal({"kind": "no_short"}).goal({"kind": "uses", "part_kind": "switch", "min": 1})
	b.test("Switch off: LED off", [{"target": "S", "prop": "closed", "value": false}], [{"kind": "led_dark", "part": "L1"}])
	b.test("Switch on: LED on", [{"target": "S", "prop": "closed", "value": true}], [{"kind": "led_lit", "part": "L1"}])
	b.learn_goals(["What a switch does", "What a bit is"])
	b.meet("switch")
	b.idea("A [[switch]] works like a drawbridge. Closed, it joins the loop and current flows; open, it leaves a gap and everything stops.",
			"switch_states")
	b.idea("So for a switch, closed means on. That's the opposite of a door or a tap, where closed stops things.", "", "curious")
	b.idea("On or off can stand for 1 or 0. One on-or-off answer is called a [[bit]].", "bits", "wow",
			"Computers store everything, words and pictures too, as long rows of bits.")
	b.control("To flip a switch, tap it.", "control_switch")
	b.control("Press Test to try every switch setting. It ticks each one your circuit gets right.", "control_test")
	b.history("In 1948 Claude Shannon showed how to measure any message in bits, 1s and 0s.",
			"C. E. Shannon, A Mathematical Theory of Communication, Bell System Technical Journal 27, 379–423 (1948)")
	b.try_it("Here's the loop with its switch. Turn the light off, then on again.")
	b.try_part("B1", "battery", -6, 0).try_part("R1", "resistor", -2, -4).try_part("L1", "led", 12, 0, 90)
	b.try_part("SW1", "switch", 6, -4, 0, {"label": "S", "closed": true})
	b.try_wire("w1", "B1", "pos", "R1", "a", true).try_wire("w2", "R1", "b", "SW1", "a", true)
	b.try_wire("w3", "SW1", "b", "L1", "anode", true).try_wire("w4", "L1", "cathode", "B1", "neg", true)
	b.poke("Turn it off.", {"kind": "led_dark", "part": "L1"})
	b.poke("Turn it on again.", {"kind": "led_lit", "part": "L1"})
	b.readout("L1", "mA")
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.set_props(c, "SW1", {"closed": false}))
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.set_props(c, "SW1", {"closed": true}))
	b.step("Place the switch from the tray.", {"kind": "uses", "part_kind": "switch", "min": 1})
	b.why("The switch will fill the gap in the loop.")
	b.step("Connect the resistor to one side of the switch.", {"kind": "connected", "a": "R1:b", "b": "S:*"})
	b.why("The switch has to be part of the loop to control it.")
	b.step("Connect the other side to the LED's + side.", {"kind": "connected", "a": "L1:anode", "b": "S:*"})
	b.why("Now the switch's two legs close the gap.")
	b.step("Try the switch, then press Test.", {"kind": "ui_flag", "flag": "tested"})
	b.why("Test tries the switch both ways and checks the LED each time.")
	b.hint("The loop has a gap. The switch can fill it.")
	b.hint("Connect the resistor to one side of the switch, and the other side to the LED.",
			[{"part": "R1", "pin": "b"}, {"part": "L1", "pin": "anode"}])
	b.hint("Here's one way. Tap the ghosts to place them.", [], true)
	b.solution_part("SW1", "switch", 6, -4, 0, {"label": "S"})
	b.solution_wire("R1", "b", "SW1", "a").solution_wire("SW1", "b", "L1", "anode")
	b.outro("On and off, 1 and 0. That's a [[bit]]!", "wow")
	b.recap("A switch opens and closes the loop.")
	b.recap("Closed means current flows.")
	b.recap("On and off are a bit: 1 and 0.")
	b.question("A closed switch means…", [
		{"text": "Current flows.", "correct": true, "why": "Closed joins the two sides, so the loop is complete."},
		{"text": "Current stops.", "correct": false, "why": "That's an open switch: it leaves a gap."},
		{"text": "The LED breaks.", "correct": false, "why": "A switch only opens and closes the loop. It can't harm the LED."},
	])
	b.fact("'[[bit|Bit]]' is short for 'binary digit'. It was first used this way in 1947.",
			"J. W. Tukey, Bell Labs memo, January 1947; C. E. Shannon, Bell System Technical Journal 27, 380 (1948), credits Tukey with the word")
	return b.done()
