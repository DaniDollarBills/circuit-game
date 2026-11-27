extends RefCounted
## Level 6, "Either switch": two switches in parallel, the idea behind OR.

const Layout := preload("res://src/content/ch1/layout.gd")


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.either", "ch1", "Either switch")
	b.summary("Light it when either switch is on.")
	Layout.loop_wires(Layout.wide(b), PackedStringArray(["w1", "w3"]))
	b.tray("switch", {"label": "A"}).tray("switch", {"label": "B"})
	b.goal({"kind": "no_damage"}).goal({"kind": "no_short"}).goal({"kind": "uses", "part_kind": "switch", "min": 2})
	Layout.switch_tests(b, func(a_on: bool, b_on: bool) -> bool: return a_on or b_on)
	b.idea("Same switches, new rule.", "", "happy")
	b.idea("Make the LED light when A is on, or B is on, or both.", "", "curious")
	b.step("Place switches A and B.", {"kind": "uses", "part_kind": "switch", "min": 2})
	b.step("Connect one side of each switch to the resistor.", {"kind": "all", "goals": [
			{"kind": "connected", "a": "R1:b", "b": "A:*"}, {"kind": "connected", "a": "R1:b", "b": "B:*"}]})
	b.step("Connect the other sides to the LED's + side.", {"kind": "all", "goals": [
			{"kind": "connected", "a": "L1:anode", "b": "A:*"}, {"kind": "connected", "a": "L1:anode", "b": "B:*"}]})
	b.step("Press Test.", {"kind": "ui_flag", "flag": "tested"})
	b.hint("Give the current two paths, one through each switch.")
	b.hint("Connect both switches side by side between the resistor and the LED.", [{"part": "A"}, {"part": "B"}])
	b.hint("Here's one way. Tap the ghosts to place them.", [], true)
	b.solution_part("SW1", "switch", 4, -4, 0, {"label": "A"}).solution_part("SW2", "switch", 4, -7, 0, {"label": "B"})
	b.solution_wire("R1", "b", "SW1", "a").solution_wire("SW1", "a", "SW2", "a")
	b.solution_wire("SW2", "b", "SW1", "b").solution_wire("SW1", "b", "L1", "anode")
	b.outro("Side by side is called [[parallel]]. Either path works.", "wow")
	b.outro("This is the idea behind an OR gate.", "happy")
	return b.done()
