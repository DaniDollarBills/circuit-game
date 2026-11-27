class_name ValuePopover
extends PanelContainer
## Sets an adjustable resistor: a slider from 100 Ω to 2 kΩ in 10 Ω steps.
## Dragging previews the circuit live; letting go commits the value.

signal previewed(part_id: String, ohms: float)
signal committed(part_id: String, ohms: float)

var game: Game
var part_id := ""
var slider := HSlider.new()
var value_label := Label.new()

var _title: RichTextLabel
var _dragging := false


func _ready() -> void:
	custom_minimum_size = Vector2(320, 0)
	var col := VBoxContainer.new()
	add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	_title = HudText.label(game, 15)
	top.add_child(_title)
	var close_b := IconButton.make("close", "Close")
	close_b.custom_minimum_size = Vector2(IconButton.MIN_TOUCH, IconButton.MIN_TOUCH)
	close_b.pressed.connect(close)
	top.add_child(close_b)
	var row := HBoxContainer.new()
	col.add_child(row)
	slider.min_value = 100
	slider.max_value = 2000
	slider.step = 10
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(200, IconButton.MIN_TOUCH)
	slider.drag_started.connect(func() -> void: _dragging = true)
	slider.drag_ended.connect(func(_changed: bool) -> void:
		_dragging = false
		committed.emit(part_id, slider.value))
	slider.value_changed.connect(_on_value)
	row.add_child(slider)
	value_label.custom_minimum_size = Vector2(72, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	visible = false


func open(id: String, ohms: float, at: Vector2) -> void:
	part_id = id
	HudText.put(_title, "Resistance of %s" % id, game)
	slider.set_value_no_signal(clampf(ohms, slider.min_value, slider.max_value))
	value_label.text = Catalog.format_ohms(slider.value)
	visible = true
	reset_size()
	var host := get_parent_area_size()
	position = Vector2(clampf(at.x - size.x / 2.0, 8.0, maxf(host.x - size.x - 8.0, 8.0)), clampf(at.y + 24.0, 8.0, maxf(host.y - size.y - 8.0, 8.0)))


func close() -> void:
	visible = false


## Keyboard and clicks on the track commit at once; drags preview.
func _on_value(v: float) -> void:
	value_label.text = Catalog.format_ohms(v)
	if _dragging:
		previewed.emit(part_id, v)
	else:
		committed.emit(part_id, v)
