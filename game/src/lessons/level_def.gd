class_name LevelDef
extends RefCounted
## One lesson: the board the player starts with, what they may add, what counts
## as done, and the help shown along the way. Built with LevelBuilder.

var id := ""
var chapter := ""
var title := ""
var summary := ""
## "build", "zoom" or "tutorial" (Lesson 0, the workbench).
var kind := "build"
## What the lesson teaches, shown on its first card: two or three short lines.
var learn_goals := PackedStringArray()
## The Learn deck's cards: {type, text, mood, diagram, deeper, source}, plus
## `breaks` (analogy), `steps` (worked), `part` (meet) or `target` (tour).
var learn: Array[Dictionary] = []
var circuit := Circuit.new()
## {kind, props, count}
var tray: Array[Dictionary] = []
var goals: Array[Dictionary] = []
## {name, set: [{target, prop, value}], expect: [goal…]}
var tests: Array[Dictionary] = []
## {text, highlight: [{part?, pin?, wire?}], show_solution}
var hints: Array[Dictionary] = []
## The start circuit plus the solution edits.
var solution := Circuit.new()
var outro: Array[Dictionary] = []
## {text, source}
var facts: Array[Dictionary] = []
## {goal, text}, or {} when the level has no star.
var star: Dictionary = {}
## {text, check: goal, why?}: the heavy-help checklist.
var steps: Array[Dictionary] = []
## Try it: a ready-made circuit to poke at, apart from the build. No prompt,
## no Try it.
var try_prompt := ""
var try_circuit := Circuit.new()
var try_tray: Array[Dictionary] = []
## {text, check: goal}: things to try, ticked in order.
var pokes: Array[Dictionary] = []
## {part, quantity}: live values shown while trying (mA, V, W or reading).
var readouts: Array[Dictionary] = []
## Circuits a player could reach while trying, in order (for tests: every poke
## ticks along them).
var try_path: Array[Circuit] = []
## What you learned: points that may hold {part.quantity} templates.
var recap := PackedStringArray()
## {prompt, choices: [{text, correct, why}]}: quick questions after a pass.
var questions: Array[Dictionary] = []
## The calculator heavy help suggests: "", "led_resistor", "ohms_law" or "power".
var formula := ""


## The Learn deck's length: a goals card, the cards, and a closing card; 0
## when the lesson has no cards.
func deck_size() -> int:
	return 0 if learn.is_empty() else learn.size() + 2


func has_try() -> bool:
	return try_prompt != ""
