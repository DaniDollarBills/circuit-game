extends TestCase

var _dir := ""


func before_each() -> void:
	_dir = "user://test_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)


func after_each() -> void:
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _path() -> String:
	return _dir.path_join("progress.json")


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _backups() -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(_dir):
		if f.begins_with("progress.corrupt-") and f.ends_with(".json"):
			out.append(f)
	return out


func test_missing_file_gives_defaults_ok() -> void:
	var r := ProgressStorage.load(_path())
	assert_true(r["ok"])
	assert_false(r["recovered"])
	assert_eq((r["progress"] as Progress).settings["help_level"], "heavy")


func test_corrupt_file_recovered_and_backed_up() -> void:
	var junk := "{\"version\": 1, \"completed\": {\"ch1.pop\": "
	_write(_path(), junk)
	var r := ProgressStorage.load(_path())
	assert_false(r["ok"])
	assert_true(r["recovered"])
	assert_eq((r["progress"] as Progress).completed.size(), 0)
	assert_false(FileAccess.file_exists(_path()))
	var backups := _backups()
	assert_eq(backups.size(), 1)
	if backups.size() == 1:
		assert_eq(FileAccess.get_file_as_bytes(_dir.path_join(backups[0])), junk.to_utf8_buffer())


## A save from a newer version isn't thrown away either.
func test_unknown_version_file_backed_up() -> void:
	_write(_path(), JSON.stringify({"version": 99}))
	var r := ProgressStorage.load(_path())
	assert_true(r["recovered"])
	assert_eq(_backups().size(), 1)


func test_save_then_load_round_trip() -> void:
	var p := Progress.defaults()
	p.mark_complete("ch1.pop", true, 42)
	assert_true(ProgressStorage.save(p, _path()))
	assert_false(FileAccess.file_exists(_path() + ".tmp"), "the temporary file is renamed into place")
	var r := ProgressStorage.load(_path())
	assert_true(r["ok"])
	assert_true((r["progress"] as Progress).completed["ch1.pop"]["star"])
	p.mark_complete("ch1.both", false, 43)
	assert_true(ProgressStorage.save(p, _path()), "a second save replaces the first")
	assert_true((ProgressStorage.load(_path())["progress"] as Progress).completed.has("ch1.both"))


## A crash between replacing the old file and renaming the new one (possible
## on Windows) leaves only the finished temporary file; it is used.
func test_leftover_tmp_used_when_main_missing() -> void:
	var p := Progress.defaults()
	p.mark_complete("ch1.pop", true, 42)
	_write(_path() + ".tmp", JSON.stringify(p.to_dict()))
	var r := ProgressStorage.load(_path())
	assert_true(r["ok"])
	assert_true((r["progress"] as Progress).completed.has("ch1.pop"))


func test_save_to_missing_dir_returns_false() -> void:
	assert_false(ProgressStorage.save(Progress.defaults(), "user://no_such_dir/x/progress.json"))
