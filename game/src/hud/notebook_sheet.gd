class_name NotebookSheet
extends PanelContainer
## The Notebook: every word learned, in the order it was met, with both
## definitions; and all the badges, earned ones in color.

var game: Game

var _tabs: Dictionary = {}
var _list: VBoxContainer
var _showing := "words"
var _words := PackedStringArray()
var _badges := 0


func _ready() -> void:
	# Its list scrolls; CardFit gives the card its height (420 px, or less).
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	var title := Label.new()
	title.text = "Notebook"
	title.theme_type_variation = "HeadingLabel"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close_b := IconButton.make("close", "Close")
	close_b.custom_minimum_size = Vector2(IconButton.MIN_TOUCH, IconButton.MIN_TOUCH)
	close_b.pressed.connect(func() -> void: visible = false)
	top.add_child(close_b)
	var tabs := HBoxContainer.new()
	col.add_child(tabs)
	for id in ["words", "badges"]:
		var b := Button.new()
		b.text = "Words" if id == "words" else "Badges"
		b.toggle_mode = true
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
	show_tab("words")
	visible = true


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
	if id == "words":
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


## Text on a pastel (earned badge) card is always dark ink, even at night;
## anywhere else it follows the theme, so a night switch recolors it.
func _plain(text: String, font_size: int, token: String, on_pastel := false) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	if on_pastel:
		l.add_theme_color_override("font_color", Palette.color(token, false))
	elif token == "ink_soft":
		l.theme_type_variation = "SoftLabel"
	return l
