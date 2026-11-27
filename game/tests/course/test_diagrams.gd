extends TestCase
## The Learn cards' pictures: every diagram id makes a diagram that draws at a
## phone's size and a desktop's, holds still for Reduced motion, and lessons
## can only name diagrams that exist.

var _dir := ""


func before_each() -> void:
	_dir = "user://test_diagrams_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)


func after_each() -> void:
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _game(settings := {}) -> Game:
	var game := Game.new()
	add_to_tree(game)
	game.boot(_dir.path_join("progress.json"))
	for key in settings:
		game.set_setting(key, settings[key])
	return game


func _shown(id: String, game: Game, size: Vector2) -> Diagram:
	var host := Control.new()
	host.size = size
	add_to_tree(host)
	var d := Diagrams.make(id, game)
	host.add_child(d)
	d.size = size
	return d


func test_every_id_makes_a_diagram() -> void:
	var game := _game()
	assert_true(Diagrams.IDS.size() >= 5)
	for id in Diagrams.IDS:
		var d := Diagrams.make(id, game)
		assert_true(d != null and d is Diagram, id)
		if d != null:
			assert_eq(d.id, id)
			d.free()


func test_diagrams_draw_at_phone_and_desktop_sizes() -> void:
	var game := _game()
	for size in [Vector2(240, 132), Vector2(640, 352)]:
		for id in Diagrams.IDS:
			var d := _shown(id, game, size)
			await wait_frames(3)
			assert_true(d.painted > 0, "%s at %s" % [id, size])


func test_still_when_reduced_motion() -> void:
	var moving := _shown("loop_flow", _game(), Vector2(400, 220))
	var still := _shown("loop_flow", _game({"reduced_motion": true}), Vector2(400, 220))
	await wait_frames(6)
	assert_true(moving.t > 0.0, "sparks move")
	assert_true(still.still)
	assert_eq(still.t, 0.0, "a still frame for Reduced motion")
	assert_true(still.painted > 0)


func test_night_follows_the_setting() -> void:
	var d := _shown("loop_gap", _game({"night": true}), Vector2(400, 220))
	await wait_frames(2)
	assert_true(d.night)


func test_rules_flag_unknown_diagram() -> void:
	var b := LevelBuilder.new("t.pics", "ch1", "Pictures")
	b.goal({"kind": "no_damage"})
	b.idea("A loop.", "loop_flow").idea("No picture.").idea("A made-up one.", "no_such_diagram")
	b.control("Turn the dial.", "no_such_demo")
	assert_eq(LessonRules.problems(b.done()).size(), 2)


## Checkpoint S: the "gap" label (coral on the card) was too faint to read.
## Every word a picture draws keeps 4.5:1 against what it's drawn on (the
## card, or the shape under it), by day and by night.
func test_diagram_text_is_readable() -> void:
	for night in [false, true]:
		var game := _game({"night": night})
		for id in Diagrams.IDS:
			var d := _shown(id, game, Vector2(400, 220))
			await wait_frames(2)
			assert_false(d.text_log.is_empty(), id + " draws words")
			for entry in d.text_log:
				var r := Palette.contrast_ratio(entry[0], entry[1])
				assert_true(r >= 4.5, "%s (%s): '%s' %s on %s is %.2f:1" % [id, "night" if night else "day", entry[2],
						(entry[0] as Color).to_html(false), (entry[1] as Color).to_html(false), r])


## Code review (checkpoint S): a picture that moves charges faster than life
## says so (the spec's anti-goal: a sped-up animation that doesn't say so);
## its still frame for Reduced motion doesn't move, so it doesn't.
func test_sped_up_pictures_say_so() -> void:
	for id in ["charges_in_wire", "battery_push", "loop_flow", "current_direction", "aa_cell_inside", "meter_inside"]:
		for still in [false, true]:
			var d := _shown(id, _game({"reduced_motion": still}), Vector2(400, 220))
			await wait_frames(2)
			var words := d.text_log.map(func(e: Array) -> String: return str(e[2]))
			assert_eq("sped up" in words, not still, "%s%s: %s" % [id, " (still)" if still else "", words])


## Read-through: the 1 W resistor's datasheet says metal film, but its Look
## inside showed the ¼ W one's carbon film. It has its own cutaway.
func test_one_watt_resistor_inside_is_metal_film() -> void:
	var d := _shown(str(PartIntros.get_intro("resistor_1w")["inside"]), _game(), Vector2(400, 220))
	await wait_frames(2)
	var words := d.text_log.map(func(e: Array) -> String: return str(e[2]))
	assert_true("metal film, cut in a spiral" in words, str(words))
	assert_false("carbon film, cut in a spiral" in words, str(words))


## Read-through: the triangle's "V: volts   I: amps   R: ohms" mixed the
## letters up with units. Each letter has its quantity's name under it.
func test_ohm_triangle_names_each_letter() -> void:
	var d := _shown("ohm_triangle", _game({"reduced_motion": true}), Vector2(400, 220))
	await wait_frames(2)
	var words := d.text_log.map(func(e: Array) -> String: return str(e[2]))
	for w in ["voltage", "current", "resistance"]:
		assert_true(w in words, "%s: %s" % [w, words])
	assert_false("V: volts   I: amps   R: ohms" in words)


## Read-through: Lesson 2's graph said "I = (5 V − 2 V) ÷ R" a lesson before
## the letters are taught.
func test_led_graph_says_its_formula_in_words() -> void:
	var d := _shown("current_vs_resistance", _game(), Vector2(400, 220))
	await wait_frames(2)
	var words := d.text_log.map(func(e: Array) -> String: return str(e[2]))
	assert_true("current = (5 V − 2 V) ÷ resistance" in words, str(words))


## Final review: the water picture moved the water at one speed through the
## narrow pipe. The same amount passes every point each second (that's the
## current), so where the pipe narrows the water moves faster.
func test_water_speeds_up_in_the_narrow_pipe() -> void:
	var d := _shown("water_analogy", _game(), Vector2(400, 220))
	await wait_frames(1)
	var compared := false
	var time := 0.3
	while time < 6.0 and not compared:
		var a: PackedVector2Array = d.call("water_dots", time)
		var b: PackedVector2Array = d.call("water_dots", time + 0.02)
		var narrow := -1
		var wide := -1
		for i in a.size():
			if absf(a[i].y - 62.0) < 0.5 and absf(b[i].y - 62.0) < 0.5 and a[i].x > 176.0 and b[i].x < 244.0:
				narrow = i
			if absf(a[i].y - 166.0) < 0.5 and absf(b[i].y - 166.0) < 0.5 and a[i].x < 320.0 and b[i].x > 80.0:
				wide = i
		if narrow >= 0 and wide >= 0:
			compared = true
			var fast := a[narrow].distance_to(b[narrow])
			var slow := a[wide].distance_to(b[wide])
			assert_true(fast > 1.1 * slow, "at %.1f s: %.2f in the narrow pipe, %.2f in the wide one" % [time, fast, slow])
		time += 0.1
	assert_true(compared, "a moment with water in both the narrow and the wide pipe")


## Lessons 5 and 6: the truth table starts with every case unknown ("?"), and
## Try it fills each row with what the LED did as the player sees that case.
## Row n is switch A = n >> 1 and switch B = n & 1 (0 open, 1 closed).
func test_truth_table_fills_from_states() -> void:
	var d := _shown("truth_table", _game(), Vector2(400, 220))
	await wait_frames(2)
	assert_eq(d.call("results"), [-1, -1, -1, -1], "nothing seen yet")
	var words := d.text_log.map(func(e: Array) -> String: return str(e[2]))
	assert_eq(words.count("?"), 4, "each unknown LED shows ?: %s" % [words])
	d.call("mark", 3, true)
	d.call("mark", 0, false)
	assert_eq(d.call("results"), [0, -1, -1, 1])
	d.call("mark", 3, true)
	assert_eq(d.call("results"), [0, -1, -1, 1], "seeing a case again changes nothing")
	await wait_frames(2)
	words = d.text_log.map(func(e: Array) -> String: return str(e[2]))
	assert_eq(words.count("?"), 2, "two cases still to try: %s" % [words])
	assert_eq(d.call("row_of", false, true), 1)
	assert_eq(d.call("row_of", true, false), 2)


## Every moment of every picture draws cleanly: stepped through ten seconds
## of its motion at a phone's size and a desktop's. (A bar growing from
## nothing once drew a shape the renderer couldn't fill.)
func test_every_moment_draws_cleanly() -> void:
	var game := _game()
	for size in [Vector2(240, 132), Vector2(640, 352)]:
		for id in Diagrams.IDS:
			var d := _shown(id, game, size)
			for step in 41:
				d.t = step * 0.25
				d.queue_redraw()
				await wait_frames(1)
			d.get_parent().queue_free()
			await wait_frames(1)
