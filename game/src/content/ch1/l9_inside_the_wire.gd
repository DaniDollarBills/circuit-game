extends RefCounted
## Lesson 9, "Inside the wire": copper's crystal and its free electrons, which
## drift slowly from − to + while the push races along. Try it flips the
## picture between the current's way and the electrons'; then the player
## zooms into a wire until the atoms show.

const Layout := preload("res://src/content/ch1/layout.gd")

const DRIFT_SOURCE := "Copper's free-electron density n = 8.47 × 10²² cm⁻³ (C. Kittel, Introduction to Solid State Physics, 8th ed., ch. 6, table 1); v = I ÷ (n·A·e) with 13.8 mA in 22 AWG (0.644 mm) wire ≈ 3.1 µm/s ≈ 0.19 mm/min"


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.inside-the-wire", "ch1", "Inside the wire")
	b.summary("Zoom into a wire to see electrons.")
	b.kind("zoom")
	Layout.loop_wires(Layout.compact(b), PackedStringArray(["w1", "w2", "w3"]))
	b.goal({"kind": "zoom_reached", "layer": "wire.copper"})
	b.learn_goals(["What's inside a copper wire", "Which way electrons really move"])
	b.idea("Copper is a crystal: its atoms sit locked in neat rows. Each one lends an [[electron]] to a sea of free ones that can move.",
			"copper_lattice", "curious")
	b.idea("The battery's push makes all the free electrons [[drift]] along together, like the links of a bike chain.", "", "happy")
	b.idea("Electrons are negative, so they drift from − to +. That's the opposite way to the current arrows we draw.",
			"electron_vs_current", "curious")
	b.idea("Here they drift only about 0.2 mm a minute. The push itself races down the wire at nearly the speed of light.", "", "wow",
			"Each electron also zips about at random, far faster than it drifts. The drift is the slow, steady creep they share.",
			DRIFT_SOURCE)
	b.history("In 1897 Joseph John Thomson found the electron, the first particle known to be smaller than an atom.",
			"J. J. Thomson, Philosophical Magazine 44, 293 (1897)")
	b.history("In 1747 Benjamin Franklin named the two kinds of charge + and −. He guessed which way it flows, and we still draw it his way.",
			"B. Franklin, letter to P. Collinson, 25 May 1747")
	b.try_it("Here's a working loop. Switch the picture to the electrons' way, then back.")
	b.try_part("B1", "battery", -6, 0).try_part("R1", "resistor", -2, -4).try_part("L1", "led", 6, 0, 90)
	b.try_wire("w1", "B1", "pos", "R1", "a", true).try_wire("w2", "R1", "b", "L1", "anode", true)
	b.try_wire("w3", "L1", "cathode", "B1", "neg", true)
	b.poke("Show the electrons' way: they go round backwards.", {"kind": "ui_flag", "flag": "did:electron_flow"})
	b.poke("Now the current's way again.", {"kind": "ui_flag", "flag": "did:current_flow"})
	b.readout("L1", "mA")
	# The bench stays as it is: the try panel's button does the switching.
	b.try_path_edit(func(c: Circuit) -> Circuit: return c)
	b.step("Zoom in over a wire.", {"kind": "zoom_reached", "layer": "wire.closeup"})
	b.why("Zooming in over a wire takes you inside it.")
	b.step("Keep going until you see atoms.", {"kind": "zoom_reached", "layer": "wire.copper"})
	b.why("Copper's atoms sit about a quarter of a billionth of a meter apart.")
	b.hint("Put your fingers or mouse right over a wire, then zoom in.")
	b.hint("Keep zooming in. The wire gets bigger and bigger.", [{"wire": "w1"}])
	b.hint("Keep zooming in through the wire to reach the copper atoms.", [], false)
	b.outro("Those are copper [[atom|atoms]] in a [[crystal lattice]]. Electrons drift from − to +, against the [[conventional current]] arrows.", "wow")
	b.recap("Copper is full of free electrons.")
	b.recap("They drift slowly; the push travels fast.")
	b.recap("Your wire carried {L1.mA}.")
	b.question("Which way do electrons drift?", [
		{"text": "From − to +, against the arrows.", "correct": true, "why": "Electrons are negative, so they drift toward +, against the current arrows."},
		{"text": "From + to −, with the arrows.", "correct": false, "why": "That's the way we draw current, chosen before electrons were known."},
		{"text": "They don't move.", "correct": false, "why": "They do, slowly: about 0.2 mm a minute here."},
	])
	b.fact("In this wire, electrons drift only about 0.2 millimeters per minute.", DRIFT_SOURCE)
	return b.done()
