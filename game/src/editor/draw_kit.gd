class_name DrawKit
extends RefCounted
## Crisp vector drawing for the schematic art. Geometry comes in world units
## and is scaled to pixels here (the CanvasItem itself is never scaled), so
## antialiasing and text stay sharp at every zoom. Curves are cut finer as the
## zoom grows.

const FONT_REGULAR := "res://assets/fonts/nunito-latin-700-normal.woff2"
const FONT_BOLD := "res://assets/fonts/nunito-latin-800-normal.woff2"
## Text smaller than this many pixels is unreadable, so it isn't drawn.
const MIN_TEXT_PX := 5.0

static var _fonts := {}


static func segments(r: float, ppu: float) -> int:
	return clampi(int(r * ppu / 2.0), 12, 96)


static func rrect(ci: CanvasItem, rect: Rect2, radius: float, fill: Color, stroke: Color, stroke_w: float, ppu: float) -> void:
	var pts := _rounded_rect(Rect2(rect.position * ppu, rect.size * ppu), radius * ppu, ppu)
	if fill.a > 0.0:
		ci.draw_colored_polygon(pts, fill)
	if stroke.a > 0.0 and stroke_w > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, stroke, stroke_w * ppu, true)


static func circle(ci: CanvasItem, c: Vector2, r: float, fill: Color, stroke: Color, stroke_w: float, ppu: float) -> void:
	var n := segments(r, ppu)
	if fill.a > 0.0:
		ci.draw_colored_polygon(_circle(c * ppu, r * ppu, n), fill)
	if stroke.a > 0.0 and stroke_w > 0.0:
		ci.draw_arc(c * ppu, r * ppu, 0.0, TAU, n + 1, stroke, stroke_w * ppu, true)


static func capsule(ci: CanvasItem, a: Vector2, b: Vector2, r: float, fill: Color, ppu: float) -> void:
	ci.draw_line(a * ppu, b * ppu, fill, 2.0 * r * ppu, true)
	for end in [a, b]:
		ci.draw_colored_polygon(_circle(end * ppu, r * ppu, segments(r, ppu)), fill)


## A soft halo fading out from the middle, in more layers as it gets bigger on
## screen so it never shows rings.
static func glow(ci: CanvasItem, c: Vector2, r: float, color: Color, ppu: float) -> void:
	var steps := clampi(int(r * ppu / 5.0), 8, 40)
	for i in steps:
		var k := 1.0 - float(i) / steps
		ci.draw_colored_polygon(_circle(c * ppu, r * k * ppu, segments(r * k, ppu)), Color(color, color.a * 1.6 / steps))


## Centered on `at`, always upright.
static func text(ci: CanvasItem, at: Vector2, s: String, size: float, color: Color, bold: bool, ppu: float) -> void:
	var px := size * ppu
	if px < MIN_TEXT_PX or s.is_empty():
		return
	var font := _font(bold)
	var font_size := roundi(px)
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	ci.draw_string(font, at * ppu + Vector2(-w / 2.0, baseline), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## A polyline with round joins and caps.
static func polyline(ci: CanvasItem, points: PackedVector2Array, color: Color, width: float, ppu: float) -> void:
	var px := PackedVector2Array()
	for p in points:
		px.append(p * ppu)
	ci.draw_polyline(px, color, width * ppu, true)
	for p in px:
		ci.draw_colored_polygon(_circle(p, width * ppu / 2.0, segments(width / 2.0, ppu)), color)


static func poly(ci: CanvasItem, points: PackedVector2Array, fill: Color, stroke: Color, stroke_w: float, ppu: float) -> void:
	var px := PackedVector2Array()
	for p in points:
		px.append(p * ppu)
	if fill.a > 0.0:
		ci.draw_colored_polygon(px, fill)
	if stroke.a > 0.0 and stroke_w > 0.0:
		var closed := px.duplicate()
		closed.append(px[0])
		ci.draw_polyline(closed, stroke, stroke_w * ppu, true)


## Draws PartArt ops for a part placed at `origin` (world units) and turned by
## `rot` degrees clockwise. Shapes turn with the part; text stays upright.
static func draw_ops(ci: CanvasItem, ops: Array[Dictionary], origin: Vector2, rot: int, ppu: float) -> void:
	var tile := Rect2()
	for op in ops:
		if op.get("tag", "") == "tile":
			tile = op["rect"]
	for op in ops:
		match op["type"]:
			"rrect":
				var r: Rect2 = op["rect"]
				var a := origin + turn(r.position, rot)
				var b := origin + turn(r.end, rot)
				rrect(ci, Rect2(a.min(b), (b - a).abs()), op["radius"], op["fill"], op["stroke"], op["stroke_w"], ppu)
			"circle":
				circle(ci, origin + turn(op["c"], rot), op["r"], op["fill"], op["stroke"], op["stroke_w"], ppu)
			"capsule":
				capsule(ci, origin + turn(op["a"], rot), origin + turn(op["b"], rot), op["r"], op["fill"], ppu)
			"glow":
				glow(ci, origin + turn(op["c"], rot), op["r"], op["color"], ppu)
			"polyline":
				polyline(ci, _place(op["points"], origin, rot), op["color"], op["width"], ppu)
			"poly":
				poly(ci, _place(op["points"], origin, rot), op["fill"], op["stroke"], op["stroke_w"], ppu)
			"text":
				text(ci, _text_spot(op["at"], tile, origin, rot), op["text"], op["size"], op["color"], op["bold"], ppu)


## Clockwise by `rot` degrees with y pointing down: 90° maps (x, y) to (−y, x).
static func turn(v: Vector2, rot: int) -> Vector2:
	match posmod(rot, 360):
		90:
			return Vector2(-v.y, v.x)
		180:
			return -v
		270:
			return Vector2(v.y, -v.x)
	return v


## Where a text op lands. A label below the part's tile stays below the turned
## tile at the same gap, so values and readings never sit on the symbol; any
## other text turns with the part (it is always drawn upright).
static func _text_spot(at: Vector2, tile: Rect2, origin: Vector2, rot: int) -> Vector2:
	if tile.has_area() and absf(at.x - tile.get_center().x) < 1e-6 and at.y > tile.end.y:
		var a := turn(tile.position, rot)
		var b := turn(tile.end, rot)
		return origin + Vector2((a.x + b.x) / 2.0, maxf(a.y, b.y) + at.y - tile.end.y)
	return origin + turn(at, rot)


static func _place(points: PackedVector2Array, origin: Vector2, rot: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(origin + turn(p, rot))
	return out


static func _font(bold: bool) -> Font:
	var path := FONT_BOLD if bold else FONT_REGULAR
	if not _fonts.has(path):
		var f: FontFile = load(path)
		_fonts[path] = f
	return _fonts[path]


static func _circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		out.append(c + Vector2.from_angle(TAU * i / n) * r)
	return out


static func _rounded_rect(rect: Rect2, radius: float, ppu: float) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) / 2.0)
	var n := maxi(3, segments(r / maxf(ppu, 1e-6), ppu) / 4)
	var corners := [
		[rect.position + Vector2(rect.size.x - r, r), -PI / 2.0],
		[rect.end - Vector2(r, r), 0.0],
		[rect.position + Vector2(r, rect.size.y - r), PI / 2.0],
		[rect.position + Vector2(r, r), PI],
	]
	var out := PackedVector2Array()
	for corner in corners:
		for i in n + 1:
			out.append(corner[0] + Vector2.from_angle(corner[1] + PI / 2.0 * i / n) * r)
	return out
