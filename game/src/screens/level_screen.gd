class_name LevelScreen
extends Control
## One level: the zoomable building area (a ZoomStage holding the EditorLayer)
## with the HUD on top. The editor's requests go to the Game, and every change
## in the Game is drawn again from its state. Task 17 fills in the HUD.

var game: Game
var stage: ZoomStage
var editor: EditorLayer
## Every HUD element lives under this node; it lets clicks through to the board.
var hud: Control

var _title: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage = ZoomStage.new()
	stage.name = "Stage"
	add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = load("res://src/editor/editor_layer.tscn").instantiate()
	stage.add_layer(editor)
	_build_hud()

	editor.commit_requested.connect(game.commit)
	editor.datasheet_requested.connect(func(id: String) -> void: game.set_ui_flag("datasheet:" + id))
	editor.toast_requested.connect(func(text: String) -> void: game.toast.emit(text))
	stage.layer_changed.connect(game.set_zoom_layer)
	game.changed.connect(_refresh)
	_refresh()
	_frame_circuit.call_deferred()


## Draws the current state: the circuit (or the preview), its simulation, the
## settings and the tray counts.
func _refresh() -> void:
	var s := game.state
	if s.level == null:
		return
	var shown := s.shown()
	editor.set_state(shown.circuit, shown.result, s.progress.settings, {}, [])
	editor.set_tray(s.level.tray, s.tray_used())
	_title.text = s.level.title


## Starts the camera on the whole circuit once the stage has its size.
func _frame_circuit() -> void:
	if editor.size.y < 1.0:
		await editor.resized
	stage.set_camera(ZoomCamera.make("editor", editor.fit_center(), editor.fit_view()))


func _build_hud() -> void:
	hud = Control.new()
	hud.name = "HUD"
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bar := HBoxContainer.new()
	bar.name = "TopBar"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_constant_override("separation", 12)
	hud.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 16)
	var back := Button.new()
	back.text = "‹ Map"
	back.pressed.connect(func() -> void: game.open_map())
	bar.add_child(back)
	_title = Label.new()
	_title.theme_type_variation = "HeadingLabel"
	bar.add_child(_title)
