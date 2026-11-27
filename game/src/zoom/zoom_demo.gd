extends Control
## A two-layer zoom to watch the cross-fade: scroll to zoom at the cursor, drag
## to pan. For captures, --view=<units> sets the starting view of the outer layer.


class DemoLayer extends ZoomLayer:
	var title := ""
	var title_y := 24.0
	var tint := Color.WHITE
	var ring := Color.WHITE
	var cam2d: Camera2D

	func _ready() -> void:
		super._ready()
		var world := Rings.new()
		world.tint = tint
		world.ring = ring
		viewport.add_child(world)
		cam2d = Camera2D.new()
		viewport.add_child(cam2d)
		var overlay := CanvasLayer.new()
		var label := Label.new()
		label.text = title
		label.position = Vector2(24, title_y)
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Palette.color("ink"))
		overlay.add_child(label)
		viewport.add_child(overlay)

	func apply_view(center: Vector2, view: float) -> void:
		super.apply_view(center, view)
		if cam2d != null:
			cam2d.position = center
			cam2d.zoom = Vector2.ONE * (maxf(size.y, 1.0) / view)


## A pastel field with rings 1, 3, 10, 30 and 100 units across, so the scale shows.
class Rings extends Node2D:
	var tint := Color.WHITE
	var ring := Color.WHITE

	func _draw() -> void:
		draw_rect(Rect2(-10000, -10000, 20000, 20000), tint)
		for r in [0.5, 1.5, 5.0, 15.0, 50.0]:
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, ring, r * 0.08, true)


var stage: ZoomStage
var readout: Label
var _dragging := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = PastelTheme.build()
	stage = ZoomStage.new()
	add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_layer(_layer("outer", "Outer layer: 1 unit = 1 cm", 0.01, 1.0, 400.0, 100.0,
			Palette.color("lilac"), Palette.color("lavender")))
	stage.add_layer(_layer("inner", "Inner layer: 1 unit = 1 µm", 1e-6, 5.0, 100.0, 100.0,
			Palette.color("mint"), Palette.color("sky")))
	stage.add_link(ZoomLink.make("outer", "inner", Vector2.ZERO, 10.0, 100.0))
	readout = Label.new()
	readout.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	readout.position = Vector2(24, -56)
	readout.add_theme_font_size_override("font_size", 22)
	add_child(readout)
	stage.view_changed.connect(_on_view_changed)
	var view := 100.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--view="):
			view = float(arg.substr(7))
	stage.set_camera(ZoomCamera.make("outer", Vector2.ZERO, view))


func _layer(id: String, title: String, mpu: float, lo: float, hi: float, home: float, tint: Color, ring: Color) -> DemoLayer:
	var l := DemoLayer.new()
	l.layer_id = id
	l.title = title
	l.title_y = 24.0 + 44.0 * stage.get_child_count()
	l.meters_per_unit = mpu
	l.min_view = lo
	l.max_view = hi
	l.home_view = home
	l.tint = tint
	l.ring = ring
	return l


func _on_view_changed(meters: float, jump_text: String) -> void:
	readout.text = "Seeing %s top to bottom%s" % [ScaleFormat.meters(meters), "   " + jump_text if jump_text != "" else ""]


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var b := event as InputEventMouseButton
		if b.pressed and b.button_index == MOUSE_BUTTON_WHEEL_UP:
			stage.zoom_at_screen(1.15, b.position)
		elif b.pressed and b.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			stage.zoom_at_screen(1.0 / 1.15, b.position)
		elif b.button_index == MOUSE_BUTTON_LEFT:
			_dragging = b.pressed
	elif event is InputEventMouseMotion and _dragging:
		stage.pan_screen((event as InputEventMouseMotion).relative)
