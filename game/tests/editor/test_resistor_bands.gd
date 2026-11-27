extends TestCase


func test_digits() -> void:
	var cases := {220.0: [2, 2, 1], 1000.0: [1, 0, 2], 47.0: [4, 7, 0], 500.0: [5, 0, 1], 150.0: [1, 5, 1], 1234.0: [1, 2, 2]}
	for ohms in cases:
		assert_eq(ResistorBands.digits(ohms), cases[ohms] as Array[int], str(ohms))


func test_band_colors_220_red_red_brown() -> void:
	assert_eq(ResistorBands.colors(220.0), [Color("#E0605E"), Color("#E0605E"), Color("#8B5A2B"), Color("#E8C66A")] as Array[Color])


## Brown, black, red: 1 kΩ. The L2 fact says brown, green, brown is 150 Ω.
func test_band_colors_1k_and_150() -> void:
	assert_eq(ResistorBands.colors(1000.0).slice(0, 3), [Color("#8B5A2B"), Color("#2B2B2B"), Color("#E0605E")] as Array[Color])
	assert_eq(ResistorBands.colors(150.0).slice(0, 3), [Color("#8B5A2B"), Color("#6CBF84"), Color("#8B5A2B")] as Array[Color])
