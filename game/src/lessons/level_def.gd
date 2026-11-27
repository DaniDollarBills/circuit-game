class_name LevelDef
extends RefCounted
## One lesson: the board the player starts with, what they may add, what counts
## as done, and the help shown along the way. Built with LevelBuilder.

var id := ""
var chapter := ""
var title := ""
var summary := ""
## "build" or "zoom".
var kind := "build"
## {text, mood}; mood is happy, curious, wow or oops.
var intro: Array[Dictionary] = []
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
## {text, check: goal}: the heavy-help checklist.
var steps: Array[Dictionary] = []
## The calculator heavy help suggests: "", "led_resistor", "ohms_law" or "power".
var formula := ""
