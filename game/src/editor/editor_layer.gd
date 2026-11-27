class_name EditorLayer
extends ZoomLayer
## The building board: the real-looking workbench (the default) or the
## schematic, chosen by settings.view_style, with one pointer input feeding one
## editor controller. Positions go from the screen to the grid through the view
## on show. The layer never changes the circuit itself: it asks with
## commit_requested and is told the new state with set_state.

signal commit_requested(c: Circuit)
signal menu_requested(target: Dictionary, screen_pos: Vector2)
signal value_requested(part_id: String)
signal datasheet_requested(part_id: String)
signal selected(id: String)
signal toast_requested(text: String)
signal ghost_tapped(kind: String, data: Dictionary)

var controller := EditorController.new()
var pointer: PointerInput
var workbench: Workbench3D
var schematic: Node2D
var circuit_view: CircuitView
var flow_view: FlowView
var circuit := Circuit.new()
var sim: SimResult
var settings: Dictionary = Progress.DEFAULT_SETTINGS.duplicate()
var ghosts: Dictionary = {}
var highlights: Array = []
var tray: Array = []
var tray_used: Array[int] = []


func _ready() -> void:
	super._ready()
	viewport.msaa_2d = Viewport.MSAA_4X
	viewport.msaa_3d = Viewport.MSAA_4X
	workbench = Workbench3D.new()
	viewport.add_child(workbench)
	schematic = Node2D.new()
	circuit_view = CircuitView.new()
	flow_view = FlowView.new()
	schematic.add_child(circuit_view)
	schematic.add_child(flow_view)
	viewport.add_child(schematic)
	pointer = PointerInput.new()
	add_child(pointer)
	pointer.gesture.connect(_on_gesture)
	resized.connect(func() -> void: apply_view(view_center, view_height))
	_apply_style()
	apply_view(view_center, view_height)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event as InputEventMouseMotion).button_mask == 0 \
			and event.device != InputEvent.DEVICE_ID_EMULATION:
		_on_gesture({"type": "hover", "at": (event as InputEventMouseMotion).position})
	pointer.feed(event, PointerInput.now())
	accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return
	var key := ""
	match (event as InputEventKey).keycode:
		KEY_R:
			key = "rotate"
		KEY_DELETE, KEY_BACKSPACE:
			key = "delete"
		KEY_ESCAPE:
			key = "cancel"
	if key != "":
		_on_gesture({"type": "key", "key": key})


func set_state(c: Circuit, s: SimResult, st: Dictionary, gh: Dictionary, hl: Array) -> void:
	for p in c.parts:
		if circuit.find_part(p.id) == null and not circuit.parts.is_empty():
			circuit_view.pops[p.id] = 0.0
			_pop_3d(p.id)
	circuit = c
	sim = s
	settings = st
	ghosts = gh
	highlights = hl
	_apply_style()
	if _physical():
		workbench.set_state(c, s, st, gh, hl)
		if not circuit_view.pops.is_empty():
			for id in circuit_view.pops:
				_pop_3d(id)
	circuit_view.circuit = c
	circuit_view.sim = s
	circuit_view.settings = st
	circuit_view.ghosts = gh
	circuit_view.highlights = hl
	circuit_view.selection = controller.selection
	flow_view.set_flows(c, s, st)
	circuit_view.queue_redraw()


func set_tray(items: Array, used: Array[int]) -> void:
	tray = items
	tray_used = used


func begin_placing(i: int) -> void:
	controller.begin_placing(i)


## The view height that shows the whole circuit plus 3 units of margin (at
## least 12); its center is fit_center(). In the real view that includes the
## battery holders and meters beside the board.
func fit_view() -> float:
	var bounds := _fit_bounds()
	var aspect := size.y / maxf(size.x, 1.0)
	var widen := 1.0
	var raised := 0.0
	if _physical():
		widen = Workbench3D.near_edge_widening()
		raised = Workbench3D.raised_allowance(MeterRig.tallest(circuit))
	var view := maxf(12.0, maxf(bounds.size.y, bounds.size.x * aspect * widen) + raised)
	home_view = view
	return view


func fit_center() -> Vector2:
	return _fit_bounds().get_center()


## The area fit_view() frames, in grid units.
func _fit_bounds() -> Rect2:
	var bounds := Rect2()
	var first := true
	for p in circuit.parts:
		var r := CircuitGeometry.part_rect(p)
		bounds = r if first else bounds.merge(r)
		first = false
	for w in circuit.wires:
		for pt in CircuitGeometry.wire_path(circuit, w):
			bounds = bounds.expand(pt)
	if first:
		bounds = Rect2(-6, -6, 12, 12)
	if _physical():
		var world := MeterRig.content_rect(circuit)
		bounds = bounds.merge(Rect2(world.position / PartDims.GRID, world.size / PartDims.GRID))
	return bounds.grow(3.0)


func apply_view(center: Vector2, view: float) -> void:
	super.apply_view(center, view)
	if workbench == null:
		return
	if _physical():
		workbench.apply_view(center, view)
	for v in [circuit_view, flow_view]:
		v.center = center
		v.ppu = size.y / maxf(view, 1e-6)
		v.size = size
		v.queue_redraw()


func screen_to_grid(px: Vector2) -> Vector2:
	if _physical():
		return workbench.screen_to_grid(px)
	return (px - size / 2.0) / circuit_view.ppu + circuit_view.center


func grid_to_screen(g: Vector2) -> Vector2:
	if _physical():
		return workbench.grid_to_screen(g)
	return circuit_view.to_screen(g)


func pin_screen_pos(part_id: String, pin: String) -> Vector2:
	return grid_to_screen(Vector2(CircuitGeometry.pin_position(circuit.find_part(part_id), pin)))


## Grid units within which a touch counts as on a pin: at least 0.35, and at
## least 22 pixels on screen.
func pin_radius() -> float:
	return maxf(0.35, 22.0 / (size.y / maxf(view_height, 1e-6)))


func dynamic_child(_center: Vector2) -> ZoomLink:
	return null


func _physical() -> bool:
	return str(settings.get("view_style", "physical")) != "schematic"


func _apply_style() -> void:
	if workbench == null:
		return
	var physical := _physical()
	workbench.visible = physical
	workbench.set_process(physical)
	viewport.disable_3d = not physical
	schematic.visible = not physical


func _on_gesture(g: Dictionary) -> void:
	var gg := g.duplicate()
	if g.has("at"):
		gg["screen"] = g["at"]
		gg["at"] = screen_to_grid(g["at"])
	if gg["type"] == "tap" and _tap_ghost(gg["at"]):
		return
	var ctx := {"circuit": circuit, "tray": tray, "tray_used": tray_used, "pin_r": pin_radius(), "wire_r": pin_radius() * 0.8}
	for e in controller.handle(gg, ctx):
		_apply_effect(e, gg)
	_update_preview()


func _apply_effect(e: Dictionary, g: Dictionary) -> void:
	match e["type"]:
		"commit":
			commit_requested.emit(e["circuit"])
		"menu":
			var target := {}
			if e.has("part"):
				target["part"] = e["part"]
			if e.has("wire"):
				target["wire"] = e["wire"]
			menu_requested.emit(target, g.get("screen", Vector2.ZERO))
		"value":
			value_requested.emit(e["part"])
		"datasheet":
			datasheet_requested.emit(e["part"])
		"selected":
			selected.emit(e["id"])
		"toast":
			toast_requested.emit(e["text"])
		"camera_zoom":
			_zoom(e["factor"], g.get("screen", size / 2.0))
		"camera_pan":
			_pan(e["delta"])
	circuit_view.selection = controller.selection
	circuit_view.queue_redraw()


func _zoom(factor: float, screen: Vector2) -> void:
	var stage := get_parent() as ZoomStage
	if stage != null:
		stage.zoom_at_screen(factor, screen + position)
		return
	var cam := ZoomMath.zoom_at(ZoomCamera.make(layer_id, view_center, view_height), factor, screen_to_grid(screen))
	apply_view(cam.center, clampf(cam.view, min_view, max_view))


func _pan(delta_px: Vector2) -> void:
	var stage := get_parent() as ZoomStage
	if stage != null:
		stage.pan_screen(delta_px)
		return
	apply_view(view_center - delta_px / (size.y / maxf(view_height, 1e-6)), view_height)


## A tap on a hint's ghost part or ghost wire places it.
func _tap_ghost(at: Vector2) -> bool:
	if ghosts.is_empty():
		return false
	for p in ghosts.get("parts", []):
		if CircuitGeometry.part_rect(p).has_point(at):
			ghost_tapped.emit("part", {"part": p})
			return true
	var with_ghosts := circuit.copy()
	for p in ghosts.get("parts", []):
		with_ghosts.parts.append((p as Part).copy())
	for gw in ghosts.get("wires", []):
		var path := CircuitGeometry.wire_path(with_ghosts, Wire.make("ghost", gw["a_part"], gw["a_pin"], gw["b_part"], gw["b_pin"]))
		if HitTest.distance_to_path(at, path) <= pin_radius():
			ghost_tapped.emit("wire", gw)
			return true
	return false


func _update_preview() -> void:
	var m := controller.mode
	var preview := {}
	match m["kind"]:
		"wiring":
			var from := Vector2(CircuitGeometry.pin_position(circuit.find_part(m["from_part"]), m["from_pin"]))
			var snap: Variant = null
			if m["snap_part"] != "":
				snap = Vector2(CircuitGeometry.pin_position(circuit.find_part(m["snap_part"]), m["snap_pin"]))
			preview = {"from": from, "to": snap if snap != null else m["to"], "snap": snap}
		"placing":
			var i: int = m["tray"]
			if m["has_ghost"] and i >= 0 and i < tray.size():
				var spot := Vector2i(m["ghost"])
				preview = {"part": Part.make("ghost", tray[i]["kind"], spot.x, spot.y, 0, tray[i].get("props", {}))}
	circuit_view.preview = preview
	circuit_view.queue_redraw()
	if _physical():
		workbench.set_preview(preview)


func _pop_3d(id: String) -> void:
	if bool(settings.get("reduced_motion", false)) or workbench == null:
		return
	var node := workbench.part_node(id)
	if node == null:
		return
	node.scale = Vector3.ONE * 0.6
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector3.ONE, CircuitView.POP_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
