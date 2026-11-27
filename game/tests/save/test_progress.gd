extends TestCase


func test_defaults_are_real_life_heavy_help() -> void:
	var p := Progress.defaults()
	assert_eq(p.settings["help_level"], "heavy")
	assert_eq(p.settings["view_style"], "physical")
	assert_eq(p.settings["show_values"], true)
	assert_eq(p.settings["show_current"], true)
	assert_eq(p.settings["quality"], "auto")
	for key in ["reduced_motion", "electron_flow", "large_text", "patterns", "night"]:
		assert_eq(p.settings[key], false, key)
	assert_eq(p.stats["parts_burnt"], 0)


func test_mark_terms_seen_returns_only_new() -> void:
	var p := Progress.defaults()
	assert_eq(p.mark_terms_seen(PackedStringArray(["current", "voltage"]), 100), PackedStringArray(["current", "voltage"]))
	assert_eq(p.mark_terms_seen(PackedStringArray(["voltage", "resistor", "resistor"]), 200), PackedStringArray(["resistor"]))
	assert_eq(p.seen_terms["voltage"], 100, "the first sighting is kept")
	assert_eq(p.seen_terms["resistor"], 200)


func test_progress_round_trip() -> void:
	var p := Progress.defaults()
	p.mark_complete("ch1.light-it-up", false, 1700000000)
	p.mark_complete("ch1.pop", true, 1700000100)
	p.drafts["ch1.pop"] = CircuitIO.to_dict(TestCircuits.compact_loop(150.0))
	p.settings["help_level"] = "light"
	p.stats["parts_burnt"] = 3
	p.mark_terms_seen(PackedStringArray(["current"]), 1700000200)
	p.achievements["first_light"] = 1700000000
	var back := Progress.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	assert_true(back != null)
	if back == null:
		return
	assert_eq(back.completed["ch1.pop"]["star"], true)
	assert_eq(back.completed["ch1.light-it-up"]["at"], 1700000000)
	assert_eq(typeof(back.completed["ch1.pop"]["at"]), TYPE_INT)
	assert_eq(back.settings["help_level"], "light")
	assert_eq(back.settings["view_style"], "physical")
	assert_eq(back.stats["parts_burnt"], 3)
	assert_eq(back.seen_terms["current"], 1700000200)
	assert_eq(back.achievements["first_light"], 1700000000)
	var draft := CircuitIO.from_dict(back.drafts["ch1.pop"])
	assert_true(draft != null)
	assert_eq(draft.find_part("R1").props["ohms"], 150.0)


func test_unknown_version_rejected() -> void:
	var d := Progress.defaults().to_dict()
	d["version"] = 2
	assert_true(Progress.from_dict(d) == null)
	var unversioned := Progress.defaults().to_dict()
	unversioned.erase("version")
	assert_true(Progress.from_dict(unversioned) == null)
	assert_true(Progress.from_dict("nope") == null)


func test_wrong_types_rejected() -> void:
	var bad_table := Progress.defaults().to_dict()
	bad_table["settings"] = "loud"
	assert_true(Progress.from_dict(bad_table) == null)
	var bad_entry := Progress.defaults().to_dict()
	bad_entry["completed"] = {"ch1.pop": {"star": "yes", "at": 1}}
	assert_true(Progress.from_dict(bad_entry) == null)


## A file from a build that had fewer settings still loads; the rest are defaults.
func test_missing_keys_take_defaults() -> void:
	var p := Progress.from_dict({"version": 1, "settings": {"night": true}})
	assert_true(p != null)
	if p == null:
		return
	assert_eq(p.settings["night"], true)
	assert_eq(p.settings["help_level"], "heavy")
	assert_eq(p.stats["parts_burnt"], 0)


func test_unlock_chain() -> void:
	var ids := PackedStringArray(["a", "b", "c"])
	var p := Progress.defaults()
	assert_true(p.is_unlocked("a", ids))
	assert_false(p.is_unlocked("b", ids))
	p.mark_complete("a", false, 1)
	assert_true(p.is_unlocked("b", ids))
	assert_false(p.is_unlocked("c", ids))
	assert_false(p.is_unlocked("zzz", ids))


func test_star_is_sticky() -> void:
	var p := Progress.defaults()
	p.mark_complete("ch1.pop", true, 10)
	p.mark_complete("ch1.pop", false, 20)
	assert_true(p.completed["ch1.pop"]["star"])
	p.mark_complete("ch1.both", false, 30)
	assert_false(p.completed["ch1.both"]["star"])
	p.mark_complete("ch1.both", true, 40)
	assert_true(p.completed["ch1.both"]["star"])


## Checkpoint B (M7): a setting this build can't use (a newer value, a wrong
## type) falls back to its default instead of throwing away all progress.
func test_bad_setting_values_take_defaults() -> void:
	var d := Progress.defaults().to_dict()
	d["completed"] = {"ch1.pop": {"star": true, "at": 5}}
	d["settings"]["help_level"] = 3
	d["settings"]["view_style"] = "sketchy"
	d["settings"]["night"] = true
	var p := Progress.from_dict(d)
	assert_true(p != null)
	if p == null:
		return
	assert_eq(p.settings["help_level"], "heavy")
	assert_eq(p.settings["view_style"], "physical")
	assert_eq(p.settings["night"], true)
	assert_true(p.completed.has("ch1.pop"))


func test_lessons_and_parts_round_trip() -> void:
	var p := Progress.defaults()
	p.mark_lesson("ch1.pop", "learn", 1700000000)
	p.mark_lesson("ch1.pop", "try", 1700000050)
	p.mark_lesson("ch1.pop", "learn", 1700000099)
	assert_true(p.mark_part_seen("led", 1700000010))
	assert_false(p.mark_part_seen("led", 1700000020), "met once")
	var back := Progress.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	assert_true(back != null)
	if back == null:
		return
	assert_eq(back.lesson_marks("ch1.pop"), {"learn": 1700000000, "try": 1700000050}, "the first time is kept")
	assert_eq(back.lesson_marks("ch1.both"), {})
	assert_eq(back.parts_seen, {"led": 1700000010})
	assert_eq(typeof(back.parts_seen["led"]), TYPE_INT)


func test_bad_lessons_table_rejected() -> void:
	var d := Progress.defaults().to_dict()
	d["lessons"] = {"ch1.pop": "yes"}
	assert_eq(Progress.from_dict(d), null, "a lesson entry must be a table")
	d["lessons"] = {"ch1.pop": {"learn": "soon"}}
	assert_eq(Progress.from_dict(d), null, "marks are times")
	d["lessons"] = {"ch1.pop": {"dance": 5}}
	assert_eq(Progress.from_dict(d), null, "only learn, try and recap")
	d["lessons"] = {}
	d["parts_seen"] = {"led": "now"}
	assert_eq(Progress.from_dict(d), null)


## Saved by v0.2.0: every Chapter 1 lesson done, no Lesson 0, no lesson marks.
func test_old_save_keeps_lessons_open() -> void:
	var old := {"version": 1, "completed": {}, "drafts": {}, "settings": {}, "stats": {}, "seen_terms": {}, "achievements": {}}
	var ids := PackedStringArray(["ch1.workbench", "ch1.light-it-up", "ch1.pop", "ch1.push-and-flow"])
	for id in ids.slice(1):
		old["completed"][id] = {"star": false, "at": 1700000000}
	var p := Progress.from_dict(old)
	assert_true(p != null)
	if p == null:
		return
	for id in ids:
		assert_true(p.is_unlocked(id, ids), id)
	assert_eq(p.lessons, {})
