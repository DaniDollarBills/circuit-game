class_name MapScreen
extends Control
## The level map: Chapter 1's levels along a winding path (✓ finished, ★ star,
## greyed out until the level before is finished), then the chapters still to
## come with their era and what they teach.

const NODE_W := 260.0
const ROW_H := 124.0
const TOP := 64.0

var game: Game
var notebook: NotebookSheet
var glossary_popup: GlossaryPopup

var _buttons: Array[Button] = []
var _cards: Array[Control] = []
var _path: MapPath


var _cards_root: Control
var _word_cards: Array[NewWordCard] = []
var _word_queue: Array[String] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var top := HBoxContainer.new()
	var back := Button.new()
	back.text = "‹ Title"
	back.pressed.connect(func() -> void: game.open_title())
	top.add_child(back)
	var heading := Label.new()
	heading.theme_type_variation = "HeadingLabel"
	heading.text = "Map"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(heading)
	var book := IconButton.make("book", "Notebook")
	book.pressed.connect(func() -> void:
		notebook.open()
		notebook.visible = true)
	top.add_child(book)
	column.add_child(top)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)

	var ch1: Dictionary = Chapters.ALL[0]
	content.add_child(_chapter_header(ch1))
	_path = MapPath.new()
	_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_path)
	var ids := Levels.chapter_ids("ch1")
	var p := game.state.progress
	var i := 0
	for l in Levels.all():
		if l.chapter != "ch1":
			continue
		_path.add_child(_level_node(i, l, p, ids))
		i += 1
	_path.done = _done_flags(ids, p)
	_path.custom_minimum_size = Vector2(0, TOP + (i - 1) * ROW_H + 96.0)

	var later := Label.new()
	later.theme_type_variation = "HeadingLabel"
	later.text = "Coming later"
	content.add_child(later)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 12)
	content.add_child(flow)
	for n in range(1, Chapters.ALL.size()):
		var card := _chapter_card(n + 1, Chapters.ALL[n])
		flow.add_child(card)
		_cards.append(card)
	notebook = NotebookSheet.new()
	notebook.game = game
	add_child(notebook)
	glossary_popup = GlossaryPopup.new()
	glossary_popup.game = game
	add_child(glossary_popup)
	game.term_requested.connect(func(term: String) -> void: glossary_popup.open(term))
	_cards_root = Control.new()
	_cards_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cards_root)
	# Plain text (level titles such as "Short circuit!") is introduced too.
	HudText.introduce_in(game, self)


## The cards fit the screen as in a level (CardFit): narrower on a phone, and
## scrolling when they're still too tall.
func _process(_delta: float) -> void:
	_take_events()
	_place_cards()
	var area := Rect2(12, 64, size.x - 24.0, size.y - 80.0)
	for card: Control in [notebook, glossary_popup]:
		if card != null and card.visible:
			var w := minf(380.0, area.size.x)
			var at := area.position + (area.size - Vector2(w, card.size.y)) / 2.0
			CardFit.fit(card, w, area, at, 420.0 if card == notebook else -1.0)


## Chapter 1's level buttons, in play order.
func level_buttons() -> Array[Button]:
	return _buttons


## The cards for the chapters that can't be played yet.
func chapter_cards() -> Array[Control]:
	return _cards


func _level_node(i: int, l: LevelDef, p: Progress, ids: PackedStringArray) -> Control:
	var node := VBoxContainer.new()
	node.custom_minimum_size = Vector2(NODE_W, 0)
	node.add_theme_constant_override("separation", 4)
	var b := Button.new()
	var marks := ""
	if p.completed.has(l.id):
		marks += "  ✓"
		if bool(p.completed[l.id]["star"]):
			marks += " ★"
	b.text = "%d  %s%s" % [i + 1, l.title, marks]
	b.disabled = not p.is_unlocked(l.id, ids)
	b.tooltip_text = l.summary if not b.disabled else "Finish level %d to unlock this one." % i
	b.pressed.connect(func() -> void: game.open_level(l.id))
	node.add_child(b)
	# What a level is about shows once it can be played: its words are met
	# (with New word cards) then, not all at once on a first visit.
	var summary := HudText.label(game, 14)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_color_override("default_color", Palette.color("ink_soft", _night()))
	summary.visible = not b.disabled
	if summary.visible:
		HudText.put(summary, l.summary, game)
	var backing := StyleBoxFlat.new()
	backing.bg_color = Palette.color("cream", _night())
	backing.set_corner_radius_all(8)
	backing.content_margin_left = 6
	backing.content_margin_right = 6
	summary.add_theme_stylebox_override("normal", backing)
	node.add_child(summary)
	_buttons.append(b)
	return node


func _done_flags(ids: PackedStringArray, p: Progress) -> Array[bool]:
	var out: Array[bool] = []
	for id in ids:
		out.append(p.completed.has(id))
	return out


func _chapter_header(ch: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.theme_type_variation = "HeadingLabel"
	title.text = "Chapter 1 · %s" % ch["title"]
	box.add_child(title)
	var sub := HudText.make(game, "%s · %s" % [ch["era"], ch["blurb"]])
	sub.add_theme_color_override("default_color", Palette.color("ink_soft", _night()))
	box.add_child(sub)
	return panel


func _chapter_card(number: int, ch: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 0)
	panel.modulate = Color(1, 1, 1, 0.85)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var soft := Palette.color("ink_soft", _night())
	var top := Label.new()
	top.text = "Chapter %d · %s" % [number, ch["era"]]
	HudText.font_size(top, 14, game)
	top.add_theme_color_override("font_color", soft)
	box.add_child(top)
	var title := Label.new()
	title.text = ch["title"]
	HudText.font_size(title, 22, game)
	box.add_child(title)
	box.add_child(HudText.make(game, ch["blurb"]))
	var lock := Label.new()
	lock.text = "Locked: coming in a later update"
	HudText.font_size(lock, 14, game)
	lock.add_theme_color_override("font_color", soft)
	box.add_child(lock)
	return panel


## Closes the definition or the Notebook (Android's Back); false when neither
## was open.
func close_top() -> bool:
	for card: Control in [glossary_popup, notebook]:
		if card.visible:
			card.visible = false
			return true
	return false


## Words met on the map get New word cards, as in a level; badges, toasts.
func _take_events() -> void:
	if game.state.events.is_empty():
		return
	for e in game.state.take_events():
		match str(e["type"]):
			"new_word":
				_word_queue.append(str(e["term"]))
			"badge":
				_sound("badge")
				for a in Achievements.ALL:
					if a["id"] == e["id"]:
						game.toast.emit("Badge earned: %s" % a["name"])
	while _word_cards.size() < (1 if size.y < 600.0 or size.x < 700.0 else 2) and not _word_queue.is_empty():
		var card := NewWordCard.make(game, _word_queue.pop_front())
		card.finished.connect(func(c: NewWordCard) -> void:
			_word_cards.erase(c)
			c.queue_free()
			_take_events())
		_cards_root.add_child(card)
		_word_cards.append(card)
		_sound("word")


## New word cards slide in at the bottom left, one above another.
func _place_cards() -> void:
	var y := size.y - 16.0
	for card in _word_cards:
		var w := minf(card.custom_minimum_size.x if card.custom_minimum_size.x > 0.0 else 320.0, size.x - 32.0)
		card.size = Vector2(w, 0)
		card.reset_size()
		card.size.x = w
		y -= card.size.y
		card.position = Vector2(16.0 - (1.0 - card.slide_progress()) * (w + 16.0), y)
		y -= 8.0


## Every term that has a New word card here, shown or waiting.
func word_card_terms() -> PackedStringArray:
	var out := PackedStringArray(_word_queue)
	for c in _word_cards:
		out.append(c.term)
	return out


func _sound(name: String) -> void:
	var audio := get_tree().get_first_node_in_group("audio") as Audio
	if audio != null:
		audio.play(name)


func _night() -> bool:
	return game != null and bool(game.state.progress.settings.get("night", false))


## Lays the level nodes out along a gentle S-curve and draws the trail between
## them; the stretch between finished levels is drawn in mint.
class MapPath:
	extends Container

	var done: Array[bool] = []

	func _notification(what: int) -> void:
		if what == NOTIFICATION_SORT_CHILDREN:
			_layout()

	func centers() -> PackedVector2Array:
		var out := PackedVector2Array()
		var amp := clampf(size.x * 0.5 - MapScreen.NODE_W * 0.5 - 8.0, 0.0, 240.0)
		for i in get_child_count():
			out.append(Vector2(size.x * 0.5 + amp * sin(i * 1.15), MapScreen.TOP + i * MapScreen.ROW_H))
		return out

	func _layout() -> void:
		var c := centers()
		for i in get_child_count():
			var n := get_child(i) as Control
			var s := n.get_combined_minimum_size()
			fit_child_in_rect(n, Rect2(c[i] - Vector2(s.x * 0.5, 24.0), s))
		queue_redraw()

	func _draw() -> void:
		var c := centers()
		if c.size() < 2:
			return
		var trail := Palette.color("lilac")
		var finished := Palette.color("mint")
		for i in c.size() - 1:
			var pts := _segment(c, i)
			var both_done := i + 1 < done.size() and done[i] and done[i + 1]
			draw_polyline(pts, finished if both_done else trail, 12.0, true)

	## Catmull-Rom from c[i] to c[i+1], 16 samples.
	func _segment(c: PackedVector2Array, i: int) -> PackedVector2Array:
		var p0 := c[maxi(i - 1, 0)]
		var p1 := c[i]
		var p2 := c[i + 1]
		var p3 := c[mini(i + 2, c.size() - 1)]
		var out := PackedVector2Array()
		for k in 17:
			var t := k / 16.0
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
					+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
		return out
