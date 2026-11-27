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
## `themed` applies the game's theme first, as Main does.
func _screen(level_id: String, size := Vector2(1280, 720), settings := {}, game: Game = null, themed := false) -> LevelScreen:
	var host := Control.new()
	host.size = size
	if themed:
		host.theme = PastelTheme.build(bool(settings.get("night", false)))
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


func test_uses_goal_says_how_many() -> void:
	var c := Circuit.new()
	assert_eq(GoalsPanel.label_for({"kind": "uses", "part_kind": "switch", "min": 1}, c), "Use a switch")
	assert_eq(GoalsPanel.label_for({"kind": "uses", "part_kind": "switch", "min": 2}, c), "Use 2 switches")
	assert_eq(GoalsPanel.label_for({"kind": "uses", "part_kind": "resistor", "min": 3}, c), "Use 3 resistors")
	assert_eq(GoalsPanel.label_for({"kind": "uses", "part_kind": "switch", "max": 2}, c), "Use at most 2 switches")


## The real circuit's answer can be above or below the ideal one; the note
## must say which, with the voltage the resistor really gets.
func test_calculator_note_says_more_or_less_by_the_real_numbers() -> void:
	var s := await _screen("ch1.too-hot")
	await _skip_intro(s)
	var c := s.game.state.level.circuit.copy()
	c.parts.append(Part.make("R1", "resistor", -2, 0, 90, {"ohms": 47.0, "watts": 1.0}))
	c.wires.append(Wire.make("w1", "B1", "pos", "R1", "a"))
	c.wires.append(Wire.make("w2", "R1", "b", "B1", "neg"))
	s.game.commit(c)
	s.top_bar.button("calculator").pressed.emit()
	await wait_frames(1)
	assert_eq(s.formula.tab, "power")
	s.formula.field("r").text = "47"
	s.formula.field("v").text = "5.0"
	s.formula.calculate()
	var less := s.formula.steps_text()
	assert_true(less.contains("0.51 W: a little less") and less.contains("4.90 V across"), less)
	s.formula.field("v").text = "4.8"
	s.formula.calculate()
	var more := s.formula.steps_text()
	assert_true(more.contains("0.51 W: a little more") and more.contains("4.90 V across"), more)
	assert_false(more.contains("less"), more)


func test_trimmer_datasheet_has_no_color_code() -> void:
	var s := await _screen("ch1.push-and-flow")
	await _skip_intro(s)
	s.datasheet.open(s.game.state.outcome.circuit.find_part("R1"), true)
	await wait_frames(1)
	assert_false(s.datasheet._bands.visible, "a trimmer has no color bands")
	var plain := s.datasheet.row_texts()
	assert_true(Array(plain).any(func(t: String) -> bool: return t.contains("Cermet trimmer")), str(plain))
	s.datasheet.open(Part.make("R9", "resistor", 0, 0), false)
	assert_true(s.datasheet._bands.visible, "a fixed resistor still shows its bands")


func _press_at(s: Control, at: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at
	click.global_position = at
	s.get_viewport().push_input(click)
	var up := click.duplicate()
	up.pressed = false
	s.get_viewport().push_input(up)


## The part menu must always have a way out, even for a locked part whose
## Rotate and Delete are disabled.
func test_part_menu_closes_on_escape_outside_press_and_cancel() -> void:
	var s := await _screen("ch1.light-it-up")
	await _skip_intro(s)
	s.menu.open({"part": "B1"}, Vector2(200, 200))
	assert_true(s.menu.visible)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	s.get_viewport().push_input(esc)
	await wait_frames(1)
	assert_false(s.menu.visible, "Esc closes it")
	s.menu.open({"part": "B1"}, Vector2(200, 200))
	_press_at(s, Vector2(900, 600))
	await wait_frames(1)
	assert_false(s.menu.visible, "a press outside closes it")
	s.menu.open({"part": "B1"}, Vector2(200, 200))
	var picked := []
	s.menu.chosen.connect(func(a: String, _t: Dictionary) -> void: picked.append(a))
	s.menu.button("Cancel").pressed.emit()
	assert_false(s.menu.visible, "Cancel closes it")
	assert_eq(picked, [], "Cancel chooses nothing")
	# The runner's window is 64 × 64; make it big enough for the press to land.
	var root := s.get_tree().root
	var old := root.size
	var old_scale := root.content_scale_size
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i.ZERO
	s.menu.open({"part": "B1"}, Vector2(200, 200))
	await wait_frames(1)
	var inside := s.menu.button("Datasheet").get_global_rect().get_center()
	_press_at(s, inside)
	await wait_frames(1)
	root.size = old
	root.content_scale_size = old_scale
	assert_true(s.datasheet.visible, "a press on a row still works")


## Open popovers describe the circuit as it is now, not as it was when they
## opened.
func test_explain_popover_follows_the_circuit() -> void:
	var s := await _screen("ch1.push-and-flow")
	await _skip_intro(s)
	var o := s.game.state.outcome
	s.explain.open(o.circuit.find_part("R1"), o.result, Vector2(300, 300))
	assert_true("\n".join(s.explain.line_texts()).contains("1 kΩ"), "\n".join(s.explain.line_texts()))
	var c := s.game.state.history.present.copy()
	c.find_part("R1").props["ohms"] = 500.0
	s.game.commit(c)
	await wait_frames(2)
	var after := "\n".join(s.explain.line_texts())
	assert_true(after.contains("500 Ω") and not after.contains("1 kΩ"), after)
	c = s.game.state.history.present.copy()
	c.parts = c.parts.filter(func(p: Part) -> bool: return p.id != "R1")
	c.wires = c.wires.filter(func(w: Wire) -> bool: return w.a_part != "R1" and w.b_part != "R1")
	s.game.commit(c)
	await wait_frames(2)
	assert_false(s.explain.visible, "the part is gone, so its explanation closes")


func test_part_menu_closes_when_its_part_is_undone_away() -> void:
	var s := await _screen("ch1.pop")
	await _skip_intro(s)
	var c := s.game.state.history.present.copy()
	c.parts.append(Part.make("R1", "resistor", 2, -4))
	s.game.commit(c)
	await wait_frames(2)
	s.menu.open({"part": "R1"}, Vector2(200, 200))
	assert_true(s.menu.visible)
	s.game.undo()
	await wait_frames(2)
	assert_false(s.menu.visible, "R1 is gone")


## Review Focus 5: undo after damage leaves nothing about the burn behind.
func test_undo_after_a_burn_clears_pips_explanation_and_the_toast() -> void:
	var s := await _screen("ch1.pop")
	await _skip_intro(s)
	s.game.commit(_direct_led(s.game.state.level))
	await wait_frames(2)
	assert_true(s.guide.visible and s.guide.mood == "oops")
	assert_true("Pop! LED burned out." in s.toasts.texts())
	s.game.undo()
	await wait_frames(2)
	assert_false(s.guide.visible and s.guide.mood == "oops", s.guide.plain_text())
	assert_false("Pop! LED burned out." in s.toasts.texts(), str(s.toasts.texts()))
	s.game.redo()
	await wait_frames(2)
	assert_true(s.guide.visible and s.guide.mood == "oops", "redo brings the burn, and its help, back")


## Every visible control a finger can press that is under 44 × 44 px (spec
## §11), described for the failure message.
func _small_targets(root: Node, where: String) -> PackedStringArray:
	var out := PackedStringArray()
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		if not (c is BaseButton or c is LineEdit or c is Slider or c is SpinBox):
			continue
		if c.size.x < 44.0 or c.size.y < 44.0:
			var label := str(c.get("text")) if c.get("text") != null and str(c.get("text")) != "" else str(c.tooltip_text)
			out.append("%s: %s \"%s\" %s" % [where, c.get_class(), label, c.size])
	return out


func test_touch_targets_are_at_least_44_px() -> void:
	var small := PackedStringArray()
	for id in ["ch1.pop", "ch1.push-and-flow", "ch1.both"]:
		var s := await _screen(id, Vector2(1280, 720), {}, null, true)
		await _skip_intro(s)
		s.guide.show_line("Hello", "happy", "help")
		await wait_frames(2)
		small.append_array(_small_targets(s, id + " board"))
		s.guide.hide_bubble()
		var openers := {
			"datasheet": func() -> void: s.dev_show("datasheet:B1"),
			"calculator": func() -> void: s.dev_show("calculator"),
			"notebook": func() -> void: s.dev_show("notebook"),
			"settings": func() -> void: s.dev_show("settings"),
			"glossary": func() -> void: s.glossary_popup.open("voltage"),
			"menu": func() -> void: s.menu.open({"part": "B1"}, Vector2(300, 300)),
			"explain": func() -> void: s.explain.open(s.game.state.outcome.circuit.find_part("B1"), s.game.state.outcome.result, Vector2(300, 300)),
			"value": func() -> void: s.value_popover.open("B1", 1000.0, Vector2(300, 300)),
		}
		for name in openers:
			(openers[name] as Callable).call()
			await wait_frames(2)
			small.append_array(_small_targets(s, "%s %s" % [id, name]))
			for card in [s.datasheet, s.formula, s.notebook, s.settings_sheet, s.glossary_popup, s.explain, s.value_popover]:
				card.visible = false
			s.menu.close()
	assert_eq("\n".join(small), "")


func test_map_and_title_touch_targets_are_at_least_44_px() -> void:
	var game := _game({})
	var small := PackedStringArray()
	for path in ["res://src/screens/map_screen.tscn", "res://src/screens/title_screen.tscn"]:
		var host := Control.new()
		host.size = Vector2(1280, 720)
		host.theme = PastelTheme.build()
		add_to_tree(host)
		var screen: Control = load(path).instantiate()
		screen.set("game", game)
		host.add_child(screen)
		await wait_frames(3)
		small.append_array(_small_targets(screen, path.get_file()))
	assert_eq("\n".join(small), "")


## The first opaque fill behind `c`: its own box (a button or text box), or
## the nearest panel. Null when only the 3D scene is behind it.
func _background(c: Control) -> Variant:
	var n: Node = c
	while n is Control:
		var k := n as Control
		var sb: StyleBox = null
		if k is Button and not (k as Button).flat:
			sb = k.get_theme_stylebox("disabled" if (k as Button).disabled else "normal")
		elif k is LineEdit:
			sb = k.get_theme_stylebox("normal")
		elif k is PanelContainer or k is Panel:
			sb = k.get_theme_stylebox("panel")
		elif k is Label:
			sb = k.get_theme_stylebox("normal")
		if sb is StyleBoxFlat and (sb as StyleBoxFlat).bg_color.a >= 0.9:
			return (sb as StyleBoxFlat).bg_color
		if k is ColorRect and (k as ColorRect).color.a >= 0.9:
			return (k as ColorRect).color
		n = k.get_parent()
	return null


## Text a reader can't make out (spec §11): main text under 7:1, secondary
## (ink_soft) text under 4.5:1, or text with nothing opaque behind it.
func _faint_text(root: Node, where: String) -> PackedStringArray:
	var out := PackedStringArray()
	var soft := [Palette.color("ink_soft"), Palette.color("ink_soft", true)]
	var tags := RegEx.create_from_string("\\[color=(#[0-9a-fA-F]{6,8})\\]")
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		var text := ""
		var colors: Array[Color] = []
		if c is Label:
			text = (c as Label).text
			colors.append(c.get_theme_color("font_color"))
		elif c is RichTextLabel:
			text = (c as RichTextLabel).get_parsed_text()
			colors.append(c.get_theme_color("default_color"))
			for m in tags.search_all((c as RichTextLabel).text):
				colors.append(Color(m.get_string(1)))
		elif c is Button:
			text = (c as Button).text
			colors.append(c.get_theme_color("font_disabled_color" if (c as Button).disabled else "font_color"))
		elif c is LineEdit:
			text = (c as LineEdit).text
			colors.append(c.get_theme_color("font_color"))
		if text.strip_edges() == "":
			continue
		var what := "%s: %s \"%s\"" % [where, c.get_class(), text.strip_edges().left(28)]
		var bg: Variant = _background(c)
		if bg == null:
			out.append(what + " has nothing behind it")
			continue
		for col in colors:
			var need := 4.5 if soft.any(func(s: Color) -> bool: return s.is_equal_approx(col)) else 7.0
			var ratio := Palette.contrast_ratio(col, bg)
			if ratio < need:
				out.append("%s %.2f:1 (needs %.1f)" % [what, ratio, need])
	return out


func test_hud_text_is_readable_by_day_and_night() -> void:
	var faint := PackedStringArray()
	# Day, night, and night switched on mid-level (the theme is rebuilt then).
	for mode in ["day", "night", "day to night"]:
		for id in ["ch1.pop", "ch1.both"]:
			var night: bool = mode != "day"
			var s := await _screen(id, Vector2(1280, 720), {"night": mode == "night"}, null, true)
			if mode == "day to night":
				s.game.set_setting("night", true)
				(s.get_parent() as Control).theme = PastelTheme.build(true)
			await _skip_intro(s)
			s.guide.show_line("Hello [[voltage]]", "happy", "help")
			await wait_frames(2)
			var tag := "%s %s" % [mode, id]
			faint.append_array(_faint_text(s, tag + " board"))
			s.guide.hide_bubble()
			for name in ["datasheet:B1", "calculator", "notebook", "badges", "settings"]:
				if name == "badges":
					s.dev_show("notebook")
					s.notebook.show_tab("badges")
				else:
					s.dev_show(name)
				await wait_frames(2)
				faint.append_array(_faint_text(s, "%s %s" % [tag, name]))
				for card in [s.datasheet, s.formula, s.notebook, s.settings_sheet]:
					card.visible = false
	var unique := {}
	for f in faint:
		unique[f] = true
	assert_eq("\n".join(unique.keys()), "")


## Zooming into a wire from any level shows the copper caption; its words are
## defined then, not before.
func test_copper_caption_defines_its_words_when_it_shows() -> void:
	var s := await _screen("ch1.pop")
	await _skip_intro(s)
	var words: PackedStringArray = GlossaryText.render(CopperLayer.CAPTION, {}, true, false)["new_terms"]
	assert_true("crystal lattice" in words, str(words))
	var seen := s.game.state.progress.seen_terms
	assert_false(seen.has("crystal lattice"), "not before the caption shows")
	s.game.state.set_zoom_layer("wire.copper")
	s.game.changed.emit()
	await wait_frames(2)
	assert_true(s.zoom_caption.visible)
	assert_true(s.zoom_caption is RichTextLabel and (s.zoom_caption as RichTextLabel).text.contains("[url=crystal lattice]"))
	for w in words:
		assert_true(seen.has(w), w)


func test_wire_layers_and_datasheet_follow_the_quality_setting() -> void:
	var s := await _screen("ch1.pop", Vector2(1280, 720), {"quality": "low"})
	await _skip_intro(s)
	assert_eq(s.closeup.quality, "low")
	assert_eq(s.copper.quality, "low")
	s.dev_show("datasheet:B1")
	await wait_frames(1)
	assert_eq(s.datasheet._viewport.msaa_3d, Viewport.MSAA_2X, "Low quality: 2× anti-aliasing")
	s.game.set_setting("quality", "high")
	await wait_frames(2)
	assert_eq(s.closeup.quality, "high")
	assert_eq(s.copper.quality, "high")


## A battery's or meter's part on the board is just its two header posts; the
## datasheet shows the real thing: the AA holder or the multimeter.
func test_datasheet_shows_the_holder_and_multimeters() -> void:
	var s := await _screen("ch1.push-and-flow")
	await _skip_intro(s)
	for pair in [["B1", "holder"], ["M1", "multimeter"], ["V1", "multimeter"], ["R1", "R1"]]:
		s.datasheet.open(s.game.state.outcome.circuit.find_part(pair[0]), true)
		await wait_frames(1)
		var shown: Array = s.datasheet._turntable.get_children().filter(func(n: Node) -> bool: return not n.is_queued_for_deletion())
		assert_eq(shown.size(), 1, pair[0])
		assert_eq(str((shown[0] as Node).name), pair[1], pair[0])


## The trimmer's definition says its rating is for the whole track; the
## game's simplification of that must be said, as for other parts.
func test_trimmer_go_deeper_explains_its_derating() -> void:
	var note := GoDeeper.for_part(Part.make("R1", "resistor", 0, 0, 0, {"ohms": 1000.0, "adjustable": true, "watts": 0.5}))
	assert_true(note.contains("whole track") and note.contains("0.025 W") and note.contains("The game"), note)
	assert_false(GoDeeper.for_part(Part.make("R2", "resistor", 0, 0)).contains("track"), "fixed resistors keep their own note")


## Each visible piece of text's font size, by node path.
func _text_sizes(root: Node) -> Dictionary:
	var out := {}
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		if c is Label and (c as Label).text.strip_edges() != "":
			out[root.get_path_to(c)] = c.get_theme_font_size("font_size")
		elif c is RichTextLabel and (c as RichTextLabel).get_parsed_text().strip_edges() != "":
			out[root.get_path_to(c)] = c.get_theme_font_size("normal_font_size")
		elif c is Button and (c as Button).text.strip_edges() != "":
			out[root.get_path_to(c)] = c.get_theme_font_size("font_size")
	return out


## Spec §11's large-text option: every piece of HUD text grows, not just the
## few that use the theme's default size.
func test_large_text_grows_every_hud_text() -> void:
	var s := await _screen("ch1.both", Vector2(1280, 720), {}, null, true)
	await _skip_intro(s)
	s.guide.show_line("Hello [[voltage]]", "happy", "help", [], "a source")
	s.dev_show("datasheet:B1")
	await wait_frames(2)
	var before := _text_sizes(s)
	assert_true(before.size() > 20, "found %d texts" % before.size())
	s.game.set_setting("large_text", true)
	# Main rebuilds the theme when the look changes.
	(s.get_parent() as Control).theme = PastelTheme.build(false, true)
	await wait_frames(2)
	var after := _text_sizes(s)
	var small := PackedStringArray()
	for path in before:
		if after.has(path) and float(after[path]) < float(before[path]) * 1.2 - 0.5:
			small.append("%s: %d → %d" % [str(path).get_file(), before[path], after[path]])
	assert_eq("\n".join(small), "")


func test_start_over_button_resets_the_board() -> void:
	var s := await _screen("ch1.pop")
	await _skip_intro(s)
	var c := s.game.state.history.present.copy()
	c.parts.append(Part.make("R1", "resistor", 2, -4))
	s.game.commit(c)
	await wait_frames(1)
	s.top_bar.button("restart").pressed.emit()
	await wait_frames(1)
	assert_eq(s.game.state.history.present.find_part("R1"), null)


## A hint pressed during the intro would be used up unseen.
func test_hint_waits_for_the_intro() -> void:
	var s := await _screen("ch1.pop")
	assert_eq(s.game.state.session.phase, "intro")
	assert_false(s.hint_button.visible, "no lightbulb while Pip introduces the level")
	await _skip_intro(s)
	assert_true(s.hint_button.visible)


## Dragging the trimmer's slider previews new values: the bench updates its
## readings in place instead of rebuilding its wires and equipment each step.
func test_slider_drag_rebuilds_the_bench_once() -> void:
	var s := await _screen("ch1.push-and-flow", Vector2(1280, 720), {"view_style": "physical"})
	await _skip_intro(s)
	await wait_frames(2)
	var bench := s.editor.workbench
	var wires := bench.wire_builds
	var rigs := bench.rig_builds
	for i in 10:
		s.value_popover.previewed.emit("R1", 200.0 + i * 150.0)
		await wait_frames(1)
	assert_true(bench.wire_builds - wires <= 1, "%d wire rebuilds" % (bench.wire_builds - wires))
	assert_true(bench.rig_builds - rigs <= 1, "%d equipment rebuilds" % (bench.rig_builds - rigs))


## Starting a solved level over is building it again: Pip's outro, which
## described the solved board, goes; solving it again is a new pass.
func test_start_over_after_passing_builds_again() -> void:
	var s := await _screen("ch1.light-it-up")
	await _skip_intro(s)
	s.game.commit(s.game.state.level.solution.copy())
	await wait_frames(2)
	assert_eq(s.game.state.session.phase, "passed")
	assert_eq(s.guide.kind, "outro")
	s.top_bar.button("restart").pressed.emit()
	await wait_frames(2)
	assert_eq(s.game.state.session.phase, "build")
	assert_false(s.guide.visible and s.guide.kind == "outro", "the outro no longer describes the board: " + s.guide.plain_text())
	s.game.commit(s.game.state.level.solution.copy())
	await wait_frames(2)
	assert_eq(s.game.state.session.phase, "passed")
	assert_eq(s.guide.kind, "outro", "solving it again celebrates again")
	assert_true(s.game.state.progress.completed.has("ch1.light-it-up"), "the completion stays recorded")
