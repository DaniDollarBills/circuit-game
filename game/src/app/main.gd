extends Control
## Root scene: owns the one Game, shows one screen at a time, and shows toasts
## that aren't tied to a screen (a damaged save, a failed save).

const SCREENS := {
	"title": "res://src/screens/title_screen.tscn",
	"map": "res://src/screens/map_screen.tscn",
	"level": "res://src/screens/level_screen.tscn",
}
const TOAST_S := 4.0

## Where progress is saved. Tests point it at a scratch folder before _ready.
var progress_path := "user://progress.json"
var game: Game
var screen: Control

var _toast: PanelContainer
var _toast_label: Label
var _toast_left := 0.0
var _look := []


func _ready() -> void:
	get_window().size_changed.connect(_fit_window)
	_fit_window()
	game = Game.new()
	game.name = "Game"
	add_child(game)
	game.navigate.connect(_show)
	game.toast.connect(_show_toast)
	game.changed.connect(_apply_look)
	_build_toast()
	game.boot(progress_path)
	_apply_look()
	if not _open_from_args():
		game.open_title()


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.modulate.a = clampf(_toast_left / 0.3, 0.0, 1.0)
		_toast.visible = _toast_left > 0.0


func _show(screen_id: String, _arg: String) -> void:
	if not SCREENS.has(screen_id):
		return
	if screen != null:
		# Out of the tree at once, so its deferred refresh can't take the
		# events (new words, badges) meant for the next screen.
		remove_child(screen)
		screen.queue_free()
	var next: Control = load(SCREENS[screen_id]).instantiate()
	next.set("game", game)
	add_child(next)
	move_child(next, _toast.get_index())
	screen = next


func _fit_window() -> void:
	var win := get_window()
	var logical := ScreenScale.logical_size(win.size, ScreenScale.screen_points(win.current_screen))
	if logical != Vector2i.ZERO:
		win.content_scale_size = logical


## For development and screenshots: --open=map or --open=level:<id> starts
## there instead of on the title screen.
func _open_from_args() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg == "--open=map":
			game.open_map()
			return true
		if arg.begins_with("--open=level:"):
			game.open_level(arg.substr("--open=level:".length()), true)
			if "--skip-intro" in OS.get_cmdline_user_args():
				while game.state.session.phase == "intro":
					game.next_intro()
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--show=") and screen is LevelScreen:
					(screen as LevelScreen).dev_show.call_deferred(a.substr("--show=".length()))
			return screen != null
	return false


## The theme and background follow the night and large-text settings.
func _apply_look() -> void:
	var st := game.state.progress.settings
	var look := [bool(st.get("night", false)), bool(st.get("large_text", false))]
	if look == _look:
		return
	_look = look
	theme = PastelTheme.build(look[0], look[1])
	($Background as ColorRect).color = Palette.color("cream", look[0])
	HudText.refresh_all(get_tree(), game)
	HudText.refresh_sizes(get_tree(), game)


func _build_toast() -> void:
	_toast = PanelContainer.new()
	_toast.name = "Toast"
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	_toast_label = Label.new()
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_child(_toast_label)
	add_child(_toast)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	resized.connect(_place_toast)


func _show_toast(text: String) -> void:
	if screen != null and screen.has_method("show_toast"):
		screen.call("show_toast", text)
		return
	_toast_label.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast_left = TOAST_S
	_place_toast()


func _place_toast() -> void:
	var w := minf(size.x - 32.0, 560.0)
	_toast_label.custom_minimum_size = Vector2(w - 32.0, 0)
	_toast.custom_minimum_size = Vector2(w, 0)
	_toast.size = Vector2(w, 0)
	_toast.reset_size()
	_toast.position = Vector2((size.x - w) / 2.0, 24.0)
