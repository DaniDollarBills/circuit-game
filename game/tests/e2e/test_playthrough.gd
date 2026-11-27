extends TestCase
## Whole-game playthroughs driven by real mouse input.

var _dir := ""
var e2e: E2E


func before_each() -> void:
	_dir = "user://test_e2e_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)
	e2e = E2E.new(tree)


func after_each() -> void:
	e2e.stop()
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _to_map() -> MapScreen:
	var title := e2e.screen() as TitleScreen
	await e2e.click_control(title.find_child("Skip", true, false))
	await e2e.click_control(title.find_child("Start", true, false))
	await e2e.frames(2)
	return e2e.screen() as MapScreen


func _open(map: MapScreen, index: int) -> LevelScreen:
	await e2e.click_control(map.level_buttons()[index])
	await e2e.frames(4)
	var s := e2e.screen() as LevelScreen
	await e2e.skip_intro(s)
	return s


func _wire(s: LevelScreen, a: Array, b: Array) -> void:
	var from := e2e.pin(s, a[0], a[1])
	var to := e2e.pin(s, b[0], b[1])
	await e2e.clear_cards_at(s, [from, to])
	await e2e.drag(from, to)
	await e2e.frames(2)


func _part_center(s: LevelScreen, id: String) -> Vector2:
	return e2e.part_top(s, id)


func _wire_mid(s: LevelScreen, id: String) -> Vector2:
	var c := s.game.state.history.present
	var path := CircuitGeometry.wire_path(c, c.find_wire(id))
	return e2e.grid(s, (path[0] + path[1]) / 2.0)


func _place(s: LevelScreen, tray_index: int, spot: Vector2) -> String:
	var before := s.game.state.history.present.parts.size()
	await e2e.click_control(s.tray.items()[tray_index])
	var at := e2e.grid(s, spot)
	await e2e.clear_cards_at(s, [at])
	await e2e.click(at)
	await e2e.frames(2)
	var parts := s.game.state.history.present.parts
	return parts[parts.size() - 1].id if parts.size() > before else ""


func test_play_l1_by_mouse() -> void:
	await e2e.start(_dir.path_join("progress.json"))
	var map := await _to_map()
	assert_true(map != null, "the title leads to the map")
	var s := await _open(map, 0)
	await _wire(s, ["B1", "pos"], ["R1", "a"])
	await _wire(s, ["R1", "b"], ["L1", "anode"])
	await _wire(s, ["L1", "cathode"], ["B1", "neg"])
	await e2e.frames(3)
	assert_eq(s.game.state.session.phase, "passed")
	assert_true(s.guide.visible and s.guide.kind == "outro", "Pip reads the outro")
	for i in 10:
		var m := E2E.find_button(s.guide, "Map")
		if m != null:
			await e2e.click_control(m)
			break
		await e2e.click_control(s.guide.action_buttons()[0])
	await e2e.frames(3)
	var back := e2e.screen() as MapScreen
	assert_true(back != null, "back on the map")
	if back != null:
		assert_false(back.level_buttons()[1].disabled, "L2 is open")


func test_play_l2_burn_and_replace() -> void:
	await e2e.start(_dir.path_join("progress.json"))
	e2e.game().state.progress.mark_complete("ch1.light-it-up", false, 1)
	var map := await _to_map()
	var s := await _open(map, 1)
	await _wire(s, ["B1", "pos"], ["L1", "anode"])
	await _wire(s, ["L1", "cathode"], ["B1", "neg"])
	assert_true(s.game.state.history.present.find_part("L1").props.get("burnt", false), "the LED pops")
	assert_true("Pop! LED burned out." in s.toasts.texts(), str(s.toasts.texts()))
	assert_true(s.guide.visible and s.guide.mood == "oops", "Pip explains")
	var shorting := s.game.state.history.present.wires_at("L1", "anode")[0].id
	await e2e.click(_wire_mid(s, shorting), MOUSE_BUTTON_RIGHT)
	await e2e.click_control(s.menu.button("Delete"))
	await e2e.long_press(_part_center(s, "L1"))
	assert_true(s.menu.visible and s.menu.button("Replace").visible, "a long press opens the menu")
	await e2e.click_control(s.menu.button("Replace"))
	assert_false(s.game.state.history.present.find_part("L1").props.get("burnt", false), "a new LED")
	await e2e.click(_part_center(s, "L1"))
	await e2e.frames(2)
	assert_true(s.datasheet.visible, "tapping the LED opens its datasheet")
	s.datasheet.close()
	await e2e.click_control(s.top_bar.button("calculator"))
	await e2e.click_control(E2E.find_button(s.formula, "Calculate"))
	s.formula.visible = false
	await e2e.frames(2)
	assert_true(s.game.state.session.step_results[0]["pass"] and s.game.state.session.step_results[1]["pass"], "steps 1 and 2 tick")
	var r := await _place(s, 2, Vector2(-2, -5))
	assert_true(r != "", "the 150 Ω resistor is placed")
	await _wire(s, ["B1", "pos"], [r, "a"])
	await _wire(s, [r, "b"], ["L1", "anode"])
	await e2e.frames(3)
	assert_eq(s.game.state.session.phase, "passed")
	assert_true(s.game.state.progress.completed["ch1.pop"]["star"], "18–20 mA earns the star")


func test_play_l8_power_rating() -> void:
	await e2e.start(_dir.path_join("progress.json"))
	for id in Levels.chapter_ids("ch1").slice(0, 7):
		e2e.game().state.progress.mark_complete(id, false, 1)
	var map := await _to_map()
	var s := await _open(map, 7)
	var weak := await _place(s, 0, Vector2(-2, 0))
	assert_true(weak != "")
	var turned := s.game.state.history.present.find_part(weak)
	await _wire(s, ["B1", "pos"], [weak, "a"])
	await _wire(s, [weak, "b"], ["B1", "neg"])
	assert_true(s.game.state.history.present.find_part(weak).props.get("burnt", false), "¼ W can't take 0.53 W")
	await e2e.long_press(_part_center(s, weak))
	await e2e.click_control(s.menu.button("Delete"))
	assert_eq(s.game.state.history.present.find_part(weak), null)
	var strong := await _place(s, 1, Vector2(-2, 0))
	assert_true(strong != "" and turned != null)
	await _wire(s, ["B1", "pos"], [strong, "a"])
	await _wire(s, [strong, "b"], ["B1", "neg"])
	await e2e.frames(3)
	assert_eq(s.game.state.session.phase, "passed", str(s.game.state.session.goal_results))


func test_every_word_defined_on_first_sight() -> void:
	await e2e.start(_dir.path_join("progress.json"))
	var title := e2e.screen() as TitleScreen
	await e2e.frames(3)
	await e2e.click_control(title.find_child("Skip", true, false))
	await e2e.frames(2)
	var announced := Array(title.shown_subtitles())
	await e2e.click_control(title.find_child("Start", true, false))
	await e2e.frames(2)
	var map := e2e.screen() as MapScreen
	var s := await _open(map, 0)
	await _wire(s, ["B1", "pos"], ["R1", "a"])
	await _wire(s, ["R1", "b"], ["L1", "anode"])
	await _wire(s, ["L1", "cathode"], ["B1", "neg"])
	for i in 10:
		await e2e.frames(2)
		if E2E.find_button(s.guide, "Map") != null:
			break
		await e2e.click_control(s.guide.action_buttons()[0])
	await e2e.frames(3)
	announced.append_array(Array(s.shown_word_terms()))
	var seen := e2e.game().state.progress.seen_terms.keys()
	var dupes := announced.filter(func(t: String) -> bool: return announced.count(t) > 1)
	assert_eq(dupes, [], "no word is introduced twice")
	for t in seen:
		assert_true(t in announced, "'%s' was seen but never defined" % t)
	for t in announced:
		assert_true(t in seen, "'%s' was defined but isn't in the Notebook" % t)
	assert_true(seen.size() >= 8, "%d words met" % seen.size())
	await e2e.click_control(E2E.find_button(s.guide, "Map"))
	await e2e.frames(3)
	var back := e2e.screen() as MapScreen
	back.notebook.open()
	for t in seen:
		assert_true(t in back.notebook.word_terms(), "Notebook lists '%s'" % t)
