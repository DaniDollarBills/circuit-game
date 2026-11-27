class_name PartModels
extends RefCounted
## True-to-size 3D models of the parts (1 unit = 1 cm). Each is built in its
## part's frame (pins along x, as at rotation 0), then placed at the part's grid
## position and turned like it. Every lead ends in the hole at its pin, where a
## Marker3D "tip_<pin>" sits; posts that lead off the board carry a
## "lead_<pin>" marker where their wire leaves.

const LIGHT_COLORS := {"red": "#FF2A1A", "yellow": "#FFC21A", "green": "#9CFF3A", "blue": "#2A6BFF"}
const CARBON_FILM := "#D8C39A"
const METAL_FILM := "#6E9FCB"
const SCORCHED := "#3B2A22"
const LEAD_RED := "#D2342B"
const LEAD_BLACK := "#1E1E22"
## Gap between a part's underside and the board, mm.
const STANDOFF := 1.0

## A SphereMesh hemisphere needs height = radius; its flat side is at y = 0.
static var _gold: StandardMaterial3D
static var _smoke: StandardMaterial3D


static func build(p: Part) -> Node3D:
	var root := Node3D.new()
	root.name = p.id
	root.position = PartDims.grid_to_world(Vector2(p.x, p.y))
	root.rotation.y = -deg_to_rad(p.rot)
	match p.kind:
		"resistor":
			_resistor(root, p)
		"led":
			_led(root, p)
		"switch":
			_switch(root, p)
		"battery":
			_posts(root, p, {"pos": LEAD_RED, "neg": LEAD_BLACK}, false)
		"ammeter":
			_posts(root, p, {"a": LEAD_RED, "b": LEAD_BLACK}, true)
		"voltmeter":
			_posts(root, p, {"pos": LEAD_RED, "neg": LEAD_BLACK}, true)
	for pin in Catalog.pin_names(p.kind):
		var tip := Marker3D.new()
		tip.name = "tip_" + pin
		tip.position = _pin_local(p, pin) + _v(0, -PartDims.BOARD_THICK, 0)
		root.add_child(tip)
	return root


## LEDs glow, burnt parts darken and smoke, switch levers follow the switch.
static func apply_state(node: Node3D, vis: Dictionary) -> void:
	var burnt := bool(vis.get("burnt", false))
	var die := node.find_child("die", true, false) as MeshInstance3D
	if die != null:
		var light := node.find_child("glow", true, false) as OmniLight3D
		var b := 0.0 if burnt else clampf(float(vis.get("brightness", 0.0)), 0.0, 1.0)
		var color := Color(LIGHT_COLORS.get(str(vis.get("color", "red")), LIGHT_COLORS["red"]))
		var m := die.material_override as StandardMaterial3D
		m.emission = color
		m.emission_energy_multiplier = 16.0 * b
		light.light_color = color
		light.light_energy = 1.6 * b
		light.visible = b > 0.0
		if burnt:
			var dark := Materials.epoxy_clear(Color(0.18, 0.12, 0.1))
			for e in node.get_node("epoxy").get_children():
				if e is MeshInstance3D:
					(e as MeshInstance3D).material_override = dark
	var lever := node.find_child("lever", true, false) as Node3D
	if lever != null:
		lever.rotation.z = deg_to_rad(-15.0 if vis.get("closed", false) else 15.0)
	if burnt:
		var body := node.get_node_or_null("body")
		if body != null:
			for m in body.get_children():
				if m is MeshInstance3D:
					var c := Color(SCORCHED) if not str(m.name).begins_with("band") else Color(SCORCHED).lerp(Color.BLACK, 0.3)
					(m as MeshInstance3D).material_override = Materials.resistor_paint(c)
		if node.find_child("smoke", true, false) == null:
			_add_smoke(node)


## The holder glows red when its battery is shorted.
static func apply_holder(holder: Node3D, hot: bool) -> void:
	var overlay: StandardMaterial3D = null
	if hot:
		overlay = StandardMaterial3D.new()
		overlay.albedo_color = Color(1.0, 0.25, 0.15, 0.35)
		overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		overlay.emission_enabled = true
		overlay.emission = Color("#FF3A20")
		overlay.emission_energy_multiplier = 0.8
	for m in holder.find_children("wall*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_overlay = overlay


## The multimeter's display shows the reading, or FUSE when its fuse blew.
static func apply_meter(meter: Node3D, reading: String, fuse_blown: bool) -> void:
	(meter.find_child("lcd_text", true, false) as Label3D).text = "FUSE" if fuse_blown else reading


## A 4 × AA holder with its cells, base at y = 0; its leads leave over the top
## of its +x wall.
static func build_holder() -> Node3D:
	var root := Node3D.new()
	root.name = "holder"
	var size := PartDims.AA_HOLDER
	var w := size.y
	var length := size.x
	var h := size.z
	var plastic := Materials.plastic_matte(Color("#1E1E22"))
	_mesh(root, "wall_base", _box(w, 2.0, length), plastic, _v(0, 1.0, 0))
	_mesh(root, "wall_left", _box(1.5, h, length), plastic, _v(-w / 2.0 + 0.75, h / 2.0, 0))
	_mesh(root, "wall_right", _box(1.5, h, length), plastic, _v(w / 2.0 - 0.75, h / 2.0, 0))
	_mesh(root, "wall_front", _box(w, h, 3.0), plastic, _v(0, h / 2.0, length / 2.0 - 1.5))
	_mesh(root, "wall_back", _box(w, h, 3.0), plastic, _v(0, h / 2.0, -length / 2.0 + 1.5))
	var cell := PartDims.AA_CELL
	var wrap := Materials.plastic_gloss(Color("#26262B"))
	var band := Materials.copper()
	for i in 4:
		var x := -w / 2.0 + 1.5 + cell.y / 2.0 + i * (w - 3.0 - cell.y) / 3.0
		var flip := 1.0 if i % 2 == 0 else -1.0
		var y := 2.0 + cell.y / 2.0
		_mesh(root, "cell%d" % i, _cyl(cell.y / 2.0, cell.y / 2.0, cell.x * 0.78), wrap, _v(x, y, -flip * cell.x * 0.11), Vector3(PI / 2.0, 0, 0))
		_mesh(root, "top%d" % i, _cyl(cell.y / 2.0, cell.y / 2.0, cell.x * 0.22), band, _v(x, y, flip * cell.x * 0.39), Vector3(PI / 2.0, 0, 0))
		_mesh(root, "nub%d" % i, _cyl(2.75, 2.75, 1.0), Materials.steel(), _v(x, y, flip * (cell.x / 2.0 + 0.5)), Vector3(PI / 2.0, 0, 0))
	for t in [["term_pos", -8.0], ["term_neg", 8.0]]:
		var m := Marker3D.new()
		m.name = t[0]
		m.position = _v(w / 2.0 - 0.75, h, t[1])
		root.add_child(m)
	return root


## A handheld multimeter lying face up, base at y = 0, its display facing the
## viewer at +z; the dial points at mA for a current meter and V for a voltage meter.
static func build_multimeter(kind: String) -> Node3D:
	var root := Node3D.new()
	root.name = "multimeter"
	var size := PartDims.MULTIMETER
	var length := size.x
	var w := size.y
	var h := size.z
	_mesh(root, "holster", _box(w, h, length), Materials.plastic_matte(Color("#F2C230")), _v(0, h / 2.0, 0))
	var face_y := h + 0.5
	_mesh(root, "face", _box(w - 10.0, 1.0, length - 14.0), Materials.plastic_matte(Color("#2A2A2E")), _v(0, face_y, 0))
	_mesh(root, "lcd", _box(w - 22.0, 1.0, 30.0), Materials.lcd(), _v(0, face_y + 0.6, -length * 0.3))
	var text := Label3D.new()
	text.name = "lcd_text"
	text.text = "—"
	text.font_size = 96
	## Digits about 1 cm tall (pixel_size is world units, cm, per font pixel).
	text.pixel_size = 0.0105
	text.modulate = Color("#1E2A22")
	text.outline_size = 0
	text.position = _v(0, face_y + 1.2, -length * 0.3)
	text.rotation_degrees = Vector3(-90, 0, 0)
	root.add_child(text)
	var dial_z := length * 0.08
	_mesh(root, "dial", _cyl(17.0, 18.0, 4.0, 32), Materials.plastic_matte(Color("#3A3A40")), _v(0, face_y + 2.0, dial_z))
	var pointer := Node3D.new()
	pointer.name = "pointer"
	pointer.position = _v(0, face_y + 4.2, dial_z)
	pointer.rotation.y = deg_to_rad(40.0 if kind == "ammeter" else -40.0)
	root.add_child(pointer)
	_mesh(pointer, "mark", _box(3.0, 1.0, 15.0), Materials.plastic_matte(Color("#EDEDED")), _v(0, 0, -8.0))
	for m in [["mA", 40.0], ["V", -40.0]]:
		var mark := Label3D.new()
		mark.text = m[0]
		mark.font_size = 48
		mark.pixel_size = 0.0083
		mark.modulate = Color("#EDEDED")
		mark.rotation_degrees = Vector3(-90, 0, 0)
		mark.position = _v(sin(deg_to_rad(m[1])) * -24.0, face_y + 0.6, dial_z - cos(deg_to_rad(m[1])) * 24.0)
		root.add_child(mark)
	for j in [["jack_com", -18.0, LEAD_BLACK], ["jack_v", 0.0, LEAD_RED], ["jack_ma", 18.0, LEAD_RED]]:
		_mesh(root, j[0] + "_ring", _cyl(4.0, 4.0, 2.0), Materials.plastic_matte(Color(j[2])), _v(j[1], face_y + 1.0, length * 0.38))
		var at := Marker3D.new()
		at.name = j[0]
		at.position = _v(j[1], face_y + 2.0, length * 0.38)
		root.add_child(at)
	return root


static func _resistor(root: Node3D, p: Part) -> void:
	var one_watt := float(p.props.get("watts", 0.25)) >= 1.0
	var dims: Vector2 = PartDims.RESISTOR_1W_BODY if one_watt else PartDims.RESISTOR_BODY
	var length := dims.x
	var d := dims.y
	var axis_y := STANDOFF + d / 2.0
	var body := Node3D.new()
	body.name = "body"
	body.position = _v(0, axis_y, 0)
	root.add_child(body)
	var paint := Materials.resistor_paint(Color(METAL_FILM if one_watt else CARBON_FILM))
	var cap_r := d / 2.0
	var mid_r := d * 0.44
	var end := d * 0.23
	var cap_len := d * 0.42
	var mid_len := length - 2.0 * (end + cap_len)
	var along := Vector3(0, 0, PI / 2.0)
	_mesh(body, "middle", _cyl(mid_r, mid_r, mid_len), paint, Vector3.ZERO, along)
	for s in [-1.0, 1.0]:
		_mesh(body, "cap", _cyl(cap_r, cap_r, cap_len), paint, _v(s * (mid_len + cap_len) / 2.0, 0, 0), along)
		var dome := SphereMesh.new()
		dome.radius = _mm(cap_r)
		dome.height = _mm(cap_r)
		dome.is_hemisphere = true
		_mesh(body, "end", dome, paint, _v(s * (mid_len / 2.0 + cap_len), 0, 0), Vector3(0, 0, -s * PI / 2.0), Vector3(1, end / cap_r, 1))
	var colors := ResistorBands.colors(float(p.props.get("ohms", 220.0)))
	var band_w := d * 0.22
	var spots := [-(mid_len + cap_len) / 2.0, -mid_len * 0.22, mid_len * 0.12, (mid_len + cap_len) / 2.0]
	for i in 4:
		var r := (cap_r if absf(spots[i]) > mid_len / 2.0 else mid_r) + 0.015
		_mesh(body, "band%d" % i, _cyl(r, r, band_w), Materials.resistor_paint(colors[i]), _v(spots[i], 0, 0), along)
	for pin in ["a", "b"]:
		var px := _pin_local(p, pin).x
		var s := signf(px)
		var pts := PackedVector3Array([_v(s * (length / 2.0 - end * 0.5), axis_y, 0), Vector3(px, _mm(axis_y), 0),
				Vector3(px, -_mm(PartDims.BOARD_THICK), 0)])
		_lead(root, "lead_" + pin, WireMesh.fillet(pts, _mm(0.8)), PartDims.RESISTOR_LEAD_D / 2.0, 8, Materials.tin())


static func _led(root: Node3D, p: Part) -> void:
	var color := str(p.props.get("color", "red"))
	var tint := Palette.led_tint(color)
	var base := STANDOFF + 1.0
	var epoxy := Node3D.new()
	epoxy.name = "epoxy"
	root.add_child(epoxy)
	var clear := Materials.epoxy_clear(tint)
	var flange_h := 1.0
	var r := PartDims.LED_DOME_D / 2.0
	var body_h := PartDims.LED_HEIGHT - flange_h - r
	_mesh(epoxy, "flange", _flanged_disc(PartDims.LED_FLANGE_D / 2.0, PartDims.LED_FLAT, flange_h), clear, _v(0, base, 0))
	_mesh(epoxy, "body", _cyl(r, r, body_h, 32), clear, _v(0, base + flange_h + body_h / 2.0, 0))
	var dome := SphereMesh.new()
	dome.radius = _mm(r)
	dome.height = _mm(r)
	dome.is_hemisphere = true
	_mesh(epoxy, "dome", dome, clear, _v(0, base + flange_h + body_h, 0))
	var inside := Node3D.new()
	inside.name = "inside"
	epoxy.add_child(inside)
	var frame_top := base + 3.4
	_mesh(inside, "post", _box(0.6, 2.4, 0.45), Materials.tin(), _v(-0.95, frame_top - 1.2, 0))
	_mesh(inside, "anvil", _box(1.6, 2.6, 0.45), Materials.tin(), _v(0.65, frame_top - 1.3, 0))
	_mesh(inside, "cup", _cyl(0.6, 0.32, 0.4), Materials.tin(), _v(0.5, frame_top + 0.2, 0))
	var die_mat := StandardMaterial3D.new()
	die_mat.albedo_color = tint
	die_mat.emission_enabled = true
	die_mat.emission = Color(LIGHT_COLORS.get(color, LIGHT_COLORS["red"]))
	die_mat.emission_energy_multiplier = 0.0
	_mesh(inside, "die", _box(0.28, 0.14, 0.28), die_mat, _v(0.5, frame_top + 0.3, 0))
	var bond := PackedVector3Array([_v(0.5, frame_top + 0.4, 0), _v(-0.2, frame_top + 1.0, 0), _v(-0.95, frame_top + 0.05, 0)])
	_lead(inside, "bond", bond, 0.02, 4, _gold_material())
	var glow := OmniLight3D.new()
	glow.name = "glow"
	glow.omni_range = 3.0
	glow.light_energy = 0.0
	glow.visible = false
	glow.position = _v(0, frame_top + 1.5, 0)
	epoxy.add_child(glow)
	var lead_r := PartDims.LED_LEAD / sqrt(2.0)
	for pin in ["anode", "cathode"]:
		var px := _pin_local(p, pin).x
		var s := signf(px)
		var inner := s * PartDims.LED_LEAD_PITCH / 2.0
		var pts := PackedVector3Array([_v(inner, frame_top - 2.4, 0), _v(inner, 1.2, 0), Vector3(px, _mm(0.4), 0),
				Vector3(px, -_mm(PartDims.BOARD_THICK), 0)])
		_lead(root, "lead_" + pin, WireMesh.fillet(pts, _mm(0.5)), lead_r, 4, Materials.tin())


static func _switch(root: Node3D, p: Part) -> void:
	var size := PartDims.SWITCH_BODY
	var bottom := 0.5
	var plastic := Materials.plastic_matte(Color("#2B2B30"))
	_mesh(root, "body", _box(size.x, size.z, size.y), plastic, _v(0, bottom + size.z / 2.0, 0))
	var top := bottom + size.z
	_mesh(root, "nut", _cyl(4.6, 4.6, 1.6, 6), Materials.steel(), _v(0, top + 0.8, 0))
	_mesh(root, "bushing", _cyl(3.0, 3.0, 6.0), Materials.steel(), _v(0, top + 3.0, 0))
	var lever := Node3D.new()
	lever.name = "lever"
	lever.position = _v(0, top + 6.0, 0)
	lever.rotation.z = deg_to_rad(15.0)
	root.add_child(lever)
	_mesh(lever, "stem", _cyl(0.8, 1.1, PartDims.SWITCH_LEVER - 1.2), Materials.steel(), _v(0, (PartDims.SWITCH_LEVER - 1.2) / 2.0, 0))
	var ball := SphereMesh.new()
	ball.radius = _mm(1.2)
	ball.height = _mm(2.4)
	_mesh(lever, "tip", ball, Materials.steel(), _v(0, PartDims.SWITCH_LEVER - 1.2, 0))
	for pin in ["a", "b"]:
		var px := _pin_local(p, pin).x
		var length := bottom + 1.0 + PartDims.BOARD_THICK
		_mesh(root, "lug_" + pin, _box(2.0, length, 0.5), Materials.tin(), Vector3(px, _mm(bottom + 1.0 - length / 2.0), 0))


## Square header posts in a plastic collar; meters' posts carry a colored clip.
static func _posts(root: Node3D, p: Part, colors: Dictionary, clips: bool) -> void:
	for pin in colors:
		var at := _pin_local(p, pin)
		_mesh(root, "collar_" + pin, _box(2.54, 2.5, 2.54), Materials.plastic_matte(Color("#1E1E22")), at + _v(0, 1.25, 0))
		var low := -PartDims.BOARD_THICK
		var high := 8.5
		_mesh(root, "post_" + pin, _box(0.64, high - low, 0.64), Materials.tin(), at + _v(0, (high + low) / 2.0, 0))
		if clips:
			_mesh(root, "clip_" + pin, _box(2.2, 4.0, 3.2), Materials.plastic_gloss(Color(colors[pin])), at + _v(0, high - 1.0, 0))
		var m := Marker3D.new()
		m.name = "lead_" + pin
		m.position = at + _v(0, high, 0)
		root.add_child(m)


static func _add_smoke(node: Node3D) -> void:
	var smoke := GPUParticles3D.new()
	smoke.name = "smoke"
	smoke.one_shot = true
	smoke.amount = 24
	smoke.lifetime = 3.0
	smoke.explosiveness = 0.3
	smoke.position = _v(0, 6.0, 0)
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 18.0
	process.initial_velocity_min = 0.4
	process.initial_velocity_max = 0.9
	process.gravity = Vector3(0, 0.15, 0)
	process.scale_min = 0.6
	process.scale_max = 1.4
	smoke.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	if _smoke == null:
		_smoke = StandardMaterial3D.new()
		_smoke.albedo_color = Color(0.55, 0.55, 0.58, 0.35)
		_smoke.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_smoke.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_smoke.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = _smoke
	smoke.draw_pass_1 = quad
	smoke.emitting = true
	node.add_child(smoke)


static func _gold_material() -> StandardMaterial3D:
	if _gold == null:
		_gold = StandardMaterial3D.new()
		_gold.albedo_color = Color("#E2B13C")
		_gold.metallic = 1.0
		_gold.roughness = 0.3
	return _gold


static func _mm(x: float) -> float:
	return PartDims.mm(x)


static func _v(x: float, y: float, z: float) -> Vector3:
	return Vector3(_mm(x), _mm(y), _mm(z))


static func _pin_local(p: Part, pin: String) -> Vector3:
	var o := CircuitGeometry.pin_offset(p, pin)
	return Vector3(o.x * PartDims.GRID, 0, o.y * PartDims.GRID)


static func _mesh(parent: Node, mesh_name: String, mesh: Mesh, mat: Material, at := Vector3.ZERO, rot := Vector3.ZERO,
		scale := Vector3.ONE) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = mesh_name
	m.mesh = mesh
	m.material_override = mat
	m.position = at
	m.rotation = rot
	m.scale = scale
	parent.add_child(m, true)
	return m


static func _lead(parent: Node, lead_name: String, pts: PackedVector3Array, radius_mm: float, sides: int, mat: Material) -> void:
	_mesh(parent, lead_name, WireMesh.tube(pts, radius_mm, sides), mat)


static func _cyl(top_mm: float, bottom_mm: float, height_mm: float, segments := 24) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = _mm(top_mm)
	c.bottom_radius = _mm(bottom_mm)
	c.height = _mm(height_mm)
	c.radial_segments = segments
	c.rings = 1
	return c


static func _box(x_mm: float, y_mm: float, z_mm: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(_mm(x_mm), _mm(y_mm), _mm(z_mm))
	return b


## An LED flange: a disc of radius `r` with a flat at x = `flat` (the cathode
## side), `h` thick, standing on y = 0.
static func _flanged_disc(r: float, flat: float, h: float) -> ArrayMesh:
	var outline := PackedVector2Array()
	var cut := acos(flat / r)
	var n := 40
	for i in n + 1:
		var a := cut + (TAU - 2.0 * cut) * i / n
		outline.append(Vector2(cos(a), sin(a)) * r)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := _mm(h)
	var count := outline.size()
	for i in count:
		var a := outline[i]
		var b := outline[(i + 1) % count]
		var pa := Vector3(_mm(a.x), 0, _mm(a.y))
		var pb := Vector3(_mm(b.x), 0, _mm(b.y))
		var side_n := Vector3(b.y - a.y, 0, -(b.x - a.x)).normalized()
		for v in [pa, pb + Vector3(0, top, 0), pb, pa, pa + Vector3(0, top, 0), pb + Vector3(0, top, 0)]:
			st.set_normal(side_n)
			st.add_vertex(v)
		for v in [Vector3(0, top, 0), pb + Vector3(0, top, 0), pa + Vector3(0, top, 0)]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
		for v in [Vector3.ZERO, pa, pb]:
			st.set_normal(Vector3.DOWN)
			st.add_vertex(v)
	return st.commit()
