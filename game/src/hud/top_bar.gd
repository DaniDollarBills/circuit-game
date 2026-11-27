class_name TopBar
extends HBoxContainer
## Back to the map, the level's title, undo and redo, the calculator, the
## Notebook and settings.

var game: Game
## Narrow screens hide the title; the goals pill shows it instead.
var show_title := true:
	set(value):
		show_title = value
		_apply_width()

var _title: Label
var _spacer: Control
var _buttons := {}


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add("map", IconButton.make("back", "Back to the map"))
	_title = Label.new()
	_title.theme_type_variation = "HeadingLabel"
	HudText.font_size(_title, 22, game)
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
	# Narrow screens: no title, an empty spacer keeps the buttons right.
	_spacer = Control.new()
	_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_spacer)
	_add("restart", IconButton.make("restart", "Start over"))
	_add("undo", IconButton.make("undo", "Undo (Ctrl+Z)"))
	_add("redo", IconButton.make("redo", "Redo (Ctrl+Shift+Z)"))
	_add("calculator", IconButton.make("calculator", "Calculator"))
	_add("notebook", IconButton.make("book", "Notebook"))
	_add("settings", IconButton.make("gear", "Settings"))
	_apply_width()
	button("map").pressed.connect(func() -> void: game.open_map())
	button("undo").pressed.connect(func() -> void: game.undo())
	button("redo").pressed.connect(func() -> void: game.redo())


## Wide: the title on its pill, 48 px buttons 8 px apart. Narrow (a phone):
## no title, 44 px buttons 4 px apart, so all seven fit 360 px (336 of 336).
func _apply_width() -> void:
	if _title == null:
		return
	(_title.get_parent() as Control).visible = show_title
	_spacer.visible = not show_title
	add_theme_constant_override("separation", 8 if show_title else 4)
	var side := 48.0 if show_title else IconButton.MIN_TOUCH
	for b in _buttons.values():
		(b as Control).custom_minimum_size = Vector2(side, side)


func button(id: String) -> Button:
	return _buttons.get(id)


func refresh(state: GameState) -> void:
	_title.text = state.level.title if state.level != null else ""
	button("undo").disabled = state.history == null or not state.history.can_undo()
	button("redo").disabled = state.history == null or not state.history.can_redo()


func _add(id: String, b: Button) -> void:
	_buttons[id] = b
	add_child(b)
