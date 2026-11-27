extends TestCase
## Review Focus 3 and the course's accessibility: on the smallest phones,
## with Large text and Night, the deck (every card type), Meet the part, the
## try panel and the recap stay on screen, and every button is at least 44 px
## and can be reached, scrolling if need be. Help changed mid-lesson, Reduced
## motion, and the turntable sleeping while hidden.

const SMALL := [Vector2(360, 640), Vector2(640, 360)]
const HARD := {"large_text": true, "night": true}

var _dir := ""


func before_each() -> void:
	_dir = "user://test_course_fit_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)


func after_each() -> void:
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _game(settings := {}) -> Game:
	var game := Game.new()
	add_to_tree(game)
	game.boot(_dir.path_join("progress_%d.json" % randi()))
	for key in settings:
		game.set_setting(key, settings[key])
	return game


func _screen(level_id: String, size: Vector2, settings := {}) -> LevelScreen:
	var game := _game(settings)
	var host := Control.new()
	host.size = size
	host.theme = PastelTheme.build(bool(settings.get("night", false)), bool(settings.get("large_text", false)))
	add_to_tree(host)
	game.open_level(level_id, true)
	var s: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
	s.game = game
	host.add_child(s)
	await wait_frames(4)
	return s


func _done(s: LevelScreen) -> void:
	s.get_parent().queue_free()
	await wait_frames(1)


func _scroll_of(c: Control) -> ScrollContainer:
	var n := c.get_parent()
	while n != null:
		if n is ScrollContainer:
			return n
		n = n.get_parent()
	return null


## What's wrong with `card` on a screen of `size`: sticking out, or a visible
## button under it too small or out of reach (inside a scroll area it's
## scrolled to first).
func _problems(card: Control, size: Vector2, where: String) -> PackedStringArray:
	var out := PackedStringArray()
	var screen := Rect2(Vector2.ZERO, size).grow(0.5)
	# A card in a scroll area (the try panel in the column) may run past it;
	# its scroll area is checked instead.
	if _scroll_of(card) == null and not screen.encloses(card.get_global_rect()):
		out.append("%s: the card %s sticks out of %s" % [where, card.get_global_rect(), size])
	for n in card.find_children("*", "Button", true, false):
		var b := n as Button
		if not b.is_visible_in_tree():
			continue
		var name := b.text if b.text != "" else b.tooltip_text
		if b.size.y < IconButton.MIN_TOUCH - 0.5:
			out.append("%s: '%s' is %.0f px tall" % [where, name, b.size.y])
		var scroll := _scroll_of(b)
		var view := screen
		if scroll != null:
			scroll.ensure_control_visible(b)
			await wait_frames(1)
			# A pixel of rounding where the scroll stops.
			view = scroll.get_global_rect().grow(1.0).intersection(screen.grow(0.5))
		if not view.encloses(b.get_global_rect()):
			out.append("%s: '%s' at %s can't be reached (%s)" % [where, name, b.get_global_rect(), view])
	return out


func test_course_cards_fit_small_phone_deck() -> void:
	var problems := PackedStringArray()
	for size in SMALL:
		# Every card type: Lesson 3 has an analogy, a worked example, meet,
		# control and history cards; Lesson 2 a real-life one; Lesson 0 tours.
		for id in ["ch1.push-and-flow", "ch1.pop", "ch1.workbench"]:
			var s := await _screen(id, size, HARD)
			var l := s.game.state.level
			for i in l.deck_size():
				if i > 0:
					s.game.next_card()
				await wait_frames(2)
				if s.deck.visible:
					problems.append_array(await _problems(s.deck, size, "%s %s card %d" % [size, id, i]))
			await _done(s)
	assert_eq("\n".join(problems), "")


func test_course_cards_fit_small_phone_meet() -> void:
	var problems := PackedStringArray()
	for size in SMALL:
		var s := await _screen("ch1.light-it-up", size, HARD)
		s.game.skip_learn()
		s.game.finish_try()
		for key in PartIntros.KEYS:
			s.game.state.progress.mark_part_seen(key, 1)
		await wait_frames(2)
		for key in PartIntros.KEYS:
			s.dev_show("meet:" + key)
			await wait_frames(3)
			problems.append_array(await _problems(s.meet_card, size, "%s %s" % [size, key]))
			s.meet_card.close_button().pressed.emit()
			await wait_frames(2)
		await _done(s)
	assert_eq("\n".join(problems), "")


func test_course_cards_fit_small_phone_try() -> void:
	var problems := PackedStringArray()
	for size in SMALL:
		for id in ["ch1.push-and-flow", "ch1.both", "ch1.too-hot", "ch1.inside-the-wire"]:
			var s := await _screen(id, size, HARD)
			s.game.state.progress.parts_seen = {"battery": 1, "wire": 1, "resistor": 1, "resistor_1w": 1, "trimmer": 1,
					"led": 1, "switch": 1, "ammeter": 1, "voltmeter": 1}
			s.game.skip_learn()
			await wait_frames(3)
			assert_eq(s.column_scroll.scroll_vertical, 0, "%s %s: Try it opens on its prompt" % [size, id])
			problems.append_array(await _problems(s.try_panel, size, "%s %s" % [size, id]))
			var view := s.column_scroll.get_global_rect()
			if not Rect2(Vector2.ZERO, size).grow(0.5).encloses(view):
				problems.append("%s %s: the column %s sticks out" % [size, id, view])
			await _done(s)
	assert_eq("\n".join(problems), "")


func test_course_cards_fit_small_phone_recap() -> void:
	var problems := PackedStringArray()
	for size in SMALL:
		for id in ["ch1.light-it-up", "ch1.short-circuit", "ch1.too-hot"]:
			var s := await _screen(id, size, HARD)
			s.game.skip_learn()
			s.game.finish_try()
			s.game.state.progress.parts_seen = {"battery": 1, "wire": 1, "resistor": 1, "resistor_1w": 1, "led": 1}
			s.game.commit(s.game.state.level.solution.copy())
			await wait_frames(4)
			assert_true(s.recap.visible, "%s %s: the recap" % [size, id])
			problems.append_array(await _problems(s.recap, size, "%s %s" % [size, id]))
			await _done(s)
	assert_eq("\n".join(problems), "")


## Heavy to Off in the middle of the deck leaves the deck where it is, Skip
## still reaches the build, and at Off the Lesson button opens it again.
func test_help_change_mid_learn() -> void:
	var s := await _screen("ch1.light-it-up", Vector2(1280, 720))
	assert_eq(s.game.state.session.phase, "learn")
	s.game.next_card()
	s.game.set_setting("help_level", "off")
	await wait_frames(2)
	assert_true(s.deck.visible, "the lesson stays")
	assert_eq(s.game.state.session.card_index, 1, "on its card")
	s.deck.skip_button().pressed.emit()
	await wait_frames(2)
	assert_true(s.game.state.trying())
	s.try_panel.ready_button().pressed.emit()
	await wait_frames(2)
	assert_eq(s.game.state.session.phase, "build")
	assert_true(s.lesson_button.visible, "the Lesson button at help Off too")
	s.lesson_button.pressed.emit()
	await wait_frames(2)
	assert_eq(s.game.state.session.phase, "learn")
	assert_true(s.deck.visible)
	await _done(s)


## Reduced motion: every picture holds a still frame (and a picture already
## showing stops when the setting comes on), and the moving hand holds still
## with an arrow for a drag.
func test_reduced_motion_course() -> void:
	var game := _game({"reduced_motion": true})
	var host := Control.new()
	host.size = Vector2(400, 220)
	add_to_tree(host)
	for id in Diagrams.IDS:
		var d := Diagrams.make(id, game)
		host.add_child(d)
		d.size = host.size
		await wait_frames(3)
		assert_true(d.still and d.t == 0.0, id)
		d.queue_free()
	var other := _game()
	var moving := Diagrams.make("loop_flow", other)
	host.add_child(moving)
	await wait_frames(2)
	assert_false(moving.still)
	other.set_setting("reduced_motion", true)
	var t := moving.t
	await wait_frames(3)
	assert_true(moving.still and moving.t == t, "a showing picture stops when Reduced motion comes on")
	var s := await _screen("ch1.workbench", Vector2(1280, 720), {"reduced_motion": true})
	s.game.skip_learn()
	await wait_frames(3)
	assert_true(s.hand.playing() and s.hand.still)
	assert_eq(s.hand.gesture(), "drag", "Lesson 0's first step is a drag")
	var at := s.hand.hand_position()
	await wait_frames(10)
	assert_eq(s.hand.hand_position(), at, "the hand holds still, with its arrow to the drag's end")
	await _done(s)


## The turntable's viewport stops drawing while its card is hidden.
func test_turntable_sleeps_when_hidden() -> void:
	var game := _game()
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	var card := MeetPartCard.make(game, "led")
	host.add_child(card)
	card.visible = true
	await wait_frames(2)
	var vp := card.turntable_viewport()
	assert_true(vp.render_target_update_mode != SubViewport.UPDATE_DISABLED, "drawing while shown")
	card.visible = false
	await wait_frames(2)
	assert_eq(vp.render_target_update_mode, SubViewport.UPDATE_DISABLED)


## On a phone a New word card came up over the lesson card's picture. While a
## course card is up, New word cards go in the room above or below it.
func test_new_word_cards_keep_off_the_deck() -> void:
	var s := await _screen("ch1.pop", Vector2(390, 844))
	s.game.next_card()
	await wait_frames(30)
	var cards := s.visible_word_cards()
	assert_false(cards.is_empty(), "Lesson 2's first card brings new words")
	for c in cards:
		assert_false(c.get_global_rect().intersects(s.deck.get_global_rect()),
				"%s clear of the deck %s" % [c.get_global_rect(), s.deck.get_global_rect()])
	await _done(s)
