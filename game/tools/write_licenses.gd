extends SceneTree

const Notices := preload("res://src/app/godot_notices.gd")
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
	_write(dir.path_join("Godot-LICENSE.txt"), Notices.license())
	_write(dir.path_join("Godot-third-party.txt"), Notices.third_party())
	quit()


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot write " + path)
		quit(1)
		return
	f.store_string(text)
	f.close()
