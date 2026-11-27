extends RefCounted
## Level 1, "Light it up": close the loop to light an LED.

const Layout := preload("res://src/content/ch1/layout.gd")


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.light-it-up", "ch1", "Light it up")
	b.summary("Close the loop to light an LED.")
	Layout.compact(b, {"ohms": 220.0})
	b.goal({"kind": "led_lit", "part": "L1"}).goal({"kind": "no_short"})
	b.idea("Hi! I'm Pip, a tiny spark of [[electricity]].", "", "happy")
	b.idea("Electricity only flows around a full loop: out of the battery's + side, through your parts, and back into −.", "", "curious")
	b.idea("Drag from one metal dot to another to add a wire. Can you light the [[led|LED]]?", "", "happy")
	b.step("Connect the battery's + to the resistor's left end.", {"kind": "connected", "a": "B1:pos", "b": "R1:a"})
	b.step("Connect the resistor's right end to the LED's + side.", {"kind": "connected", "a": "R1:b", "b": "L1:anode"})
	b.step("Connect the LED's − side back to the battery's −.", {"kind": "connected", "a": "L1:cathode", "b": "B1:neg"})
	b.hint("Current leaves the battery's + end. Where should it go first?")
	b.hint("Connect the battery's + to the resistor, the resistor to the LED, and the LED back to −.",
			[{"part": "B1", "pin": "pos"}, {"part": "R1", "pin": "a"}])
	b.hint("Here's one way to do it. Tap the ghost wires to place them.", [], true)
	b.solution_wire("B1", "pos", "R1", "a").solution_wire("R1", "b", "L1", "anode").solution_wire("L1", "cathode", "B1", "neg")
	b.outro("You made light! About 14 [[milliamp|milliamps]] are flowing around your loop.", "wow")
	b.outro("Every phone and computer works because of loops like this one.", "happy")
	b.fact("The first practical visible-light LED, made in 1962, could only glow red.",
			"N. Holonyak Jr. and S. F. Bevacqua, Applied Physics Letters 1, 82 (1962). Earlier LEDs were infrared (J. R. Biard and G. Pittman, Texas Instruments, 1961) or far too dim to use (H. J. Round, Electrical World 49, 309 (1907)).")
	return b.done()
