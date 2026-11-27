extends TestCase
## Try it on the level screen: the try panel takes the column's place with its
## prompt, the things to try (ticking as you do them), live readouts and "I'm
## ready to build"; the bench holds the try circuit until then.

var _dir := ""


func before_each() -> void:
	_dir = "user://test_try_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)


func after_each() -> void:
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


## A working loop to try: delete a wire (dark), then undo (lit). The build
## starts with the parts and no wires; it has a hint so Hint could show.
func _lesson() -> LevelDef:
	var b := LevelBuilder.new("t.try", "ch1", "Try")
	b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4).part("L1", "led", 6, 0, 90)
	b.goal({"kind": "led_lit", "part": "L1"})
	b.hint("Close the loop.")
	b.idea("One.")
	b.try_it("Break it, then fix it.")
	b.try_part("B1", "battery", -6, 0).try_part("R1", "resistor", -2, -4, 0, {"ohms": 220.0}).try_part("L1", "led", 6, 0, 90)
	b.try_wire("w1", "B1", "pos", "R1", "a").try_wire("w2", "R1", "b", "L1", "anode").try_wire("w3", "L1", "cathode", "B1", "neg")
	b.poke("Delete a wire.", {"kind": "led_dark", "part": "L1"})
	b.poke("Undo it.", {"kind": "led_lit", "part": "L1"})
	b.readout("L1", "mA")
	b.try_path_edit(func(c: Circuit) -> Circuit: return CircuitEdits.delete_wire(c, "w1"))
	return b.done()


func _screen() -> LevelScreen:
	var game := Game.new()
	add_to_tree(game)
	game.boot(_dir.path_join("progress.json"))
	game.state.progress.parts_seen = {"battery": 1, "resistor": 1, "led": 1}
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	game.state.start_level(_lesson())
	var screen: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
	screen.game = game
	host.add_child(screen)
	await wait_frames(3)
	game.skip_learn()
	await wait_frames(2)
	return screen


func test_try_panel_lists_pokes_and_readouts() -> void:
	var s := await _screen()
	assert_eq(s.game.state.session.phase, "try")
	assert_true(s.try_panel.is_visible_in_tree())
	assert_true("Break it, then fix it." in s.try_panel.prompt_text())
	assert_eq(s.try_panel.poke_rows(), [{"text": "Delete a wire.", "done": false}, {"text": "Undo it.", "done": false}])
	assert_eq(s.try_panel.readout_texts(), PackedStringArray(["LED: 13.8 mA"]))


func test_pokes_tick_as_you_go() -> void:
	var s := await _screen()
	s.game.commit(CircuitEdits.delete_wire(s.game.state.history.present, "w1"))
	await wait_frames(2)
	assert_eq(s.try_panel.poke_rows()[0]["done"], true)
	assert_eq(s.try_panel.readout_texts(), PackedStringArray(["LED: 0.0 mA"]))
	s.game.undo()
	await wait_frames(2)
	assert_eq(s.try_panel.poke_rows()[1]["done"], true)


func test_ready_goes_to_build() -> void:
	var s := await _screen()
	s.try_panel.ready_button().pressed.emit()
	await wait_frames(2)
	assert_eq(s.game.state.session.phase, "build")
	assert_false(s.try_panel.is_visible_in_tree())
	assert_true(s.goals.is_visible_in_tree())
	assert_eq(s.game.state.history.present.wires.size(), 0, "the build circuit is back")


func test_try_hides_goals_and_hints() -> void:
	var s := await _screen()
	assert_false(s.goals.is_visible_in_tree(), "the build's goals wait")
	assert_false(s.checklist.is_visible_in_tree())
	assert_false(s.hint_button.visible)
	assert_false(s.test_button.visible)
	assert_true(s.column_scroll.visible, "the column holds the try panel")


func test_start_over_in_try_resets_try_circuit() -> void:
	var s := await _screen()
	s.game.commit(CircuitEdits.delete_wire(s.game.state.history.present, "w2"))
	await wait_frames(1)
	s.top_bar.button("restart").pressed.emit()
	await wait_frames(2)
	assert_eq(s.game.state.session.phase, "try")
	assert_eq(s.game.state.history.present.wires.size(), 3)
