class_name Game
extends Node
## The running game. Owns the GameState, keeps it saved, and tells the screens
## when it changed or where to go next. Screens call these actions instead of
## changing the state themselves.

signal changed
signal toast(text: String)
signal navigate(screen: String, arg: String)

## Saves wait this long after the last change, so a burst of edits is one write.
const SAVE_DELAY_S := 0.5
const DAMAGED_SAVE_KEPT := "Your saved progress couldn't be read, so a fresh save was started. The old file was kept as a backup."
const DAMAGED_SAVE_LOST := "Your saved progress couldn't be read, so a fresh save was started."
const SAVE_FAILED := "Couldn't save your progress. Check that the disk isn't full."
const LOCKED_LEVEL := "Finish the level before this one to unlock it."

var state := GameState.new()
var save_path := "user://progress.json"

var _save_timer: Timer
var _save_pending := false
var _save_failed := false


func _init() -> void:
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY_S
	_save_timer.timeout.connect(save_now)
	add_child(_save_timer)


## Loads the saved progress. A damaged save starts fresh and says so once the
## first screen is up.
func boot(path := "user://progress.json") -> void:
	save_path = path
	var loaded := ProgressStorage.load(path)
	state.progress = loaded["progress"]
	if not loaded["ok"]:
		toast.emit.call_deferred(DAMAGED_SAVE_KEPT if loaded["recovered"] else DAMAGED_SAVE_LOST)


## `ignore_lock` is for development and screenshots only.
func open_level(id: String, ignore_lock := false) -> void:
	var l := Levels.by_id(id)
	if l == null:
		return
	if not ignore_lock and not state.progress.is_unlocked(id, Levels.chapter_ids(l.chapter)):
		toast.emit(LOCKED_LEVEL)
		return
	_flush()
	state.start_level(l)
	navigate.emit("level", id)
	changed.emit()


func open_map() -> void:
	_flush()
	navigate.emit("map", "")


func open_title() -> void:
	_flush()
	navigate.emit("title", "")


func commit(c: Circuit) -> void:
	state.commit(c)
	_changed()


func preview(c: Circuit) -> void:
	state.preview(c)
	changed.emit()


func undo() -> bool:
	var done := state.undo()
	if done:
		_changed()
	return done


func redo() -> bool:
	var done := state.redo()
	if done:
		_changed()
	return done


func run_tests() -> void:
	state.run_tests()
	_changed()


func next_intro() -> void:
	state.next_intro()
	_changed()


func use_hint() -> void:
	state.use_hint()
	changed.emit()


func set_zoom_layer(id: String) -> void:
	state.set_zoom_layer(id)
	_changed()


func set_ui_flag(flag: String) -> void:
	if state.ui_flags.has(flag):
		return
	state.set_ui_flag(flag)
	_changed()


func mark_terms_seen(terms: PackedStringArray) -> PackedStringArray:
	var fresh := state.mark_terms_seen(terms, state.now())
	if not fresh.is_empty():
		_changed()
	return fresh


## Ignores keys this build doesn't know and values a setting can't take.
func set_setting(key: String, value: Variant) -> void:
	if not Progress.is_valid_setting(key, value) or state.progress.settings.get(key) == value:
		return
	state.progress.settings[key] = value
	_changed()


## Starts (or restarts) the save countdown.
func save_soon() -> void:
	_save_pending = true
	if _save_timer.is_inside_tree():
		_save_timer.start(SAVE_DELAY_S)
	else:
		save_now()


func save_now() -> void:
	_save_pending = false
	_save_timer.stop()
	var ok := ProgressStorage.save(state.progress, save_path)
	if not ok and not _save_failed:
		toast.emit(SAVE_FAILED)
	_save_failed = not ok


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED:
			save_now()
		NOTIFICATION_EXIT_TREE:
			_flush()


func _changed() -> void:
	save_soon()
	changed.emit()


## Writes a pending save right away.
func _flush() -> void:
	if _save_pending:
		save_now()
