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
	var bad_setting := Progress.defaults().to_dict()
	bad_setting["settings"]["help_level"] = 3
	assert_true(Progress.from_dict(bad_setting) == null)
	var bad_choice := Progress.defaults().to_dict()
	bad_choice["settings"]["view_style"] = "sketchy"
	assert_true(Progress.from_dict(bad_choice) == null)
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
