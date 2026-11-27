class_name ContextMenu
extends PanelContainer
## The menu for a part or wire (right-click or long-press): Rotate, Delete,
## Datasheet, Explain, and Replace for a burnt part, then Cancel. Locked parts
## can't be rotated or deleted. Esc or a press anywhere else closes it.

signal chosen(action: String, target: Dictionary)

const ACTIONS := ["Rotate", "Delete", "Datasheet", "Explain", "Replace", "Cancel"]

var game: Game
var target: Dictionary = {}

var _buttons := {}


func _ready() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	add_child(col)
	for a in ACTIONS:
		var b := Button.new()
		b.text = a
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void:
			var t := target
			close()
			if a != "Cancel":
				chosen.emit(a, t))
		col.add_child(b)
		_buttons[a] = b
	visible = false


func button(action: String) -> Button:
	return _buttons[action]


## `at` is a screen position inside the parent; the menu stays on screen.
func open(t: Dictionary, at: Vector2) -> void:
	target = t
	var c := game.state.history.present
	if t.has("part"):
		var p := c.find_part(str(t["part"]))
		if p == null:
			return
		var burnt := bool(p.props.get("burnt", false))
		for a in ACTIONS:
			_buttons[a].visible = a != "Replace" or burnt
		_buttons["Rotate"].disabled = p.locked
		_buttons["Delete"].disabled = p.locked
	else:
		var w := c.find_wire(str(t.get("wire", "")))
		if w == null:
			return
		for a in ACTIONS:
			_buttons[a].visible = a == "Delete" or a == "Cancel"
		_buttons["Delete"].disabled = w.locked
	visible = true
	reset_size()
	var host := get_parent_area_size()
	position = Vector2(clampf(at.x, 8.0, maxf(host.x - size.x - 8.0, 8.0)), clampf(at.y, 8.0, maxf(host.y - size.y - 8.0, 8.0)))


## Checks the rows against the circuit as it is now, in place; closes when
## the part or wire is gone (an undo, say).
func sync() -> void:
	if not visible:
		return
	var t := target
	var at := position
	close()
	open(t, at)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	var at: Variant = null
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		at = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		at = (event as InputEventScreenTouch).position
	if at != null and not get_global_rect().has_point(at):
		close()


func close() -> void:
	visible = false
	target = {}
