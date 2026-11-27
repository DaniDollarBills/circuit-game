class_name Diagrams
extends RefCounted
## Every Learn-card picture, by id. A lesson names a picture by its id, and
## LessonRules checks the id is here.

const _LOOP := preload("res://src/course/diagrams/loop_diagrams.gd")
const _INSIDE := preload("res://src/course/diagrams/inside_diagrams.gd")
const _LED := preload("res://src/course/diagrams/led_diagrams.gd")
const _FLOW := preload("res://src/course/diagrams/flow_diagrams.gd")
const _SWITCH := preload("res://src/course/diagrams/switch_diagrams.gd")
const _TABLE := preload("res://src/course/diagrams/truth_table_diagram.gd")
const _HEAT := preload("res://src/course/diagrams/heat_diagrams.gd")
const _ELECTRON := preload("res://src/course/diagrams/electron_diagrams.gd")
const _CONTROL := preload("res://src/course/diagrams/control_demos.gd")

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
	"led_one_way": _LED,
	"voltage_budget": _LED,
	"current_vs_resistance": _LED,
	"water_analogy": _FLOW,
	"ohm_triangle": _FLOW,
	"unit_ladder": _FLOW,
	"meter_placement": _FLOW,
	"switch_states": _SWITCH,
	"bits": _SWITCH,
	"series_paths": _SWITCH,
	"parallel_paths": _SWITCH,
	"truth_table": _TABLE,
	"short_path": _HEAT,
	"power_heat": _HEAT,
	"electron_vs_current": _ELECTRON,
	"copper_lattice": _ELECTRON,
	"control_dial": _CONTROL,
	"control_switch": _CONTROL,
	"control_test": _CONTROL,
}
const IDS: PackedStringArray = ["charges_in_wire", "battery_push", "loop_flow", "loop_gap", "current_direction",
		"led_inside", "resistor_inside", "trimmer_inside", "aa_cell_inside", "switch_inside", "meter_inside",
		"led_one_way", "voltage_budget", "current_vs_resistance",
		"water_analogy", "ohm_triangle", "unit_ladder", "meter_placement",
		"switch_states", "bits", "series_paths", "parallel_paths", "truth_table",
		"short_path", "power_heat", "electron_vs_current", "copper_lattice",
		"control_dial", "control_switch", "control_test"]


static func has(id: String) -> bool:
	return SCRIPTS.has(id)


## A new picture for `id`, reading Reduced motion and Night from `game`; null
## for an unknown id.
static func make(id: String, game: Game) -> Diagram:
	if not SCRIPTS.has(id):
		return null
	var d: Diagram = (SCRIPTS[id] as GDScript).new()
	return d.setup(id, game)
