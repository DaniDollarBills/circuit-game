class_name TopBar
extends HBoxContainer
## Back to the map, the level's title, undo and redo, the calculator, the
## Notebook and settings.

var game: Game
## Narrow screens hide the title; the goals pill shows it instead.
var show_title := true:
	set(value):
		show_title = value
		if _title != null:
			_title.modulate.a = 1.0 if value else 0.0

var _title: Label
var _buttons := {}


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add("map", IconButton.make("back", "Back to the map"))
	_title = Label.new()
	_title.theme_type_variation = "HeadingLabel"
	_title.add_theme_font_size_override("font_size", 22)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.clip_text = true
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# On a pill: the 3D scene behind the bar can be any shade.
	var pill := PanelContainer.new()
	pill.name = "TitlePill"
	pill.theme_type_variation = "PillPanel"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.add_child(_title)
	add_child(pill)
	_add("undo", IconButton.make("undo", "Undo (Ctrl+Z)"))
	_add("redo", IconButton.make("redo", "Redo (Ctrl+Shift+Z)"))
	_add("calculator", IconButton.make("calculator", "Calculator"))
	_add("notebook", IconButton.make("book", "Notebook"))
	_add("settings", IconButton.make("gear", "Settings"))
	button("map").pressed.connect(func() -> void: game.open_map())
	button("undo").pressed.connect(func() -> void: game.undo())
	button("redo").pressed.connect(func() -> void: game.redo())


func button(id: String) -> Button:
	return _buttons.get(id)


func refresh(state: GameState) -> void:
	_title.text = state.level.title if state.level != null else ""
	button("undo").disabled = state.history == null or not state.history.can_undo()
	button("redo").disabled = state.history == null or not state.history.can_redo()


func _add(id: String, b: Button) -> void:
	_buttons[id] = b
	add_child(b)
