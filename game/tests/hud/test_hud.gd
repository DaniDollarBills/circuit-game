extends TestCase

var _dir := ""


func before_each() -> void:
	_dir = "user://test_hud_%d_%d" % [Time.get_ticks_usec(), randi()]
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


## A LevelScreen for `level_id` inside a host of `size`, intro still showing.
func _screen(level_id: String, size := Vector2(1280, 720), settings := {}, game: Game = null) -> LevelScreen:
	var host := Control.new()
	host.size = size
	add_to_tree(host)
	if game == null:
		game = _game(settings)
	game.open_level(level_id, true)
	var screen: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
	screen.game = game
	host.add_child(screen)
	await wait_frames(3)
	return screen


func _skip_intro(s: LevelScreen) -> void:
	while s.game.state.session.phase == "intro":
		s.game.next_intro()
	await wait_frames(2)


func _tap(layer: EditorLayer, at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		layer._gui_input(e)


func _direct_led(level: LevelDef) -> Circuit:
	var c := level.circuit.copy()
	c.wires.append(Wire.make("w1", "B1", "pos", "L1", "anode"))
	c.wires.append(Wire.make("w2", "L1", "cathode", "B1", "neg"))
	return c


func test_tray_tap_then_board_tap_places_part() -> void:
	var s := await _screen("ch1.pop")
	await _skip_intro(s)
	s.tray.items()[2].pressed.emit()
	assert_eq(s.editor.controller.mode["kind"], "placing")
	_tap(s.editor, s.editor.grid_to_screen(Vector2(0, 5)))
	await wait_frames(2)
	var r := s.game.state.history.present.find_part("R1")
	assert_true(r != null and r.tray == 2, "the 150 Ω resistor from the tray is on the board")


func test_tray_drag_drops_part_on_board() -> void:
	var s := await _screen("ch1.pop")
	await _skip_intro(s)
	var at := s.editor.grid_to_screen(Vector2(0, 5))
	assert_true(s.editor._can_drop_data(at, {"tray": 3}))
	s.editor._drop_data(at, {"tray": 3})
	await wait_frames(2)
	var r := s.game.state.history.present.find_part("R1")
	assert_true(r != null and r.tray == 3 and Vector2i(r.x, r.y) == Vector2i(0, 5))


func test_tray_item_disabled_at_zero() -> void:
	var s := await _screen("ch1.pop")
	await _skip_intro(s)
	assert_false(s.tray.items()[2].disabled)
	s.game.commit(s.game.state.level.solution)
	await wait_frames(2)
	assert_true(s.tray.items()[2].disabled, "the only 150 Ω resistor is on the board")
	assert_false(s.tray.items()[3].disabled)


func test_hint_tiers_progress_and_tier3_shows_ghosts() -> void:
	var s := await _screen("ch1.light-it-up")
	await _skip_intro(s)
	s.hint_button.pressed.emit()
	await wait_frames(2)
	assert_eq(s.game.state.session.hint_tier, 1)
	assert_true(s.guide.visible and s.guide.plain_text().contains("Current leaves the battery's + end."))
	assert_true(s.editor.highlights.is_empty() and s.editor.ghosts.is_empty())
	s.hint_button.pressed.emit()
	await wait_frames(2)
	assert_eq(s.editor.highlights.size(), 2)
	s.hint_button.pressed.emit()
	await wait_frames(2)
	assert_eq((s.editor.ghosts.get("wires", []) as Array).size(), 3)


func test_ghost_tap_places_wire() -> void:
	var s := await _screen("ch1.light-it-up")
	await _skip_intro(s)
	for i in 3:
		s.hint_button.pressed.emit()
	await wait_frames(2)
	s.editor.ghost_tapped.emit("wire", s.editor.ghosts["wires"][0])
	await wait_frames(2)
	assert_eq(s.game.state.history.present.wires.size(), 1)
	assert_eq((s.editor.ghosts["wires"] as Array).size(), 2)


func test_replace_resets_burnt() -> void:
	var s := await _screen("ch1.pop")
	await _skip_intro(s)
	s.game.commit(_direct_led(s.game.state.level))
	s.game.commit(CircuitEdits.delete_wire(s.game.state.history.present, "w1"))
	await wait_frames(2)
	s.menu.open({"part": "B1"}, Vector2(300, 300))
	assert_false(s.menu.button("Replace").visible, "only burnt parts can be replaced")
	s.menu.open({"part": "L1"}, Vector2(300, 300))
	assert_true(s.menu.button("Replace").visible)
	s.menu.button("Replace").pressed.emit()
	await wait_frames(2)
	assert_false(s.game.state.history.present.find_part("L1").props.get("burnt", false))
	assert_false(s.menu.visible)


func test_value_slider_commits_on_release() -> void:
	var s := await _screen("ch1.push-and-flow")
	await _skip_intro(s)
	s.editor.value_requested.emit("R1")
	await wait_frames(1)
	assert_true(s.value_popover.visible)
	var before := float(s.game.state.history.present.find_part("R1").props["ohms"])
	s.value_popover.slider.drag_started.emit()
	s.value_popover.slider.value = 500
	assert_true(s.game.state.preview_circuit != null, "dragging previews")
	assert_eq(float(s.game.state.history.present.find_part("R1").props["ohms"]), before)
	assert_eq(s.value_popover.value_label.text, "500 Ω")
	s.value_popover.slider.drag_ended.emit(true)
	await wait_frames(1)
	assert_eq(float(s.game.state.history.present.find_part("R1").props["ohms"]), 500.0)
	assert_true(s.game.state.ui_flags.has("value:R1"))


func test_settings_toggle_persists_in_progress() -> void:
	var s := await _screen("ch1.light-it-up")
	s.top_bar.button("settings").pressed.emit()
	await wait_frames(1)
	assert_true(s.settings_sheet.visible)
	s.settings_sheet.toggle("night").button_pressed = true
	assert_eq(s.game.state.progress.settings["night"], true)
	s.settings_sheet.choice("help_level").select(1)
	s.settings_sheet.choice("help_level").item_selected.emit(1)
	assert_eq(s.game.state.progress.settings["help_level"], "light")
	s.game.save_now()
	var saved: Progress = ProgressStorage.load(_dir.path_join("progress.json"))["progress"]
	assert_eq(saved.settings["night"], true)
	assert_eq(saved.settings["help_level"], "light")


func test_portrait_layout_moves_tray_to_bottom() -> void:
	var wide := await _screen("ch1.pop", Vector2(1280, 720))
	var r := wide.tray.get_global_rect()
	assert_true(r.position.x < 40.0 and r.size.y > r.size.x, "landscape: a left column, got %s" % r)
	var tall := await _screen("ch1.pop", Vector2(390, 844))
	r = tall.tray.get_global_rect()
	assert_true(r.end.y > 844.0 - 40.0 and r.size.x > r.size.y, "portrait: a bottom strip, got %s" % r)


func test_checklist_visible_only_on_heavy() -> void:
	var s := await _screen("ch1.light-it-up")
	await _skip_intro(s)
	assert_true(s.checklist.visible)
	s.game.set_setting("help_level", "light")
	await wait_frames(2)
	assert_false(s.checklist.visible)
	s.game.set_setting("help_level", "off")
	await wait_frames(2)
	assert_false(s.checklist.visible)


func test_datasheet_card_rows_and_flag() -> void:
	var s := await _screen("ch1.pop")
	await _skip_intro(s)
	s.editor.datasheet_requested.emit("L1")
	await wait_frames(2)
	assert_true(s.datasheet.visible)
	var rows := s.datasheet.row_texts()
	assert_eq(rows.size(), 5)
	assert_true(rows[1].begins_with("Forward voltage") and rows[1].contains("2.0 V at 20 mA"), rows[1])
	assert_true(s.game.state.ui_flags.has("datasheet:L1"))
	s.datasheet.close()
	s.tray.info_buttons()[0].pressed.emit()
	await wait_frames(2)
	assert_true(s.datasheet.visible)
	assert_true(s.game.state.ui_flags.has("datasheet:tray"))


func test_formula_card_led_resistor_gives_150_and_sets_flag() -> void:
	var s := await _screen("ch1.pop")
	await _skip_intro(s)
	s.top_bar.button("calculator").pressed.emit()
	await wait_frames(1)
	assert_true(s.formula.visible)
	assert_eq(s.formula.tab, "led_resistor")
	assert_eq(s.formula.field("supply").text, "5.0")
	assert_eq(s.formula.field("led_v").text, "2.0")
	assert_eq(s.formula.field("led_a").text, "0.020")
	s.formula.calculate()
	await wait_frames(1)
	assert_true(s.formula.steps_text().contains("Nearest standard value at or above: 150 Ω"), s.formula.steps_text())
	assert_true(s.game.state.ui_flags.has("formula:led_resistor"))


func test_pip_explains_burn_on_heavy() -> void:
	var s := await _screen("ch1.pop")
	await _skip_intro(s)
	s.game.commit(_direct_led(s.game.state.level))
	await wait_frames(2)
	assert_true(s.guide.visible)
	assert_eq(s.guide.mood, "oops")
	assert_true(s.guide.plain_text().contains("burned out"), s.guide.plain_text())
	assert_true("Pop! LED burned out." in s.toasts.texts())
	var light := await _screen("ch1.pop", Vector2(1280, 720), {"help_level": "light"})
	await _skip_intro(light)
	light.game.commit(_direct_led(light.game.state.level))
	await wait_frames(2)
	assert_false(light.guide.visible, "Pip only steps in on Heavy help")
	assert_true("Pop! LED burned out." in light.toasts.texts())


func test_idle_offer_after_30s_on_heavy_only() -> void:
	var s := await _screen("ch1.light-it-up")
	await _skip_intro(s)
	s.idle_tick(29.0)
	assert_false(s.guide.visible)
	s.idle_tick(2.0)
	assert_true(s.guide.visible)
	assert_eq(s.guide.plain_text(), "Stuck? Tap the lightbulb and I'll help.")
	var light := await _screen("ch1.light-it-up", Vector2(1280, 720), {"help_level": "light"})
	await _skip_intro(light)
	light.idle_tick(31.0)
	assert_false(light.guide.visible)


func test_help_off_hides_hint_button() -> void:
	var s := await _screen("ch1.light-it-up")
	await _skip_intro(s)
	assert_true(s.hint_button.visible)
	s.game.set_setting("help_level", "light")
	await wait_frames(2)
	assert_true(s.hint_button.visible)
	s.game.set_setting("help_level", "off")
	await wait_frames(2)
	assert_false(s.hint_button.visible)


func test_explain_popover_lines() -> void:
	var s := await _screen("ch1.light-it-up")
	await _skip_intro(s)
	s.game.commit(s.game.state.level.solution)
	await wait_frames(2)
	s.menu.open({"part": "R1"}, Vector2(400, 300))
	s.menu.button("Explain").pressed.emit()
	await wait_frames(2)
	assert_true(s.explain.visible)
	var o := s.game.state.outcome
	assert_eq(s.explain.line_texts(), Explain.part(o.circuit.find_part("R1"), o.result))


func test_tapping_a_value_label_explains_its_part() -> void:
	var s := await _screen("ch1.light-it-up")
	await _skip_intro(s)
	s.game.commit(s.game.state.level.solution)
	await wait_frames(2)
	var spot: Dictionary = s.editor.value_label_spots().filter(func(l: Dictionary) -> bool: return l["text"].ends_with("mA"))[0]
	_tap(s.editor, spot["screen"])
	await wait_frames(2)
	assert_true(s.explain.visible)
	assert_eq(s.explain.part_id, spot["part"])


func test_new_word_card_on_first_sight_only() -> void:
	var game := _game()
	var first := await _screen("ch1.light-it-up", Vector2(1280, 720), {}, game)
	assert_true("electricity" in first.shown_word_terms())
	first.get_parent().remove_child(first)
	first.free()
	var again := await _screen("ch1.light-it-up", Vector2(1280, 720), {}, game)
	assert_eq(again.shown_word_terms(), PackedStringArray())


func test_new_word_cards_shown_with_help_off() -> void:
	var s := await _screen("ch1.light-it-up", Vector2(1280, 720), {"help_level": "off"})
	assert_true("electricity" in s.shown_word_terms())
	assert_true(s.visible_word_cards().size() <= 2, "at most two cards at once")


func test_notebook_lists_seen_words_in_order() -> void:
	var game := _game()
	game.state.progress.seen_terms = {"volt": 5, "current": 3, "led": 9}
	var s := await _screen("ch1.light-it-up", Vector2(1280, 720), {}, game)
	s.top_bar.button("notebook").pressed.emit()
	await wait_frames(1)
	assert_true(s.notebook.visible)
	var words := s.notebook.word_terms()
	assert_eq(words.slice(0, 3), PackedStringArray(["current", "volt", "led"]))
	s.notebook.show_tab("badges")
	assert_eq(s.notebook.badge_count(), Achievements.ALL.size())


func test_badge_toast_on_first_light() -> void:
	var s := await _screen("ch1.light-it-up")
	await _skip_intro(s)
	s.game.commit(s.game.state.level.solution)
	await wait_frames(2)
	assert_true("Badge earned: First Light" in s.toasts.texts(), str(s.toasts.texts()))
