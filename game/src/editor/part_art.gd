class_name PartArt
extends RefCounted
## The Schematic view's circuit symbols, as drawing ops in part-local grid
## units (before rotation): ink strokes on soft pastel tiles, metal pin dots,
## and the part's state (glow, heat, scorch, readings). DrawKit draws them.
## Each op may carry a "tag" naming what it is.

const STROKE := 0.11
const ACCENT := "#7C5CC4"


static func ops(p: Part, vis: Dictionary, selected: bool, highlighted: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var burnt := bool(vis.get("burnt", false))
	var rect := _tile_rect(p)
	if highlighted:
		out.append({"type": "glow", "c": rect.get_center(), "r": maxf(rect.size.x, rect.size.y) * 0.85,
				"color": Palette.color("spark"), "tag": "highlight"})
	var tile := _tile_color(p, vis)
	if burnt:
		tile = tile.darkened(0.35)
	out.append({"type": "rrect", "rect": rect, "radius": 0.32, "fill": tile, "stroke": Palette.color("line"),
			"stroke_w": 0.06, "tag": "tile"})
	var ink := Palette.color("ink")
	if burnt:
		ink = Color(ink, 0.55)
	match p.kind:
		"battery":
			_battery(out, vis, ink)
		"resistor":
			_resistor(out, p, ink)
		"led":
			_led(out, vis, ink, burnt)
		"switch":
			_switch(out, vis, ink)
		"ammeter", "voltmeter":
			_meter(out, p, vis, ink)
	if burnt:
		out.append({"type": "circle", "c": rect.get_center() + Vector2(0.15, -0.05), "r": minf(rect.size.x, rect.size.y) * 0.42,
				"fill": Color(0.24, 0.17, 0.14, 0.55), "stroke": Color(0, 0, 0, 0), "stroke_w": 0.0, "tag": "scorch"})
	for pin in Catalog.pin_names(p.kind):
		out.append({"type": "circle", "c": Vector2(CircuitGeometry.pin_offset(p, pin)), "r": 0.16,
				"fill": Palette.color("metal"), "stroke": Color(Palette.color("ink"), 0.5), "stroke_w": 0.04, "tag": "pin"})
	if selected:
		out.append({"type": "rrect", "rect": rect.grow(0.18), "radius": 0.45, "fill": Color(0, 0, 0, 0),
				"stroke": Color(ACCENT), "stroke_w": 0.1, "tag": "selected"})
	return out


static func _tile_rect(p: Part) -> Rect2:
	var size := Vector2(Catalog.size(p.kind, p.props))
	if p.kind == "led":
		size.y = 1.3
	return Rect2(-size / 2.0, size)


static func _tile_color(p: Part, vis: Dictionary) -> Color:
	match p.kind:
		"battery":
			return Palette.color("coral") if vis.get("hot", false) else Palette.color("mint")
		"resistor":
			return Palette.color("butter")
		"led":
			return Palette.color("paper")
		"switch":
			return Palette.color("peach")
		"ammeter":
			return Palette.color("sky")
		"voltmeter":
			return Palette.color("lilac")
	return Palette.color("paper")


static func _line(out: Array[Dictionary], points: Array, color: Color, width := STROKE, tag := "") -> void:
	var op := {"type": "polyline", "points": PackedVector2Array(points), "color": color, "width": width}
	if tag != "":
		op["tag"] = tag
	out.append(op)


static func _text(out: Array[Dictionary], at: Vector2, text: String, size: float, color: Color, bold: bool, tag := "") -> void:
	var op := {"type": "text", "at": at, "text": text, "size": size, "color": color, "bold": bold}
	if tag != "":
		op["tag"] = tag
	out.append(op)


## Long thin plate (+) over a short thick plate (−), leads to the pins.
static func _battery(out: Array[Dictionary], vis: Dictionary, ink: Color) -> void:
	if vis.get("hot", false):
		out.append({"type": "glow", "c": Vector2.ZERO, "r": 2.4, "color": Color(Palette.color("coral"), 0.8), "tag": "hot"})
	_line(out, [Vector2(0, -2), Vector2(0, -0.35)], ink)
	_line(out, [Vector2(0, 0.35), Vector2(0, 2)], ink)
	_line(out, [Vector2(-0.7, -0.35), Vector2(0.7, -0.35)], ink, 0.13, "plate_pos")
	_line(out, [Vector2(-0.38, 0.35), Vector2(0.38, 0.35)], ink, 0.28, "plate_neg")
	_text(out, Vector2(-0.6, -0.95), "+", 0.7, ink, true, "plus")
	_text(out, Vector2(0.55, 1.2), "5V", 0.45, ink, true, "volts")


## A zigzag with six peaks, the value underneath, and an arrow when adjustable.
static func _resistor(out: Array[Dictionary], p: Part, ink: Color) -> void:
	var half := Catalog.size(p.kind, p.props).x / 2.0
	_line(out, [Vector2(-half, 0), Vector2(-1.2, 0)], ink)
	_line(out, [Vector2(1.2, 0), Vector2(half, 0)], ink)
	var zig: Array = [Vector2(-1.2, 0)]
	for i in 6:
		zig.append(Vector2(-1.0 + 0.4 * i, -0.3 if i % 2 == 0 else 0.3))
	zig.append(Vector2(1.2, 0))
	_line(out, zig, ink, STROKE, "zigzag")
	var value := Catalog.format_ohms(float(p.props.get("ohms", 220.0)))
	if float(p.props.get("watts", 0.25)) >= 1.0:
		value += " · 1 W"
	_text(out, Vector2(0, 0.98), value, 0.5, Palette.color("ink"), true, "value")
	if bool(p.props.get("adjustable", false)):
		var tip := Vector2(1.0, -0.62)
		_line(out, [Vector2(-1.05, 0.55), tip], Color(ACCENT), 0.09, "adjust")
		out.append({"type": "poly", "points": PackedVector2Array([tip, tip + Vector2(-0.36, 0.06), tip + Vector2(-0.12, 0.33)]),
				"fill": Color(ACCENT), "stroke": Color(ACCENT), "stroke_w": 0.04, "tag": "adjust"})


## A triangle from anode to cathode, a bar at the cathode, and two light arrows
## that glow with the current.
static func _led(out: Array[Dictionary], vis: Dictionary, ink: Color, burnt: bool) -> void:
	var tint := Palette.led_tint(str(vis.get("color", "red")))
	var bright := 0.0 if burnt else float(vis.get("brightness", 0.0))
	if bright > 0.0:
		out.append({"type": "glow", "c": Vector2.ZERO, "r": 0.9 + 0.9 * bright, "color": Color(tint, 0.35 + 0.5 * bright), "tag": "light"})
	_line(out, [Vector2(-1, 0), Vector2(-0.4, 0)], ink)
	_line(out, [Vector2(0.42, 0), Vector2(1, 0)], ink)
	out.append({"type": "poly", "points": PackedVector2Array([Vector2(-0.4, -0.4), Vector2(-0.4, 0.4), Vector2(0.38, 0)]),
			"fill": tint if not burnt else tint.darkened(0.5), "stroke": ink, "stroke_w": 0.08, "tag": "body"})
	_line(out, [Vector2(0.42, -0.4), Vector2(0.42, 0.4)], ink, STROKE, "cathode_bar")
	var ray := Palette.color("line").lerp(tint.darkened(0.15), bright) if not burnt else Color(ink, 0.3)
	for base in [Vector2(-0.12, -0.5), Vector2(0.22, -0.46)]:
		var tip: Vector2 = base + Vector2(0.24, -0.3)
		_line(out, [base, tip], ray, 0.06, "ray")
		out.append({"type": "poly", "points": PackedVector2Array([tip + Vector2(0.06, -0.08), tip + Vector2(-0.14, -0.02), tip + Vector2(0.03, 0.13)]),
				"fill": ray, "stroke": ray, "stroke_w": 0.02, "tag": "ray"})


## Two contact dots and a lever: flat when closed, raised 30° when open.
static func _switch(out: Array[Dictionary], vis: Dictionary, ink: Color) -> void:
	_line(out, [Vector2(-2, 0), Vector2(-0.9, 0)], ink)
	_line(out, [Vector2(0.9, 0), Vector2(2, 0)], ink)
	var lever_end := Vector2(0.9, 0) if vis.get("closed", false) else Vector2(-0.9, 0) + Vector2.from_angle(deg_to_rad(-30.0)) * 1.8
	_line(out, [Vector2(-0.9, 0), lever_end], ink, 0.12, "lever")
	for x in [-0.9, 0.9]:
		out.append({"type": "circle", "c": Vector2(x, 0), "r": 0.14, "fill": ink, "stroke": Color(0, 0, 0, 0), "stroke_w": 0.0, "tag": "contact"})
	var label := str(vis.get("label", ""))
	if label != "":
		_text(out, Vector2(0, 0.98), label, 0.55, Palette.color("ink"), true, "label")


## A circle with A or V, and the reading underneath.
static func _meter(out: Array[Dictionary], p: Part, vis: Dictionary, ink: Color) -> void:
	_line(out, [Vector2(-1, 0), Vector2(-0.72, 0)], ink)
	_line(out, [Vector2(0.72, 0), Vector2(1, 0)], ink)
	out.append({"type": "circle", "c": Vector2.ZERO, "r": 0.72, "fill": Palette.color("paper"), "stroke": ink, "stroke_w": 0.1, "tag": "dial"})
	_text(out, Vector2.ZERO, "A" if p.kind == "ammeter" else "V", 0.8, ink, true, "letter")
	_text(out, Vector2(0, 1.4), str(vis.get("reading", "")), 0.5, Palette.color("ink"), true, "reading")
