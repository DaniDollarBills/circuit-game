extends TestCase

var r: GestureRecognizer


func before_each() -> void:
	r = GestureRecognizer.new()


func _types(gs: Array[Dictionary]) -> Array:
	return gs.map(func(g: Dictionary) -> String: return g["type"])


func test_tap() -> void:
	assert_eq(r.down(0, Vector2(100, 100), 0.0).size(), 0)
	var gs := r.up(0, Vector2(100, 100), 0.1)
	assert_eq(_types(gs), ["tap"])
	assert_eq(gs[0]["at"], Vector2(100, 100))


func test_small_move_is_still_tap() -> void:
	r.down(0, Vector2(100, 100), 0.0)
	assert_eq(r.move(0, Vector2(106, 100), 0.05).size(), 0)
	var gs := r.up(0, Vector2(106, 100), 0.1)
	assert_eq(_types(gs), ["tap"])
	assert_eq(gs[0]["at"], Vector2(100, 100), "a tap lands where the finger went down")


func test_drag_after_9px() -> void:
	r.down(0, Vector2(100, 100), 0.0)
	var gs := r.move(0, Vector2(109, 100), 0.05)
	assert_eq(_types(gs), ["drag_start", "drag_move"])
	assert_eq(gs[0]["at"], Vector2(100, 100), "the drag starts where the finger went down")
	assert_eq(gs[1]["at"], Vector2(109, 100))
	assert_eq(_types(r.move(0, Vector2(120, 100), 0.1)), ["drag_move"])
	var end := r.up(0, Vector2(120, 100), 0.2)
	assert_eq(_types(end), ["drag_end"])
	assert_eq(end[0]["at"], Vector2(120, 100))


func test_long_press_at_0_5s() -> void:
	r.down(0, Vector2(50, 50), 0.0)
	assert_eq(r.tick(0.3).size(), 0)
	var gs := r.tick(0.5)
	assert_eq(_types(gs), ["long_press"])
	assert_eq(gs[0]["at"], Vector2(50, 50))
	assert_eq(r.tick(0.9).size(), 0, "only once")


func test_no_tap_after_long_press() -> void:
	r.down(0, Vector2(50, 50), 0.0)
	r.tick(0.5)
	assert_eq(r.move(0, Vector2(80, 50), 0.6).size(), 0)
	assert_eq(r.up(0, Vector2(80, 50), 0.7).size(), 0)


func test_second_pointer_cancels_drag() -> void:
	r.down(0, Vector2(100, 100), 0.0)
	r.move(0, Vector2(120, 100), 0.05)
	assert_eq(_types(r.down(1, Vector2(220, 100), 0.1)), ["drag_cancel"])
	var gs := r.move(1, Vector2(320, 100), 0.15)
	assert_eq(_types(gs), ["zoom", "pan"])
	assert_near(gs[0]["factor"], 2.0, 1e-6)
	assert_eq(gs[0]["at"], Vector2(220, 100))
	assert_eq(gs[1]["delta"], Vector2(50, 0))
	assert_eq(r.up(1, Vector2(320, 100), 0.2).size(), 0)
	assert_eq(r.move(0, Vector2(300, 300), 0.25).size(), 0, "the remaining finger is ignored")
	assert_eq(r.up(0, Vector2(300, 300), 0.3).size(), 0)
	r.down(0, Vector2(10, 10), 1.0)
	assert_eq(_types(r.up(0, Vector2(10, 10), 1.05)), ["tap"], "a fresh tap works again")


func test_pinch_before_drag_gives_no_tap() -> void:
	r.down(0, Vector2(100, 100), 0.0)
	assert_eq(r.down(1, Vector2(200, 100), 0.05).size(), 0, "no drag to cancel yet")
	r.up(0, Vector2(100, 100), 0.1)
	assert_eq(r.up(1, Vector2(200, 100), 0.15).size(), 0)


func test_right_button_secondary_tap() -> void:
	r.down(1000, Vector2(10, 10), 0.0, MOUSE_BUTTON_RIGHT)
	assert_eq(_types(r.up(1000, Vector2(10, 10), 0.1)), ["secondary_tap"])
	r.down(1000, Vector2(10, 10), 1.0, MOUSE_BUTTON_RIGHT)
	assert_eq(r.tick(2.0).size(), 0, "the right button has no long press")


func test_wheel_factor() -> void:
	var gs := r.wheel(Vector2(5, 5), 1.0)
	assert_eq(_types(gs), ["zoom"])
	assert_eq(gs[0]["at"], Vector2(5, 5))
	assert_near(gs[0]["factor"], 1.15, 1e-9)
	assert_near(r.wheel(Vector2(5, 5), -2.0)[0]["factor"], 1.0 / (1.15 * 1.15), 1e-9)


func test_trackpad_gestures() -> void:
	var z := r.magnify(Vector2(3, 4), 1.2)
	assert_eq(_types(z), ["zoom"])
	assert_near(z[0]["factor"], 1.2, 1e-9)
	assert_eq(r.pan_gesture(Vector2(7, -2)), [{"type": "pan", "delta": Vector2(7, -2)}] as Array[Dictionary])


func test_third_finger_does_not_end_pinch() -> void:
	r.down(0, Vector2(100, 100), 0.0)
	r.down(1, Vector2(200, 100), 0.05)
	r.down(2, Vector2(400, 400), 0.1)
	r.up(2, Vector2(400, 400), 0.15)
	var gs := r.move(1, Vector2(300, 100), 0.2)
	assert_eq(_types(gs), ["zoom", "pan"])
	assert_near(gs[0]["factor"], 2.0, 1e-6)
