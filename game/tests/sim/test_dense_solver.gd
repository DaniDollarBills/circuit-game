extends TestCase


func test_solves_2x2() -> void:
	var x := DenseSolver.solve(PackedFloat64Array([2, 1, 1, 3]), PackedFloat64Array([4, 7]), 2)
	assert_eq(x.size(), 2)
	assert_near(x[0], 1.0, 1e-12)
	assert_near(x[1], 2.0, 1e-12)


func test_needs_pivot() -> void:
	var x := DenseSolver.solve(PackedFloat64Array([0, 1, 1, 0]), PackedFloat64Array([3, 5]), 2)
	assert_near(x[0], 5.0, 1e-12)
	assert_near(x[1], 3.0, 1e-12)


func test_singular_returns_empty() -> void:
	var x := DenseSolver.solve(PackedFloat64Array([1, 2, 2, 4]), PackedFloat64Array([1, 2]), 2)
	assert_eq(x.size(), 0)


func test_3x3() -> void:
	var a := PackedFloat64Array([3, 2, -1, 2, -2, 4, -1, 0.5, -1])
	var x := DenseSolver.solve(a, PackedFloat64Array([1, -2, 0]), 3)
	assert_near(x[0], 1.0, 1e-12)
	assert_near(x[1], -2.0, 1e-12)
	assert_near(x[2], -2.0, 1e-12)


func test_input_not_modified() -> void:
	var a := PackedFloat64Array([0, 1, 1, 0])
	var b := PackedFloat64Array([3, 5])
	DenseSolver.solve(a, b, 2)
	assert_eq(a, PackedFloat64Array([0, 1, 1, 0]))
	assert_eq(b, PackedFloat64Array([3, 5]))
