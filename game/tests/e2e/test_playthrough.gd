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
	# A New word card slides in from the left edge, across the tray: let it
	# land (and clear it) before pressing the tray item, or the press hits it.
	var item: Control = s.tray.items()[tray_index]
	await e2e.clear_cards_at(s, [item.get_global_rect().get_center()])
	await e2e.click_control(item)
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
	assert_true(s.recap.visible, "the recap sums up the lesson")
	await e2e.click_control(s.recap.map_button())
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
	# The map introduces its own words (with New word cards).
	await e2e.frames(2)
	announced.append_array(Array(map.word_card_terms()))
	var s := await _open(map, 0)
	await _wire(s, ["B1", "pos"], ["R1", "a"])
	await _wire(s, ["R1", "b"], ["L1", "anode"])
	await _wire(s, ["L1", "cathode"], ["B1", "neg"])
	for i in 10:
		await e2e.frames(2)
		if s.recap.visible:
			break
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
	await e2e.click_control(s.recap.map_button())
	await e2e.frames(3)
	var back := e2e.screen() as MapScreen
	back.notebook.open()
	for t in seen:
		assert_true(t in back.notebook.word_terms(), "Notebook lists '%s'" % t)


## True inside a definition (New word card, definition popup, Notebook): its
## own words are plain text by design (Task 17).
func _in_definition(c: Node) -> bool:
	var n := c
	while n != null:
		if n.is_in_group("definitions"):
			return true
		n = n.get_parent()
	return false


## Glossary words in the visible text under `root` that the player hasn't met.
func _undefined_words(root: Node, where: String) -> PackedStringArray:
	var seen := e2e.game().state.progress.seen_terms
	var out := PackedStringArray()
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or _in_definition(c):
			continue
		var text := ""
		if c is Label:
			text = (c as Label).text
		elif c is RichTextLabel:
			# Glossary text is checked as the game renders it, from its source.
			text = str(c.get_meta("hud_src")) if c.has_meta("hud_src") else (c as RichTextLabel).get_parsed_text()
		elif c is Button:
			text = (c as Button).text
		if text.strip_edges() == "" or text == "Circuit":
			continue
		for t in GlossaryText.render(text, seen, true)["new_terms"]:
			out.append("%s: '%s' in \"%s\"" % [where, t, text.strip_edges().left(48)])
	return out


## The plan's rule, checked on what is really on screen: every glossary word
## the title, the map, each level and each card shows has been introduced.
func test_every_visible_word_is_defined() -> void:
	await e2e.start(_dir.path_join("progress.json"))
	var problems := PackedStringArray()
	var title := e2e.screen() as TitleScreen
	await e2e.frames(3)
	await e2e.click_control(title.find_child("Skip", true, false))
	await e2e.frames(3)
	problems.append_array(_undefined_words(title, "title"))
	title.get("_settings").call("open")
	await e2e.frames(3)
	problems.append_array(_undefined_words(title, "title settings"))
	title.get("_settings").set("visible", false)
	await e2e.click_control(title.find_child("Start", true, false))
	await e2e.frames(3)
	var map := e2e.screen() as MapScreen
	problems.append_array(_undefined_words(map, "map"))
	for id in Levels.chapter_ids("ch1"):
		e2e.game().open_level(id, true)
		await e2e.frames(4)
		var s := e2e.screen() as LevelScreen
		problems.append_array(_undefined_words(s, id + " intro"))
		await e2e.skip_intro(s)
		await e2e.frames(2)
		problems.append_array(_undefined_words(s, id))
		for card in ["datasheet:" + s.game.state.level.circuit.parts[0].id, "calculator", "settings"]:
			s.dev_show(card)
			await e2e.frames(3)
			problems.append_array(_undefined_words(s, "%s %s" % [id, card]))
			for c in [s.datasheet, s.formula, s.settings_sheet]:
				c.visible = false
	assert_eq("\n".join(problems), "")
