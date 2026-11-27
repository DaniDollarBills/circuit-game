extends TestCase


func test_land_data_sane() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/land_110m.json"))
	var polygons: Array = data["polygons"]
	assert_true(polygons.size() >= 50, "%d polygons" % polygons.size())
	for poly in polygons:
		assert_true((poly as Array).size() >= 4)
		for pt in poly:
			assert_true(float(pt[0]) >= -180.0 and float(pt[0]) <= 180.0 and float(pt[1]) >= -90.0 and float(pt[1]) <= 90.0, str(pt))
