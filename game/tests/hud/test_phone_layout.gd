extends TestCase
## Review Focus 4 and Checkpoint D (C2, I5): on a desktop window, a portrait
## phone and a landscape phone, everything the player needs is on screen:
## the column, the Test and Hint buttons, every card and its close button,
## the New word cards, and the title's Start button and settings.

const SIZES := [Vector2(1280, 720), Vector2(390, 844), Vector2(844, 390)]

var _dir := ""


func before_each() -> void:
	_dir = "user://test_phone_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)


func after_each() -> void:
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _game() -> Game:
	var game := Game.new()
	add_to_tree(game)
	game.boot(_dir.path_join("progress_%d.json" % randi()))
	return game


func _host(size: Vector2) -> Control:
	var host := Control.new()
	host.size = size
	host.theme = PastelTheme.build()
	add_to_tree(host)
	return host


func _level(id: String, size: Vector2) -> LevelScreen:
	var game := _game()
	game.open_level(id, true)
	while game.state.session.phase == "learn":
		game.skip_learn()
	var s: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
	s.game = game
	_host(size).add_child(s)
	await wait_frames(4)
	return s


## "" when `c` lies inside `area`, else what sticks out.
func _outside(c: Control, area: Rect2, what: String) -> String:
	var r := c.get_global_rect()
	if area.grow(0.5).encloses(r):
		return ""
	return "%s %s sticks out of %s" % [what, r, area]


func test_level_hud_fits_every_screen() -> void:
	var problems := PackedStringArray()
	for size in SIZES:
		for id in ["ch1.pop", "ch1.both"]:
			var s := await _level(id, size)
			var screen := Rect2(Vector2.ZERO, size)
			var tag := "%s %s" % [id, size]
			s.game.run_tests()
			# New word cards slide in; check where they come to rest.
			await tree.create_timer(NewWordCard.SLIDE_S + 0.1).timeout
			await wait_frames(2)
			for c in [s.hint_button, s.test_button] if id == "ch1.both" else [s.hint_button]:
				problems.append(_outside(c, screen, tag + " " + str(c.get("text"))))
			if id == "ch1.both":
				if s.test_button.get_global_rect().intersects(s.hint_button.get_global_rect()):
					problems.append(tag + " Test overlaps Hint")
				if s.column_area().intersects(s.test_button.get_global_rect()):
					problems.append(tag + " the column covers Test")
			problems.append(_outside(s.column_scroll, screen, tag + " column"))
			if s.column_area().intersects(s.hint_button.get_global_rect()):
				problems.append(tag + " the column covers Hint")
			for card in s.visible_word_cards():
				problems.append(_outside(card, s.editor.safe_rect, tag + " New word card"))
			for name in ["datasheet:B1", "calculator", "notebook", "settings", "glossary", "explain"]:
				match name:
					"glossary":
						s.glossary_popup.open("voltage")
						s._open_card(s.glossary_popup)
					"explain":
						s.explain.open(s.game.state.outcome.circuit.find_part("B1"), s.game.state.outcome.result, Vector2(size.x - 20, size.y - 20))
					_:
						s.dev_show(name)
				await wait_frames(3)
				for card in [s.datasheet, s.formula, s.notebook, s.settings_sheet, s.glossary_popup, s.explain]:
					if card.visible:
						problems.append(_outside(card, screen, "%s %s card" % [tag, name]))
						for b in card.find_children("*", "BaseButton", true, false):
							if (b as Control).is_visible_in_tree() and str((b as Control).tooltip_text) == "Close":
								problems.append(_outside(b, screen, "%s %s close button" % [tag, name]))
						card.visible = false
	assert_eq("\n".join(Array(problems).filter(func(p: String) -> bool: return p != "")), "")


func test_title_fits_every_screen() -> void:
	var problems := PackedStringArray()
	for size in SIZES:
		var game := _game()
		var t: Control = load("res://src/screens/title_screen.tscn").instantiate()
		t.set("game", game)
		_host(size).add_child(t)
		await wait_frames(3)
		(t.get("_skip") as Button).pressed.emit()
		await wait_frames(4)
		var screen := Rect2(Vector2.ZERO, size)
		var tag := str(size)
		problems.append(_outside(t.get("_start"), screen, tag + " Start"))
		problems.append(_outside(t.get("_bottom"), screen, tag + " caption block"))
		if (t.get("_scale_bar") as Control).get_global_rect().intersects((t.get("_bottom") as Control).get_global_rect()):
			problems.append(tag + " the scale bar covers the caption block")
		(t.get("_settings") as SettingsSheet).open()
		await wait_frames(3)
		problems.append(_outside(t.get("_settings"), screen, tag + " settings"))
	assert_eq("\n".join(Array(problems).filter(func(p: String) -> bool: return p != "")), "")


## Too narrow for the level title: its pill goes too, not just the words.
func test_narrow_top_bar_hides_the_title_pill() -> void:
	var s := await _level("ch1.pop", Vector2(390, 844))
	var pill := s.top_bar.find_child("TitlePill", true, false) as Control
	assert_true(pill != null)
	assert_false(pill.is_visible_in_tree(), "an empty pill would show as a blank white bar")


## The closest two pins of the board, in screen pixels.
func _closest_pins_px(s: LevelScreen) -> float:
	var pts: Array[Vector2] = []
	for p in s.game.state.history.present.parts:
		for pin in Catalog.pin_names(p.kind):
			pts.append(s.editor.pin_screen_pos(p.id, pin))
	var best := INF
	for i in pts.size():
		for j in range(i + 1, pts.size()):
			var d := pts[i].distance_to(pts[j])
			if d > 0.5:
				best = minf(best, d)
	return best


## Spec §11 (44 px touch targets) and §17 (phones are first-class): at the
## first framing on a phone, neighboring pins are at least a pick radius
## apart, so a tap resolves to the pin meant without pinching first. (The
## whole circuit must stay in view, which caps this near 23 px on a 390 px
## phone; the meters beside the board used to shrink it to 5 px.)
func test_phone_framing_keeps_pins_tappable() -> void:
	var report := PackedStringArray()
	var tight := PackedStringArray()
	for size in [Vector2(390, 844), Vector2(844, 390)]:
		for id in Levels.chapter_ids("ch1"):
			var s := await _level(id, size)
			await wait_frames(4)
			var px := _closest_pins_px(s)
			report.append("%s %s %.1f" % [id, size, px])
			if px < EditorLayer.PICK_PX:
				tight.append("%s at %s: pins %.1f px apart" % [id, size, px])
	assert_eq("\n".join(tight), "", ", ".join(report))


## On a portrait phone the column keeps the room it had: test results scroll
## inside it instead of spilling over the board.
func test_portrait_column_never_covers_the_board() -> void:
	var s := await _level("ch1.both", Vector2(390, 844))
	s.game.run_tests()
	await wait_frames(4)
	var board := s.editor.safe_rect
	assert_true(s.column_area().end.y <= board.position.y + 0.5, "column ends at %.0f, board starts at %.0f" % [s.column_area().end.y, board.position.y])
	assert_true(s.test_sheet.is_visible_in_tree())


## Spec §11 and §17: on common phones (360 to 390 px wide) every top-bar
## button is on screen and at least 44 px.
func test_top_bar_fits_phones() -> void:
	var problems := PackedStringArray()
	for size in [Vector2(360, 780), Vector2(375, 812), Vector2(390, 844)]:
		var s := await _level("ch1.pop", size)
		for id in ["map", "restart", "undo", "redo", "calculator", "notebook", "settings"]:
			var b := s.top_bar.button(id)
			problems.append(_outside(b, Rect2(Vector2.ZERO, size), "%s %s" % [size, id]))
			if b.size.x < 44.0 or b.size.y < 44.0:
				problems.append("%s %s is %s" % [size, id, b.size])
	assert_eq("\n".join(Array(problems).filter(func(p: String) -> bool: return p != "")), "")
