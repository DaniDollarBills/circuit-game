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
