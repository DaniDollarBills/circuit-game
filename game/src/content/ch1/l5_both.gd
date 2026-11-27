extends RefCounted
## Level 5, "Both switches": two switches in series, the idea behind AND.

const Layout := preload("res://src/content/ch1/layout.gd")


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.both", "ch1", "Both switches")
	b.summary("Light it only when both switches are on.")
	Layout.loop_wires(Layout.wide(b), PackedStringArray(["w1", "w3"]))
	b.tray("switch", {"label": "A"}).tray("switch", {"label": "B"})
	b.goal({"kind": "no_damage"}).goal({"kind": "no_short"}).goal({"kind": "uses", "part_kind": "switch", "min": 2})
	Layout.switch_tests(b, func(a_on: bool, b_on: bool) -> bool: return a_on and b_on)
	b.intro("Here are two switches, A and B.", "happy")
	b.intro("Make the LED light only when A and B are both on.", "curious")
	b.step("Place switches A and B.", {"kind": "uses", "part_kind": "switch", "min": 2})
	b.step("Connect the resistor to A.", {"kind": "connected", "a": "R1:b", "b": "A:*"})
	b.step("Connect A to B.", {"kind": "connected", "a": "A:*", "b": "B:*"})
	b.step("Connect B to the LED's + side.", {"kind": "connected", "a": "B:*", "b": "L1:anode"})
	b.step("Press Test.", {"kind": "ui_flag", "flag": "tested"})
	b.hint("Current has to pass through both switches, one after the other.")
	b.hint("Connect the resistor to A, A to B, and B to the LED.", [{"part": "A"}, {"part": "B"}])
	b.hint("Here's one way. Tap the ghosts to place them.", [], true)
	b.solution_part("SW1", "switch", 3, -4, 0, {"label": "A"}).solution_part("SW2", "switch", 8, -4, 0, {"label": "B"})
	b.solution_wire("R1", "b", "SW1", "a").solution_wire("SW1", "b", "SW2", "a").solution_wire("SW2", "b", "L1", "anode")
	b.outro("Parts in a row are in [[series]]. Every switch must be on.", "wow")
	b.outro("This is the idea behind an AND gate. You'll build real ones soon!", "happy")
	return b.done()
