extends RefCounted
## Level 4, "On and off": control the light with a switch.

const Layout := preload("res://src/content/ch1/layout.gd")


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.on-and-off", "ch1", "On and off")
	b.summary("Control the light with a switch.")
	Layout.loop_wires(Layout.wide(b), PackedStringArray(["w1", "w3"]))
	b.tray("switch", {"label": "S"})
	b.goal({"kind": "no_damage"}).goal({"kind": "no_short"}).goal({"kind": "uses", "part_kind": "switch", "min": 1})
	b.test("Switch off: LED off", [{"target": "S", "prop": "closed", "value": false}], [{"kind": "led_dark", "part": "L1"}])
	b.test("Switch on: LED on", [{"target": "S", "prop": "closed", "value": true}], [{"kind": "led_lit", "part": "L1"}])
	b.intro("A [[switch]] opens and closes the loop, like a drawbridge.", "curious")
	b.intro("Add the switch so it controls the LED. Tap it to try, then press Test.", "happy")
	b.step("Place the switch from the tray.", {"kind": "uses", "part_kind": "switch", "min": 1})
	b.step("Connect the resistor to one side of the switch.", {"kind": "connected", "a": "R1:b", "b": "S:*"})
	b.step("Connect the other side to the LED's + side.", {"kind": "connected", "a": "L1:anode", "b": "S:*"})
	b.step("Try the switch, then press Test.", {"kind": "ui_flag", "flag": "tested"})
	b.hint("The loop has a gap. The switch can fill it.")
	b.hint("Connect the resistor to one side of the switch, and the other side to the LED.",
			[{"part": "R1", "pin": "b"}, {"part": "L1", "pin": "anode"}])
	b.hint("Here's one way. Tap the ghosts to place them.", [], true)
	b.solution_part("SW1", "switch", 6, -4, 0, {"label": "S"})
	b.solution_wire("R1", "b", "SW1", "a").solution_wire("SW1", "b", "L1", "anode")
	b.outro("On and off, 1 and 0. That's a [[bit]]!", "wow")
	b.outro("Computers are made of billions of tiny switches doing exactly this.", "happy")
	b.fact("'[[bit|Bit]]' is short for 'binary digit'. It was first used this way in 1947.",
			"J. W. Tukey, Bell Labs memo, January 1947; C. E. Shannon, Bell System Technical Journal 27, 380 (1948), credits Tukey with the word")
	return b.done()
