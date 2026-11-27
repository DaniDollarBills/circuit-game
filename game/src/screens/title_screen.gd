class_name TitleScreen
extends Control
## The title: one continuous zoom from the whole Earth, through an undersea
## cable's landing beach and a grain of sand, down to a single silicon atom.
## Captions name each step; new words get a one-line definition underneath.
## Any zoom or drag by the player stops the autoplay. With reduced motion the
## title shows each layer in turn, fading through cream.
## Development and screenshots: --layer=<id> opens at that layer's home view.

const CAPTIONS := {
	"title.globe": "This is Earth. The glowing lines are undersea cables that carry the internet.",
	"title.coast": "Some of those cables come ashore on beaches like this one.",
	"title.beach": "A quiet beach. This is where your journey starts.",
	"title.grain": "One grain of sand.",
	"title.silica": "Sand is mostly silica: silicon and oxygen atoms locked together.",
	"title.atom": "A silicon atom. Everything you'll build starts here.",
}
const LAYER_SCRIPTS := {
	"title.globe": preload("res://src/scenes/title/globe_layer.gd"),
	"title.coast": preload("res://src/scenes/title/coast_layer.gd"),
	"title.beach": preload("res://src/scenes/title/beach_layer.gd"),
	"title.grain": preload("res://src/scenes/title/grain_layer.gd"),
	"title.silica": preload("res://src/scenes/title/silica_layer.gd"),
	"title.atom": preload("res://src/scenes/title/atom_layer.gd"),
}
const SLIDE_S := 4.0
const FADE_S := 0.6

var game: Game
var stage: ZoomStage
var director: TitleDirector
var autoplay := true
var layers := {}

var _caption: RichTextLabel
var _subtitles: VBoxContainer
var _deeper: Label
var _simple: CheckButton
var _start: Button
var _skip: Button
var _scale_bar: ScaleBar
var _settings: SettingsSheet
var _fade: ColorRect
var _pointer: PointerInput
var _layer := ""
var _slideshow := false
var _slide := 0
var _slide_t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.012, 0.025)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage = ZoomStage.new()
	add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for id in TitleChain.ORDER:
		var l: TitleLayer = LAYER_SCRIPTS[id].new()
		layers[id] = l
		stage.add_layer(l)
	for link in TitleChain.links():
		stage.add_link(link)
	director = TitleDirector.new(TitleChain.infos(), TitleChain.links())
	_build_input()
	_build_ui()
	stage.layer_changed.connect(_on_layer)
	stage.view_changed.connect(func(meters: float, jump: String) -> void: _scale_bar.set_view(meters, jump, stage.size.y))
	var first := "title.globe"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--layer=") and LAYER_SCRIPTS.has(arg.substr(8)):
			first = arg.substr(8)
			autoplay = false
	_slideshow = autoplay and bool(_settings_value("reduced_motion", false))
	_go_home.call_deferred(first)


func _process(delta: float) -> void:
	if _slideshow:
		_step_slideshow(delta)
	elif autoplay and stage.camera() != null:
		stage.set_camera(director.step(stage.camera(), minf(delta, 0.1)))
		if director.finished:
			_finish()


## Starts the zoom over from `id`'s home view.
func _go_home(id: String) -> void:
	stage.set_camera(ZoomCamera.make(id, Vector2.ZERO, TitleChain.home(id)))
	_on_layer(stage.camera().layer)
	if not autoplay:
		_finish()


func skip() -> void:
	_slideshow = false
	_fade.modulate.a = 0.0
	stage.set_camera(director.skip_to_end())
	_finish()


func _finish() -> void:
	autoplay = false
	_skip.visible = false
	_start.visible = true


func _on_layer(id: String) -> void:
	if id == _layer:
		return
	_layer = id
	var p := game.state.progress
	# Light links: the title sits on dark space and photographs.
	var r := GlossaryText.render(CAPTIONS.get(id, ""), p.seen_terms, true, true)
	_caption.text = "[center]%s[/center]" % r["bbcode"]
	for c in _subtitles.get_children():
		c.queue_free()
	for t in r["new_terms"]:
		var e: Dictionary = Glossary.ENTRIES.get(t, {})
		if e.is_empty():
			continue
		var line := Label.new()
		line.text = "%s: %s" % [e["title"], e["simple"]]
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.add_theme_font_size_override("font_size", 14)
		line.add_theme_color_override("font_color", Color(0.86, 0.85, 0.92))
		_subtitles.add_child(line)
	if not (r["new_terms"] as PackedStringArray).is_empty():
		game.mark_terms_seen(r["new_terms"])
		# The subtitles stand in for New word cards here; badges become toasts.
		for e in game.state.take_events():
			if e["type"] == "badge":
				for a in Achievements.ALL:
					if a["id"] == e["id"]:
						game.toast.emit("Badge earned: %s" % a["name"])
	var atom := id == "title.atom"
	_deeper.visible = atom
	_simple.visible = atom


func _step_slideshow(delta: float) -> void:
	_slide_t += delta
	var order := director.slideshow_order()
	if _slide_t >= SLIDE_S:
		_slide_t -= SLIDE_S
		_slide += 1
		if _slide >= order.size():
			_slideshow = false
			_fade.modulate.a = 0.0
			_finish()
			return
		stage.set_camera(ZoomCamera.make(order[_slide], Vector2.ZERO, TitleChain.home(order[_slide])))
	# Fade out over the last 0.3 s of a slide and in over the first 0.3 s.
	var half := FADE_S / 2.0
	var a := 0.0
	if _slide_t > SLIDE_S - half and _slide < order.size() - 1:
		a = (_slide_t - (SLIDE_S - half)) / half
	elif _slide_t < half and _slide > 0:
		a = 1.0 - _slide_t / half
	_fade.modulate.a = clampf(a, 0.0, 1.0)


## Wheel, pinch and drag move the zoom by hand and stop the autoplay.
func _build_input() -> void:
	var catcher := Control.new()
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(catcher)
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pointer = PointerInput.new()
	catcher.add_child(_pointer)
	catcher.gui_input.connect(func(e: InputEvent) -> void: _pointer.feed(e, PointerInput.now()))
	_pointer.gesture.connect(_on_gesture)


func _on_gesture(g: Dictionary) -> void:
	match str(g["type"]):
		"zoom":
			_take_over()
			stage.zoom_at_screen(float(g["factor"]), g["at"])
		"pan":
			_take_over()
			stage.pan_screen(g["delta"])
		"drag_move":
			_take_over()


func _take_over() -> void:
	if autoplay or _slideshow:
		_slideshow = false
		_fade.modulate.a = 0.0
		_finish()


func _build_ui() -> void:
	var title := Label.new()
	title.text = "Circuit"
	title.theme_type_variation = "HeadingLabel"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.97, 0.95, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.09, 0.15, 0.7))
	title.add_theme_constant_override("outline_size", 6)
	title.position = Vector2(24, 16)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_skip = Button.new()
	_skip.text = "Skip"
	_skip.pressed.connect(skip)
	top.add_child(_skip)
	var gear := IconButton.make("gear", "Settings")
	gear.pressed.connect(func() -> void:
		_settings.open()
		_settings.visible = true)
	top.add_child(gear)
	top.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var bottom := VBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 8)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -260
	bottom.offset_bottom = -20
	bottom.offset_left = 24
	bottom.offset_right = -24
	_caption = RichTextLabel.new()
	_caption.bbcode_enabled = true
	_caption.fit_content = true
	_caption.scroll_active = false
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("normal_font_size", 22)
	_caption.add_theme_color_override("default_color", Color(0.97, 0.96, 1.0))
	_caption.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.12, 0.8))
	_caption.add_theme_constant_override("outline_size", 6)
	_caption.meta_clicked.connect(func(meta: Variant) -> void: game.term_requested.emit(str(meta)))
	bottom.add_child(_caption)
	_subtitles = VBoxContainer.new()
	_subtitles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(_subtitles)
	_deeper = Label.new()
	_deeper.text = AtomLayer.GO_DEEPER
	_deeper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_deeper.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_deeper.add_theme_font_size_override("font_size", 14)
	_deeper.add_theme_color_override("font_color", Color(0.8, 0.78, 0.9))
	_deeper.visible = false
	bottom.add_child(_deeper)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(row)
	_simple = CheckButton.new()
	_simple.text = "Simple picture"
	_simple.visible = false
	_simple.toggled.connect(func(on: bool) -> void: (layers["title.atom"] as AtomLayer).simple_picture = on)
	row.add_child(_simple)
	_start = Button.new()
	_start.text = "Continue" if not game.state.progress.completed.is_empty() else "Start"
	_start.custom_minimum_size = Vector2(180, 52)
	_start.visible = false
	_start.pressed.connect(func() -> void: game.open_map())
	row.add_child(_start)
	_scale_bar = ScaleBar.new()
	add_child(_scale_bar)
	_scale_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_scale_bar.offset_left = 20
	_scale_bar.offset_top = -72
	_scale_bar.offset_right = 220
	_scale_bar.offset_bottom = -20
	_fade = ColorRect.new()
	_fade.color = Palette.color("cream")
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings = SettingsSheet.new()
	_settings.game = game
	add_child(_settings)
	_settings.set_anchors_and_offsets_preset(Control.PRESET_CENTER)


func _settings_value(key: String, fallback: Variant) -> Variant:
	return game.state.progress.settings.get(key, fallback)
