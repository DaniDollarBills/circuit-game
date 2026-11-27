class_name SettingsSheet
extends PanelContainer
## Settings that apply at once and are saved with progress: how much help,
## real 3D or schematic, values and current flow, graphics quality, and
## comfort options.

const CHOICES := [
	["help_level", "Help", ["heavy", "light", "off"], ["Heavy: checklist and Pip's tips", "Light: hints when you ask", "Off: no hints"]],
	["view_style", "Look", ["physical", "schematic"], ["Real 3D", "Schematic"]],
	["quality", "Graphics quality", ["auto", "low", "medium", "high", "ultra"], ["Auto", "Low", "Medium", "High", "Ultra"]],
]
const TOGGLES := [
	["show_values", "Show values"],
	["show_current", "Show current flow"],
	["electron_flow", "Show electrons instead of conventional current"],
	["reduced_motion", "Reduce motion"],
	["large_text", "Large text"],
	["patterns", "Patterns as well as colors"],
	["night", "Night colors"],
]

var game: Game

var _choices := {}
var _toggles := {}


func _ready() -> void:
	custom_minimum_size = Vector2(360, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	var title := Label.new()
	title.text = "Settings"
	title.theme_type_variation = "HeadingLabel"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close_b := IconButton.make("close", "Close")
	close_b.custom_minimum_size = Vector2(IconButton.MIN_TOUCH, IconButton.MIN_TOUCH)
	close_b.pressed.connect(func() -> void: visible = false)
	top.add_child(close_b)
	for c in CHOICES:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = c[1]
		l.custom_minimum_size = Vector2(120, 0)
		row.add_child(l)
		var o := OptionButton.new()
		o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		o.clip_text = true
		for label in c[3]:
			o.add_item(label)
		var key: String = c[0]
		var values: Array = c[2]
		o.item_selected.connect(func(i: int) -> void: game.set_setting(key, values[i]))
		row.add_child(o)
		col.add_child(row)
		_choices[key] = o
	for t in TOGGLES:
		var b := CheckButton.new()
		b.text = t[1]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var key: String = t[0]
		b.toggled.connect(func(on: bool) -> void: game.set_setting(key, on))
		col.add_child(b)
		_toggles[key] = b
	visible = false


func open() -> void:
	sync()
	visible = true


## Shows the saved values without sending them back.
func sync() -> void:
	var st := game.state.progress.settings
	for c in CHOICES:
		var o: OptionButton = _choices[c[0]]
		o.select(maxi((c[2] as Array).find(st.get(c[0])), 0))
	for t in TOGGLES:
		(_toggles[t[0]] as CheckButton).set_pressed_no_signal(bool(st.get(t[0], false)))


func toggle(key: String) -> CheckButton:
	return _toggles.get(key)


func choice(key: String) -> OptionButton:
	return _choices.get(key)
