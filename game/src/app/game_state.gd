class_name GameState
extends RefCounted
## Everything the game knows that isn't drawing: the player's progress, the open
## level, its undo history, the latest simulation and the level session. Plain
## logic, so it can be tested without a scene. Screens call its actions and read
## its fields; anything worth announcing (a burn, a pass, a badge) is queued as
## an event for take_events().

var progress: Progress = Progress.defaults()
var level: LevelDef
var history: CircuitHistory
## The simulation of history.present. Goals, steps, tests and passing are only
## ever judged on this, never on a preview.
var outcome: SimOutcome
var session: LevelSession
var zoom_layer := "editor"
## Every zoom layer reached in this visit to the level.
var zoom_seen: Dictionary = {}
var ui_flags: Dictionary = {}
## The circuit being previewed (a value slider mid-drag), or null.
var preview_circuit: Circuit
var preview_outcome: SimOutcome
var events: Array[Dictionary] = []
## The clock, in Unix seconds, for actions that record a time on their own
## (passing on a commit, a badge for a burn). Tests replace it.
var now_fn: Callable = func() -> int: return int(Time.get_unix_time_from_system())

var _announced_pass := false
var _ch1_ids := PackedStringArray()


## Opens a level on the player's saved draft when it still fits the level,
## otherwise on a fresh copy of the start circuit.
func start_level(l: LevelDef) -> void:
	level = l
	session = LevelSession.start(l)
	zoom_layer = "editor"
	zoom_seen = {}
	ui_flags = {}
	preview_circuit = null
	preview_outcome = null
	_announced_pass = false
	var draft := _usable_draft(l)
	var start := draft if draft != null else l.circuit.copy()
	outcome = Simulator.simulate(start)
	history = CircuitHistory.new(outcome.circuit)
	_update()


## Simulates `c` and makes it the present: parts that burn are stored burnt, so
## undo brings them back.
func commit(c: Circuit) -> void:
	if level == null:
		return
	_end_preview()
	var out := Simulator.simulate(c)
	outcome = out
	history.commit(out.circuit)
	_circuit_changed()
	_save_draft()
	for d in out.damage:
		events.append({"type": "burnt", "part": d["part"], "reason": d["reason"]})
	if not out.damage.is_empty():
		progress.stats["parts_burnt"] = int(progress.stats.get("parts_burnt", 0)) + out.damage.size()
	_update()
	if not out.damage.is_empty():
		check_achievements(now())


## Simulates `c` for display only: history, goals and the session don't change.
func preview(c: Circuit) -> void:
	if level == null:
		return
	preview_circuit = c
	preview_outcome = Simulator.simulate(c)


## What to draw: the preview while there is one, otherwise the present.
func shown() -> SimOutcome:
	return preview_outcome if preview_circuit != null else outcome


func undo() -> bool:
	if history == null or not history.undo():
		return false
	_resimulate()
	return true


func redo() -> bool:
	if history == null or not history.redo():
		return false
	_resimulate()
	return true


func run_tests() -> void:
	if level == null:
		return
	var was := session.phase
	LevelSession.run_tests(session, level, history.present, _ctx())
	_after_evaluation(was)


func next_intro() -> void:
	if level == null:
		return
	LevelSession.next_intro(session, level)
	_update()


func use_hint() -> void:
	if level != null:
		LevelSession.hint(session, level)


func set_zoom_layer(id: String) -> void:
	zoom_layer = id
	zoom_seen[id] = true
	_update()


func set_ui_flag(flag: String) -> void:
	ui_flags[flag] = true
	_update()


## Records a pass (with the star result) once per visit, then checks badges.
func complete(now: int) -> void:
	if level == null or session.phase != "passed" or _announced_pass:
		return
	_announced_pass = true
	var star := _star_holds()
	progress.mark_complete(level.id, star, now)
	events.append({"type": "passed", "star": star})
	check_achievements(now)


## Records the terms in the Notebook and returns the ones that are new; each
## new one is announced with a `new_word` event.
func mark_terms_seen(terms: PackedStringArray, now: int) -> PackedStringArray:
	var fresh := progress.mark_terms_seen(terms, now)
	for t in fresh:
		events.append({"type": "new_word", "term": t})
	if not fresh.is_empty():
		check_achievements(now)
	return fresh


func check_achievements(now: int) -> void:
	if _ch1_ids.is_empty():
		_ch1_ids = Levels.chapter_ids("ch1")
	for id in Achievements.newly_earned(progress, _ch1_ids):
		progress.achievements[id] = now
		events.append({"type": "badge", "id": id})


## How many parts from each tray item are on the board, by tray index.
func tray_used() -> Array[int]:
	var used: Array[int] = []
	if level == null:
		return used
	used.resize(level.tray.size())
	used.fill(0)
	for p in history.present.parts:
		if p.tray >= 0 and p.tray < used.size():
			used[p.tray] += 1
	return used


func take_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out


func _resimulate() -> void:
	_end_preview()
	outcome = Simulator.simulate(history.present)
	_circuit_changed()
	_save_draft()
	_update()


## The last test report was about the old circuit, so it goes, and the
## "Press Test." step needs a new press.
func _circuit_changed() -> void:
	session.test_report = {}
	ui_flags.erase("tested")


func _end_preview() -> void:
	preview_circuit = null
	preview_outcome = null


func _update() -> void:
	if level == null:
		return
	var was := session.phase
	LevelSession.update(session, level, _ctx())
	_after_evaluation(was)


## Passing is announced once. A star reached after passing is still recorded.
func _after_evaluation(was: String) -> void:
	if session.phase != "passed":
		return
	if was != "passed" or not _announced_pass:
		complete(now())
	elif _star_holds() and not bool(progress.completed.get(level.id, {}).get("star", false)):
		var t := now()
		progress.mark_complete(level.id, true, t)
		events.append({"type": "star"})
		check_achievements(t)


func _star_holds() -> bool:
	return not level.star.is_empty() and bool(Goals.evaluate(level.star["goal"], _ctx())["pass"])


func _ctx() -> Dictionary:
	return {
		"circuit": outcome.circuit, "sim": outcome.result, "zoom_layer": zoom_layer,
		"zoom_seen": zoom_seen, "ui_flags": ui_flags,
	}


func _save_draft() -> void:
	progress.drafts[level.id] = CircuitIO.to_dict(history.present)


## A draft is used only when it reads back cleanly and still holds every
## locked part (same kind and place) and locked wire of the level, so a draft
## from an older version of the level is never mixed with the new one.
func _usable_draft(l: LevelDef) -> Circuit:
	var d: Variant = progress.drafts.get(l.id)
	if typeof(d) != TYPE_DICTIONARY:
		return null
	var c := CircuitIO.from_dict(d)
	if c == null:
		return null
	for p in l.circuit.parts:
		if not p.locked:
			continue
		var q := c.find_part(p.id)
		if q == null or q.id != p.id or q.kind != p.kind or q.x != p.x or q.y != p.y or q.rot != p.rot:
			return null
	for w in l.circuit.wires:
		if not w.locked:
			continue
		var v := c.find_wire(w.id)
		if v == null or [v.a_part, v.a_pin, v.b_part, v.b_pin] != [w.a_part, w.a_pin, w.b_part, w.b_pin]:
			return null
	return c


func now() -> int:
	return int(now_fn.call())
