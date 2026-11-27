extends TestCase
## Lesson 0, your workbench: first in Chapter 1, a tour of the screen, then
## one step per control with a moving-hand demo; it can be skipped once.

const CONTROLS := ["did:placed", "did:moved", "did:rotated", "did:wired", "did:deleted", "did:undone",
		"did:zoomed", "did:panned", "datasheet:L1", "did:hint"]
const GESTURES := ["tap", "drag", "long_press", "pinch", "scroll", "key"]


func _l0() -> LevelDef:
	return Levels.by_id("ch1.workbench")


func test_lesson0_first_and_open() -> void:
	assert_eq(Levels.chapter_ids("ch1")[0], "ch1.workbench")
	assert_eq(_l0().kind, "tutorial")
	assert_eq(Levels.lesson_number("ch1.workbench"), 0)
	assert_eq(Levels.lesson_number("ch1.light-it-up"), 1)
	var p := Progress.defaults()
	var ids := Levels.chapter_ids("ch1")
	assert_true(p.is_unlocked("ch1.workbench", ids))
	assert_false(p.is_unlocked("ch1.light-it-up", ids), "Lesson 1 waits for Lesson 0")


func test_lesson0_steps_cover_every_control() -> void:
	var flags := []
	for st in _l0().steps:
		flags.append(str(st["check"].get("flag", "")))
	for c in CONTROLS:
		assert_true(c in flags, "no step for " + c)


func test_every_step_has_a_demo() -> void:
	for st in _l0().steps:
		var demo: Dictionary = st.get("demo", {})
		assert_true(str(demo.get("gesture", "")) in GESTURES, "%s: %s" % [st["text"], demo])
		assert_true(demo.has("from"), st["text"])


func test_lesson0_tour() -> void:
	var targets := []
	for c in _l0().learn:
		if c["type"] == "tour":
			targets.append(c["target"])
	# The top bar is three cards, one per group of buttons, each lit up in turn
	# (checkpoint S: seven buttons in one sentence taught none of them).
	assert_eq(targets, ["board", "tray", "battery", "map_button", "edit_buttons", "tool_buttons", "column", "hint"])


func test_lesson0_passes_when_every_step_is_done() -> void:
	var l := _l0()
	var flags := {}
	for st in l.steps:
		flags[st["check"]["flag"]] = true
	var out := Simulator.simulate(l.circuit)
	var ctx := {"circuit": out.circuit, "sim": out.result, "zoom_layer": "editor", "zoom_seen": {}, "ui_flags": flags}
	assert_true(Goals.evaluate_all(l.goals, ctx).all(func(r: Dictionary) -> bool: return r["pass"]))
	ctx["ui_flags"] = {}
	assert_false(Goals.evaluate_all(l.goals, ctx).all(func(r: Dictionary) -> bool: return r["pass"]), "not before")


## Checkpoint S: "metal dot" read as the board's holes, which look like black
## dots. A wire joins the metal ends of parts, and the copy says so.
func test_lesson0_says_what_a_wire_joins() -> void:
	var l := _l0()
	var texts := PackedStringArray()
	for st in l.steps:
		texts.append(str(st["text"]))
	texts.append_array(l.recap)
	for q in l.questions:
		texts.append(str(q["prompt"]))
		for ch in q["choices"]:
			texts.append(str(ch["text"]))
			texts.append(str(ch["why"]))
	for t in texts:
		assert_false("metal dot" in t or "posts" in t, t)
	var wire_step := ""
	for st in l.steps:
		if st["check"].get("flag", "") == "did:wired":
			wire_step = str(st["text"])
	assert_true("lead" in wire_step and "resistor" in wire_step, wire_step)
