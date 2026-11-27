class_name PartsTray
extends PanelContainer
## The parts the level offers, with how many are left. Tap one and then the
## board to place it, or drag it onto the board. Each has an ⓘ button for its
## datasheet. A left column in landscape, a bottom strip in portrait.

signal place_requested(index: int)
signal info_requested(index: int)

var game: Game
var vertical := true:
	set(value):
		vertical = value
		_rebuild()

var _scroll: ScrollContainer
var _box: BoxContainer
var _items: Array[Button] = []
var _infos: Array[Button] = []
var _tray: Array = []
var _used: Array[int] = []


func _ready() -> void:
	_scroll = ScrollContainer.new()
	add_child(_scroll)
	_rebuild()


func refresh(tray: Array, used: Array[int]) -> void:
	var changed := str(tray) != str(_tray)
	_tray = tray
	_used = used
	if changed:
		_rebuild()
	else:
		_update_counts()


func items() -> Array[Button]:
	return _items


func info_buttons() -> Array[Button]:
	return _infos


func _rebuild() -> void:
	if _scroll == null:
		return
	if _box != null:
		_scroll.remove_child(_box)
		_box.queue_free()
	_box = VBoxContainer.new() if vertical else HBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	_scroll.add_child(_box)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if vertical else ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if vertical else ScrollContainer.SCROLL_MODE_DISABLED
	_items.clear()
	_infos.clear()
	visible = not _tray.is_empty()
	for i in _tray.size():
		var item: Dictionary = _tray[i]
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		var b := TrayItem.new()
		b.index = i
		b.part = Part.make("?", item["kind"], 0, 0, 0, item.get("props", {}))
		b.custom_minimum_size = Vector2(104, 80)
		b.pressed.connect(func() -> void: place_requested.emit(i))
		cell.add_child(b)
		var info := IconButton.make("info", "Datasheet")
		info.flat = true
		info.custom_minimum_size = Vector2(IconButton.MIN_TOUCH, IconButton.MIN_TOUCH)
		info.size = info.custom_minimum_size
		info.position = Vector2(104 - IconButton.MIN_TOUCH, 0)
		info.pressed.connect(func() -> void: info_requested.emit(i))
		b.add_child(info)
		_box.add_child(cell)
		_items.append(b)
		_infos.append(info)
	_update_counts()


func _update_counts() -> void:
	for i in _items.size():
		var left := int(_tray[i].get("count", 1)) - (_used[i] if i < _used.size() else 0)
		var b := _items[i] as TrayItem
		b.left = left
		b.disabled = left <= 0
		b.queue_redraw()


## One tray item: its symbol, its value and how many are left. It can be
## dragged onto the board.
class TrayItem:
	extends Button

	var index := 0
	var part: Part
	var left := 1

	func _get_drag_data(_at: Vector2) -> Variant:
		if disabled:
			return null
		var preview := PartIcon.new()
		preview.part = part
		preview.size = Vector2(72, 40)
		set_drag_preview(preview)
		return {"tray": index}

	func _draw() -> void:
		var ink := get_theme_color("font_disabled_color" if disabled else "font_color")
		var icon_rect := Rect2(10, 10, size.x - 44, size.y * 0.5)
		var ops := PartArt.ops(part, {}, false, false).filter(func(op: Dictionary) -> bool: return op["type"] != "text")
		var tile := Rect2()
		for op in ops:
			if op.get("tag", "") == "tile":
				tile = op["rect"]
		var ppu := minf(icon_rect.size.x / (tile.size.x + 0.6), icon_rect.size.y / (tile.size.y + 0.6))
		var origin := (icon_rect.position + icon_rect.size / 2.0) / ppu - tile.get_center()
		DrawKit.draw_ops(self, ops, origin, 0, ppu)
		var font := get_theme_default_font()
		draw_string(font, Vector2(6, size.y - 26), _value_text(), HORIZONTAL_ALIGNMENT_CENTER, size.x - 12, 15, ink)
		draw_string(font, Vector2(6, size.y - 9), "%d left" % maxi(left, 0), HORIZONTAL_ALIGNMENT_CENTER, size.x - 12, 12, Color(ink, 0.75))

	func _value_text() -> String:
		match part.kind:
			"resistor":
				return Catalog.format_ohms(float(part.props.get("ohms", 220.0)))
			"led":
				return str(part.props.get("color", "red")).capitalize() + " LED"
		return Catalog.title(part.kind)
