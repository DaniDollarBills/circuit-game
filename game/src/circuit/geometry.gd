class_name CircuitGeometry
extends RefCounted
## Grid geometry: rotation, pin positions, part bounds and wire routes.


## Rotates a pin offset clockwise (y points down): 90° maps (x, y) to (-y, x).
static func rotate_offset(v: Vector2i, rot: int) -> Vector2i:
	match posmod(rot, 360):
		90:
			return Vector2i(-v.y, v.x)
		180:
			return Vector2i(-v.x, -v.y)
		270:
			return Vector2i(v.y, -v.x)
	return v


static func pin_offset(p: Part, pin: String) -> Vector2i:
	for entry in Catalog.pins(p.kind, p.props):
		if entry[0] == pin:
			return entry[1]
	push_error("Part %s (%s) has no pin '%s'" % [p.id, p.kind, pin])
	return Vector2i.ZERO


static func pin_position(p: Part, pin: String) -> Vector2i:
	return Vector2i(p.x, p.y) + rotate_offset(pin_offset(p, pin), p.rot)


## The unit axis pointing from the part's center toward the pin.
static func pin_outward(p: Part, pin: String) -> Vector2i:
	var o := rotate_offset(pin_offset(p, pin), p.rot)
	if absi(o.x) >= absi(o.y):
		return Vector2i(signi(o.x), 0)
	return Vector2i(0, signi(o.y))


static func part_rect(p: Part) -> Rect2:
	var s := Catalog.size(p.kind, p.props)
	var w := float(s.x)
	var h := float(s.y)
	if posmod(p.rot, 180) == 90:
		var t := w
		w = h
		h = t
	return Rect2(p.x - w / 2.0, p.y - h / 2.0, w, h)


## The wire's route in grid units. Author waypoints are used as given; otherwise
## the wire leaves each pin by a one-unit stub along the pin's axis and joins the
## stubs with an L that leaves the first pin along its axis.
static func wire_path(c: Circuit, w: Wire) -> PackedVector2Array:
	var pa := c.find_part(w.a_part)
	var pb := c.find_part(w.b_part)
	if pa == null or pb == null:
		return PackedVector2Array()
	var a := Vector2(pin_position(pa, w.a_pin))
	var b := Vector2(pin_position(pb, w.b_pin))
	var pts: Array[Vector2] = []
	if not w.via.is_empty():
		pts.append(a)
		for v in w.via:
			pts.append(Vector2(v))
		pts.append(b)
	else:
		var out_a := pin_outward(pa, w.a_pin)
		var p := a + Vector2(out_a)
		var q := b + Vector2(pin_outward(pb, w.b_pin))
		var corner := Vector2(q.x, p.y) if out_a.x != 0 else Vector2(p.x, q.y)
		pts = [a, p, corner, q, b]
	return _simplify(pts)


## Drops repeated points, then middle points in line with both neighbors,
## until nothing changes.
static func _simplify(points: Array[Vector2]) -> PackedVector2Array:
	var pts := points.duplicate()
	var changed := true
	while changed:
		changed = false
		var i := 1
		while i < pts.size():
			if pts[i].is_equal_approx(pts[i - 1]):
				pts.remove_at(i)
				changed = true
			else:
				i += 1
		i = 1
		while i < pts.size() - 1:
			if is_zero_approx((pts[i] - pts[i - 1]).cross(pts[i + 1] - pts[i])):
				pts.remove_at(i)
				changed = true
			else:
				i += 1
	return PackedVector2Array(pts)
