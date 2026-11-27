class_name HitTest
extends RefCounted
## What is under a point on the board (grid units): the nearest pin within
## `pin_r`, else the topmost part whose turned footprint holds the point, else
## the nearest wire within `wire_r` of its route, else empty space.


static func at(c: Circuit, p: Vector2, pin_r: float, wire_r: float) -> Dictionary:
	var best := {}
	var best_d := pin_r
	for part in c.parts:
		for pin in Catalog.pin_names(part.kind):
			var pos := Vector2(CircuitGeometry.pin_position(part, pin))
			var d := p.distance_to(pos)
			if d <= best_d:
				best_d = d
				best = _hit("pin", part.id, pin, "", pos)
	if not best.is_empty():
		return best
	for i in range(c.parts.size() - 1, -1, -1):
		if CircuitGeometry.part_rect(c.parts[i]).has_point(p):
			return _hit("part", c.parts[i].id, "", "", p)
	var wire_d := wire_r
	for w in c.wires:
		var d := distance_to_path(p, CircuitGeometry.wire_path(c, w))
		if d <= wire_d:
			wire_d = d
			best = _hit("wire", "", "", w.id, p)
	return best if not best.is_empty() else _hit("empty", "", "", "", p)


static func distance_to_path(p: Vector2, path: PackedVector2Array) -> float:
	var best := INF
	for i in range(1, path.size()):
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, path[i - 1], path[i])))
	return best


static func _hit(kind: String, part: String, pin: String, wire: String, at: Vector2) -> Dictionary:
	return {"kind": kind, "part": part, "pin": pin, "wire": wire, "at": at}
