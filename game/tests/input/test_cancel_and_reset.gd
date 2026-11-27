extends TestCase
## Checkpoint C, I1 and I2: a touch the system cancels never taps or drops,
## and a release that never arrives can't leave a gesture stuck.


func _types(gs: Array[Dictionary]) -> Array:
	return gs.map(func(g: Dictionary) -> String: return g["type"])


func test_cancelled_press_does_not_tap() -> void:
	var r := GestureRecognizer.new()
	r.down(1, Vector2(10, 10), 0.0)
	assert_eq(_types(r.cancel(1)), [])
	assert_eq(_types(r.down(1, Vector2(50, 50), 0.1)), [])
	assert_eq(_types(r.up(1, Vector2(50, 50), 0.2)), ["tap"], "the next press works normally")


func test_cancelled_drag_cancels_instead_of_dropping() -> void:
	var r := GestureRecognizer.new()
	r.down(1, Vector2(10, 10), 0.0)
	r.move(1, Vector2(60, 10), 0.1)
	assert_eq(_types(r.cancel(1)), ["drag_cancel"])
	assert_eq(_types(r.up(1, Vector2(60, 10), 0.2)), [], "a late release is ignored")


func test_press_on_an_id_already_down_resets_first() -> void:
	var r := GestureRecognizer.new()
	r.down(1000, Vector2(10, 10), 0.0)
	r.move(1000, Vector2(60, 10), 0.1)
	# The release was lost (focus moved away); the next click must still work.
	assert_eq(_types(r.down(1000, Vector2(200, 200), 1.0)), ["drag_cancel"])
	assert_eq(_types(r.up(1000, Vector2(200, 200), 1.1)), ["tap"])


func test_reset_cancels_a_drag() -> void:
	var r := GestureRecognizer.new()
	r.down(1, Vector2(10, 10), 0.0)
	r.move(1, Vector2(60, 10), 0.1)
	assert_eq(_types(r.reset()), ["drag_cancel"])
	assert_eq(_types(r.reset()), [], "nothing left to cancel")


func test_pointer_input_ignores_cancelled_touch() -> void:
	var p := PointerInput.new()
	add_to_tree(p)
	var got: Array = []
	p.gesture.connect(func(g: Dictionary) -> void: got.append(g["type"]))
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = Vector2(10, 10)
	p.feed(down, 0.0)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.canceled = true
	up.position = Vector2(10, 10)
	p.feed(up, 0.1)
	assert_eq(got, [])


func test_focus_out_resets_pointer_input() -> void:
	var p := PointerInput.new()
	add_to_tree(p)
	var got: Array = []
	p.gesture.connect(func(g: Dictionary) -> void: got.append(g["type"]))
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(10, 10)
	p.feed(down, 0.0)
	var move := InputEventMouseMotion.new()
	move.position = Vector2(80, 10)
	p.feed(move, 0.1)
	p.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(got, ["drag_start", "drag_move", "drag_cancel"])


func test_layer_that_stops_taking_input_drops_its_gesture() -> void:
	var layer: EditorLayer = load("res://src/editor/editor_layer.tscn").instantiate()
	layer.size = Vector2(1280, 720)
	add_to_tree(layer)
	var level := Levels.by_id("ch1.light-it-up")
	var out := Simulator.simulate(level.circuit)
	var st := Progress.DEFAULT_SETTINGS.duplicate()
	st["view_style"] = "schematic"
	layer.set_state(out.circuit, out.result, st, {}, [])
	layer.set_live(true, true)
	layer.apply_view(layer.fit_center(), layer.fit_view())
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = layer.pin_screen_pos("B1", "pos")
	layer._gui_input(down)
	var move := InputEventMouseMotion.new()
	move.position = down.position + Vector2(80, 0)
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	layer._gui_input(move)
	assert_eq(layer.controller.mode["kind"], "wiring")
	layer.set_live(true, false)
	assert_eq(layer.controller.mode["kind"], "idle", "the rubber band is gone")
