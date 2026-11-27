extends TestCase
## The Learn deck: a goals card, one idea per card, worked examples revealed a
## step at a time, Go deeper, sources, and Skip, plus the Lesson button that
## brings the deck back.

var _dir := ""


func before_each() -> void:
	_dir = "user://test_deck_%d_%d" % [Time.get_ticks_usec(), randi()]
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


## A lesson with one card of each teaching kind.
func _lesson() -> LevelDef:
	var b := LevelBuilder.new("t.deck", "ch1", "Deck")
	b.part("B1", "battery", -6, 0).goal({"kind": "no_damage"})
	b.learn_goals(["Why a loop", "What a resistor does"])
	b.idea("A loop needs no gaps.", "loop_flow", "curious", "The current is the same all the way round.")
	b.worked("Ohm's law, step by step.", ["I = V ÷ R", "I = 5 V ÷ 500 Ω", "I = 0.010 A = 10 mA"])
	b.analogy("A battery is like a pump.", "A cut wire spills nothing.", "battery_push")
	b.history("Volta made the first battery in 1800.", "A. Volta, Philosophical Transactions of the Royal Society 90, 403 (1800)")
	b.idea("A [[resistor]] limits the current.")
	return b.done()


func _deck(game: Game) -> LessonDeck:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	var deck := LessonDeck.new()
	deck.game = game
	host.add_child(deck)
	# Hidden until its host shows it, as the level screen does in "learn".
	deck.visible = true
	deck.size = Vector2(560, 480)
	return deck


func _screen(level_id: String, game: Game) -> LevelScreen:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	game.open_level(level_id, true)
	var screen: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
	screen.game = game
	host.add_child(screen)
	await wait_frames(3)
	return screen


func test_deck_opens_on_goals_card() -> void:
	var deck := _deck(_game())
	deck.show_card(_lesson(), 0)
	assert_eq(deck.card_kind(), "goals")
	assert_true("In this lesson you'll learn" in deck.body_text())
	assert_true("Why a loop" in deck.body_text() and "What a resistor does" in deck.body_text())
	assert_true(deck.back_button().disabled, "nothing before the first card")


func test_closing_card_names_what_comes_next() -> void:
	var deck := _deck(_game())
	var l := _lesson()
	deck.show_card(l, l.deck_size() - 1)
	assert_eq(deck.card_kind(), "closing")
	assert_true("build" in deck.body_text().to_lower(), "no Try it, so building comes next")


func test_worked_steps_reveal_one_per_next() -> void:
	var deck := _deck(_game())
	var nexts := [0]
	deck.next_pressed.connect(func() -> void: nexts[0] += 1)
	deck.show_card(_lesson(), 2)
	assert_eq(deck.card_kind(), "worked")
	assert_eq(deck.steps_shown(), 1)
	assert_false("I = 5 V ÷ 500 Ω" in deck.body_text())
	deck.next_button().pressed.emit()
	assert_eq(deck.steps_shown(), 2)
	assert_true("I = 5 V ÷ 500 Ω" in deck.body_text())
	deck.next_button().pressed.emit()
	assert_eq(deck.steps_shown(), 3)
	assert_eq(nexts[0], 0, "Next shows the next step before moving on")
	deck.next_button().pressed.emit()
	assert_eq(nexts[0], 1)


func test_analogy_shows_where_it_breaks() -> void:
	var deck := _deck(_game())
	deck.show_card(_lesson(), 3)
	assert_eq(deck.card_kind(), "analogy")
	assert_true("Where it breaks" in deck.body_text())
	assert_true("A cut wire spills nothing." in deck.body_text())


func test_go_deeper_toggles() -> void:
	var deck := _deck(_game())
	deck.show_card(_lesson(), 1)
	assert_true(deck.deeper_button().visible)
	assert_false("The current is the same all the way round." in deck.body_text())
	deck.deeper_button().pressed.emit()
	assert_true("The current is the same all the way round." in deck.body_text())
	deck.show_card(_lesson(), 3)
	assert_false(deck.deeper_button().visible, "no Go deeper on a card without one")


func test_history_shows_source() -> void:
	var deck := _deck(_game())
	deck.show_card(_lesson(), 4)
	assert_eq(deck.card_kind(), "history")
	assert_true("Source: A. Volta" in deck.body_text())


func test_card_shows_its_diagram() -> void:
	var deck := _deck(_game())
	deck.show_card(_lesson(), 1)
	await wait_frames(2)
	var d := deck.diagram()
	assert_true(d != null and d.id == "loop_flow" and d.is_visible_in_tree())
	deck.show_card(_lesson(), 5)
	assert_eq(deck.diagram(), null, "a card without a picture shows none")


func test_card_words_become_new_words() -> void:
	var game := _game()
	var deck := _deck(game)
	deck.show_card(_lesson(), 5)
	assert_true(game.state.progress.seen_terms.has("resistor"))


func test_next_and_back_walk_the_lesson() -> void:
	var game := _game()
	var s := await _screen("ch1.light-it-up", game)
	assert_eq(game.state.session.phase, "learn")
	assert_true(s.deck.visible)
	assert_false(s.guide.visible, "the deck, not Pip's bubble")
	assert_eq(s.deck.card_kind(), "goals")
	s.deck.next_button().pressed.emit()
	await wait_frames(2)
	assert_eq(game.state.session.card_index, 1)
	assert_eq(s.deck.card_kind(), "idea")
	s.deck.back_button().pressed.emit()
	await wait_frames(2)
	assert_eq(game.state.session.card_index, 0)


func test_skip_goes_to_try_or_build() -> void:
	var game := _game()
	var s := await _screen("ch1.light-it-up", game)
	s.deck.skip_button().pressed.emit()
	await wait_frames(2)
	assert_eq(game.state.session.phase, "try", "Lesson 1 has a Try it")
	assert_false(s.deck.visible)
	var game2 := _game()
	game2.state.progress.completed["ch1.workbench"] = {"star": false, "at": 1}
	var s2 := await _screen("ch1.workbench", game2)
	game2.reopen_lesson()
	await wait_frames(1)
	s2.deck.skip_button().pressed.emit()
	await wait_frames(2)
	assert_eq(game2.state.session.phase, "build", "Lesson 0 has none")


func test_lesson_button_reopens_deck() -> void:
	var game := _game()
	var s := await _screen("ch1.light-it-up", game)
	assert_false(s.lesson_button.visible, "not while the lesson is showing")
	s.deck.skip_button().pressed.emit()
	await wait_frames(2)
	assert_false(s.lesson_button.visible, "nor while trying")
	s.try_panel.ready_button().pressed.emit()
	await wait_frames(2)
	assert_true(s.lesson_button.visible)
	s.lesson_button.pressed.emit()
	await wait_frames(2)
	assert_eq(game.state.session.phase, "learn")
	assert_true(s.deck.visible)
	assert_eq(s.deck.card_kind(), "goals")


func test_lesson_has_the_stage_to_itself() -> void:
	var game := _game()
	var s := await _screen("ch1.pop", game)
	assert_eq(game.state.session.phase, "learn")
	assert_false(s.tray.visible, "the build's tray waits")
	assert_false(s.column_scroll.visible, "and so do its goals")
	s.deck.skip_button().pressed.emit()
	await wait_frames(2)
	assert_true(s.tray.visible)
	assert_true(s.column_scroll.visible)


## Checkpoint S: "Meet the led!" — the title keeps its capitals.
func test_meet_title_keeps_acronyms() -> void:
	var game := _game()
	var deck := _deck(game)
	var l := Levels.by_id("ch1.light-it-up")
	var titles := {}
	for i in l.learn.size():
		if l.learn[i]["type"] == "meet":
			deck.show_card(l, i + 1)
			titles[l.learn[i]["part"]] = deck.body_text().get_slice("\n", 0)
	assert_eq(titles["led"], "Meet the LED!")
	assert_eq(titles["battery"], "Meet the battery pack!")
	assert_eq(titles["resistor"], "Meet the resistor!")


## Checkpoint S: on a landscape phone the pictures were cut in half (the card
## is short, and the picture only showed by scrolling). Every picture shows
## whole, at a readable size, without scrolling, on every screen.
func test_pictures_whole_on_every_screen() -> void:
	for screen in [Vector2(844, 390), Vector2(640, 360), Vector2(390, 844), Vector2(1280, 720)]:
		var game := _game()
		var host := Control.new()
		host.size = screen
		add_to_tree(host)
		game.open_level("ch1.light-it-up", true)
		var s: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
		s.game = game
		host.add_child(s)
		await wait_frames(3)
		var l := game.state.level
		for i in l.learn.size():
			game.next_card()
			if str(l.learn[i].get("diagram", "")) == "" or l.learn[i]["type"] == "meet":
				continue
			await wait_frames(3)
			var d := s.deck.diagram()
			var where := "%s, card %d" % [screen, i + 1]
			assert_true(d != null and d.is_visible_in_tree(), where)
			var r := d.get_global_rect()
			assert_true(r.size.x >= 240.0 and r.size.y >= 132.0, "%s: readable, %s" % [where, r.size])
			assert_true(r.position.y >= s.deck.get_global_rect().position.y, where)
			assert_true(r.end.y <= s.deck.next_button().get_global_rect().position.y + 0.5,
					"%s: whole without scrolling, %s ends below %s" % [where, r, s.deck.next_button().get_global_rect().position.y])
		host.queue_free()
		await wait_frames(1)


## A source is a citation: its words aren't linked (Georg Ohm's name isn't
## the unit, the ohm).
func test_sources_are_not_linked() -> void:
	var game := _game()
	var deck := _deck(game)
	var l := Levels.by_id("ch1.push-and-flow")
	for i in l.learn.size():
		if l.learn[i]["type"] == "history":
			deck.show_card(l, i + 1)
	await wait_frames(1)
	var source := deck.find_children("*", "RichTextLabel", true, false).filter(
			func(n: Node) -> bool: return (n as RichTextLabel).visible and (n as RichTextLabel).get_parsed_text().begins_with("Source:"))
	assert_eq(source.size(), 1)
	assert_false("[url" in (source[0] as RichTextLabel).text, (source[0] as RichTextLabel).text)


## The lesson has the stage: Test waits for the build, like the tray.
func test_test_button_waits_for_the_build() -> void:
	var game := _game()
	var s := await _screen("ch1.on-and-off", game)
	assert_eq(game.state.session.phase, "learn")
	assert_false(s.test_button.visible, "no Test under the deck")
	game.skip_learn()
	game.finish_try()
	await wait_frames(2)
	assert_true(s.test_button.visible)
