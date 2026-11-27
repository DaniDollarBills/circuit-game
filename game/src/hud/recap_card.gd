class_name RecapCard
extends PanelContainer
## The Recap, after a pass: Pip's cheer, "What you learned" (with the player's
## own numbers), one or two quick questions where every answer is explained
## (no score, never required), the history, then Next lesson, Map or Read
## again. At Light or Off help the questions wait behind "Check yourself".

signal next_lesson
signal to_map
signal read_again
## "Back to my circuit": put the recap away to look at the bench.
signal put_away

const MAX_W := 560.0

var game: Game

var _level: LevelDef
var _pip: Pip
var _cheer: RichTextLabel
var _points: VBoxContainer
var _check: Button
var _questions: VBoxContainer
var _explanations: Array[RichTextLabel] = []
var _history: VBoxContainer
var _next: Button
var _map: Button
var _again: Button
var _back: Button
var _scroll: ScrollContainer


func _ready() -> void:
	name = "RecapCard"
	add_to_group("course_card")
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	add_child(col)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	_scroll.add_child(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	body.add_child(row)
	_pip = Pip.new()
	_pip.mood = "wow"
	_pip.custom_minimum_size = Vector2(56, 56)
	row.add_child(_pip)
	_cheer = HudText.label(game, 18)
	_cheer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_cheer)
	var learned := Label.new()
	learned.text = "What you learned"
	learned.theme_type_variation = "HeadingLabel"
	HudText.font_size(learned, 18, game)
	body.add_child(learned)
	_points = VBoxContainer.new()
	_points.add_theme_constant_override("separation", 6)
	body.add_child(_points)
	_check = Button.new()
	_check.text = "Check yourself"
	_check.theme_type_variation = "FlatButton"
	_check.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
	_check.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_check.pressed.connect(func() -> void: _questions.visible = true; _check.visible = false)
	body.add_child(_check)
	_questions = VBoxContainer.new()
	_questions.add_theme_constant_override("separation", 8)
	body.add_child(_questions)
	_history = VBoxContainer.new()
	_history.add_theme_constant_override("separation", 2)
	body.add_child(_history)
	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 8)
	buttons.add_theme_constant_override("v_separation", 8)
	col.add_child(buttons)
	_back = _button("Back to my circuit", func() -> void: put_away.emit(), true)
	buttons.add_child(_back)
	_again = _button("Read again", func() -> void: read_again.emit(), true)
	buttons.add_child(_again)
	_map = _button("Map", func() -> void: to_map.emit())
	buttons.add_child(_map)
	_next = _button("Next lesson", func() -> void: next_lesson.emit())
	buttons.add_child(_next)
	visible = false


func _button(text: String, on_press: Callable, flat := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
	if flat:
		b.theme_type_variation = "FlatButton"
	b.pressed.connect(on_press)
	return b


## Fills the card for `level`, passed with `outcome`; `next_id` is the next
## lesson ("" when there's none).
func show_recap(level: LevelDef, outcome: SimOutcome, next_id: String) -> void:
	_level = level
	var cheer := str(level.outro[0]["text"]) if not level.outro.is_empty() else "You did it!"
	HudText.put(_cheer, cheer, game)
	for c in _points.get_children() + _questions.get_children() + _history.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()
	_explanations.clear()
	for point in _point_sources(level):
		var l := HudText.label(game, 16)
		HudText.put(l, "• " + RecapText.fill(point, outcome.circuit, outcome.result), game)
		_points.add_child(l)
	for qi in level.questions.size():
		_add_question(qi, level.questions[qi])
	var light := str(game.state.progress.settings.get("help_level", "heavy")) != "heavy"
	_check.visible = light and not level.questions.is_empty()
	_questions.visible = not light and not level.questions.is_empty()
	for f in level.facts:
		var fact := HudText.label(game, 15)
		HudText.put(fact, str(f["text"]), game)
		_history.add_child(fact)
		var source := HudText.label(game, 12)
		HudText.put(source, "Source: " + str(f["source"]), game, false, false)
		_history.add_child(source)
	_history.visible = not level.facts.is_empty()
	_next.visible = next_id != ""
	_scroll.scroll_vertical = 0


## The recap's points, or until a lesson has its own, its outro lines after
## Pip's first (which is the cheer).
static func _point_sources(level: LevelDef) -> PackedStringArray:
	if not level.recap.is_empty():
		return level.recap
	var out := PackedStringArray()
	for i in range(1, level.outro.size()):
		out.append(str(level.outro[i]["text"]))
	return out


func _add_question(qi: int, q: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var prompt := HudText.label(game, 16)
	HudText.put(prompt, str(q["prompt"]), game, true)
	box.add_child(prompt)
	var choices := HFlowContainer.new()
	choices.add_theme_constant_override("h_separation", 8)
	choices.add_theme_constant_override("v_separation", 8)
	box.add_child(choices)
	var answers: Array = q["choices"]
	for ci in answers.size():
		var b := Button.new()
		b.text = str(answers[ci]["text"])
		b.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
		b.pressed.connect(choose.bind(qi, ci))
		choices.add_child(b)
	var why := HudText.label(game, 15)
	why.visible = false
	box.add_child(why)
	_explanations.append(why)
	_questions.add_child(box)


## Shows why choice `ci` of question `qi` is right or not. Choosing again is
## fine; nothing is scored or saved.
func choose(qi: int, ci: int) -> void:
	if _level == null or qi >= _level.questions.size():
		return
	var ch: Dictionary = _level.questions[qi]["choices"][ci]
	var lead := "Right! " if bool(ch["correct"]) else "Not quite. "
	HudText.put(_explanations[qi], lead + str(ch["why"]), game)
	_explanations[qi].visible = true


func explanation_text(qi: int) -> String:
	if qi >= _explanations.size() or not _explanations[qi].visible:
		return ""
	return _explanations[qi].get_parsed_text()


func point_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for l in _points.get_children():
		if not l.is_queued_for_deletion():
			out.append((l as RichTextLabel).get_parsed_text().trim_prefix("• "))
	return out


func cheer_text() -> String:
	return _cheer.get_parsed_text()


func history_text() -> String:
	var out := PackedStringArray()
	for l in _history.get_children():
		if not l.is_queued_for_deletion():
			out.append((l as RichTextLabel).get_parsed_text())
	return "\n".join(out) if _history.visible else ""


func questions_shown() -> bool:
	return _questions.visible


func next_button() -> Button:
	return _next


func back_button() -> Button:
	return _back


func map_button() -> Button:
	return _map


func again_button() -> Button:
	return _again


func check_button() -> Button:
	return _check


## Sizes the card to `width` (at most MAX_W) and its content's height (at
## most the area's; past that its body scrolls), centered in `area`.
func fit_into(area: Rect2, width: float) -> void:
	var w := minf(minf(width, MAX_W), area.size.x)
	size = Vector2(w, 0)
	var body := _scroll.get_child(0) as Control
	var pad := get_theme_stylebox("panel").get_minimum_size()
	var col := get_child(0) as VBoxContainer
	var fixed := col.get_combined_minimum_size().y - _scroll.get_combined_minimum_size().y
	size = Vector2(w, minf(fixed + body.get_combined_minimum_size().y + pad.y, area.size.y))
	position = (area.position + (area.size - size) / 2.0).round()
