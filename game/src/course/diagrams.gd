class_name Diagrams
extends RefCounted
## Every Learn-card picture, by id. A lesson names a picture by its id, and
## LessonRules checks the id is here.

const _LOOP := preload("res://src/course/diagrams/loop_diagrams.gd")
const _INSIDE := preload("res://src/course/diagrams/inside_diagrams.gd")

const SCRIPTS := {
	"charges_in_wire": _LOOP,
	"battery_push": _LOOP,
	"loop_flow": _LOOP,
	"loop_gap": _LOOP,
	"current_direction": _LOOP,
	"led_inside": _INSIDE,
	"resistor_inside": _INSIDE,
	"trimmer_inside": _INSIDE,
	"aa_cell_inside": _INSIDE,
	"switch_inside": _INSIDE,
	"meter_inside": _INSIDE,
}
const IDS: PackedStringArray = ["charges_in_wire", "battery_push", "loop_flow", "loop_gap", "current_direction",
		"led_inside", "resistor_inside", "trimmer_inside", "aa_cell_inside", "switch_inside", "meter_inside"]


static func has(id: String) -> bool:
	return SCRIPTS.has(id)


## A new picture for `id`, reading Reduced motion and Night from `game`; null
## for an unknown id.
static func make(id: String, game: Game) -> Diagram:
	if not SCRIPTS.has(id):
		return null
	var d: Diagram = (SCRIPTS[id] as GDScript).new()
	return d.setup(id, game)
