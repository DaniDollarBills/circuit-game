extends TestCase


func test_grid_world_round_trip() -> void:
	assert_eq(PartDims.grid_to_world(Vector2(1, 0)), Vector3(0.254, 0, 0))
	assert_eq(PartDims.grid_to_world(Vector2(0, -2)), Vector3(0, 0, -0.508))
	for g in [Vector2(3, -4), Vector2(-6.5, 2.25), Vector2(0, 0)]:
		var back := PartDims.world_to_grid(PartDims.grid_to_world(g))
		assert_near(back.x, g.x, 1e-5)
		assert_near(back.y, g.y, 1e-5)


func test_dims_match_the_real_parts() -> void:
	assert_near(PartDims.mm(25.4), 2.54, 1e-12, "1 world unit = 1 cm")
	assert_eq(PartDims.GRID_MM, 2.54)
	assert_eq(PartDims.LED_DOME_D, 5.0)
	assert_eq(PartDims.RESISTOR_BODY, Vector2(6.3, 2.4))
	assert_eq(PartDims.RESISTOR_1W_BODY, Vector2(11.0, 4.5))
	assert_eq(PartDims.AA_CELL, Vector2(50.5, 14.5))
	assert_eq(PartDims.MULTIMETER, Vector3(150, 75, 35))
