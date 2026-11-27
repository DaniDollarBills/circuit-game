class_name Progress
extends RefCounted
## Everything the game remembers between sessions: finished levels, drafts,
## settings, stats, the Notebook's words and earned badges.

const VERSION := 1
## Real-life depth with heavy help by default: the real-looking 3D workbench,
## live values and the current-flow glow, with the quality picked per device.
const DEFAULT_SETTINGS := {
	"help_level": "heavy",
	"view_style": "physical",
	"show_values": true,
	"show_current": true,
	"quality": "auto",
	"reduced_motion": false,
	"electron_flow": false,
	"large_text": false,
	"patterns": false,
	"night": false,
	"sound": true,
	"music_volume": 0.5,
}
const SETTING_CHOICES := {
	"help_level": ["heavy", "light", "off"],
	"view_style": ["physical", "schematic"],
	"quality": ["auto", "low", "medium", "high", "ultra"],
}
const TABLES: PackedStringArray = ["completed", "drafts", "settings", "stats", "seen_terms", "achievements",
		"lessons", "parts_seen"]
## The steps of a lesson that are remembered once seen.
const LESSON_STEPS: PackedStringArray = ["learn", "try", "recap"]

## Level id → {star: bool, at: unix time first completed}.
var completed: Dictionary = {}
## Level id → circuit dictionary (CircuitIO); checked when the level opens.
var drafts: Dictionary = {}
var settings: Dictionary = {}
var stats: Dictionary = {}
## Term → unix time first seen. This is the Notebook.
var seen_terms: Dictionary = {}
## Badge id → unix time earned.
var achievements: Dictionary = {}
## Level id → {learn?, try?, recap?: unix time first seen}: what plays by
## itself, and the course marks on the map.
var lessons: Dictionary = {}
## Part intro key → unix time its Meet the part card was first seen.
var parts_seen: Dictionary = {}


static func defaults() -> Progress:
	var p := Progress.new()
	p.settings = DEFAULT_SETTINGS.duplicate(true)
	p.stats = {"parts_burnt": 0}
	return p


func to_dict() -> Dictionary:
	var d := {"version": VERSION}
	for table in TABLES:
		d[table] = (get(table) as Dictionary).duplicate(true)
	return d


## Null for an unknown version or any progress value of the wrong type. Keys
## that are missing, and settings this build can't use, take their defaults.
static func from_dict(d: Variant) -> Progress:
	if typeof(d) != TYPE_DICTIONARY:
		return null
	var src: Dictionary = d
	if not _is_number(src.get("version")) or int(src["version"]) != VERSION:
		return null
	for table in TABLES:
		if src.has(table) and typeof(src[table]) != TYPE_DICTIONARY:
			return null
	var p := defaults()
	var done: Dictionary = src.get("completed", {})
	for id in done:
		var e: Variant = done[id]
		if typeof(e) != TYPE_DICTIONARY or typeof(e.get("star")) != TYPE_BOOL or not _is_number(e.get("at")):
			return null
		p.completed[str(id)] = {"star": e["star"], "at": int(e["at"])}
	var drafts_in: Dictionary = src.get("drafts", {})
	for id in drafts_in:
		if typeof(drafts_in[id]) != TYPE_DICTIONARY:
			return null
		p.drafts[str(id)] = (drafts_in[id] as Dictionary).duplicate(true)
	var settings_in: Dictionary = src.get("settings", {})
	for key in settings_in:
		if is_valid_setting(key, settings_in[key]):
			p.settings[key] = settings_in[key]
	for table in ["stats", "seen_terms", "achievements", "parts_seen"]:
		var from: Dictionary = src.get(table, {})
		var into: Dictionary = p.get(table)
		for key in from:
			if not _is_number(from[key]):
				return null
			into[str(key)] = int(from[key])
	var lessons_in: Dictionary = src.get("lessons", {})
	for id in lessons_in:
		var marks: Variant = lessons_in[id]
		if typeof(marks) != TYPE_DICTIONARY:
			return null
		var kept := {}
		for step in marks:
			if not step in LESSON_STEPS or not _is_number(marks[step]):
				return null
			kept[str(step)] = int(marks[step])
		p.lessons[str(id)] = kept
	return p


## A setting this build knows, with a value of the right type and, for a
## choice, one of the listed values.
static func is_valid_setting(key: Variant, v: Variant) -> bool:
	if typeof(key) != TYPE_STRING or not DEFAULT_SETTINGS.has(key):
		return false
	if typeof(v) != typeof(DEFAULT_SETTINGS[key]):
		return false
	if key == "music_volume":
		return float(v) >= 0.0 and float(v) <= 1.0
	return not SETTING_CHOICES.has(key) or v in SETTING_CHOICES[key]


## Records the terms not seen before and returns just those.
func mark_terms_seen(terms: PackedStringArray, now: int) -> PackedStringArray:
	var fresh := PackedStringArray()
	for t in terms:
		if not seen_terms.has(t):
			seen_terms[t] = now
			fresh.append(t)
	return fresh


## The chapter's first lesson is always open; each other needs the one before
## it. A lesson already passed stays open, even when a lesson is added before
## it (Lesson 0 arrived after many players had passed Lesson 1).
func is_unlocked(level_id: String, chapter_level_ids: PackedStringArray) -> bool:
	var i := chapter_level_ids.find(level_id)
	if i < 0:
		return false
	return i == 0 or completed.has(level_id) or completed.has(chapter_level_ids[i - 1])


## Records a lesson step (learn, try or recap) the first time it's seen.
func mark_lesson(level_id: String, step: String, now: int) -> void:
	var marks: Dictionary = lessons.get(level_id, {})
	if not marks.has(step):
		marks[step] = now
	lessons[level_id] = marks


func lesson_marks(level_id: String) -> Dictionary:
	return (lessons.get(level_id, {}) as Dictionary).duplicate()


## True when this is the first time the part's card is seen.
func mark_part_seen(key: String, now: int) -> bool:
	if parts_seen.has(key):
		return false
	parts_seen[key] = now
	return true


## A star, once earned, stays; the first completion time is kept.
func mark_complete(level_id: String, star: bool, now: int) -> void:
	if completed.has(level_id):
		completed[level_id]["star"] = bool(completed[level_id]["star"]) or star
	else:
		completed[level_id] = {"star": star, "at": now}


static func _is_number(v: Variant) -> bool:
	return (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and is_finite(float(v))
