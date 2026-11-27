class_name NotebookSheet
extends PanelContainer
## The Notebook, the course's textbook: every lesson read (to read again),
## every part met (to meet again), every word learned with both definitions,
## and all the badges, earned ones in color. A finished chapter gets a summary.

signal open_lesson(level_id: String)
signal open_part(key: String)

const TABS := [["lessons", "Lessons"], ["parts", "Parts"], ["words", "Words"], ["badges", "Badges"]]

var game: Game

var _tabs: Dictionary = {}
var _list: VBoxContainer
var _showing := "lessons"
var _words := PackedStringArray()
var _badges := 0
var _lesson_rows := PackedStringArray()
var _part_rows := PackedStringArray()
var _summaries := {}


func _ready() -> void:
	# A definition: its own words stay plain (HudText.introduce_in skips it).
	add_to_group("definitions")
	# Its list scrolls; CardFit gives the card its height (420 px, or less).
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	var title := Label.new()
	title.text = "Notebook"
	title.theme_type_variation = "HeadingLabel"
	HudText.font_size(title, 22, game)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close_b := IconButton.make("close", "Close")
	close_b.custom_minimum_size = Vector2(IconButton.MIN_TOUCH, IconButton.MIN_TOUCH)
	close_b.pressed.connect(func() -> void: visible = false)
	top.add_child(close_b)
	# Four tabs wrap onto two rows on a narrow phone.
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	col.add_child(tabs)
	for tab in TABS:
		var id: String = tab[0]
		var b := Button.new()
		b.text = tab[1]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
		b.pressed.connect(func() -> void: show_tab(id))
		tabs.add_child(b)
		_tabs[id] = b
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)
	visible = false


func open() -> void:
	show_tab("lessons")
	visible = true


func tab_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for tab in TABS:
		out.append(tab[0])
	return out


## The lessons listed to read again ("Lesson 1 · Light it up").
func lesson_rows() -> PackedStringArray:
	return _lesson_rows


## The parts listed to meet again, by title, first met first.
func part_rows() -> PackedStringArray:
	return _part_rows


func has_chapter_summary(chapter: String) -> bool:
	return _summaries.has(chapter)


func chapter_summary_text(chapter: String) -> String:
	return str(_summaries.get(chapter, ""))


## The seen words, first learned first.
func word_terms() -> PackedStringArray:
	return _words


## How many badges the Badges tab lists (0 while Words is showing).
func badge_count() -> int:
	return _badges


## Terms in the order they were first seen; ties keep their recorded order.
static func in_order(seen: Dictionary) -> PackedStringArray:
	var keys := seen.keys()
	var order := {}
	for i in keys.size():
		order[keys[i]] = i
	keys.sort_custom(func(a: Variant, b: Variant) -> bool:
		if int(seen[a]) != int(seen[b]):
			return int(seen[a]) < int(seen[b])
		return int(order[a]) < int(order[b]))
	return PackedStringArray(keys)


func show_tab(id: String) -> void:
	_showing = id
	for t in _tabs:
		_tabs[t].button_pressed = t == id
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var p := game.state.progress
	_words = in_order(p.seen_terms)
	_badges = 0
	_lesson_rows = PackedStringArray()
	_part_rows = PackedStringArray()
	_summaries = {}
	if id == "lessons":
		_fill_lessons(p)
	elif id == "parts":
		_fill_parts(p)
	elif id == "words":
		if _words.is_empty():
			_list.add_child(_plain("Words you meet will collect here.", 15, "ink_soft"))
		for t in _words:
			var e: Dictionary = Glossary.ENTRIES.get(t, {})
			if e.is_empty():
				continue
			var box := VBoxContainer.new()
			box.add_child(_plain(e["title"], 18, "ink"))
			box.add_child(HudText.make(game, e["simple"], 15))
			box.add_child(HudText.make(game, "More precisely: " + str(e["precise"]), 13))
			_list.add_child(box)
	else:
		for a in Achievements.ALL:
			var earned := p.achievements.has(a["id"])
			var card := PanelContainer.new()
			var sb := StyleBoxFlat.new()
			# Not earned yet: an outline on paper, where soft text keeps 4.5:1.
			var night := bool(p.settings.get("night", false))
			sb.bg_color = Palette.color("mint") if earned else Palette.color("paper", night)
			if not earned:
				sb.set_border_width_all(2)
				sb.border_color = Palette.color("line", night).darkened(0.1)
			sb.set_corner_radius_all(14)
			sb.set_content_margin_all(10)
			card.add_theme_stylebox_override("panel", sb)
			var box := VBoxContainer.new()
			card.add_child(box)
			box.add_child(_plain(("★ " if earned else "") + str(a["name"]), 17, "ink" if earned else "ink_soft", earned))
			box.add_child(_plain(a["description"], 14, "ink" if earned else "ink_soft", earned))
			_list.add_child(card)
			_badges += 1


## Each lesson read (or finished), to read again; a finished chapter's
## summary first.
func _fill_lessons(p: Progress) -> void:
	var levels := Levels.all()
	var first_tutorial := not levels.is_empty() and levels[0].kind == "tutorial"
	var ids := Levels.chapter_ids("ch1")
	if not ids.is_empty() and Array(ids).all(func(i: String) -> bool: return p.completed.has(i)):
		var lines: Array = Chapters.SUMMARY.get("ch1", [])
		_summaries["ch1"] = "\n".join(lines.map(func(t: String) -> String: return "• " + t))
		var title := _plain("Chapter 1 summary", 18, "ink")
		_list.add_child(title)
		_list.add_child(HudText.make(game, _summaries["ch1"], 15))
	var i := 0
	for l in levels:
		var number := i if first_tutorial else i + 1
		i += 1
		if not (p.lesson_marks(l.id).has("learn") or p.completed.has(l.id)) or l.deck_size() == 0:
			continue
		var row := "Lesson %d · %s" % [number, l.title]
		_lesson_rows.append(row)
		var b := Button.new()
		b.text = row
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
		var lid := l.id
		b.pressed.connect(func() -> void: open_lesson.emit(lid))
		_list.add_child(b)
	if _lesson_rows.is_empty():
		_list.add_child(_plain("Lessons you read will collect here, to read again.", 15, "ink_soft"))


## Each part met, first met first, to meet again.
func _fill_parts(p: Progress) -> void:
	for key in in_order(p.parts_seen):
		var intro := PartIntros.get_intro(key)
		if intro.is_empty():
			continue
		_part_rows.append(str(intro["title"]))
		var b := Button.new()
		b.text = str(intro["title"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
		var k: String = key
		b.pressed.connect(func() -> void: open_part.emit(k))
		_list.add_child(b)
	if _part_rows.is_empty():
		_list.add_child(_plain("Parts you meet will collect here.", 15, "ink_soft"))


## Text on a pastel (earned badge) card is always dark ink, even at night;
## anywhere else it follows the theme, so a night switch recolors it.
func _plain(text: String, font_size: int, token: String, on_pastel := false) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HudText.font_size(l, font_size, game)
	if on_pastel:
		l.add_theme_color_override("font_color", Palette.color(token, false))
	elif token == "ink_soft":
		l.theme_type_variation = "SoftLabel"
	return l
