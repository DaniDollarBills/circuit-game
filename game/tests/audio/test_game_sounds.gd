extends TestCase
## Spec §11: soft clicks and chimes for what happens, through the real Main.

var e2e: E2E
var _dir := ""


func before_each() -> void:
	_dir = "user://test_sounds_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)
	e2e = E2E.new(tree)


func after_each() -> void:
	await e2e.stop()
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _audio() -> Audio:
	return tree.get_first_node_in_group("audio") as Audio


func _level(id: String) -> LevelScreen:
	await e2e.start(_dir.path_join("progress.json"))
	e2e.game().open_level(id, true)
	await e2e.frames(4)
	var s := e2e.screen() as LevelScreen
	await e2e.skip_intro(s)
	return s


## The sounds played since `from` (an index into Audio.played).
func _since(from: int) -> Array[String]:
	return _audio().played.slice(from)


func test_placing_and_wiring_make_soft_clicks() -> void:
	var s := await _level("ch1.pop")
	var mark := _audio().played.size()
	var c := s.game.state.history.present.copy()
	c.parts.append(Part.make("R1", "resistor", 2, -4))
	s.game.commit(c)
	await e2e.frames(2)
	assert_true("place" in _since(mark), str(_since(mark)))
	mark = _audio().played.size()
	c = s.game.state.history.present.copy()
	c.wires.append(Wire.make("w9", "B1", "pos", "R1", "a"))
	s.game.commit(c)
	await e2e.frames(2)
	assert_true("connect" in _since(mark), str(_since(mark)))


func test_light_burn_and_pass_have_their_sounds() -> void:
	var s := await _level("ch1.light-it-up")
	var mark := _audio().played.size()
	s.game.commit(s.game.state.level.solution.copy())
	await e2e.frames(3)
	var heard := _since(mark)
	assert_true("light" in heard and "success" in heard, str(heard))
	var p := await _level("ch1.pop")
	mark = _audio().played.size()
	var c := p.game.state.level.circuit.copy()
	c.wires.append(Wire.make("w1", "B1", "pos", "L1", "anode"))
	c.wires.append(Wire.make("w2", "L1", "cathode", "B1", "neg"))
	p.game.commit(c)
	await e2e.frames(2)
	assert_true("pop" in _since(mark), str(_since(mark)))


func test_new_words_badges_and_tests_chime() -> void:
	var s := await _level("ch1.light-it-up")
	assert_true("word" in _audio().played, "a New word card chimes: %s" % [_audio().played])
	var mark := _audio().played.size()
	s.game.commit(s.game.state.level.solution.copy())
	await e2e.frames(3)
	assert_true("badge" in _since(mark), "the First Light badge: %s" % [_since(mark)])
	var both := await _level("ch1.both")
	mark = _audio().played.size()
	both.game.run_tests()
	await e2e.frames(2)
	assert_true("test_fail" in _since(mark), str(_since(mark)))
	both.game.commit(both.game.state.level.solution.copy())
	await e2e.frames(2)
	mark = _audio().played.size()
	both.game.run_tests()
	await e2e.frames(2)
	assert_true("test_pass" in _since(mark), str(_since(mark)))


func test_buttons_click() -> void:
	var s := await _level("ch1.pop")
	var mark := _audio().played.size()
	await e2e.click_control(s.top_bar.button("settings"))
	await e2e.frames(1)
	assert_true("click" in _since(mark), str(_since(mark)))


func test_sound_toggle_mid_level() -> void:
	var s := await _level("ch1.pop")
	s.game.set_setting("sound", false)
	await e2e.frames(1)
	var mark := _audio().played.size()
	var c := s.game.state.history.present.copy()
	c.parts.append(Part.make("R1", "resistor", 2, -4))
	s.game.commit(c)
	await e2e.click_control(s.top_bar.button("settings"))
	await e2e.frames(2)
	assert_eq(_since(mark), [] as Array[String], "Sound off: silent")
	assert_false(_audio().music_playing(), "and no music")
