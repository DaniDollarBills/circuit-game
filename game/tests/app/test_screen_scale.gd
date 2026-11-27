extends TestCase


func test_phone_keeps_one_logical_pixel_per_point() -> void:
	assert_eq(ScreenScale.factor(Vector2i(390, 844), 1.0), 1.0)
	assert_eq(ScreenScale.factor(Vector2i(1170, 2532), 3.0), 3.0)
	assert_eq(ScreenScale.factor(Vector2i(844, 390), 1.0), 1.0)


func test_big_windows_show_720_on_the_short_side() -> void:
	assert_eq(ScreenScale.factor(Vector2i(1280, 720), 1.0), 1.0)
	assert_eq(ScreenScale.factor(Vector2i(1920, 1080), 1.0), 1.5)
	assert_eq(ScreenScale.factor(Vector2i(2560, 1440), 2.0), 2.0)


func test_small_desktop_window_is_not_shrunk() -> void:
	assert_eq(ScreenScale.factor(Vector2i(800, 500), 1.0), 1.0)


func test_logical_size_matches_factor() -> void:
	assert_eq(ScreenScale.logical_size(Vector2i(1170, 2532), 3.0), Vector2i(390, 844))
	assert_eq(ScreenScale.logical_size(Vector2i(1920, 1080), 1.0), Vector2i(1280, 720))
	assert_eq(ScreenScale.logical_size(Vector2i(0, 0), 1.0), Vector2i(0, 0))
