extends TestCase
## Why? on the checklist's current step, and on Pip's mistake lines.

var _dir := ""


func before_each() -> void:
	_dir = "user://test_why_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)


func after_each() -> void:
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _game() -> Game:
	var game := Game.new()
	add_to_tree(game)
	game.boot(_dir.path_join("progress.json"))
	game.state.progress.parts_seen = {"battery": 1, "resistor": 1, "led": 1}
	return game


func test_checklist_why_toggle() -> void:
	var game := _game()
	var b := LevelBuilder.new("t.why", "ch1", "Why")
	b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4).part("L1", "led", 6, 0, 90)
	b.goal({"kind": "led_lit", "part": "L1"})
	b.step("Wire + to the resistor.", {"kind": "connected", "a": "B1:pos", "b": "R1:a"}).why("The push starts at +.")
	b.step("Close the loop.", {"kind": "led_lit", "part": "L1"})
	var level := b.done()
	var session := LevelSession.start(level, false)
	var host := Control.new()
	host.size = Vector2(400, 600)
	add_to_tree(host)
	var list := StepsChecklist.new()
	list.game = game
	host.add_child(list)
	list.refresh(level, session)
	assert_true(list.why_button() != null, "the current step has its why")
	assert_eq(list.why_text(), "")
	list.why_button().pressed.emit()
	assert_eq(list.why_text(), "The push starts at +.")
	list.why_button().pressed.emit()
	assert_eq(list.why_text(), "", "tap again to fold it")


func test_guide_why_expands() -> void:
	var game := _game()
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	game.open_level("ch1.pop", true)
	var s: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
	s.game = game
	host.add_child(s)
	await wait_frames(3)
	game.skip_learn()
	game.finish_try()
	var c := game.state.history.present
	c = CircuitEdits.add_wire(c, "B1", "pos", "L1", "anode")
	c = CircuitEdits.add_wire(c, "L1", "cathode", "B1", "neg")
	game.commit(c)
	await wait_frames(3)
	assert_true(s.guide.visible and s.guide.plain_text().begins_with("Pop!"), s.guide.plain_text())
	var why: Button = E2E.find_button(s.guide, "Why?")
	assert_true(why != null, "Pip's mistake line has a Why?")
	why.pressed.emit()
	await wait_frames(1)
	assert_true("30 mA" in s.guide.plain_text(), s.guide.plain_text())


## Code review (checkpoint S): build help leaked into Try it. After using the
## hints' ghost wires, reading the lesson again showed those ghosts over Try
## it's circuit; and a burn in Try it was explained with the build's old goals.
func test_build_help_stays_out_of_try_it() -> void:
	var game := _game()
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	game.open_level("ch1.light-it-up", true)
	var s: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
	s.game = game
	host.add_child(s)
	await wait_frames(3)
	game.skip_learn()
	game.finish_try()
	game.state.progress.parts_seen = {"battery": 1, "wire": 1, "resistor": 1, "led": 1}
	for i in 3:
		game.use_hint()
	await wait_frames(2)
	assert_false(s.hint_ghosts().is_empty(), "the third hint shows the answer's ghosts")
	# A short on the bench: the build's goals now say "Short circuit!".
	game.commit(CircuitEdits.add_wire(game.state.history.present, "B1", "pos", "B1", "neg"))
	await wait_frames(2)
	game.reopen_lesson()
	game.skip_learn()
	await wait_frames(3)
	assert_true(game.state.trying())
	assert_true(s.hint_ghosts().is_empty(), "no build ghosts over Try it's circuit")
	# Bypass the resistor: the LED burns, and Pip explains the LED.
	game.commit(CircuitEdits.add_wire(game.state.history.present, "B1", "pos", "L1", "anode"))
	await wait_frames(3)
	assert_true(s.guide.visible, "burn help")
	assert_false(s.guide.plain_text().begins_with("Short circuit"), s.guide.plain_text())
	assert_true("LED" in s.guide.plain_text(), s.guide.plain_text())


## Lesson 2's Try it burns the LED on purpose: Pip says what burned, with a
## Why? that gives the physics, as on the build.
func test_burn_in_try_it_has_a_why() -> void:
	var game := _game()
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	game.open_level("ch1.pop", true)
	var s: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
	s.game = game
	host.add_child(s)
	await wait_frames(3)
	game.skip_learn()
	assert_true(game.state.trying())
	var c := game.state.history.present
	c = CircuitEdits.add_wire(c, "B1", "pos", "L1", "anode")
	c = CircuitEdits.add_wire(c, "L1", "cathode", "B1", "neg")
	game.commit(c)
	await wait_frames(3)
	assert_true(s.guide.visible and "LED" in s.guide.plain_text(), s.guide.plain_text())
	var why: Button = E2E.find_button(s.guide, "Why?")
	assert_true(why != null, "a Why? in Try it too")
	if why != null:
		why.pressed.emit()
		await wait_frames(1)
		assert_true("30 mA" in s.guide.plain_text(), s.guide.plain_text())
