class_name ProgressStorage
extends RefCounted
## Reads and writes progress so that a crash or a damaged file never loses the
## player's work silently. Saves go to "<path>.tmp" and are then renamed over
## the real file; a file that can't be used is kept as
## progress.corrupt-<unix>.json in the same folder and the game starts fresh.


## {progress, ok, recovered}: ok is false when a file existed but couldn't be
## used; recovered is true when that file was backed up.
static func load(path := "user://progress.json") -> Dictionary:
	if not FileAccess.file_exists(path):
		var tmp := path + ".tmp"
		var left_over := _read(tmp) if FileAccess.file_exists(tmp) else null
		return {"progress": left_over if left_over != null else Progress.defaults(), "ok": true, "recovered": false}
	var p := _read(path)
	if p != null:
		return {"progress": p, "ok": true, "recovered": false}
	var backed_up := DirAccess.rename_absolute(path, _backup_path(path)) == OK
	return {"progress": Progress.defaults(), "ok": false, "recovered": backed_up}


static func save(p: Progress, path := "user://progress.json") -> bool:
	var tmp := path + ".tmp"
	var text := JSON.stringify(p.to_dict(), "\t")
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	var stored := f.store_string(text)
	f.flush()
	stored = stored and f.get_error() == OK
	f.close()
	if not stored:
		DirAccess.remove_absolute(tmp)
		return false
	return _commit(tmp, path, text)


## Renames the finished temporary file over the real one, but only after reading
## it back whole. A write that came out short (disk full, a size limit, an error
## that only showed up on close) is removed instead, and the good file stays.
static func _commit(tmp: String, path: String, expected: String) -> bool:
	if FileAccess.get_file_as_string(tmp) != expected:
		DirAccess.remove_absolute(tmp)
		return false
	return DirAccess.rename_absolute(tmp, path) == OK


static func _read(path: String) -> Progress:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return Progress.from_dict(json.data)


static func _backup_path(path: String) -> String:
	var dir := path.get_base_dir()
	var stem := path.get_file().get_basename()
	var unix := int(Time.get_unix_time_from_system())
	var out := dir.path_join("%s.corrupt-%d.json" % [stem, unix])
	var n := 2
	while FileAccess.file_exists(out):
		out = dir.path_join("%s.corrupt-%d-%d.json" % [stem, unix, n])
		n += 1
	return out
