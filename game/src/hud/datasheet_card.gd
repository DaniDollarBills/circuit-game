class_name DatasheetCard
extends PanelContainer
## A part's datasheet: its circuit symbol beside a turning model of the real
## part, the datasheet rows with their words linked, the resistor color code,
## and the Go deeper note on what the game simplifies.

signal explain_requested(part_id: String)

const BAND_NAMES := ["black", "brown", "red", "orange", "yellow", "green", "blue", "violet", "grey", "white"]

var game: Game
var part: Part

var _title: RichTextLabel
var _icon: PartIcon
var _viewport: SubViewport
var _turntable: Node3D
var _camera: Camera3D
var _rows: VBoxContainer
var _bands: RichTextLabel
var _deeper: RichTextLabel
var _explain: Button


func _ready() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	# Narrower on a phone, and scrolls when it is still too tall.
	CardFit.wrap(self, col)
	var top := HBoxContainer.new()
	col.add_child(top)
	_title = HudText.label(game)
	top.add_child(_title)
	var close_b := IconButton.make("close", "Close")
	close_b.custom_minimum_size = Vector2(IconButton.MIN_TOUCH, IconButton.MIN_TOUCH)
	close_b.pressed.connect(close)
	top.add_child(close_b)
	var pics := HBoxContainer.new()
	pics.alignment = BoxContainer.ALIGNMENT_CENTER
	pics.add_theme_constant_override("separation", 12)
	col.add_child(pics)
	_icon = PartIcon.new()
	_icon.custom_minimum_size = Vector2(120, 96)
	pics.add_child(_icon)
	pics.add_child(_model_view())
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 2)
	col.add_child(_rows)
	_bands = HudText.label(game, 15)
	col.add_child(_bands)
	_deeper = HudText.label(game, 14)
	col.add_child(_deeper)
	_explain = Button.new()
	_explain.text = "Why these numbers?"
	_explain.pressed.connect(func() -> void: explain_requested.emit(part.id))
	col.add_child(_explain)
	visible = false


## `on_board` parts can explain their live numbers; tray parts can't yet.
func open(p: Part, on_board: bool) -> void:
	part = p
	HudText.put(_title, Catalog.title(p.kind) + (" " + p.id if on_board else ""), game, true)
	_icon.part = p
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	for r in Catalog.datasheet(p):
		var label := str(r["label"])
		var text := "[[%s|%s]]: %s" % [r["term"], label, r["value"]] if str(r["term"]) != "" else "%s: %s" % [label, r["value"]]
		_rows.add_child(HudText.make(game, text, 15))
	# Only fixed resistors carry color bands; a trimmer has its value printed.
	_bands.visible = p.kind == "resistor" and not bool(p.props.get("adjustable", false))
	if _bands.visible:
		HudText.put(_bands, "Color code: %s" % ", ".join(band_names(float(p.props.get("ohms", 220.0)))), game)
	var deeper := GoDeeper.for_part(p)
	_deeper.visible = deeper != ""
	if deeper != "":
		HudText.put(_deeper, deeper, game)
	_explain.visible = on_board
	_show_model(p)
	visible = true


func close() -> void:
	visible = false
	if _turntable != null:
		for c in _turntable.get_children():
			c.queue_free()


## The datasheet rows as shown, "Label: value".
func row_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for c in _rows.get_children():
		if c is RichTextLabel and not c.is_queued_for_deletion():
			out.append((c as RichTextLabel).get_parsed_text())
	return out


## The four bands' color names, IEC 60062: 150 Ω → brown, green, brown, gold.
static func band_names(ohms: float) -> PackedStringArray:
	var d := ResistorBands.digits(ohms)
	var mult: String = "gold" if d[2] == -1 else ("silver" if d[2] <= -2 else BAND_NAMES[mini(d[2], 9)])
	return PackedStringArray([BAND_NAMES[d[0]], BAND_NAMES[d[1]], mult, "gold"])


func _process(delta: float) -> void:
	if visible and _turntable != null and not bool(game.state.progress.settings.get("reduced_motion", false)):
		_turntable.rotate_y(delta * 0.6)


func _model_view() -> Control:
	var box := SubViewportContainer.new()
	box.stretch = true
	box.custom_minimum_size = Vector2(160, 120)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	box.add_child(_viewport)
	var env := WorldEnvironment.new()
	env.environment = StudioEnvironment.build(Workbench3D.HDRI, "low")
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	_viewport.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 0.8
	_viewport.add_child(sun)
	_turntable = Node3D.new()
	_viewport.add_child(_turntable)
	_camera = Camera3D.new()
	_camera.fov = 30
	_viewport.add_child(_camera)
	return box


## Frames the real part, true to size, from a little above.
func _show_model(p: Part) -> void:
	# Anti-aliasing follows the quality setting, as on the board.
	_viewport.msaa_3d = Quality.msaa(Quality.resolve(str(game.state.progress.settings.get("quality", "auto")), Quality.current_method()))
	for c in _turntable.get_children():
		_turntable.remove_child(c)
		c.queue_free()
	# On the board a battery or meter is just the two posts its leads plug
	# into; the card shows the real thing beside the board.
	var model: Node3D
	match p.kind:
		"battery":
			model = PartModels.build_holder()
		"ammeter", "voltmeter":
			model = PartModels.build_multimeter(p.kind)
		_:
			model = PartModels.build(p)
	_turntable.add_child(model)
	var box := _bounds(model)
	model.position = -box.get_center()
	var radius := maxf(box.size.length() * 0.5, 0.2)
	var distance := radius / tan(deg_to_rad(_camera.fov / 2.0)) * 1.1
	_camera.position = Vector3(0, distance * 0.45, distance * 0.9)
	_camera.look_at(Vector3.ZERO, Vector3.UP)
	_camera.near = distance * 0.05
	_camera.far = distance * 10.0


static func _bounds(node: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		var t := node.global_transform.affine_inverse() * mi.global_transform if mi.is_inside_tree() else _local(node, mi)
		var b: AABB = t * mi.mesh.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out


static func _local(root: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t
