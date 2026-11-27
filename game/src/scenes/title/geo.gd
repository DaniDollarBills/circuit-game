class_name Geo
extends RefCounted
## Latitude and longitude on a sphere: y points to the north pole, longitude 0
## faces +z and 90° east faces +x.


static func to_vec3(lat: float, lon: float, r: float) -> Vector3:
	var la := deg_to_rad(lat)
	var lo := deg_to_rad(lon)
	return Vector3(r * cos(la) * sin(lo), r * sin(la), r * cos(la) * cos(lo))


## `steps` + 1 points along the shorter great circle from a to b ((lat, lon)
## pairs), at radius r.
static func great_circle(a_latlon: Vector2, b_latlon: Vector2, r: float, steps: int) -> PackedVector3Array:
	var a := to_vec3(a_latlon.x, a_latlon.y, 1.0)
	var b := to_vec3(b_latlon.x, b_latlon.y, 1.0)
	var out := PackedVector3Array()
	for i in steps + 1:
		out.append(a.slerp(b, float(i) / maxf(steps, 1)).normalized() * r)
	return out
