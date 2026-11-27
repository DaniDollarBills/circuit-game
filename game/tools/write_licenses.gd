extends SceneTree
## Writes Godot's own license, and the notices of the libraries built into the
## engine, into the folder given after `--`, for shipping beside the game.
## tools/export.sh runs it for every download:
##   godot --headless --path game -s res://tools/write_licenses.gd -- <folder>


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("usage: -s res://tools/write_licenses.gd -- <folder>")
		quit(2)
		return
	var dir := args[0]
	_write(dir.path_join("Godot-LICENSE.txt"), Engine.get_license_text())
	var text := "Third-party components built into Godot Engine %s\n\n" % Engine.get_version_info()["string"]
	for c in Engine.get_copyright_info():
		text += "## %s\n" % c["name"]
		for part in c["parts"]:
			for line in part["copyright"]:
				text += "Copyright: %s\n" % line
			text += "License: %s\n\n" % part["license"]
	text += "\n# License texts\n\n"
	var info := Engine.get_license_info()
	for name in info:
		text += "## %s\n\n%s\n\n" % [name, info[name]]
	_write(dir.path_join("Godot-third-party.txt"), text)
	quit()


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot write " + path)
		quit(1)
		return
	f.store_string(text)
	f.close()
