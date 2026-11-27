extends TestCase

const LINE: PackedVector2Array = [Vector2(0, 0), Vector2(6, 0)]


func test_color_for_volts_endpoints_and_floating() -> void:
	assert_eq(WireArt.color_for_volts(0.0, false), Palette.color("signal_low"))
	assert_eq(WireArt.color_for_volts(5.0, false), Palette.color("signal_high"))
	assert_eq(WireArt.color_for_volts(9.0, false), Palette.color("signal_high"), "clamped")
	assert_eq(WireArt.color_for_volts(2.0, true), Palette.color("line"))
	assert_eq(WireArt.color_for_volts(NAN, false), Palette.color("line"))
	assert_eq(WireArt.color_for_volts(2.0, true, true), Palette.color("line", true))


func test_no_dots_without_current() -> void:
	assert_eq(WireArt.dots(LINE, 0.0, 1.0).size(), 0)
	assert_eq(WireArt.dots(LINE, 5e-12, 1.0).size(), 0, "leakage shows nothing")


func test_dot_spacing_0_6() -> void:
	var d := WireArt.dots(LINE, 0.0138, 0.0)
	assert_eq(d.size(), 10)
	for i in range(1, d.size()):
		assert_near(d[i].x - d[i - 1].x, 0.6, 1e-6)


func test_dot_speed_monotonic() -> void:
	assert_eq(WireArt.dot_speed(5e-6), 0.0)
	var last := 0.0
	for amps in [2e-5, 1e-4, 1e-3, 1e-2, 0.1, 1.0, 5.0]:
		var s := WireArt.dot_speed(amps)
		assert_true(s >= last, "%s" % amps)
		assert_between(s, 0.3, 4.0)
		last = s
	assert_eq(WireArt.dot_speed(-0.01), WireArt.dot_speed(0.01))


func test_dots_reverse_for_negative_amps() -> void:
	var s := WireArt.dot_speed(0.0138)
	assert_near(WireArt.dots(LINE, 0.0138, 0.1)[0].x, fposmod(s * 0.1, 0.6), 1e-5)
	assert_near(WireArt.dots(LINE, -0.0138, 0.1)[0].x, fposmod(-s * 0.1, 0.6), 1e-5)


func test_dots_follow_corners() -> void:
	var bend := PackedVector2Array([Vector2(0, 0), Vector2(0.9, 0), Vector2(0.9, 3)])
	var d := WireArt.dots(bend, 0.0138, 0.0)
	assert_eq(d[1], Vector2(0.6, 0))
	assert_true(d[2].is_equal_approx(Vector2(0.9, 0.3)), str(d[2]))


func test_display_amps_electron_flow() -> void:
	assert_eq(WireArt.display_amps(0.01, {}), 0.01)
	assert_eq(WireArt.display_amps(0.01, {"electron_flow": false}), 0.01)
	assert_eq(WireArt.display_amps(0.01, {"electron_flow": true}), -0.01)


func test_pattern_dashes_only_high_and_enabled() -> void:
	assert_eq(WireArt.pattern_dashes(LINE, 5.0, false).size(), 0)
	assert_eq(WireArt.pattern_dashes(LINE, 2.0, true).size(), 0)
	var dashes := WireArt.pattern_dashes(LINE, 5.0, true)
	assert_eq(dashes.size(), 10)
	assert_near(dashes[0][0].x, 0.0, 1e-6)
	assert_near(dashes[0][dashes[0].size() - 1].x, 0.3, 1e-6)
	assert_near(dashes[1][0].x, 0.6, 1e-6)
