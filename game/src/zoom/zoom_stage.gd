class_name ZoomStage
extends Control
## Stacks ZoomLayers and runs one camera through them: it hands the camera
## between layers, cross-fades a child over its parent near the hand-off, and
## keeps only the layers on screen rendering. Layers draw parent first; only
## the child's alpha changes.

signal layer_changed(id: String)
## Visible height in meters, plus "Skipping ahead ×N" while a magnifying link
## is cross-fading (empty otherwise).
signal view_changed(meters: float, jump_text: String)

## A hand-off that shrinks the visible distance by more than this is a jump.
const JUMP_THRESHOLD := 1.5

var _layers := {}
var _links: Array[ZoomLink] = []
var _cam: ZoomCamera
var _active := ""
var _reapply_queued := false


## Layers fill the stage, so after a resize (or the first layout) the camera is
## applied again once their sizes have settled.
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _cam != null and not _reapply_queued:
		_reapply_queued = true
		_reapply.call_deferred()


func _reapply() -> void:
	_reapply_queued = false
	if _cam != null:
		set_camera(_cam)


func add_layer(l: ZoomLayer) -> void:
	_layers[l.layer_id] = l
	add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.visible = false
	l.set_live(false, false)


func add_link(link: ZoomLink) -> void:
	_links.append(link)


func set_camera(cam: ZoomCamera) -> void:
	var infos := _infos()
	var dynamic := Callable(self, "_dynamic_child")
	_cam = ZoomMath.resolve(cam, infos, _links, dynamic)
	var entries := ZoomMath.blend(_cam, _links, dynamic)
	var shown := {}
	for e in entries:
		shown[e["layer"]] = e
	for id in _layers:
		var l: ZoomLayer = _layers[id]
		if shown.has(id):
			var lc: ZoomCamera = shown[id]["cam"]
			l.visible = true
			l.modulate.a = shown[id]["alpha"]
			l.set_live(true, id == _cam.layer)
			l.apply_view(lc.center, lc.view)
		else:
			l.visible = false
			l.set_live(false, false)
	if entries.size() > 1 and _layers.has(entries[0]["layer"]) and _layers.has(entries[1]["layer"]):
		var p: ZoomLayer = _layers[entries[0]["layer"]]
		var c: ZoomLayer = _layers[entries[1]["layer"]]
		if c.get_index() < p.get_index():
			move_child(c, p.get_index())
	if _cam.layer != _active:
		_active = _cam.layer
		layer_changed.emit(_active)
	view_changed.emit(ZoomMath.meters_visible(_cam, infos) if infos.has(_cam.layer) else 0.0,
			_jump_text(entries, infos, dynamic))


func camera() -> ZoomCamera:
	return _cam.copy() if _cam != null else null


func zoom_at_screen(factor: float, screen_pos: Vector2) -> void:
	if _cam != null:
		set_camera(ZoomMath.zoom_at(_cam, factor, screen_to_active(screen_pos)))


## Moves the content with a drag of `delta_px` pixels.
func pan_screen(delta_px: Vector2) -> void:
	if _cam != null and _layers.has(_cam.layer):
		var units_per_px := _cam.view / maxf((_layers[_cam.layer] as ZoomLayer).size.y, 1.0)
		set_camera(ZoomMath.pan(_cam, -delta_px * units_per_px))


func go_home(layer_id: String) -> void:
	if _layers.has(layer_id):
		set_camera(ZoomCamera.make(layer_id, Vector2.ZERO, (_layers[layer_id] as ZoomLayer).home_view))


func screen_to_active(p: Vector2) -> Vector2:
	var l: ZoomLayer = _layers[_cam.layer]
	return l.screen_to_layer(p - l.position, _cam.view, _cam.center)


func active_to_screen(p: Vector2) -> Vector2:
	var l: ZoomLayer = _layers[_cam.layer]
	return l.layer_to_screen(p, _cam.view, _cam.center) + l.position


func _infos() -> Dictionary:
	var out := {}
	for id in _layers:
		out[id] = (_layers[id] as ZoomLayer).info()
	return out


func _dynamic_child(layer: String, center: Vector2) -> ZoomLink:
	return (_layers[layer] as ZoomLayer).dynamic_child(center) if _layers.has(layer) else null


func _jump_text(entries: Array[Dictionary], infos: Dictionary, dynamic: Callable) -> String:
	if entries.size() < 2:
		return ""
	var link := ZoomMath.child_link(_cam, _links, dynamic)
	if link == null or not infos.has(link.parent) or not infos.has(link.child):
		return ""
	var m := ZoomMath.magnification(link, infos)
	return ScaleFormat.jump(m) if m > JUMP_THRESHOLD else ""
