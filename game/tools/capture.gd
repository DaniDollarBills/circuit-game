extends SceneTree
## Renders a scene to a PNG for visual review (run under Xvfb by tools/capture.sh).
## Args after "--": --scene=<res://path.tscn> --out=<absolute .png path> [scene args...]

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene_path := ""
	var out_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene_path = arg.substr(8)
		elif arg.begins_with("--out="):
			out_path = arg.substr(6)
	if scene_path.is_empty() or out_path.is_empty():
		push_error("capture.gd needs --scene= and --out=")
		quit(2)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("capture.gd could not load " + scene_path)
		quit(2)
		return
	root.add_child(packed.instantiate())
	for i in 30:
		await process_frame
	var err := root.get_texture().get_image().save_png(out_path)
	print("captured ", scene_path, " -> ", out_path, " (", error_string(err), ")")
	quit(0 if err == OK else 1)
