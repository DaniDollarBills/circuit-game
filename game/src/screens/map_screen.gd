class_name MapScreen
extends Control
## The level map: Chapter 1's levels along a winding path (✓ finished, ★ star,
## greyed out until the level before is finished), then the chapters still to
## come with their era and what they teach.

const NODE_W := 260.0
const ROW_H := 124.0
const TOP := 64.0

var game: Game

var _buttons: Array[Button] = []
var _cards: Array[Control] = []
var _path: MapPath


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
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(back.get_combined_minimum_size().x, 0)
	top.add_child(balance)
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
	var summary := Label.new()
	summary.text = l.summary
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 14)
	summary.add_theme_color_override("font_color", Palette.color("ink_soft", _night()))
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
	var sub := Label.new()
	sub.text = "%s · %s" % [ch["era"], ch["blurb"]]
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_color_override("font_color", Palette.color("ink_soft", _night()))
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
	top.add_theme_font_size_override("font_size", 14)
	top.add_theme_color_override("font_color", soft)
	box.add_child(top)
	var title := Label.new()
	title.text = ch["title"]
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	var blurb := Label.new()
	blurb.text = ch["blurb"]
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(blurb)
	var lock := Label.new()
	lock.text = "Locked: coming in a later update"
	lock.add_theme_font_size_override("font_size", 14)
	lock.add_theme_color_override("font_color", soft)
	box.add_child(lock)
	return panel


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
