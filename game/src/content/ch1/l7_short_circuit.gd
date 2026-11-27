extends RefCounted
## Level 7, "Short circuit!": find and delete the wire that skips everything.

const Layout := preload("res://src/content/ch1/layout.gd")


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.short-circuit", "ch1", "Short circuit!")
	b.summary("Find the wire that skips everything.")
	Layout.loop_wires(Layout.compact(b), PackedStringArray(["w1", "w2", "w3"]))
	var detour: Array[Vector2i] = [Vector2i(-4, -6), Vector2i(9, -6), Vector2i(9, 1)]
	b.wire("w_bad", "R1", "a", "L1", "cathode", false, detour)
	b.goal({"kind": "no_short"}).goal({"kind": "led_lit", "part": "L1"})
	b.idea("Uh oh, this battery is getting hot!", "", "oops")
	b.idea("A [[short circuit]] is a shortcut that lets current skip your parts. Find it and delete it.", "", "curious")
	b.step("Tap the wires to find the one going from + straight to −.", {"kind": "ui_flag", "flag": "selected:w_bad"})
	b.step("Hold it and choose Delete.", {"kind": "no_short"})
	b.hint("One wire connects the + side straight to the − side.")
	b.hint("It's this wire. Hold it and choose Delete.", [{"wire": "w_bad"}])
	b.hint("Delete the highlighted wire.", [{"wire": "w_bad"}], true)
	b.solution_remove_wire("w_bad")
	b.outro("Fixed! The current goes through the LED again.", "wow")
	b.outro("Real short circuits can melt wires. Never connect a real battery's + and − together!", "curious")
	b.fact("Fuses and circuit breakers cut the power when too much current flows.", "IEC 60269 (fuses) and IEC 60898-1 (circuit breakers)")
	return b.done()
