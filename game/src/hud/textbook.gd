class_name Textbook
extends Control
## Reading again from the Notebook: a lesson's Learn deck (read only, with its
## own place in the deck, so the lesson being played isn't touched) or a
## part's Meet the part card.

var game: Game
var deck: LessonDeck
var meet_card: MeetPartCard

var _level: LevelDef
var _index := 0


func _ready() -> void:
	name = "Textbook"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck = LessonDeck.new()
	deck.game = game
	deck.read_only = true
	add_child(deck)
	deck.next_pressed.connect(_next)
	deck.back_pressed.connect(_back)
	# Read again from the Notebook: Close on every card.
	deck.skip_pressed.connect(func() -> void: deck.visible = false)


func _process(_delta: float) -> void:
	var area := Rect2(12.0, 72.0, maxf(size.x - 24.0, 0.0), maxf(size.y - 84.0, 0.0))
	if deck.visible:
		deck.fit_into(area, LessonDeck.MAX_W)
	if meet_card != null and meet_card.visible:
		meet_card.fit_into(area, MeetPartCard.MAX_W)


func open_lesson(level_id: String) -> void:
	_level = Levels.by_id(level_id)
	if _level == null or _level.deck_size() == 0:
		return
	_index = 0
	deck.visible = true
	deck.show_card(_level, 0)


func open_part(key: String) -> void:
	if meet_card != null:
		remove_child(meet_card)
		meet_card.queue_free()
	meet_card = MeetPartCard.make(game, key)
	add_child(meet_card)
	meet_card.visible = true


## Escape puts away a lesson or part card read from the Notebook, as Back
## does on Android.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and close_top():
		get_viewport().set_input_as_handled()


## Closes whatever is open (Android's Back); false when nothing was.
func close_top() -> bool:
	if meet_card != null and meet_card.visible:
		meet_card.visible = false
		return true
	if deck.visible:
		deck.visible = false
		return true
	return false


func _next() -> void:
	if _index >= _level.deck_size() - 1:
		deck.visible = false
		return
	_index += 1
	deck.show_card(_level, _index)


func _back() -> void:
	_index = maxi(0, _index - 1)
	deck.show_card(_level, _index)
