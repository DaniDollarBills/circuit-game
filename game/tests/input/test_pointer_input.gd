extends TestCase

var got: Array[Dictionary] = []


func _node() -> PointerInput:
	got.clear()
	var p := PointerInput.new()
	add_to_tree(p)
	p.gesture.connect(func(g: Dictionary) -> void: got.append(g))
	return p


func _mouse(button: MouseButton, pressed: bool, at: Vector2, device := 0) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.device = device
	e.button_index = button
	e.pressed = pressed
	e.position = at
	return e


## Touch screens also send mouse events marked as emulated; using both would
## double every tap.
func test_emulated_mouse_ignored() -> void:
	var p := _node()
	p.feed(_mouse(MOUSE_BUTTON_LEFT, true, Vector2(10, 10), InputEvent.DEVICE_ID_EMULATION), 0.0)
	var motion := InputEventMouseMotion.new()
	motion.device = InputEvent.DEVICE_ID_EMULATION
	motion.position = Vector2(60, 10)
	p.feed(motion, 0.05)
	p.feed(_mouse(MOUSE_BUTTON_LEFT, false, Vector2(60, 10), InputEvent.DEVICE_ID_EMULATION), 0.1)
	assert_eq(got.size(), 0)


func test_touch_tap() -> void:
	var p := _node()
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = Vector2(40, 30)
	p.feed(down, 0.0)
	var up := down.duplicate() as InputEventScreenTouch
	up.pressed = false
	p.feed(up, 0.1)
	assert_eq(got.size(), 1)
	assert_eq(got[0]["type"], "tap")


func test_mouse_drag() -> void:
	var p := _node()
	p.feed(_mouse(MOUSE_BUTTON_LEFT, true, Vector2(10, 10)), 0.0)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(40, 10)
	p.feed(motion, 0.05)
	p.feed(_mouse(MOUSE_BUTTON_LEFT, false, Vector2(40, 10)), 0.1)
	assert_eq(got.map(func(g: Dictionary) -> String: return g["type"]), ["drag_start", "drag_move", "drag_end"])


func test_wheel_zooms_at_cursor() -> void:
	var p := _node()
	var e := _mouse(MOUSE_BUTTON_WHEEL_UP, true, Vector2(5, 6))
	e.factor = 1.0
	p.feed(e, 0.0)
	p.feed(_mouse(MOUSE_BUTTON_WHEEL_UP, false, Vector2(5, 6)), 0.0)
	assert_eq(got.size(), 1)
	assert_eq(got[0]["at"], Vector2(5, 6))
	assert_near(got[0]["factor"], 1.15, 1e-6)
	p.feed(_mouse(MOUSE_BUTTON_WHEEL_DOWN, true, Vector2(5, 6)), 0.0)
	assert_near(got[1]["factor"], 1.0 / 1.15, 1e-6, "a wheel event without a factor counts as one step")


func test_trackpad_events() -> void:
	var p := _node()
	var m := InputEventMagnifyGesture.new()
	m.position = Vector2(1, 2)
	m.factor = 1.25
	p.feed(m, 0.0)
	var pan := InputEventPanGesture.new()
	pan.position = Vector2(1, 2)
	pan.delta = Vector2(3, 4)
	p.feed(pan, 0.0)
	assert_eq(got.map(func(g: Dictionary) -> String: return g["type"]), ["zoom", "pan"])
