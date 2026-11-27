extends RefCounted
## Level 9, "Inside the wire": zoom into a wire until the copper atoms show.

const Layout := preload("res://src/content/ch1/layout.gd")


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.inside-the-wire", "ch1", "Inside the wire")
	b.summary("Zoom into a wire to see electrons.")
	b.kind("zoom")
	Layout.loop_wires(Layout.compact(b), PackedStringArray(["w1", "w2", "w3"]))
	b.goal({"kind": "zoom_reached", "layer": "wire.copper"})
	b.idea("Wires look solid, but a 10 cm piece holds billions of trillions of free [[electron|electrons]] that can move.", "", "curious")
	b.idea("Pinch or scroll over a wire to zoom in. Keep going until you see atoms!", "", "happy")
	b.step("Zoom in over a wire.", {"kind": "zoom_reached", "layer": "wire.closeup"})
	b.step("Keep going until you see atoms.", {"kind": "zoom_reached", "layer": "wire.copper"})
	b.hint("Put your fingers or mouse right over a wire, then zoom in.")
	b.hint("Keep zooming in. The wire gets bigger and bigger.", [{"wire": "w1"}])
	b.hint("Keep zooming in through the wire to reach the copper atoms.", [], false)
	b.outro("Those are copper [[atom|atoms]] in a [[crystal lattice]]. Electrons drift from − to +, against the [[conventional current]] arrows.", "wow")
	b.outro("Electrons crawl slower than a snail, but the push travels down the wire at a large fraction of the speed of light.", "happy")
	b.fact("In this wire, electrons drift only about 0.2 millimeters per minute.",
			"Copper's free-electron density n = 8.47 × 10²² cm⁻³ (C. Kittel, Introduction to Solid State Physics, 8th ed., ch. 6, table 1); v = I ÷ (n·A·e) with 13.8 mA in 22 AWG (0.644 mm) wire ≈ 3.1 µm/s ≈ 0.19 mm/min")
	return b.done()
