class_name ZoomLayer
extends SubViewportContainer
## One world in the endless zoom (the bench, the inside of a wire, the Earth…),
## drawn in its own SubViewport at its own real-world scale. Subclasses put
## their content in `viewport` and follow the camera in apply_view().

@export var layer_id := ""
@export var meters_per_unit := 1.0
@export var min_view := 1.0
@export var max_view := 100.0
@export var home_view := 10.0

var viewport: SubViewport
## The camera this layer was last shown with, in its own units.
var view_center := Vector2.ZERO
var view_height := 10.0


func _ready() -> void:
	stretch = true
	_ensure_viewport()


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


## Container pixels → layer units, with the view centered on the container.
func screen_to_layer(p: Vector2, view: float, center: Vector2) -> Vector2:
	return center + (p - size / 2.0) * _units_per_px(view)


func layer_to_screen(q: Vector2, view: float, center: Vector2) -> Vector2:
	return (q - center) / _units_per_px(view) + size / 2.0


func _units_per_px(view: float) -> float:
	return view / maxf(size.y, 1.0)


func _ensure_viewport() -> void:
	if viewport != null:
		return
	for c in get_children():
		if c is SubViewport:
			viewport = c
			return
	viewport = SubViewport.new()
	viewport.name = "Viewport"
	add_child(viewport)
