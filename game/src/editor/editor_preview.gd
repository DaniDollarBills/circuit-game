extends Control
## Dev only: a level's circuit (or its solution, with --solution) in the editor
## with live simulation. --level=<id>, --schematic for the circuit-symbol view.

var layer: EditorLayer
var settings := Progress.DEFAULT_SETTINGS.duplicate()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var id := "ch1.light-it-up"
	var solution := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			id = arg.substr(8)
		elif arg == "--solution":
			solution = true
		elif arg == "--schematic":
			settings["view_style"] = "schematic"
	var level := Levels.by_id(id)
	layer = load("res://src/editor/editor_layer.tscn").instantiate()
	add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.commit_requested.connect(_show)
	_show(level.solution if solution else level.circuit)
	layer.set_live(true, true)
	layer.set_tray(level.tray, [])
	await get_tree().process_frame
	layer.apply_view(layer.fit_center(), layer.fit_view())


func _show(c: Circuit) -> void:
	var out := Simulator.simulate(c)
	layer.set_state(out.circuit, out.result, settings, {}, [])
