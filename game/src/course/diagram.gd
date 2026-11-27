class_name Diagram
extends Control
## A small moving picture for a Learn card. It draws in a 400 × 220 design box,
## scaled to fit and centered; DrawKit scales the geometry itself (the canvas
## is only moved, never scaled), so lines and text stay sharp at any size.
## Reduced motion holds it on a still frame that tells the same story with
## arrows instead of motion.

const DESIGN := Vector2(400, 220)

## Which picture. A script can hold several pictures and draw by this.
var id := ""
## Seconds of motion so far; stays 0 while still.
var t := 0.0
var still := false
var night := false
## Frames drawn, for tests.
var painted := 0

var _k := 1.0


## Sets the picture and reads Reduced motion and Night from the game.
func setup(diagram_id: String, game: Game) -> Diagram:
	id = diagram_id
	name = "Diagram_" + diagram_id
	if game != null:
		var st := game.state.progress.settings
		still = bool(st.get("reduced_motion", false))
		night = bool(st.get("night", false))
	return self


func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(Vector2(240, 132))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	if not still and is_visible_in_tree():
		t += delta
		queue_redraw()


func _draw() -> void:
	_k = minf(size.x / DESIGN.x, size.y / DESIGN.y)
	if _k <= 0.0:
		return
	draw_set_transform(((size - DESIGN * _k) / 2.0).round())
	_paint(t)
	draw_set_transform(Vector2.ZERO)
	painted += 1


## Subclasses draw here in design units (0–400 across, 0–220 down).
func _paint(_time: float) -> void:
	pass


# Helpers, all in design units.

func col(token: String) -> Color:
	return Palette.color(token, night)


func line(points: PackedVector2Array, color: Color, width: float) -> void:
	DrawKit.polyline(self, points, color, width, _k)


func dot(c: Vector2, r: float, fill: Color, stroke := Color(0, 0, 0, 0), stroke_w := 0.0) -> void:
	DrawKit.circle(self, c, r, fill, stroke, stroke_w, _k)


func label(at: Vector2, s: String, size_units := 16.0, color := Color(0, 0, 0, 0), bold := false) -> void:
	DrawKit.text(self, at, s, size_units, color if color.a > 0.0 else col("ink"), bold, _k)


func box(r: Rect2, radius: float, fill: Color, stroke := Color(0, 0, 0, 0), stroke_w := 0.0) -> void:
	DrawKit.rrect(self, r, radius, fill, stroke, stroke_w, _k)


func arrow(a: Vector2, b: Vector2, color: Color, width := 4.0) -> void:
	var dir := (b - a).normalized()
	var side := Vector2(-dir.y, dir.x)
	var head := width * 3.0
	line(PackedVector2Array([a, b - dir * head * 0.8]), color, width)
	DrawKit.poly(self, PackedVector2Array([b, b - dir * head + side * head * 0.6, b - dir * head - side * head * 0.6]),
			color, Color(0, 0, 0, 0), 0.0, _k)


## A schematic part symbol (the game's own art), `unit` design units per grid
## unit, centered on `at` and turned `rot` degrees clockwise.
## Text drawn outside a part's tile (a resistor's value, a switch's label, a
## meter's reading) takes this theme's ink, so it reads on the night card too.
func symbol(kind: String, at: Vector2, rot := 0, vis := {}, unit := 20.0, props := {}) -> void:
	var p := Part.make("D", kind, 0, 0, rot, props)
	var ops := PartArt.ops(p, vis, false, false)
	for op in ops:
		if op.get("tag", "") in ["value", "label", "reading"]:
			op["color"] = col("ink")
	DrawKit.draw_ops(self, ops, at / unit, rot, _k * unit)


## Glowing sparks spaced evenly along `path`, moving `speed` units a second.
func sparks(path: PackedVector2Array, count: int, speed: float, time: float) -> void:
	var length := path_length(path)
	if length <= 0.0:
		return
	for i in count:
		var c := along(path, fmod(time * speed + length * i / count, length))
		DrawKit.glow(self, c, 10.0, col("spark"), _k)
		dot(c, 3.5, col("spark"))


static func path_length(path: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i - 1].distance_to(path[i])
	return total


## The point `dist` along the path from its first point.
static func along(path: PackedVector2Array, dist: float) -> Vector2:
	var left := dist
	for i in range(1, path.size()):
		var seg := path[i - 1].distance_to(path[i])
		if left <= seg and seg > 0.0:
			return path[i - 1].lerp(path[i], left / seg)
		left -= seg
	return path[path.size() - 1]
