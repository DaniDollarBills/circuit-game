extends SceneTree
## Headless test runner.
## Usage: godot --headless --path game -s res://tests/run_tests.gd -- [--filter=<text>]
## Runs every test_* method in res://tests/**/test_*.gd. A test fails if it
## records an assertion failure or causes an engine/script error it did not
## declare with allow_errors().

class _ErrorCatcher extends Logger:
	var _mutex := Mutex.new()
	var _errors: PackedStringArray = PackedStringArray()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		_errors.append("%s:%d %s %s" % [file, line, code, rationale])
		_mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass

	func take() -> PackedStringArray:
		_mutex.lock()
		var out := _errors.duplicate()
		_errors.clear()
		_mutex.unlock()
		return out


var _passed := 0
var _failed := 0
var _catcher := _ErrorCatcher.new()


func _initialize() -> void:
	OS.add_logger(_catcher)
	_run.call_deferred()


func _run() -> void:
	var filter := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.substr("--filter=".length())
	var files := _find_tests("res://tests")
	files.sort()
	for path in files:
		_catcher.take()
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			_report_fail(path + "::<load>", "could not load script")
			continue
		for m in script.get_script_method_list():
			var test_name: String = m["name"]
			if not test_name.begins_with("test_"):
				continue
			var id := "%s::%s" % [path, test_name]
			if not filter.is_empty() and id.find(filter) == -1:
				continue
			await _run_one(script, test_name, id)
	print("%d passed, %d failed" % [_passed, _failed])
	OS.remove_logger(_catcher)
	quit(1 if (_failed > 0 or _passed == 0) else 0)


func _run_one(script: GDScript, test_name: String, id: String) -> void:
	_catcher.take()
	var inst: Object = script.new()
	inst.set("tree", self)
	if inst.has_method("before_each"):
		await inst.call("before_each")
	await Callable(inst, test_name).call()
	if inst.has_method("after_each"):
		await inst.call("after_each")
	inst.call("_free_tracked")
	var fails: PackedStringArray = inst.get("failures")
	var errors := _catcher.take()
	var allowed: int = inst.get("allowed_errors")
	if errors.size() > allowed:
		fails.append("unexpected engine errors: " + " | ".join(errors))
	if fails.is_empty():
		_passed += 1
		print("PASS ", id)
	else:
		_report_fail(id, "; ".join(fails))


func _report_fail(id: String, why: String) -> void:
	_failed += 1
	print("FAIL %s: %s" % [id, why])


func _find_tests(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				out.append_array(_find_tests(full))
		elif entry.begins_with("test_") and entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
	return out
