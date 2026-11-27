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
## The build's history and outcome, set aside while Try it's circuit is out.
var _build_history: CircuitHistory
var _build_outcome: SimOutcome
var _ch1_ids := PackedStringArray()


## Opens a level on the player's saved draft when it still fits the level,
## otherwise on a fresh copy of the start circuit.
func start_level(l: LevelDef) -> void:
	level = l
	zoom_layer = "editor"
	zoom_seen = {}
	ui_flags = {}
	preview_circuit = null
	preview_outcome = null
	_announced_pass = false
	_build_history = null
	_build_outcome = null
	var draft := _usable_draft(l)
	var start := draft if draft != null else l.circuit.copy()
	outcome = Simulator.simulate(start)
	history = CircuitHistory.new(outcome.circuit)
	session = LevelSession.start(l, _plays_lesson(l))
	_entered("build")
	_update()


## The lesson plays by itself (Learn, then Try it) on a first visit at Heavy
## help: never passed, and its deck never seen.
func _plays_lesson(l: LevelDef) -> bool:
	return str(progress.settings.get("help_level", "heavy")) == "heavy" \
			and not progress.completed.has(l.id) and not progress.lesson_marks(l.id).has("learn")


## Simulates `c` and makes it the present: parts that burn are stored burnt, so
## undo brings them back.
func commit(c: Circuit) -> void:
	if level == null:
		return
	_end_preview()
	var out := Simulator.simulate(c)
	# What the player did, for Lesson 0's steps (did:placed, did:wired…).
	for action in CircuitDiff.actions(history.present, out.circuit):
		ui_flags["did:" + action] = true
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
	ui_flags["did:undone"] = true
	_resimulate()
	return true


func redo() -> bool:
	if history == null or not history.redo():
		return false
	_resimulate()
	return true


## Back to the level's own start circuit, as one step that undo can take
## back (the old test report goes with the old circuit). A passed level is
## being built again, so solving it again is a new pass; the completion
## already saved stays.
func start_over() -> void:
	if level == null:
		return
	if trying():
		commit(level.try_circuit.copy())
		return
	if session.phase == "passed":
		session.phase = "build"
		_announced_pass = false
	commit(level.circuit.copy())


func run_tests() -> void:
	if level == null:
		return
	var was := session.phase
	LevelSession.run_tests(session, level, history.present, _ctx())
	_after_evaluation(was)


func next_card() -> void:
	if level == null:
		return
	var was := session.phase
	LevelSession.next_card(session, level)
	_entered(was)
	_update()


func back_card() -> void:
	if level == null:
		return
	LevelSession.back_card(session)
	_update()


func skip_learn() -> void:
	if level == null:
		return
	var was := session.phase
	LevelSession.skip_learn(session, level)
	_entered(was)
	_update()


func finish_try() -> void:
	if level == null:
		return
	var was := session.phase
	LevelSession.finish_try(session)
	_entered(was)
	_update()


## Back to the lesson's deck (or its Try it) from building; the build's
## circuit waits untouched.
func reopen_lesson() -> void:
	if level == null:
		return
	var was := session.phase
	LevelSession.reopen(session, level)
	_entered(was)
	_update()


func trying() -> bool:
	return session != null and session.phase == "try"


## The tray the bench offers now: Try it's own while trying.
func current_tray() -> Array[Dictionary]:
	if level == null:
		return []
	return level.try_tray if trying() else level.tray


## Try it's live values: [{label, text}] such as "LED: 13.8 mA".
func readouts() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if level == null:
		return out
	for r in level.readouts:
		out.append({"part": r["part"], "text": Readouts.text(r, outcome.circuit, outcome.result)})
	return out


## Every phase change goes through here: leaving the deck or Try it marks it
## seen, and Try it's circuit comes out (and goes away) with its phase.
func _entered(was: String) -> void:
	var phase := session.phase
	if was == phase:
		return
	if was == "learn":
		progress.mark_lesson(level.id, "learn", now())
	if was == "try":
		progress.mark_lesson(level.id, "try", now())
		_put_build_back()
	if phase == "try":
		_put_try_out()


func _put_try_out() -> void:
	if _build_history == null:
		_build_history = history
		_build_outcome = outcome
	_end_preview()
	outcome = Simulator.simulate(level.try_circuit.copy())
	history = CircuitHistory.new(outcome.circuit)
	_circuit_changed()


func _put_build_back() -> void:
	if _build_history == null:
		return
	_end_preview()
	history = _build_history
	outcome = _build_outcome
	_build_history = null
	_build_outcome = null
	_circuit_changed()


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
		# The chapter's lessons: Lesson 0 is a tour of the controls, and a
		# v0.2.0 player who never saw it has still finished every lesson.
		for id in Levels.chapter_ids("ch1"):
			if Levels.by_id(id).kind != "tutorial":
				_ch1_ids.append(id)
	for id in Achievements.newly_earned(progress, _ch1_ids):
		progress.achievements[id] = now
		events.append({"type": "badge", "id": id})


## How many parts from each tray item are on the board, by tray index.
func tray_used() -> Array[int]:
	var used: Array[int] = []
	if level == null:
		return used
	used.resize(current_tray().size())
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


## Try it's circuit is never saved: the draft is always the build's.
func _save_draft() -> void:
	if trying():
		return
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
