extends RefCounted
## Lesson 0, "Your workbench": a tour of the screen, then one step per control
## (place, move, turn, wire, delete, undo, zoom, pan, datasheet, hint), each
## shown by the moving hand. Nothing can go wrong, and it can be skipped.


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.workbench", "ch1", "Your workbench")
	b.kind("tutorial")
	b.summary("Meet your workbench and every control.")
	b.part("B1", "battery", -6, 0).part("L1", "led", 6, 0, 90)
	b.tray("resistor", {"ohms": 220.0})
	b.learn_goals(["What's where on your workbench", "How to place, move, turn and wire parts", "Where to get help"])
	b.idea("Hi, I'm Pip, a tiny spark of [[electricity]]. Let's look around your workbench before we build.", "", "happy")
	b.tour("This is your workbench. You build on the board, a grid of holes for the parts' legs.", "board")
	b.tour("New parts wait in the tray. You drag them out onto the board.", "tray")
	b.tour("The battery pack sits beside the board. Its red and black leads bring the power in.", "battery")
	b.tour("Up top: back to the map, start over, undo and redo, the calculator, your Notebook and settings.", "top_bar")
	b.tour("Your goals and steps live here. Steps tick themselves off as you go.", "column")
	b.tour("When you get stuck, tap the lightbulb for a hint. Each tap gives a little more help.", "hint")
	b.step("Drag the resistor from the tray onto the board.", {"kind": "ui_flag", "flag": "did:placed"})
	b.why("Every part you build with starts in the tray.")
	b.demo({"gesture": "drag", "from": {"tray": 0}, "to": {"board": [0, 5]}})
	b.step("Now drag the resistor to a new spot.", {"kind": "ui_flag", "flag": "did:moved"})
	b.why("You can move parts around until your circuit looks tidy.")
	b.demo({"gesture": "drag", "from": {"part": "placed"}, "to": {"part": "placed", "offset": [4, 0]}})
	b.step("Turn it: press R, or hold it and choose Rotate.", {"kind": "ui_flag", "flag": "did:rotated"})
	b.why("Turning a part helps its legs reach where you need them.")
	b.demo({"gesture": "long_press", "from": {"part": "placed"}, "mouse": {"gesture": "key", "key": "R"}})
	b.step("Drag from one metal dot to another to make a wire.", {"kind": "ui_flag", "flag": "did:wired"})
	b.why("Wires carry the current from one part to the next.")
	b.demo({"gesture": "drag", "from": {"pin": "B1:pos"}, "to": {"pin": "placed:a"}})
	b.step("Delete the wire: hold it (or right-click it), then choose Delete.", {"kind": "ui_flag", "flag": "did:deleted"})
	b.why("Mistakes are easy to take back: you can delete anything you added.")
	b.demo({"gesture": "long_press", "from": {"wire": "placed"}})
	b.step("Bring it back with the undo arrow at the top.", {"kind": "ui_flag", "flag": "did:undone"})
	b.why("Undo takes back your last change, so nothing can go badly wrong.")
	b.demo({"gesture": "tap", "from": {"button": "undo"}})
	b.step("Zoom in and out: pinch, or turn the mouse wheel.", {"kind": "ui_flag", "flag": "did:zoomed"})
	b.why("Zooming in shows small parts and their legs up close.")
	b.demo({"gesture": "pinch", "from": {"board": [0, 0]}, "mouse": {"gesture": "scroll"}})
	b.step("Move your view: drag an empty spot on the bench.", {"kind": "ui_flag", "flag": "did:panned"})
	b.why("Moving the view lets you look at any part of a big circuit.")
	b.demo({"gesture": "drag", "from": {"board": [-3, 8]}, "to": {"board": [3, 8]}})
	b.step("Tap the LED to read its datasheet.", {"kind": "ui_flag", "flag": "datasheet:L1"})
	b.why("A datasheet lists a part's real numbers, the way engineers read them.")
	b.demo({"gesture": "tap", "from": {"part": "L1"}})
	b.step("Tap the lightbulb whenever you need a hint.", {"kind": "ui_flag", "flag": "did:hint"})
	b.why("Hints come in steps: a nudge, then a highlight, then the answer.")
	b.demo({"gesture": "tap", "from": {"button": "hint"}})
	var every_step: Array = []
	for st in ["did:placed", "did:moved", "did:rotated", "did:wired", "did:deleted", "did:undone", "did:zoomed",
			"did:panned", "datasheet:L1", "did:hint"]:
		every_step.append({"kind": "ui_flag", "flag": st})
	b.goal({"kind": "all", "goals": every_step, "label": "Try every control once",
			"message": "Follow the steps: the moving hand shows each one."})
	b.hint("Do what the moving hand shows. You can skip any step.")
	b.outro("You know your way around the bench!", "wow")
	b.recap("Parts come from the tray: drag them out, move them and turn them.")
	b.recap("Wires go from one metal dot to another.")
	b.recap("Undo takes back mistakes, and the lightbulb gives hints.")
	b.question("How do you make a wire?", [
		{"text": "Drag from one metal dot to another.", "correct": true,
				"why": "Right: a wire always joins two metal dots, the legs and posts of the parts."},
		{"text": "Drag one part onto another.", "correct": false,
				"why": "Not here: parts don't join by touching. A wire joins their metal dots."},
		{"text": "Tap the battery twice.", "correct": false,
				"why": "Tapping a part opens its datasheet. Wires come from dragging between dots."},
	])
	return b.done()
