extends SceneTree
## Stitches TMS tiles (<tiles>/<x>/<y>.jpg, y = 0 at the bottom) into one
## image, north up. Used by tools/make_earth.mjs.
## Args after "--": --tiles=<dir> --cols=N --rows=N --out=<res:// path>


func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var cols := int(args.get("cols", "0"))
	var rows := int(args.get("rows", "0"))
	var out: Image = null
	for x in cols:
		for y in rows:
			var tile := Image.load_from_file("%s/%d/%d.jpg" % [args["tiles"], x, y])
			if tile == null:
				push_error("missing tile %d/%d" % [x, y])
				quit(1)
				return
			if out == null:
				out = Image.create(tile.get_width() * cols, tile.get_height() * rows, false, Image.FORMAT_RGB8)
			tile.convert(Image.FORMAT_RGB8)
			out.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), Vector2i(x * tile.get_width(), (rows - 1 - y) * tile.get_height()))
	var err := out.save_jpg(ProjectSettings.globalize_path(args["out"]), 0.92)
	print("stitched %dx%d -> %s (%s)" % [out.get_width(), out.get_height(), args["out"], error_string(err)])
	quit(0 if err == OK else 1)
