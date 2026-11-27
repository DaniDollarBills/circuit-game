extends TestCase
## Meet the part: every Chapter 1 part has a card with its real 3D model on a
## turntable, its legs named, a cutaway to look inside, and it's shown once, at
## any help level, the first time the part appears.

var _dir := ""


func before_each() -> void:
	_dir = "user://test_meet_%d_%d" % [Time.get_ticks_usec(), randi()]
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


func _card(key: String, game: Game) -> MeetPartCard:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	var card := MeetPartCard.make(game, key)
	host.add_child(card)
	card.visible = true
	card.size = Vector2(420, 640)
	return card


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


## Every part a Chapter 1 lesson puts on the bench or in a tray.
func _ch1_parts() -> Array[Part]:
	var out: Array[Part] = []
	for l in Levels.all():
		for c in [l.circuit, l.solution, l.try_circuit]:
			out.append_array((c as Circuit).parts)
		for item in l.tray + l.try_tray:
			out.append(Part.make("T", item["kind"], 0, 0, 0, item["props"]))
	return out


func test_every_ch1_part_has_intro() -> void:
	for p in _ch1_parts():
		var key := PartIntros.key_for(p)
		var intro := PartIntros.get_intro(key)
		assert_false(intro.is_empty(), "%s (%s) has no intro" % [p.kind, key])
		var legs: Array = intro.get("legs", [])
		var pins := PackedStringArray(legs.map(func(g: Dictionary) -> String: return g["pin"]))
		pins.sort()
		var want := Catalog.pin_names(p.kind)
		want.sort()
		assert_eq(pins, want, "%s: one leg line per pin" % key)


func test_key_for_resistor_kinds() -> void:
	assert_eq(PartIntros.key_for(Part.make("R", "resistor", 0, 0)), "resistor")
	assert_eq(PartIntros.key_for(Part.make("R", "resistor", 0, 0, 0, {"watts": 1.0})), "resistor_1w")
	assert_eq(PartIntros.key_for(Part.make("R", "resistor", 0, 0, 0, {"adjustable": true, "watts": 0.5})), "trimmer")
	assert_eq(PartIntros.key_for(Part.make("M", "ammeter", 0, 0)), "ammeter")


func test_every_intro_is_complete() -> void:
	for key in PartIntros.KEYS:
		var intro := PartIntros.get_intro(key)
		for field in ["title", "does", "where", "inside"]:
			assert_true(str(intro.get(field, "")) != "", "%s: no %s" % [key, field])
		assert_true(Diagrams.has(str(intro["inside"])), "%s: no cutaway %s" % [key, intro["inside"]])
		var spec: Dictionary = intro.get("spec", {})
		assert_true(str(spec.get("text", "")) != "" and str(spec.get("source", "")) != "", "%s: a spec with its source" % key)


func test_meet_card_shows_model_and_legs() -> void:
	var card := _card("led", _game())
	await wait_frames(3)
	assert_true(card.model() != null, "the real 3D LED is on the turntable")
	assert_eq(card.leg_label_texts(), PackedStringArray(["+ (anode)", "− (cathode)"]))
	assert_true("glows" in card.body_text())


## Checkpoint S: the card read as a wall of numbers and citations. The card
## says what the part does, which leg is which and where you'd find one; its
## datasheet number and source wait under Go deeper.
func test_numbers_and_sources_wait_in_go_deeper() -> void:
	var card := _card("battery", _game())
	await wait_frames(2)
	var spec: Dictionary = PartIntros.get_intro("battery")["spec"]
	assert_false("Source" in card.body_text(), card.body_text())
	assert_false(GlossaryText.plain(str(spec["text"])) in card.body_text(), card.body_text())
	assert_eq(card.deeper_text(), "", "hidden until asked for")
	card.deeper_button().button_pressed = true
	card.deeper_button().pressed.emit()
	await wait_frames(1)
	assert_true(GlossaryText.plain(str(spec["text"])) in card.deeper_text(), card.deeper_text())
	assert_true("Source: " + str(spec["source"]) in card.deeper_text(), card.deeper_text())


## Checkpoint S: "Short leg … the flat edge", but both legs looked the same.
## The card's LED is a new one, legs uncut: the + leg is the longer one, as on
## a real 5 mm LED.
func test_led_card_shows_the_long_leg() -> void:
	var card := _card("led", _game())
	await wait_frames(2)
	var bottom := func(leg: String) -> float:
		var mi := card.model().find_child("lead_" + leg, true, false) as MeshInstance3D
		return (mi.global_transform * mi.get_aabb()).position.y
	var anode: float = bottom.call("anode")
	var cathode: float = bottom.call("cathode")
	assert_true(cathode - anode >= PartDims.mm(1.5), "the anode reaches lower: %.3f vs %.3f" % [anode, cathode])
	assert_true(cathode - anode <= PartDims.mm(3.0), "by a couple of millimeters, not more")
	var length: float = (card.model().find_child("lead_cathode", true, false) as MeshInstance3D).get_aabb().size.y
	assert_true(length >= PartDims.mm(20.0), "legs as long as a new LED's: %.3f" % length)


func test_spin_turns_the_part() -> void:
	var card := _card("resistor", _game())
	await wait_frames(2)
	var before := card.turn_degrees()
	card.spin(90.0)
	assert_near(card.turn_degrees(), before + 90.0, 0.01)


func test_look_inside_switches_to_cutaway() -> void:
	var card := _card("led", _game())
	await wait_frames(2)
	assert_false(card.showing_inside())
	card.look_inside(true)
	await wait_frames(1)
	assert_true(card.showing_inside())
	assert_eq(card.cutaway().id, "led_inside")
	assert_true(card.cutaway().is_visible_in_tree())
	card.look_inside(false)
	assert_false(card.showing_inside())


func test_unseen_parts_shown_once_any_help() -> void:
	var game := _game({"help_level": "off"})
	var s := await _screen("ch1.light-it-up", game)
	assert_eq(game.state.session.phase, "build")
	var met := PackedStringArray()
	for i in 6:
		if s.meet_card == null or not s.meet_card.visible:
			break
		met.append(s.meet_card.key)
		s.meet_card.close_button().pressed.emit()
		await wait_frames(2)
	met.sort()
	assert_eq(met, PackedStringArray(["battery", "led", "resistor"]), "the parts on Lesson 1's bench, once each")
	assert_true(game.state.progress.parts_seen.has("led"))
	s.get_parent().remove_child(s)
	s.free()
	var again := await _screen("ch1.light-it-up", game)
	assert_true(again.meet_card == null or not again.meet_card.visible, "met already")


func test_about_action_opens_card() -> void:
	var game := _game()
	game.state.progress.parts_seen = {"battery": 1, "resistor": 1, "led": 1}
	var s := await _screen("ch1.light-it-up", game)
	s.deck.skip_button().pressed.emit()
	await wait_frames(2)
	s.menu.chosen.emit("About", {"part": "R1"})
	await wait_frames(2)
	assert_true(s.meet_card != null and s.meet_card.visible)
	assert_eq(s.meet_card.key, "resistor")


func test_deck_meet_card_marks_part_seen() -> void:
	var game := _game()
	var b := LevelBuilder.new("t.meet", "ch1", "Meet")
	b.part("B1", "battery", -6, 0).goal({"kind": "no_damage"})
	b.meet("switch")
	var l := b.done()
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	var deck := LessonDeck.new()
	deck.game = game
	host.add_child(deck)
	deck.visible = true
	deck.show_card(l, 1)
	await wait_frames(2)
	assert_eq(deck.card_kind(), "meet")
	assert_true(deck.meet_card() != null and deck.meet_card().key == "switch")
	assert_true(game.state.progress.parts_seen.has("switch"))


func test_rules_flag_unknown_part_key() -> void:
	var b := LevelBuilder.new("t.parts", "ch1", "Parts")
	b.goal({"kind": "no_damage"})
	b.meet("led").meet("flux_capacitor")
	assert_eq(LessonRules.problems(b.done()).size(), 1)


## Code review (checkpoint S, critical): on a landscape phone, or a small one
## with Large text, the Meet the part card grew past the screen and its close
## button went off the top, trapping the player. The card stays inside the
## screen below the top bar, its close button shows, Go deeper can be scrolled
## to, and it closes.
func test_meet_card_fits_and_closes_on_every_screen() -> void:
	for case in [[Vector2(844, 390), false], [Vector2(640, 360), false], [Vector2(360, 640), true],
			[Vector2(360, 640), false], [Vector2(1280, 720), true]]:
		var size: Vector2 = case[0]
		var large: bool = case[1]
		var game := _game({"large_text": large})
		var host := Control.new()
		host.size = size
		host.theme = PastelTheme.build(false, large)
		add_to_tree(host)
		game.open_level("ch1.light-it-up", true)
		game.skip_learn()
		game.finish_try()
		var s: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
		s.game = game
		host.add_child(s)
		await wait_frames(4)
		var card := s.meet_card
		var where := "%s%s" % [size, " large" if large else ""]
		assert_true(card != null and card.visible, where + ": the battery card shows on Build")
		if card == null:
			host.queue_free()
			continue
		var bar_end := s.top_bar.get_global_rect().end.y
		var room := Rect2(0, bar_end, size.x, size.y - bar_end)
		assert_true(room.grow(0.5).encloses(card.get_global_rect()), "%s: %s inside %s" % [where, card.get_global_rect(), room])
		assert_true(Rect2(Vector2.ZERO, size).encloses(card.close_button().get_global_rect()), where + ": close on screen")
		card.body_scroll().ensure_control_visible(card.deeper_button())
		await wait_frames(2)
		assert_true(card.body_scroll().get_global_rect().grow(0.5).encloses(card.deeper_button().get_global_rect()),
				where + ": Go deeper scrolls into view")
		card.close_button().pressed.emit()
		await wait_frames(2)
		assert_true(not is_instance_valid(card) or not card.visible, where + ": and it closes")
		host.queue_free()
		await wait_frames(1)


## A word under Go deeper isn't met until Go deeper opens: the current
## meter's fuse (in its datasheet line) didn't wait, and its New word card
## covered the card.
func test_words_under_go_deeper_wait_until_opened() -> void:
	var game := _game()
	var card := _card("ammeter", game)
	await wait_frames(2)
	assert_false(game.state.progress.seen_terms.has("fuse"), "not met yet")
	card.deeper_button().button_pressed = true
	card.deeper_button().pressed.emit()
	await wait_frames(1)
	assert_true(game.state.progress.seen_terms.has("fuse"), "met when shown")


## "Power buttons" are buttons, not watts.
func test_switch_card_power_buttons_stay_plain() -> void:
	var where := str(PartIntros.get_intro("switch")["where"])
	assert_false("power" in GlossaryText.render(where, {})["terms"], where)
