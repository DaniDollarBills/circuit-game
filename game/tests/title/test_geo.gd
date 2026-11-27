extends TestCase


func _near(a: Vector3, b: Vector3, eps := 1e-4) -> bool:
	return a.distance_to(b) <= eps


func test_to_vec3_poles_and_prime_meridian() -> void:
	assert_true(_near(Geo.to_vec3(90.0, 0.0, 1.0), Vector3(0, 1, 0)), "north pole is +y")
	assert_true(_near(Geo.to_vec3(-90.0, 0.0, 1.0), Vector3(0, -1, 0)), "south pole is −y")
	assert_true(_near(Geo.to_vec3(0.0, 0.0, 1.0), Vector3(0, 0, 1)), "0°, 0° is +z")
	assert_true(_near(Geo.to_vec3(0.0, 90.0, 1.0), Vector3(1, 0, 0)), "90° E is +x")
	assert_true(_near(Geo.to_vec3(0.0, 0.0, 6371.0), Vector3(0, 0, 6371.0), 1e-3), "radius scales")


func test_great_circle_on_sphere() -> void:
	var r := 6371.0 + 20.0
	var pts := Geo.great_circle(Vector2(40.71, -74.01), Vector2(50.83, -4.55), r, 64)
	assert_eq(pts.size(), 65)
	for p in pts:
		assert_near(p.length(), r, 1e-3)
	assert_true(_near(pts[0], Geo.to_vec3(40.71, -74.01, r), 1e-3))
	assert_true(_near(pts[64], Geo.to_vec3(50.83, -4.55, r), 1e-3))
