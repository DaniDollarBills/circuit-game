class_name Wire
extends RefCounted
## A wire between two pins. `via` holds optional author-placed waypoints in grid
## units; an empty `via` means the route is chosen automatically.

var id: String
var a_part: String
var a_pin: String
var b_part: String
var b_pin: String
var locked := false
var via: Array[Vector2i] = []


static func make(wire_id: String, from_part: String, from_pin: String, to_part: String,
		to_pin: String, is_locked := false, waypoints: Array[Vector2i] = []) -> Wire:
	var w := Wire.new()
	w.id = wire_id
	w.a_part = from_part
	w.a_pin = from_pin
	w.b_part = to_part
	w.b_pin = to_pin
	w.locked = is_locked
	w.via = waypoints.duplicate()
	return w


func copy() -> Wire:
	return Wire.make(id, a_part, a_pin, b_part, b_pin, locked, via)
