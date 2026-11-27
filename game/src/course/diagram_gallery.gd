extends Control
## Every Learn-card picture in a grid, for screenshots: tools/capture.sh
## res://src/course/diagram_gallery.tscn out.png [WxH] -- [--night] [--still]
## [--t=<seconds>]

func _ready() -> void:
	var settings := {"night": false, "reduced_motion": false}
	var at := 1.3
	for arg in OS.get_cmdline_user_args():
		if arg == "--night":
			settings["night"] = true
		elif arg == "--still":
			settings["reduced_motion"] = true
		elif arg.begins_with("--t="):
			at = float(arg.substr(4))
	var game := Game.new()
	add_child(game)
	game.boot("user://diagram_gallery_progress.json")
	for key in settings:
		game.set_setting(key, settings[key])
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Palette.color("paper", bool(settings.get("night", false)))
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)
	for id in Diagrams.IDS:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := Label.new()
		title.text = id
		title.add_theme_color_override("font_color", Palette.color("ink_soft", bool(settings.get("night", false))))
		cell.add_child(title)
		var d := Diagrams.make(id, game)
		d.t = at
		d.custom_minimum_size = Vector2(400, 220)
		cell.add_child(d)
		grid.add_child(cell)
