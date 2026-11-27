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
}
const SETTING_CHOICES := {
	"help_level": ["heavy", "light", "off"],
	"view_style": ["physical", "schematic"],
	"quality": ["auto", "low", "medium", "high", "ultra"],
}
const TABLES: PackedStringArray = ["completed", "drafts", "settings", "stats", "seen_terms", "achievements"]

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
		if not DEFAULT_SETTINGS.has(key):
			continue
		var v: Variant = settings_in[key]
		var usable: bool = typeof(v) == typeof(DEFAULT_SETTINGS[key]) and (not SETTING_CHOICES.has(key) or v in SETTING_CHOICES[key])
		if usable:
			p.settings[key] = v
	for table in ["stats", "seen_terms", "achievements"]:
		var from: Dictionary = src.get(table, {})
		var into: Dictionary = p.get(table)
		for key in from:
			if not _is_number(from[key]):
				return null
			into[str(key)] = int(from[key])
	return p


## Records the terms not seen before and returns just those.
func mark_terms_seen(terms: PackedStringArray, now: int) -> PackedStringArray:
	var fresh := PackedStringArray()
	for t in terms:
		if not seen_terms.has(t):
			seen_terms[t] = now
			fresh.append(t)
	return fresh


## The chapter's first level is always open; each other needs the one before it.
func is_unlocked(level_id: String, chapter_level_ids: PackedStringArray) -> bool:
	var i := chapter_level_ids.find(level_id)
	if i < 0:
		return false
	return i == 0 or completed.has(chapter_level_ids[i - 1])


## A star, once earned, stays; the first completion time is kept.
func mark_complete(level_id: String, star: bool, now: int) -> void:
	if completed.has(level_id):
		completed[level_id]["star"] = bool(completed[level_id]["star"]) or star
	else:
		completed[level_id] = {"star": star, "at": now}


static func _is_number(v: Variant) -> bool:
	return (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and is_finite(float(v))
