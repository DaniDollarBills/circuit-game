class_name ZoomLayer
extends SubViewportContainer
## One world in the endless zoom (the bench, the inside of a wire, the Earth…),
## drawn in its own SubViewport at its own real-world scale. Subclasses put
## their content in `viewport` and follow the camera in apply_view().
##
## The layer sizes its viewport itself and shows it through a TextureRect, so
## it can render at the screen's own resolution (k screen pixels per layout
## pixel) while everything else keeps working in layout pixels.

@export var layer_id := ""
@export var meters_per_unit := 1.0
@export var min_view := 1.0
@export var max_view := 100.0
@export var home_view := 10.0

var viewport: SubViewport
var _display: TextureRect
## The camera this layer was last shown with, in its own units.
var view_center := Vector2.ZERO
var view_height := 10.0
var _resolution_scale := 1.0


func _ready() -> void:
	stretch = false
	_ensure_viewport()
	resized.connect(_apply_resolution)


func info() -> LayerInfo:
	return LayerInfo.make(layer_id, meters_per_unit, min_view, max_view)


## Virtual: move this layer's camera. Call super() to keep conversions current.
func apply_view(center: Vector2, view: float) -> void:
	view_center = center
	view_height = view


## A live layer renders every frame; only an interactive one takes input.
func set_live(live: bool, interactive: bool) -> void:
	_ensure_viewport()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if live else SubViewport.UPDATE_DISABLED
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE


## Virtual: a link into a child world chosen by what is under `center`
## (the editor picks the nearest wire). Null when there is nothing to enter.
func dynamic_child(_center: Vector2) -> ZoomLink:
	return null


## Renders the layer at `k` screen pixels per layout pixel (Retina screens,
## phones), while everything outside and inside it keeps using layout pixels.
func set_resolution_scale(k: float) -> void:
	_resolution_scale = maxf(k, 1.0)
	_apply_resolution()


func _apply_resolution() -> void:
	if viewport == null:
		return
	if _resolution_scale <= 1.0:
		viewport.size_2d_override = Vector2i.ZERO
		viewport.size_2d_override_stretch = false
		viewport.size = Vector2i(size.round()).max(Vector2i.ONE)
		return
	viewport.size_2d_override = Vector2i(size.round()).max(Vector2i.ONE)
	viewport.size_2d_override_stretch = true
	viewport.size = Vector2i((size * _resolution_scale).round()).max(Vector2i.ONE)


## Container pixels → layer units, with the view centered on the container.
func screen_to_layer(p: Vector2, view: float, center: Vector2) -> Vector2:
	return center + (p - size / 2.0) * _units_per_px(view)


func layer_to_screen(q: Vector2, view: float, center: Vector2) -> Vector2:
	return (q - center) / _units_per_px(view) + size / 2.0


func _units_per_px(view: float) -> float:
	return view / maxf(size.y, 1.0)


## The viewport lives under a plain holder node, so the container neither
## sizes nor draws it; the TextureRect draws it scaled to the layer.
func _ensure_viewport() -> void:
	if viewport != null:
		return
	stretch = false
	for c in get_children():
		if c is SubViewport:
			viewport = c
			break
	if viewport == null:
		viewport = SubViewport.new()
		viewport.name = "Viewport"
	else:
		remove_child(viewport)
	viewport.handle_input_locally = false
	var holder := Node.new()
	holder.name = "Render"
	add_child(holder)
	holder.add_child(viewport)
	_display = TextureRect.new()
	_display.name = "Display"
	_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_display.stretch_mode = TextureRect.STRETCH_SCALE
	_display.texture = viewport.get_texture()
	add_child(_display)
	_display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_resolution()
