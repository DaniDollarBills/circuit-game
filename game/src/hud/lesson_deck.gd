class_name LessonDeck
extends PanelContainer
## The Learn deck: a lesson shown one card at a time, like the pages of a
## school book. A goals card first ("In this lesson you'll learn"), then one
## idea per card with its picture, then a closing card. A worked example shows
## one more step per Next. Back, Next and Skip lesson are always there; Go
## deeper and a source line show on the cards that have them.

signal next_pressed
signal back_pressed
signal skip_pressed

const MAX_W := 560.0

var game: Game
## The Notebook's mode: no Skip, and the closing card closes the deck.
var read_only := false

var _level: LevelDef
var _index := -1
var _key := ""
var _steps_shown := 0
var _deeper_open := false

var _title: Label
var _dots: _Dots
var _scroll: ScrollContainer
var _pip: Pip
var _text: RichTextLabel
var _picture: Control
var _diagram: Diagram
var _meet_holder: VBoxContainer
var _meet: MeetPartCard
var _breaks: RichTextLabel
var _steps: RichTextLabel
var _deeper_button: Button
var _deeper: RichTextLabel
var _source: RichTextLabel
var _back: Button
var _next: Button
var _skip: Button


## Progress dots: one per card, the current one filled.
class _Dots extends Control:
	var count := 0
	var current := 0
	var night := false

	func _draw() -> void:
		if count <= 0:
			return
		var r := clampf(size.y / 2.0 - 1.0, 2.0, 5.0)
		var gap := minf(r * 3.2, (size.x - 2.0 * r) / maxf(count - 1, 1))
		var x0 := size.x - r - gap * (count - 1)
		for i in count:
			var c := Vector2(x0 + gap * i, size.y / 2.0)
			if i == current:
				draw_circle(c, r, Palette.color("lavender", night), true, -1.0, true)
			else:
				draw_circle(c, r * 0.8, Palette.color("line", night), true, -1.0, true)


func _ready() -> void:
	name = "LessonDeck"
	add_to_group("course_card")
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	_title = Label.new()
	_title.theme_type_variation = "SoftLabel"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	HudText.font_size(_title, 14, game)
	head.add_child(_title)
	_dots = _Dots.new()
	_dots.custom_minimum_size = Vector2(120, 12)
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(_dots)
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
	_pip.custom_minimum_size = Vector2(56, 56)
	_pip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_pip)
	_text = HudText.label(game, 18)
	_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_text)
	_picture = Control.new()
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_picture)
	_meet_holder = VBoxContainer.new()
	body.add_child(_meet_holder)
	_breaks = HudText.label(game, 15)
	body.add_child(_breaks)
	_steps = HudText.label(game, 18)
	body.add_child(_steps)
	_deeper_button = Button.new()
	_deeper_button.text = "Go deeper"
	_deeper_button.theme_type_variation = "FlatButton"
	_deeper_button.flat = true
	_deeper_button.toggle_mode = true
	_deeper_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_deeper_button.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
	_deeper_button.pressed.connect(_toggle_deeper)
	body.add_child(_deeper_button)
	_deeper = HudText.label(game, 15)
	body.add_child(_deeper)
	_source = HudText.label(game, 13)
	body.add_child(_source)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	col.add_child(buttons)
	_skip = Button.new()
	_skip.text = "Skip lesson"
	_skip.theme_type_variation = "FlatButton"
	_skip.flat = true
	_skip.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
	_skip.pressed.connect(func() -> void: skip_pressed.emit())
	buttons.add_child(_skip)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	_back = Button.new()
	_back.text = "Back"
	_back.custom_minimum_size = Vector2(88, IconButton.MIN_TOUCH)
	_back.pressed.connect(func() -> void: back_pressed.emit())
	buttons.add_child(_back)
	_next = Button.new()
	_next.text = "Next"
	_next.custom_minimum_size = Vector2(104, IconButton.MIN_TOUCH)
	_next.pressed.connect(_on_next)
	buttons.add_child(_next)
	resized.connect(_size_picture)
	visible = false


## Shows card `index` of `level`'s deck: 0 is the goals card and
## deck_size() - 1 the closing card. Showing the same card again keeps its
## revealed steps and Go deeper as they were.
func show_card(level: LevelDef, index: int) -> void:
	var key := "%s:%d" % [level.id, index]
	if key != _key:
		_key = key
		_steps_shown = 1
		_deeper_open = false
	_level = level
	_index = index
	_render()


func card_kind() -> String:
	if _level == null:
		return ""
	if _index <= 0:
		return "goals"
	if _index > _level.learn.size():
		return "closing"
	return str(_level.learn[_index - 1].get("type", ""))


## Everything the card says, as plain text (for tests and screen readers).
func body_text() -> String:
	var parts := PackedStringArray()
	for l in [_text, _breaks, _steps, _deeper, _source]:
		if (l as RichTextLabel).visible:
			parts.append((l as RichTextLabel).get_parsed_text())
	return "\n".join(parts)


func steps_shown() -> int:
	return _steps_shown


func diagram() -> Diagram:
	return _diagram if _diagram != null and _diagram.visible else null


func next_button() -> Button:
	return _next


func back_button() -> Button:
	return _back


func skip_button() -> Button:
	return _skip


func deeper_button() -> Button:
	return _deeper_button


## Sizes the deck to `width` (at most MAX_W) and its content's height (at most
## the area's; past that its body scrolls), centered in `area`.
func fit_into(area: Rect2, width: float) -> void:
	var w := minf(minf(width, MAX_W), area.size.x)
	size = Vector2(w, 0)
	var body := _scroll.get_child(0) as Control
	var pad := get_theme_stylebox("panel").get_minimum_size()
	var fixed := (get_child(0) as VBoxContainer).get_combined_minimum_size().y - _scroll.get_combined_minimum_size().y
	var h := minf(fixed + body.get_combined_minimum_size().y + pad.y, area.size.y)
	size = Vector2(w, h)
	position = (area.position + (area.size - size) / 2.0).round()


func _on_next() -> void:
	var c := _card()
	if str(c.get("type", "")) == "worked" and _steps_shown < (c.get("steps", PackedStringArray()) as PackedStringArray).size():
		_steps_shown += 1
		_render()
		return
	next_pressed.emit()


func _toggle_deeper() -> void:
	_deeper_open = not _deeper_open
	_render()


func _card() -> Dictionary:
	if _level == null or _index <= 0 or _index > _level.learn.size():
		return {}
	return _level.learn[_index - 1]


func _render() -> void:
	if _level == null or _text == null:
		return
	var night := bool(game.state.progress.settings.get("night", false))
	var number := Levels.lesson_number(_level.id)
	_title.text = ("Lesson %d · %s" % [number, _level.title]) if number >= 0 else _level.title
	_dots.count = _level.deck_size()
	_dots.current = _index
	_dots.night = night
	_dots.queue_redraw()
	var kind := card_kind()
	var c := _card()
	_pip.mood = str(c.get("mood", "happy"))
	match kind:
		"goals":
			if _level.learn_goals.is_empty():
				HudText.put(_text, "In this lesson: " + _level.summary, game)
			else:
				HudText.put(_text, "In this lesson you'll learn:\n• " + "\n• ".join(_level.learn_goals), game)
		"closing":
			_pip.mood = "happy"
			if read_only:
				HudText.put(_text, "That's the lesson.", game)
			else:
				HudText.put(_text, "Now let's try it!" if _level.has_try() else "Now let's build it!", game)
		"meet":
			var intro := PartIntros.get_intro(str(c.get("part", "")))
			HudText.put(_text, "Meet the %s!" % str(intro.get("title", c.get("part", ""))).to_lower(), game)
		_:
			HudText.put(_text, str(c.get("text", "")), game)
	_show_diagram(str(c.get("diagram", "")))
	_show_meet(str(c.get("part", "")) if kind == "meet" else "")
	var breaks := str(c.get("breaks", ""))
	_breaks.visible = breaks != ""
	if _breaks.visible:
		HudText.put(_breaks, "Where it breaks: " + breaks, game)
	var steps: PackedStringArray = c.get("steps", PackedStringArray())
	_steps.visible = not steps.is_empty()
	if _steps.visible:
		HudText.put(_steps, "\n".join(steps.slice(0, mini(_steps_shown, steps.size()))), game)
	var deeper := str(c.get("deeper", ""))
	_deeper_button.visible = deeper != ""
	_deeper_button.set_pressed_no_signal(_deeper_open)
	_deeper.visible = deeper != "" and _deeper_open
	if _deeper.visible:
		HudText.put(_deeper, deeper, game)
	var source := str(c.get("source", ""))
	_source.visible = source != ""
	if _source.visible:
		HudText.put(_source, "Source: " + source, game)
	_back.disabled = _index <= 0
	_skip.visible = not read_only
	if kind == "closing":
		_next.text = "Close" if read_only else ("Try it" if _level.has_try() else "Build it")
	else:
		_next.text = "Next"
	_scroll.scroll_vertical = 0


func _show_diagram(id: String) -> void:
	if _diagram != null and (id == "" or _diagram.id != id):
		_picture.remove_child(_diagram)
		_diagram.queue_free()
		_diagram = null
	if id != "" and _diagram == null:
		_diagram = Diagrams.make(id, game)
		if _diagram != null:
			_picture.add_child(_diagram)
			_diagram.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_picture.visible = _diagram != null
	_size_picture()


## A meet card shows the part itself (a compact Meet the part card), and
## counts the part as met.
func _show_meet(part_key: String) -> void:
	if _meet != null and _meet.key != part_key:
		_meet_holder.remove_child(_meet)
		_meet.queue_free()
		_meet = null
	if part_key != "" and _meet == null:
		_meet = MeetPartCard.make(game, part_key, true)
		_meet_holder.add_child(_meet)
	_meet_holder.visible = _meet != null
	if _meet != null and is_visible_in_tree():
		game.mark_part_seen(part_key)


func meet_card() -> MeetPartCard:
	return _meet if _meet != null and _meet_holder.visible else null


## The picture keeps the diagrams' 400 × 220 shape at the deck's width.
func _size_picture() -> void:
	if _picture == null:
		return
	var w := maxf(size.x - get_theme_stylebox("panel").get_minimum_size().x, 240.0)
	_picture.custom_minimum_size = Vector2(0, clampf(w * 0.55, 132.0, 260.0)) if _diagram != null else Vector2.ZERO
