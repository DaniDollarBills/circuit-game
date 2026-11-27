class_name CircuitView
extends Node2D
## The Schematic view: circuit symbols on a cream board, drawn at screen
## resolution (the canvas is never scaled) so every edge stays crisp at any
## zoom. Colors follow the night setting; values show when show_values is on.

const POP_S := 0.18
## Where a value label may move from its anchor, nearest first.
const LABEL_SPOTS: Array[Vector2] = [
	Vector2(0, 0), Vector2(0, 0.7), Vector2(0, -0.9), Vector2(1.5, 0), Vector2(-1.5, 0),
	Vector2(0, 1.4), Vector2(0, -1.6), Vector2(1.5, 0.8), Vector2(-1.5, 0.8), Vector2(0, 2.1),
	Vector2(2.2, 0), Vector2(-2.2, 0), Vector2(0, -2.3), Vector2(2.2, 0.8), Vector2(-2.2, 0.8),
	Vector2(0, 2.8), Vector2(0, -3.0), Vector2(3.0, 0), Vector2(-3.0, 0), Vector2(0, 3.6), Vector2(0, -3.7),
]

var circuit := Circuit.new()
var sim: SimResult
var settings: Dictionary = {}
var ghosts: Dictionary = {}
var highlights: Array = []
var selection := ""
## {from: Vector2, to: Vector2, snap: Vector2|null} while a wire is dragged;
## {part: Part} while a tray part is placed.
var preview: Dictionary = {}
var center := Vector2.ZERO
var ppu := 32.0
var size := Vector2(1280, 720)
## Part id → seconds since it was placed, for the pop-in.
var pops := {}


func _process(delta: float) -> void:
	if pops.is_empty():
		return
	for id in pops.keys():
		pops[id] += delta
		if pops[id] > POP_S:
			pops.erase(id)
	queue_redraw()


func to_screen(g: Vector2) -> Vector2:
	return (g - center) * ppu + size / 2.0


func _draw() -> void:
	var night := bool(settings.get("night", false))
	draw_rect(Rect2(Vector2.ZERO, size), Palette.color("cream", night))
	var base := size / 2.0 - center * ppu
	draw_set_transform(base)
	if ppu >= 10.0:
		var half := size / 2.0 / ppu
		var dot := Color(Palette.color("line", night), 0.9)
		for gx in range(floori(center.x - half.x), ceili(center.x + half.x) + 1):
			for gy in range(floori(center.y - half.y), ceili(center.y + half.y) + 1):
				draw_rect(Rect2(Vector2(gx, gy) * ppu - Vector2.ONE, Vector2(2, 2)), dot)
	for w in circuit.wires:
		var path := CircuitGeometry.wire_path(circuit, w)
		if path.size() < 2:
			continue
		var volts := _wire_volts(w)
		var floating := is_nan(volts)
		if w.id == selection:
			DrawKit.polyline(self, path, Color(PartArt.ACCENT, 0.5), 0.42, ppu)
		DrawKit.polyline(self, path, WireArt.color_for_volts(volts, floating, night), 0.22, ppu)
		for dash in WireArt.pattern_dashes(path, volts, bool(settings.get("patterns", false))):
			DrawKit.polyline(self, dash, Palette.color("ink", night), 0.08, ppu)
	for h in highlights:
		_highlight(h)
	for p in circuit.parts:
		var vis := VisualState.for_part(p, sim, settings) if sim != null else {}
		var ops := PartArt.ops(p, vis, p.id == selection, false)
		if pops.has(p.id) and not bool(settings.get("reduced_motion", false)):
			var s := _pop_scale(pops[p.id] / POP_S)
			var origin := Vector2(p.x, p.y) * ppu
			draw_set_transform(base + origin * (1.0 - s), 0.0, Vector2(s, s))
			DrawKit.draw_ops(self, ops, Vector2(p.x, p.y), p.rot, ppu)
			draw_set_transform(base)
		else:
			DrawKit.draw_ops(self, ops, Vector2(p.x, p.y), p.rot, ppu)
	if sim != null and bool(settings.get("show_values", true)):
		for l in placed_labels(circuit, sim):
			DrawKit.text(self, l["at"], l["text"], 0.42, Palette.color("ink_soft", night), false, ppu)
	_draw_ghosts()
	_draw_preview(night)
	draw_set_transform(Vector2.ZERO)


## The engineer labels, each moved to the first nearby spot that is clear of
## every part (with the text drawn under it), every wire, and the labels placed
## before it.
static func placed_labels(c: Circuit, s: SimResult) -> Array[Dictionary]:
	var taken: Array[Rect2] = []
	for p in c.parts:
		taken.append(footprint(p))
	for w in c.wires:
		var path := CircuitGeometry.wire_path(c, w)
		for i in range(1, path.size()):
			taken.append(Rect2(path[i - 1], Vector2.ZERO).expand(path[i]).grow(0.2))
	var out: Array[Dictionary] = []
	for l in VisualState.engineer_labels(c, s):
		var text: String = l["text"]
		var box := Vector2(0.25 * text.length() + 0.2, 0.6)
		var anchor: Vector2 = l["at"]
		var spot := anchor
		for offset in LABEL_SPOTS:
			var r := Rect2(anchor + offset - box / 2.0, box)
			if not taken.any(func(t: Rect2) -> bool: return t.intersects(r)):
				spot = anchor + offset
				break
		taken.append(Rect2(spot - box / 2.0, box))
		out.append({"at": spot, "text": text, "part": l["part"]})
	return out


## A part's tile plus the text PartArt writes under it (value, label, reading).
static func footprint(p: Part) -> Rect2:
	var r := CircuitGeometry.part_rect(p)
	match p.kind:
		"resistor", "switch":
			r = r.grow_individual(0, 0, 0, 1.3)
		"ammeter", "voltmeter":
			r = r.grow_individual(0, 0, 0, 1.7)
		"battery":
			r = r.grow(0.1)
	return r


## 0 → 1 with a small overshoot.
static func _pop_scale(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return 1.0 + 2.70158 * pow(t - 1.0, 3) + 1.70158 * pow(t - 1.0, 2)


func _wire_volts(w: Wire) -> float:
	if sim == null:
		return NAN
	return sim.pin_volts(w.a_part, w.a_pin)


func _highlight(h: Dictionary) -> void:
	var spark := Color(Palette.color("spark"), 0.8)
	if h.has("wire") and circuit.find_wire(h["wire"]) != null:
		DrawKit.polyline(self, CircuitGeometry.wire_path(circuit, circuit.find_wire(h["wire"])), spark, 0.6, ppu)
	elif h.has("part") and circuit.find_part(h["part"]) != null:
		var p := circuit.find_part(h["part"])
		if h.has("pin"):
			DrawKit.glow(self, Vector2(CircuitGeometry.pin_position(p, h["pin"])), 0.8, spark, ppu)
		else:
			var r := CircuitGeometry.part_rect(p)
			DrawKit.glow(self, r.get_center(), maxf(r.size.x, r.size.y) * 0.8, spark, ppu)


func _draw_ghosts() -> void:
	if ghosts.is_empty():
		return
	var with_ghosts := circuit.copy()
	for p in ghosts.get("parts", []):
		with_ghosts.parts.append((p as Part).copy())
		DrawKit.draw_ops(self, faded(PartArt.ops(p, {}, false, false), 0.4), Vector2(p.x, p.y), p.rot, ppu)
	for g in ghosts.get("wires", []):
		var path := CircuitGeometry.wire_path(with_ghosts, Wire.make("ghost", g["a_part"], g["a_pin"], g["b_part"], g["b_pin"]))
		DrawKit.polyline(self, path, Color(Palette.color("lavender"), 0.7), 0.24, ppu)
	for id in ghosts.get("remove_wires", []):
		var w := circuit.find_wire(id)
		if w != null:
			DrawKit.polyline(self, CircuitGeometry.wire_path(circuit, w), Color(Palette.color("coral"), 0.7), 0.4, ppu)


func _draw_preview(night: bool) -> void:
	if preview.has("from"):
		DrawKit.polyline(self, PackedVector2Array([preview["from"], preview["to"]]), Color(PartArt.ACCENT, 0.7), 0.16, ppu)
		if preview.get("snap") != null:
			DrawKit.circle(self, preview["snap"], 0.42, Color(0, 0, 0, 0), Color(PartArt.ACCENT), 0.08, ppu)
	elif preview.has("part"):
		var p: Part = preview["part"]
		DrawKit.draw_ops(self, faded(PartArt.ops(p, {}, false, false), 0.55), Vector2(p.x, p.y), p.rot, ppu)
	elif preview.has("pin"):
		DrawKit.circle(self, preview["pin"], 0.42, Color(0, 0, 0, 0), Color(PartArt.ACCENT), 0.1, ppu)


## The same ops with every color made more transparent.
static func faded(ops: Array[Dictionary], alpha: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for op in ops:
		var o := op.duplicate()
		for key in ["fill", "stroke", "color"]:
			if o.has(key):
				var c: Color = o[key]
				o[key] = Color(c, c.a * alpha)
		out.append(o)
	return out
