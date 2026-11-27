class_name Workbench3D
extends Node3D
## The real-looking view of the circuit: a perfboard on a cutting mat on a
## wooden desk, true-to-size parts and jumper wires, battery holders and
## multimeters beside the board, glowing current dots, and value labels, lit
## by a photographed studio. 1 unit = 1 cm; the board top is at y = 0.

const HDRI := "res://assets/third_party/polyhaven/hdri/studio_small_09_2k.hdr"
const FOV := 30.0
## The camera looks down at the board, 25° from vertical, from the viewer's side.
const PITCH := 25.0
const LIFT_MM := 1.2
## Standard cutting-mat sizes, cm (A4 to A1); the bench uses the smallest that
## holds the board and the equipment, so nothing hangs over an edge.
const MAT_SIZES: Array[Vector2] = [Vector2(30, 22), Vector2(45, 30), Vector2(60, 45), Vector2(90, 60)]
const MAT_THICK := 0.3

var camera: Camera3D
var _env: WorldEnvironment
var _quality := ""
var _board: MeshInstance3D
var _pads: MultiMeshInstance3D
var _board_rect := Rect2()
var _mat: MeshInstance3D
var _mat_rect := Rect2()
var _parts_root: Node3D
var _wires_root: Node3D
var _rigs_root: Node3D
var _labels_root: Node3D
var _overlay_root: Node3D
var _dots: MultiMeshInstance3D
## Part id → {node, signature}
var _parts := {}
## [{path: PackedVector2Array, amps: float}]
var _flows: Array[Dictionary] = []
var _show_current := true
var _t := 0.0


func _ready() -> void:
	_ensure_scene()


func _process(delta: float) -> void:
	_t += delta
	_update_dots()


func set_state(c: Circuit, sim: SimResult, settings: Dictionary, ghosts: Dictionary, highlights: Array) -> void:
	_ensure_scene()
	var quality := Quality.resolve(str(settings.get("quality", "auto")), Quality.current_method())
	if quality != _quality:
		_quality = quality
		_env.environment = StudioEnvironment.build(HDRI, quality)
		_env.camera_attributes = StudioEnvironment.camera_attributes(quality, camera.position.length())
	_build_board(c)
	_sync_parts(c, sim, settings)
	_build_wires(c, sim, settings)
	_build_rigs(c, sim)
	_fit_mat(_content_rect(c))
	_build_labels(c, sim, settings)
	_build_overlays(c, ghosts, highlights)
	_show_current = bool(settings.get("show_current", true))
	_update_dots()


## Frames `view` grid units of board height around `center`.
func apply_view(center: Vector2, view: float) -> void:
	_ensure_scene()
	var p := deg_to_rad(PITCH)
	var f := deg_to_rad(FOV / 2.0)
	var h := view * PartDims.GRID / (tan(p + f) - tan(p - f))
	var c := PartDims.grid_to_world(center)
	camera.position = c + Vector3(0, h, h * (tan(p + f) + tan(p - f)) / 2.0)
	var target := Vector3(c.x, 0, camera.position.z - h * tan(p))
	camera.look_at(target, Vector3.UP)
	_env.camera_attributes = StudioEnvironment.camera_attributes(_quality, camera.position.distance_to(target))
	camera.near = maxf(h * 0.02, 0.05)
	camera.far = maxf(h * 40.0, 400.0)


## Where a screen point's ray meets the board's top plane, in grid units.
func screen_to_grid(screen_pos: Vector2) -> Vector2:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 1e-6:
		return Vector2(INF, INF)
	return PartDims.world_to_grid(origin + dir * (-origin.y / dir.y))


func grid_to_screen(p: Vector2) -> Vector2:
	return camera.unproject_position(PartDims.grid_to_world(p))


## The cutting mat's footprint in world x/z.
func mat_rect() -> Rect2:
	return _mat_rect


func part_node(id: String) -> Node3D:
	return _parts[id]["node"] if _parts.has(id) else null


func wire_count() -> int:
	return _wires_root.get_child_count()


func label_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for l in _labels_root.get_children():
		out.append((l as Label3D).text)
	return out


func _ensure_scene() -> void:
	if camera != null:
		return
	_env = WorldEnvironment.new()
	add_child(_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 30, 0)
	sun.light_energy = 0.55
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 200.0
	add_child(sun)
	var mat_top := -PartDims.mm(PartDims.BOARD_THICK)
	var desk := MeshInstance3D.new()
	var desk_box := BoxMesh.new()
	desk_box.size = Vector3(160.0, 4.0, 100.0)
	desk.mesh = desk_box
	desk.material_override = Materials.wood_desk()
	desk.position = Vector3(0, mat_top - MAT_THICK - 2.0, 0)
	add_child(desk)
	_mat = MeshInstance3D.new()
	_mat.material_override = Materials.cutting_mat()
	_mat.name = "mat"
	add_child(_mat)
	_fit_mat(Rect2(-10, -7, 20, 14))
	_board = MeshInstance3D.new()
	_board.name = "perfboard"
	_board.material_override = Materials.fr4()
	add_child(_board)
	_pads = MultiMeshInstance3D.new()
	_pads.name = "pads"
	add_child(_pads)
	for r in ["_parts_root", "_wires_root", "_rigs_root", "_labels_root", "_overlay_root"]:
		var n := Node3D.new()
		n.name = r.trim_prefix("_")
		add_child(n)
		set(r, n)
	_dots = MultiMeshInstance3D.new()
	_dots.name = "current_dots"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bead := SphereMesh.new()
	bead.radius = PartDims.mm(0.45)
	bead.height = PartDims.mm(0.9)
	bead.radial_segments = 8
	bead.rings = 4
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Palette.color("spark")
	glow.emission_enabled = true
	glow.emission = Palette.color("spark")
	glow.emission_energy_multiplier = 1.4
	bead.material = glow
	mm.mesh = bead
	_dots.multimesh = mm
	add_child(_dots)
	camera = Camera3D.new()
	camera.fov = FOV
	camera.current = true
	add_child(camera)
	_quality = Quality.resolve("auto", Quality.current_method())
	_env.environment = StudioEnvironment.build(HDRI, _quality)
	_env.camera_attributes = StudioEnvironment.camera_attributes(_quality, 30.0)
	apply_view(Vector2.ZERO, 24.0)


## The perfboard, sized to the circuit plus a margin, with a tinned pad and a
## hole at every grid point.
func _build_board(c: Circuit) -> void:
	var rect := MeterRig.board_rect(c)
	if rect == _board_rect:
		return
	_board_rect = rect
	var box := BoxMesh.new()
	var thick := PartDims.mm(PartDims.BOARD_THICK)
	box.size = Vector3(rect.size.x, thick, rect.size.y)
	_board.mesh = box
	_board.position = Vector3(rect.get_center().x, -thick / 2.0, rect.get_center().y)
	var pad := _pad_mesh()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = pad
	var g0 := Vector2i(ceili(rect.position.x / PartDims.GRID - 1e-6), ceili(rect.position.y / PartDims.GRID - 1e-6))
	var g1 := Vector2i(floori(rect.end.x / PartDims.GRID + 1e-6), floori(rect.end.y / PartDims.GRID + 1e-6))
	var points: Array[Vector3] = []
	for gx in range(g0.x, g1.x + 1):
		for gy in range(g0.y, g1.y + 1):
			points.append(PartDims.grid_to_world(Vector2(gx, gy)))
	mm.instance_count = points.size()
	for i in points.size():
		mm.set_instance_transform(i, Transform3D(Basis(), points[i]))
	_pads.multimesh = mm


## A tinned ring with a dark hole in it, sitting just on the board.
static func _pad_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var outer := PartDims.mm(PartDims.PAD_D) / 2.0
	var inner := PartDims.mm(PartDims.HOLE_D) / 2.0
	var y := PartDims.mm(0.03)
	var n := 16
	var ring := PackedVector3Array()
	var hole := PackedVector3Array()
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var o0 := Vector3(cos(a0), 0, sin(a0))
		var o1 := Vector3(cos(a1), 0, sin(a1))
		ring.append_array([o0 * inner + Vector3(0, y, 0), o0 * outer + Vector3(0, y, 0), o1 * outer + Vector3(0, y, 0),
				o0 * inner + Vector3(0, y, 0), o1 * outer + Vector3(0, y, 0), o1 * inner + Vector3(0, y, 0)])
		hole.append_array([Vector3(0, y, 0), o0 * inner + Vector3(0, y, 0), o1 * inner + Vector3(0, y, 0)])
	for part in [[ring, Materials.tin()], [hole, Materials.rubber()]]:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = part[0]
		var normals := PackedVector3Array()
		normals.resize((part[0] as PackedVector3Array).size())
		normals.fill(Vector3.UP)
		arrays[Mesh.ARRAY_NORMAL] = normals
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, part[1])
	return mesh


## The board plus every piece of equipment beside it, in world x/z.
func _content_rect(c: Circuit) -> Rect2:
	var r := MeterRig.board_rect(c)
	var spots := MeterRig.place(c)
	for id in spots:
		var size: Vector2 = MeterRig.FOOTPRINT_HOLDER if c.find_part(id).kind == "battery" else MeterRig.FOOTPRINT_METER
		var at: Vector3 = spots[id]
		r = r.merge(Rect2(Vector2(at.x, at.z) - size / 2.0, size))
	return r


func _fit_mat(content: Rect2) -> void:
	var need := content.grow(1.0)
	var size := MAT_SIZES[MAT_SIZES.size() - 1]
	for s in MAT_SIZES:
		if s.x >= need.size.x and s.y >= need.size.y:
			size = s
			break
	var rect := Rect2(need.get_center() - size / 2.0, size)
	if rect == _mat_rect:
		return
	_mat_rect = rect
	var box := BoxMesh.new()
	box.size = Vector3(size.x, MAT_THICK, size.y)
	_mat.mesh = box
	_mat.position = Vector3(rect.get_center().x, -PartDims.mm(PartDims.BOARD_THICK) - MAT_THICK / 2.0, rect.get_center().y)


## Reuses a part's model while its kind, place and props stay the same.
func _sync_parts(c: Circuit, sim: SimResult, settings: Dictionary) -> void:
	var keep := {}
	for p in c.parts:
		var signature := "%s|%d|%d|%d|%s" % [p.kind, p.x, p.y, p.rot, var_to_str(p.props)]
		if not _parts.has(p.id) or _parts[p.id]["signature"] != signature:
			if _parts.has(p.id):
				(_parts[p.id]["node"] as Node).queue_free()
			var node := PartModels.build(p)
			_parts_root.add_child(node)
			_parts[p.id] = {"node": node, "signature": signature}
		PartModels.apply_state(_parts[p.id]["node"], VisualState.for_part(p, sim, settings))
		keep[p.id] = true
	for id in _parts.keys():
		if not keep.has(id):
			(_parts[id]["node"] as Node).queue_free()
			_parts.erase(id)


func _build_wires(c: Circuit, sim: SimResult, settings: Dictionary) -> void:
	_clear(_wires_root)
	_flows.clear()
	var index := 0
	for w in c.wires:
		var path := CircuitGeometry.wire_path(c, w)
		if path.size() < 2:
			continue
		var color := WireMesh.color_for(c, w, index)
		if color != Color(WireMesh.RED) and color != Color(WireMesh.BLACK):
			index += 1
		var mi := MeshInstance3D.new()
		mi.name = w.id
		mi.mesh = WireMesh.tube(WireMesh.points(path, LIFT_MM), PartDims.WIRE_INSULATION_D / 2.0)
		mi.material_override = Materials.pvc(color)
		_wires_root.add_child(mi)
		_flows.append({"path": path, "amps": WireArt.display_amps(float(sim.wire_amps.get(w.id, 0.0)), settings)})


## Battery holders and multimeters on the desk, joined to their posts by leads.
func _build_rigs(c: Circuit, sim: SimResult) -> void:
	_clear(_rigs_root)
	var spots := MeterRig.place(c)
	for p in c.parts:
		if not spots.has(p.id) or not _parts.has(p.id):
			continue
		var part: Node3D = _parts[p.id]["node"]
		var rig: Node3D
		var ends := {}
		if p.kind == "battery":
			rig = PartModels.build_holder()
			PartModels.apply_holder(rig, p.id in sim.shorts)
			ends = {"pos": "term_pos", "neg": "term_neg"}
		else:
			rig = PartModels.build_multimeter(p.kind)
			var burnt := bool(p.props.get("burnt", false))
			PartModels.apply_meter(rig, VisualState.for_part(p, sim, {})["reading"], burnt)
			var pins := Catalog.pin_names(p.kind)
			ends = {pins[0]: "jack_ma" if p.kind == "ammeter" else "jack_v", pins[1]: "jack_com"}
		rig.position = spots[p.id]
		_rigs_root.add_child(rig)
		var left := p.kind == "battery"
		var clear := (MeterRig.HEIGHT_HOLDER if left else MeterRig.HEIGHT_METER) + 0.8
		for pin in ends:
			var from := part.transform * (part.get_node("lead_" + pin) as Node3D).position
			var to := rig.transform * (rig.get_node(ends[pin]) as Node3D).position
			var lead := MeshInstance3D.new()
			lead.mesh = WireMesh.tube(_route(from, to, _board_rect, clear), 0.9)
			lead.material_override = Materials.pvc(Color(PartModels.LEAD_RED if pin in ["pos", "a"] else PartModels.LEAD_BLACK))
			_rigs_root.add_child(lead)


## A lead's route on the bench: up out of its post, over the parts to the
## board's edge, up over the equipment on that side (`clear` cm above the mat),
## across to its socket and straight down into it, so it never passes through
## anything.
const LEAD_HEIGHT := 1.4


static func _route(a: Vector3, b: Vector3, board: Rect2, clear: float) -> PackedVector3Array:
	var s := signf(b.x - a.x)
	var edge := board.position.x - 0.3 if s < 0.0 else board.end.x + 0.3
	var high := maxf(clear, LEAD_HEIGHT)
	var pts := PackedVector3Array([
		a,
		Vector3(a.x, LEAD_HEIGHT, a.z),
		Vector3(edge, LEAD_HEIGHT, a.z),
		Vector3(edge + s * 1.2, high, lerpf(a.z, b.z, 0.3)),
		Vector3(b.x, high, b.z),
		b,
	])
	return WireMesh.fillet(pts, 0.5)


func _build_labels(c: Circuit, sim: SimResult, settings: Dictionary) -> void:
	_clear(_labels_root)
	if not bool(settings.get("show_values", true)):
		return
	for l in VisualState.engineer_labels(c, sim):
		var label := Label3D.new()
		label.text = l["text"]
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 40
		label.pixel_size = 0.0035
		label.modulate = Palette.color("ink")
		label.outline_modulate = Palette.color("paper")
		label.outline_size = 10
		label.position = PartDims.grid_to_world(l["at"]) + Vector3(0, 0.3, 0.35)
		_labels_root.add_child(label)


## Ghost parts and wires for the "show me" hint, and highlights for hints.
func _build_overlays(c: Circuit, ghosts: Dictionary, highlights: Array) -> void:
	_clear(_overlay_root)
	var ghost := StandardMaterial3D.new()
	ghost.albedo_color = Color(Palette.color("lavender"), 0.45)
	ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for p in ghosts.get("parts", []):
		var node := PartModels.build(p)
		for m in node.find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).material_override = ghost
		_overlay_root.add_child(node)
	var with_ghosts := c.copy()
	for p in ghosts.get("parts", []):
		with_ghosts.parts.append((p as Part).copy())
	for g in ghosts.get("wires", []):
		var w := Wire.make("ghost", g["a_part"], g["a_pin"], g["b_part"], g["b_pin"])
		_overlay_tube(CircuitGeometry.wire_path(with_ghosts, w), ghost)
	var warn := StandardMaterial3D.new()
	warn.albedo_color = Color(Palette.color("coral"), 0.6)
	warn.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	warn.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for id in ghosts.get("remove_wires", []):
		var w := c.find_wire(id)
		if w != null:
			_overlay_tube(CircuitGeometry.wire_path(c, w), warn, 1.1)
	var spark := StandardMaterial3D.new()
	spark.albedo_color = Color(Palette.color("spark"), 0.55)
	spark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for h in highlights:
		if h.has("wire") and c.find_wire(h["wire"]) != null:
			_overlay_tube(CircuitGeometry.wire_path(c, c.find_wire(h["wire"])), spark, 1.2)
		elif h.has("part") and c.find_part(h["part"]) != null:
			var p := c.find_part(h["part"])
			var at := Vector2(CircuitGeometry.pin_position(p, h["pin"])) if h.has("pin") else CircuitGeometry.part_rect(p).get_center()
			var halo := MeshInstance3D.new()
			var disc := CylinderMesh.new()
			var r := 0.25 if h.has("pin") else maxf(CircuitGeometry.part_rect(p).size.x, CircuitGeometry.part_rect(p).size.y) * PartDims.GRID * 0.6
			disc.top_radius = r
			disc.bottom_radius = r
			disc.height = 0.02
			halo.mesh = disc
			halo.material_override = spark
			halo.position = PartDims.grid_to_world(at) + Vector3(0, 0.02, 0)
			_overlay_root.add_child(halo)


func _overlay_tube(path: PackedVector2Array, mat: Material, scale := 1.0) -> void:
	if path.size() < 2:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = WireMesh.tube(WireMesh.points(path, LIFT_MM), PartDims.WIRE_INSULATION_D / 2.0 * scale)
	mi.material_override = mat
	_overlay_root.add_child(mi)


func _update_dots() -> void:
	if _dots == null:
		return
	_dots.visible = _show_current
	if not _show_current:
		return
	var spots: Array[Vector3] = []
	var lift := Vector3(0, PartDims.mm(LIFT_MM + 0.55), 0)
	for f in _flows:
		for d in WireArt.dots(f["path"], f["amps"], _t):
			spots.append(PartDims.grid_to_world(d) + lift)
	var mm := _dots.multimesh
	mm.instance_count = spots.size()
	for i in spots.size():
		mm.set_instance_transform(i, Transform3D(Basis(), spots[i]))


func _clear(n: Node) -> void:
	for child in n.get_children():
		n.remove_child(child)
		child.queue_free()
