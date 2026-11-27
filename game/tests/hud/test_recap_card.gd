extends TestCase
## The Recap: Pip's cheer, what you learned with your own numbers, quick
## questions that explain every answer, the history, and the way on.

var _dir := ""


func before_each() -> void:
	_dir = "user://test_recap_%d_%d" % [Time.get_ticks_usec(), randi()]
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


## Lesson 1's parts and goal, with a recap that uses the player's numbers and
## one question.
func _lesson() -> LevelDef:
	var b := LevelBuilder.new("t.recap", "ch1", "Recap")
	b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4).part("L1", "led", 6, 0, 90)
	b.goal({"kind": "led_lit", "part": "L1"})
	b.outro("You made light!")
	b.recap("A loop lets current flow.").recap("Your LED ran at {L1.mA}.").recap("A resistor keeps it safe.")
	b.question("What happens if one wire is removed?", [
		{"text": "Everything stops.", "correct": true, "why": "A loop with a gap carries no current at all."},
		{"text": "The LED gets dimmer.", "correct": false, "why": "No: with a gap, no current flows anywhere."},
		{"text": "Only parts after the gap stop.", "correct": false, "why": "No: the current stops everywhere at once."},
	])
	b.fact("Volta made the first battery in 1800.", "A. Volta, Philosophical Transactions of the Royal Society 90, 403 (1800)")
	return b.done()


func _outcome(ohms: float) -> SimOutcome:
	var c := Levels.by_id("ch1.light-it-up").solution.copy()
	return Simulator.simulate(CircuitEdits.set_props(c, "R1", {"ohms": ohms}))


func _card(game: Game) -> RecapCard:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	var card := RecapCard.new()
	card.game = game
	host.add_child(card)
	card.visible = true
	return card


func test_recap_uses_players_numbers() -> void:
	var card := _card(_game())
	card.show_recap(_lesson(), _outcome(220.0), "")
	assert_eq(card.point_texts(), PackedStringArray(["A loop lets current flow.", "Your LED ran at 13.8 mA.", "A resistor keeps it safe."]))
	card.show_recap(_lesson(), _outcome(150.0), "")
	assert_eq(card.point_texts()[1], "Your LED ran at 19.9 mA.", "the player's circuit, not the solution's")


func test_choice_shows_why() -> void:
	var card := _card(_game())
	card.show_recap(_lesson(), _outcome(220.0), "")
	assert_eq(card.explanation_text(0), "")
	card.choose(0, 1)
	assert_true("Not quite" in card.explanation_text(0))
	assert_true("no current flows anywhere" in card.explanation_text(0))
	card.choose(0, 0)
	assert_true("Right" in card.explanation_text(0))
	assert_true("A loop with a gap carries no current at all." in card.explanation_text(0))


func test_recap_never_blocks() -> void:
	var card := _card(_game())
	card.show_recap(_lesson(), _outcome(220.0), "ch1.pop")
	assert_true(card.next_button().visible and not card.next_button().disabled, "no answers needed to go on")
	card.show_recap(_lesson(), _outcome(220.0), "")
	assert_false(card.next_button().visible, "no next lesson after the last")


func test_recap_shows_cheer_and_history() -> void:
	var card := _card(_game())
	card.show_recap(_lesson(), _outcome(220.0), "")
	assert_true("You made light!" in card.cheer_text())
	assert_true("Source: A. Volta" in card.history_text())
	assert_false("[" in card.history_text(), "no raw markup on screen: " + card.history_text())


func test_light_help_folds_questions() -> void:
	var card := _card(_game({"help_level": "light"}))
	card.show_recap(_lesson(), _outcome(220.0), "")
	assert_false(card.questions_shown())
	card.check_button().pressed.emit()
	assert_true(card.questions_shown())


func test_recap_shown_after_a_pass() -> void:
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
	game.state.progress.parts_seen = {"battery": 1, "resistor": 1, "led": 1}
	game.commit(game.state.level.solution.copy())
	await wait_frames(3)
	assert_eq(game.state.session.phase, "passed")
	assert_true(s.recap.visible)
	assert_true(game.state.progress.lesson_marks("ch1.light-it-up").has("recap"))
	s.recap.next_button().pressed.emit()
	await wait_frames(2)
	assert_eq(game.state.level.id, "ch1.pop", "Next lesson goes on")
