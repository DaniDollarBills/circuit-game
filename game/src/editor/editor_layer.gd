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
## A value label (a voltage or a current) was tapped; the HUD explains its part.
signal explain_requested(part_id: String)

## How close, in pixels, a tap must be to a pin's metal in the real view.
const PICK_PX := 22.0

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
## The part of the layer the HUD leaves uncovered, in layer pixels. Framing
## puts the circuit inside it. Empty means the whole layer.
var safe_rect := Rect2()


func _ready() -> void:
	super._ready()
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
	_apply_quality()
	apply_view(view_center, view_height)
	resized.connect(_fit_resolution)


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
	var quality_changed := str(st.get("quality", "auto")) != str(settings.get("quality", "auto"))
	settings = st
	if quality_changed:
		_apply_quality()
	ghosts = gh
	highlights = hl
	_apply_style()
	if _physical():
		workbench.set_state(c, s, st, gh, hl)
		workbench.set_selection(c, controller.selection)
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
	var safe := _safe()
	var aspect := safe.size.y / maxf(safe.size.x, 1.0)
	var widen := 1.0
	var raised := 0.0
	if _physical():
		widen = Workbench3D.near_edge_widening()
		raised = Workbench3D.raised_allowance(MeterRig.tallest(circuit))
	var view := maxf(bounds.size.y, bounds.size.x * aspect * widen) + raised
	view = maxf(12.0, view * size.y / maxf(safe.size.y, 1.0))
	home_view = view
	return view


## The center for fit_view(): the circuit lands in the middle of safe_rect.
func fit_center() -> Vector2:
	var units_per_px := fit_view() / maxf(size.y, 1.0)
	var offset := _safe().get_center() - size / 2.0
	return _fit_bounds().get_center() - offset * units_per_px


func _safe() -> Rect2:
	var whole := Rect2(Vector2.ZERO, size)
	if safe_rect.size.x < 1.0 or safe_rect.size.y < 1.0:
		return whole
	var r := safe_rect.intersection(whole)
	return r if r.size.x >= 1.0 and r.size.y >= 1.0 else whole


## Where the value labels sit on screen, for tapping: {part, text, screen
## (center), rect}. Empty when values are hidden.
func value_label_spots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if sim == null or not bool(settings.get("show_values", true)):
		return out
	if _physical():
		var cam := workbench.camera
		for l in VisualState.engineer_labels(circuit, sim):
			var world := PartDims.grid_to_world(l["at"]) + Vector3(0, 0.3, 0.35)
			if cam.is_position_behind(world):
				continue
			var c := cam.unproject_position(world)
			var px_per_cm := cam.unproject_position(world + Vector3(1, 0, 0)).distance_to(c)
			var box := Vector2(0.08 * str(l["text"]).length(), 0.16) * px_per_cm
			out.append({"part": l["part"], "text": l["text"], "screen": c, "rect": Rect2(c - box / 2.0, box).grow(6.0)})
	else:
		for l in CircuitView.placed_labels(circuit, sim):
			var c := circuit_view.to_screen(l["at"])
			var box := Vector2(0.25 * str(l["text"]).length() + 0.2, 0.6) * circuit_view.ppu
			out.append({"part": l["part"], "text": l["text"], "screen": c, "rect": Rect2(c - box / 2.0, box).grow(4.0)})
	return out


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


## A layer that stops taking input drops any gesture under way, so a hand-off
## mid-drag can't leave a rubber band behind.
func set_live(live: bool, interactive: bool) -> void:
	super.set_live(live, interactive)
	if not interactive and pointer != null:
		pointer.reset()


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
	if physical:
		# The camera may have been left behind while the schematic showed.
		workbench.apply_view(view_center, view_height)


## The graphics preset: 3D anti-aliasing, shadow detail and render resolution.
## 2D anti-aliasing is off on the Compatibility renderer, which lacks it.
func _apply_quality() -> void:
	if viewport == null:
		return
	var method := Quality.current_method()
	var preset := Quality.resolve(str(settings.get("quality", "auto")), method)
	viewport.msaa_3d = Quality.msaa(preset)
	viewport.msaa_2d = Viewport.MSAA_DISABLED if method == "gl_compatibility" else Viewport.MSAA_4X
	var shadow := int(Quality.PRESETS[preset]["shadow_size"])
	viewport.positional_shadow_atlas_size = shadow
	RenderingServer.directional_shadow_atlas_set_size(shadow, true)
	_fit_resolution()


## Renders at the screen's own resolution, up to what the preset allows.
func _fit_resolution() -> void:
	if not is_inside_tree():
		return
	var preset := Quality.resolve(str(settings.get("quality", "auto")), Quality.current_method())
	var screen_k := get_viewport().get_final_transform().get_scale().x
	set_resolution_scale(minf(screen_k, Quality.max_resolution_scale(preset)))


## In the real view the board is seen in perspective, so screen and grid
## points convert through the camera rig rather than a flat scale.
func screen_to_layer(p: Vector2, view: float, center: Vector2) -> Vector2:
	if not _physical():
		return super.screen_to_layer(p, view, center)
	return Workbench3D.board_point(p, size, center, view)


func layer_to_screen(q: Vector2, view: float, center: Vector2) -> Vector2:
	if not _physical():
		return super.layer_to_screen(q, view, center)
	return Workbench3D.screen_point(q, size, center, view)


func _on_gesture(g: Dictionary) -> void:
	var gg := g.duplicate()
	if g.has("at"):
		gg["screen"] = g["at"]
		gg["at"] = screen_to_grid(g["at"])
	if gg["type"] == "tap" and _tap_ghost(gg["at"]):
		return
	var ctx := {"circuit": circuit, "tray": tray, "tray_used": tray_used, "pin_r": pin_radius(), "wire_r": pin_radius() * 0.8}
	if _physical() and gg.has("screen"):
		var picked := pick_3d(gg["screen"])
		if gg["type"] in ["tap", "long_press", "secondary_tap", "drag_start"]:
			if picked.is_empty():
				var flat := HitTest.at(circuit, gg["at"], ctx["pin_r"], ctx["wire_r"])
				picked = flat if flat["kind"] == "wire" else {"kind": "empty"}
			ctx["hit"] = picked
		elif gg["type"] in ["drag_move", "drag_end"] and controller.mode["kind"] == "wiring":
			ctx["snap"] = [picked["part"], picked["pin"]] if picked.get("kind", "") == "pin" else ["", ""]
	if gg["type"] == "tap" and controller.mode["kind"] == "idle" \
			and (ctx["hit"] if ctx.has("hit") else HitTest.at(circuit, gg["at"], ctx["pin_r"], ctx["wire_r"]))["kind"] == "empty" \
			and _tap_label(gg["screen"]):
		return
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
			_pan(e["delta"], g.get("screen", size / 2.0))
	circuit_view.selection = controller.selection
	circuit_view.queue_redraw()


func _zoom(factor: float, screen: Vector2) -> void:
	var stage := get_parent() as ZoomStage
	if stage != null:
		stage.zoom_at_screen(factor, screen + position)
		return
	var cam := ZoomMath.zoom_at(ZoomCamera.make(layer_id, view_center, view_height), factor, screen_to_grid(screen))
	apply_view(cam.center, clampf(cam.view, min_view, max_view))


## Moves the board so the point that was under the finger (at `screen` −
## `delta_px`) is under it again; exact in perspective too.
func _pan(delta_px: Vector2, screen: Vector2) -> void:
	var shift := screen_to_grid(screen - delta_px) - screen_to_grid(screen)
	if not (is_finite(shift.x) and is_finite(shift.y)):
		return
	var stage := get_parent() as ZoomStage
	if stage != null:
		stage.pan_units(shift)
		return
	apply_view(view_center + shift, view_height)


## What is drawn under a screen point in the real view: a pin (its metal,
## from the hole to the top of its lead or post, within PICK_PX) or else the
## part whose projected bounds hold the point, nearest the camera first.
## Empty when neither: the board plane then decides (wires, empty board).
func pick_3d(screen: Vector2) -> Dictionary:
	var cam := workbench.camera
	var best := {}
	var best_d := PICK_PX
	for p in circuit.parts:
		var node := workbench.part_node(p.id)
		if node == null:
			continue
		for pin in Catalog.pin_names(p.kind):
			var base := PartDims.grid_to_world(Vector2(CircuitGeometry.pin_position(p, pin)))
			var top := Vector3(base.x, maxf(_pin_top(node, pin), base.y), base.z)
			if cam.is_position_behind(base) or cam.is_position_behind(top):
				continue
			var d := HitTest.distance_to_path(screen, PackedVector2Array([cam.unproject_position(base), cam.unproject_position(top)]))
			if d < best_d:
				best_d = d
				best = {"kind": "pin", "part": p.id, "pin": pin}
	if not best.is_empty():
		return best
	var near := INF
	for p in circuit.parts:
		var node := workbench.part_node(p.id)
		if node == null:
			continue
		var box := _bounds(node)
		if box.size == Vector3.ZERO:
			continue
		var rect := Rect2()
		var first := true
		var behind := false
		for i in 8:
			var corner := box.get_endpoint(i)
			if cam.is_position_behind(corner):
				behind = true
				break
			var px := cam.unproject_position(corner)
			rect = Rect2(px, Vector2.ZERO) if first else rect.expand(px)
			first = false
		if behind or not rect.has_point(screen):
			continue
		var depth := cam.global_position.distance_to(box.get_center())
		if depth < near:
			near = depth
			best = {"kind": "part", "part": p.id}
	return best


## The top of a pin's visible metal (lead, lug, post and the clip on it),
## world y. Leads that run on inside a body (an LED's legs go up into the
## epoxy) count only up to the body's underside.
static func _pin_top(node: Node3D, pin: String) -> float:
	var top := -INF
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var n := str(m.name)
		if n.ends_with("_" + pin) and (n.begins_with("lead") or n.begins_with("lug") or n.begins_with("post") or n.begins_with("collar") or n.begins_with("clip")):
			var mi := m as MeshInstance3D
			top = maxf(top, (mi.global_transform * mi.mesh.get_aabb()).end.y)
	for body_name in ["epoxy", "body"]:
		var body := node.get_node_or_null(body_name)
		if body is MeshInstance3D:
			var mi := body as MeshInstance3D
			return minf(top, (mi.global_transform * mi.mesh.get_aabb()).position.y)
		if body is Node3D:
			return minf(top, _bounds(body as Node3D).position.y)
	return top


static func _bounds(node: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null or not mi.visible:
			continue
		var b: AABB = mi.global_transform * mi.mesh.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out


func _tap_label(screen: Vector2) -> bool:
	for spot in value_label_spots():
		if (spot["rect"] as Rect2).has_point(screen):
			explain_requested.emit(spot["part"])
			return true
	return false


## Tray items dragged from the HUD carry {tray: index}.
func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not (data as Dictionary).has("tray"):
		return false
	var i := int(data["tray"])
	return i >= 0 and i < tray.size() and (i >= tray_used.size() or tray_used[i] < int(tray[i].get("count", 1)))


## A drop places the part at the grid point under the cursor, by the same
## rules as tapping a tray item and then the board.
func _drop_data(at: Vector2, data: Variant) -> void:
	if not _can_drop_data(at, data):
		return
	controller.begin_placing(int(data["tray"]))
	var g := {"type": "tap", "at": screen_to_grid(at), "screen": at}
	var ctx := {"circuit": circuit, "tray": tray, "tray_used": tray_used, "pin_r": pin_radius(), "wire_r": pin_radius() * 0.8}
	for e in controller.handle(g, ctx):
		_apply_effect(e, g)
	_update_preview()


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
		"moving":
			var p := circuit.find_part(m["part"])
			if p != null:
				var ghost := p.copy()
				var spot := Vector2i(((m["at"] as Vector2) - (m["grab"] as Vector2)).round())
				ghost.x = spot.x
				ghost.y = spot.y
				preview = {"part": ghost}
		"pin_selected":
			var p := circuit.find_part(m["part"])
			if p != null:
				preview = {"pin": Vector2(CircuitGeometry.pin_position(p, m["pin"]))}
	circuit_view.preview = preview
	circuit_view.selection = controller.selection
	circuit_view.queue_redraw()
	if _physical():
		workbench.set_preview(preview)
		workbench.set_selection(circuit, controller.selection)


func _pop_3d(id: String) -> void:
	if bool(settings.get("reduced_motion", false)) or workbench == null:
		return
	var node := workbench.part_node(id)
	if node == null:
		return
	node.scale = Vector3.ONE * 0.6
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector3.ONE, CircuitView.POP_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
