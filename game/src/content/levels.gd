class_name Levels
extends RefCounted
## Every level, in play order. Levels are built fresh on each call, so nothing
## a caller does to one can leak into another.

const _CH1 := [
	preload("res://src/content/ch1/l1_light_it_up.gd"),
	preload("res://src/content/ch1/l2_pop.gd"),
	preload("res://src/content/ch1/l3_push_and_flow.gd"),
	preload("res://src/content/ch1/l4_on_and_off.gd"),
	preload("res://src/content/ch1/l5_both.gd"),
	preload("res://src/content/ch1/l6_either.gd"),
	preload("res://src/content/ch1/l7_short_circuit.gd"),
	preload("res://src/content/ch1/l8_too_hot.gd"),
	preload("res://src/content/ch1/l9_inside_the_wire.gd"),
]


static func all() -> Array[LevelDef]:
	var out: Array[LevelDef] = []
	for script in _CH1:
		out.append(script.build())
	return out


## Null when no level has that id.
static func by_id(id: String) -> LevelDef:
	for l in all():
		if l.id == id:
			return l
	return null


static func chapter_ids(chapter: String) -> PackedStringArray:
	var out := PackedStringArray()
	for l in all():
		if l.chapter == chapter:
			out.append(l.id)
	return out
