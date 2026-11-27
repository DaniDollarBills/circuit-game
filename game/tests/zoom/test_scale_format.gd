extends TestCase


func test_meters_picks_unit_and_precision() -> void:
	var cases := {
		12742000.0: "12,742 km", 300.0: "300 m", 2.5: "2.5 m", 0.02: "2 cm", 0.0025: "2.5 mm",
		0.0005: "500 µm", 2e-5: "20 µm", 5e-9: "5 nm", 4e-10: "400 pm",
	}
	for m in cases:
		assert_eq(ScaleFormat.meters(m), cases[m], str(m))


func test_jump_format() -> void:
	assert_eq(ScaleFormat.jump(833.3), "Skipping ahead ×830")
	assert_eq(ScaleFormat.jump(13333.0), "Skipping ahead ×13,000")
	assert_eq(ScaleFormat.jump(1.64), "Skipping ahead ×1.6")
