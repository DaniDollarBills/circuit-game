extends TestCase
## The moving hand that shows a gesture, which follows touch or mouse, and the
## spotlight that lets taps through its hole.


func after_each() -> void:
	InputMode.mode = ""


func _hand() -> GestureHand:
	var host := Control.new()
	host.size = Vector2(800, 600)
	add_to_tree(host)
	var hand := GestureHand.new()
	host.add_child(hand)
	hand.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return hand


func test_hand_drag_moves_along_path() -> void:
	var hand := _hand()
	hand.play("drag", Vector2(100, 100), Vector2(500, 300))
	hand.advance(0.0)
	assert_near(hand.hand_position().distance_to(Vector2(100, 100)), 0.0, 1.0, "it starts at the start")
	hand.advance(GestureHand.PRESS_S + GestureHand.MOVE_S / 2.0)
	var mid := hand.hand_position()
	assert_true(mid.x > 150.0 and mid.x < 450.0, "halfway there: %s" % mid)
	hand.advance(GestureHand.MOVE_S)
	assert_near(hand.hand_position().distance_to(Vector2(500, 300)), 0.0, 1.0, "it ends at the end")


func test_hand_loops() -> void:
	var hand := _hand()
	hand.play("tap", Vector2(200, 200))
	hand.advance(GestureHand.LOOP_S * 3.0 + 0.01)
	assert_true(hand.visible and hand.playing())
	hand.stop()
	assert_false(hand.playing())


func test_hand_mode_follows_last_input() -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	InputMode.note(touch)
	assert_eq(InputMode.current(), "touch")
	var hand := _hand()
	hand.play("tap", Vector2(10, 10))
	assert_eq(hand.mode, "touch")
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	InputMode.note(click)
	assert_eq(InputMode.current(), "mouse")
	hand.play("tap", Vector2(10, 10))
	assert_eq(hand.mode, "mouse")


func test_emulated_mouse_from_touch_stays_touch() -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	InputMode.note(touch)
	var emulated := InputEventMouseButton.new()
	emulated.pressed = true
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	InputMode.note(emulated)
	assert_eq(InputMode.current(), "touch", "a finger's emulated click is still a finger")


func test_spotlight_passes_input_in_hole() -> void:
	var host := Control.new()
	host.size = Vector2(800, 600)
	add_to_tree(host)
	var spot := Spotlight.new()
	host.add_child(spot)
	spot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spot.show_rect(Rect2(100, 100, 200, 120))
	assert_false(spot._has_point(Vector2(150, 150)), "taps reach what's in the light")
	assert_true(spot._has_point(Vector2(600, 500)), "the dimmed rest is held back")
	spot.clear()
	assert_false(spot.visible)
