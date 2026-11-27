class_name MeetPartCard
extends PanelContainer
## Meet the part: the real 3D part on a turntable (drag to spin it), its legs
## labeled, its circuit symbol, what it does and where you'd find one, and a
## cutaway to look inside. One number from its datasheet, with its source,
## waits under Go deeper. The full card pops up the first time a part appears
## (its body scrolls, so its close button is always on screen); a compact one
## sits in a Learn deck, which scrolls for it.

signal closed(key: String)

const HDRI := "res://assets/third_party/polyhaven/hdri/studio_small_09_2k.hdr"
const MAX_W := 440.0
## Where each part's legs come out on its 3D model, by pin.
const LEG_MARKERS := {
	"battery": {"pos": "term_pos", "neg": "term_neg"},
	"ammeter": {"a": "jack_ma", "b": "jack_com"},
	"voltmeter": {"pos": "jack_v", "neg": "jack_com"},
	"wire": {"a": "end_a", "b": "end_b"},
}
## Degrees a second the part turns by itself until you spin it.
const AUTO_TURN := 14.0

var game: Game
var key := ""
var compact := false

var _intro: Dictionary = {}
var _stage: Control
var _viewport: SubViewport
var _camera: Camera3D
var _pivot: Node3D
var _model: Node3D
var _chips: Control
var _cutaway: Diagram
var _inside_button: Button
var _scroll: ScrollContainer
var _text: RichTextLabel
var _source: RichTextLabel
var _deeper_button: Button
var _deeper: RichTextLabel
var _close: IconButton
var _inside := false
var _spun := false
var _dragging := false


static func make(g: Game, part_key: String, is_compact := false) -> MeetPartCard:
	var card := MeetPartCard.new()
	card.game = g
	card.key = part_key
	card.compact = is_compact
	return card


func _ready() -> void:
	name = "MeetPartCard"
	add_to_group("course_card")
	_intro = PartIntros.get_intro(key)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	var sample := PartIntros.sample_part(key)
	if sample != null:
		var icon := PartIcon.new()
		icon.part = sample
		icon.custom_minimum_size = Vector2(48, 36)
		head.add_child(icon)
	var title := Label.new()
	title.text = str(_intro.get("title", key))
	title.theme_type_variation = "HeadingLabel"
	HudText.font_size(title, 20, game)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_close = IconButton.make("close", "Close")
	_close.custom_minimum_size = Vector2(IconButton.MIN_TOUCH, IconButton.MIN_TOUCH)
	_close.pressed.connect(_on_close)
	_close.visible = not compact
	head.add_child(_close)
	# The full card scrolls below its header; a compact one is in a deck,
	# which scrolls for it.
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	if compact:
		col.add_child(body)
	else:
		_scroll = CardFit.wrap(col, body)
		_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col = body
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(0, 150.0 if compact else 210.0)
	_stage.clip_contents = true
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.gui_input.connect(_on_stage_input)
	col.add_child(_stage)
	_build_turntable()
	_cutaway = Diagrams.make(str(_intro.get("inside", "")), game)
	if _cutaway != null:
		_cutaway.visible = false
		_stage.add_child(_cutaway)
		_cutaway.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_inside_button = Button.new()
	_inside_button.theme_type_variation = "FlatButton"
	_inside_button.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
	_inside_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_inside_button.pressed.connect(func() -> void: look_inside(not _inside))
	col.add_child(_inside_button)
	_text = HudText.label(game, 16)
	col.add_child(_text)
	_deeper_button = Button.new()
	_deeper_button.text = "Go deeper"
	_deeper_button.theme_type_variation = "FlatButton"
	_deeper_button.toggle_mode = true
	_deeper_button.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
	_deeper_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_deeper_button.pressed.connect(func() -> void:
		_deeper.visible = _deeper_button.button_pressed
		_source.visible = _deeper.visible
		_fill_deeper())
	col.add_child(_deeper_button)
	_deeper = HudText.label(game, 15)
	_deeper.visible = false
	col.add_child(_deeper)
	_source = HudText.label(game, 13)
	_source.visible = false
	col.add_child(_source)
	_fill_text()
	look_inside(false)


func _process(delta: float) -> void:
	if _model == null or not is_visible_in_tree():
		return
	if not _spun and not _inside and not bool(game.state.progress.settings.get("reduced_motion", false)):
		_pivot.rotation.y += deg_to_rad(AUTO_TURN) * delta
	_place_chips()


## The part's 3D model (null when the part has none to show).
func model() -> Node3D:
	return _model


## The labels on the legs, in pin order.
func leg_label_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for leg in _intro.get("legs", []):
		out.append(str(leg.get("chip", "")))
	return out


func spin(degrees: float) -> void:
	_spun = true
	if _pivot != null:
		_pivot.rotation.y += deg_to_rad(degrees)


func turn_degrees() -> float:
	return rad_to_deg(_pivot.rotation.y) if _pivot != null else 0.0


func look_inside(on: bool) -> void:
	_inside = on and _cutaway != null
	if _cutaway != null:
		_cutaway.visible = _inside
	var view := _stage.get_node_or_null("Turntable") as Control
	if view != null:
		view.visible = not _inside
	if _viewport != null:
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED if _inside else SubViewport.UPDATE_WHEN_VISIBLE
	_chips.visible = not _inside
	_inside_button.text = "Back to the part" if _inside else "Look inside"
	_inside_button.visible = _cutaway != null


func showing_inside() -> bool:
	return _inside


func cutaway() -> Diagram:
	return _cutaway


func close_button() -> Button:
	return _close


## What the card says before Go deeper.
func body_text() -> String:
	return _text.get_parsed_text()


## The datasheet number, the deeper story and the source, once Go deeper is
## open ("" until then).
func deeper_text() -> String:
	if not _deeper.visible:
		return ""
	return _deeper.get_parsed_text() + "\n" + _source.get_parsed_text()


func deeper_button() -> Button:
	return _deeper_button


func inside_button() -> Button:
	return _inside_button


## The full card's scrolling body (null for a compact card).
func body_scroll() -> ScrollContainer:
	return _scroll


## Sizes the card to `width` (at most MAX_W) and its content's height, at most
## the area's (past that the body scrolls under the header and its close
## button), centered in `area`. A short area gets a shorter turntable.
func fit_into(area: Rect2, width: float) -> void:
	var w := minf(minf(width, MAX_W), area.size.x)
	if not compact:
		_stage.custom_minimum_size.y = clampf(area.size.y * 0.42, 120.0, 210.0)
	size = Vector2(w, 0)
	var h := get_combined_minimum_size().y
	if _scroll != null:
		var pad := get_theme_stylebox("panel").get_minimum_size()
		var col := get_child(0) as VBoxContainer
		var fixed := col.get_combined_minimum_size().y - _scroll.get_combined_minimum_size().y
		h = fixed + (_scroll.get_child(0) as Control).get_combined_minimum_size().y + pad.y
	size = Vector2(w, minf(h, area.size.y))
	position = (area.position + (area.size - size) / 2.0).round()


func _on_close() -> void:
	visible = false
	closed.emit(key)


func _fill_text() -> void:
	var lines := PackedStringArray([str(_intro.get("does", ""))])
	for leg in _intro.get("legs", []):
		lines.append("• " + str(leg.get("text", "")))
	lines.append("Where you'll find one: " + str(_intro.get("where", "")))
	HudText.put(_text, "\n".join(lines), game)
	var spec: Dictionary = _intro.get("spec", {})
	_deeper_button.visible = str(spec.get("text", "")) != "" or str(_intro.get("deeper", "")) != ""
	_fill_deeper()


## Go deeper's text is put in only while it shows, so its words are met when
## they're read (a New word card for a hidden word would cover the card).
func _fill_deeper() -> void:
	if not _deeper.visible:
		return
	var spec: Dictionary = _intro.get("spec", {})
	var more := PackedStringArray()
	for part in [str(spec.get("text", "")), str(_intro.get("deeper", ""))]:
		if part != "":
			more.append(part)
	HudText.put(_deeper, "\n".join(more), game)
	HudText.put(_source, "Source: " + str(spec.get("source", "")), game, false, false)


## The part in its own small world: studio light, a soft backdrop, a camera
## looking down at it from the front, and a pivot that turns it.
func _build_turntable() -> void:
	var view := SubViewportContainer.new()
	view.name = "Turntable"
	view.stretch = true
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	view.add_child(_viewport)
	var env := WorldEnvironment.new()
	var e := StudioEnvironment.build(HDRI, "low")
	e.background_mode = Environment.BG_CLEAR_COLOR
	env.environment = e
	_viewport.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 25, 0)
	sun.light_energy = 0.7
	_viewport.add_child(sun)
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	_viewport.add_child(_pivot)
	_model = _build_model()
	if _model != null:
		_pivot.add_child(_model)
		_model.position = Vector3.ZERO
		_model.rotation = Vector3.ZERO
		_model.position = -_bounds(_model).get_center()
	_camera = Camera3D.new()
	_camera.fov = 30.0
	_viewport.add_child(_camera)
	_frame_camera()
	_chips = Control.new()
	_chips.name = "Legs"
	_chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_chips)
	_chips.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for leg in _intro.get("legs", []):
		var chip := PanelContainer.new()
		chip.theme_type_variation = "PillPanel"
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := Label.new()
		l.text = str(leg.get("chip", ""))
		HudText.font_size(l, 13, game)
		chip.add_child(l)
		chip.set_meta("pin", str(leg.get("pin", "")))
		_chips.add_child(chip)


func _build_model() -> Node3D:
	match key:
		"battery":
			return PartModels.build_holder()
		"ammeter", "voltmeter":
			return PartModels.build_multimeter(key)
		"wire":
			return _jumper_wire()
	var p := PartIntros.sample_part(key)
	# An LED comes new, legs uncut, so its longer + leg shows.
	return PartModels.build(p, key == "led") if p != null else null


## A short jumper wire: green insulation in an arch, bare copper at each end.
func _jumper_wire() -> Node3D:
	var root := Node3D.new()
	root.name = "wire"
	var pts := PackedVector3Array()
	for i in 17:
		var s := i / 16.0
		pts.append(Vector3(lerpf(-2.4, 2.4, s), sin(s * PI) * 1.4, 0))
	var tube := MeshInstance3D.new()
	tube.mesh = WireMesh.tube(pts, 0.9)
	tube.material_override = Materials.plastic_gloss(Color("#3FA34D"))
	root.add_child(tube)
	for end in [["end_a", -2.4], ["end_b", 2.4]]:
		var tip := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.032
		cyl.bottom_radius = 0.032
		cyl.height = 0.5
		tip.mesh = cyl
		tip.material_override = Materials.copper()
		tip.position = Vector3(float(end[1]), -0.25, 0)
		root.add_child(tip)
		var m := Marker3D.new()
		m.name = end[0]
		m.position = Vector3(float(end[1]), -0.5, 0)
		root.add_child(m)
	return root


func _frame_camera() -> void:
	var b := _bounds(_pivot) if _model != null else AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	var r := maxf(b.size.length() / 2.0, 0.5)
	var dist := r / tan(deg_to_rad(_camera.fov / 2.0)) * 1.15
	var dir := Vector3(0, 0.62, 1).normalized()
	_camera.position = dir * dist
	_camera.look_at_from_position(_camera.position, Vector3.ZERO, Vector3.UP)
	_camera.near = maxf(dist * 0.02, 0.01)
	_camera.far = dist * 6.0


## Each leg's label sits where its leg ends, as the part turns.
func _place_chips() -> void:
	if _camera == null or _model == null or not _camera.is_inside_tree():
		return
	var markers: Dictionary = LEG_MARKERS.get(key, {})
	var vp := Vector2(_viewport.size)
	var stage := _stage.size
	for chip in _chips.get_children():
		var pin := str(chip.get_meta("pin"))
		var marker := _model.find_child(str(markers.get(pin, "tip_" + pin)), true, false) as Node3D
		if marker == null or vp.x <= 0.0:
			chip.visible = false
			continue
		var at := _camera.unproject_position(marker.global_position) * (stage / vp)
		var c := chip as Control
		c.reset_size()
		c.position = at - c.size / 2.0
		c.visible = not _camera.is_position_behind(marker.global_position)
	_spread_chips(stage)


## Legs close together (an LED's are 2.54 mm apart) would hide each other's
## labels: overlapping labels move apart sideways, then stay on the stage.
func _spread_chips(stage: Vector2) -> void:
	var shown: Array[Control] = []
	for chip in _chips.get_children():
		if (chip as Control).visible:
			shown.append(chip)
	shown.sort_custom(func(a: Control, b: Control) -> bool: return a.position.x < b.position.x)
	for i in range(1, shown.size()):
		var a := shown[i - 1]
		var b := shown[i]
		var overlap := a.position.x + a.size.x + 6.0 - b.position.x
		if overlap > 0.0 and absf(a.position.y - b.position.y) < a.size.y + 4.0:
			a.position.x -= overlap / 2.0
			b.position.x += overlap / 2.0
	for c in shown:
		c.position = c.position.clamp(Vector2.ZERO, (stage - c.size).max(Vector2.ZERO)).round()


func _on_stage_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press != null and press.button_index == MOUSE_BUTTON_LEFT:
		_dragging = press.pressed
	var touch := event as InputEventScreenTouch
	if touch != null:
		_dragging = touch.pressed
	var motion := event as InputEventMouseMotion
	if motion != null and _dragging:
		spin(motion.relative.x * 0.6)
		accept_event()
	var drag := event as InputEventScreenDrag
	if drag != null:
		spin(drag.relative.x * 0.6)
		accept_event()


static func _bounds(node: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		var b: AABB = _transform_to(node, mi) * mi.mesh.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out


## `mi`'s transform relative to `root` (works before either is in the tree).
static func _transform_to(root: Node3D, mi: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = mi
	while n != null and n != root:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t
