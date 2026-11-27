extends TestCase

var stage: ZoomStage
var parent: ZoomLayer
var child: ZoomLayer
var layer_events: Array[String] = []
var views: Array = []


func before_each() -> void:
	layer_events.clear()
	views.clear()
	stage = ZoomStage.new()
	stage.size = Vector2(1280, 720)
	add_to_tree(stage)
	parent = _layer("parent", 1.0, 0.1, 1000.0, 100.0, Color.LAVENDER)
	child = _layer("child", 0.001, 1.0, 100.0, 50.0, Color.AQUAMARINE)
	stage.add_link(ZoomLink.make("parent", "child", Vector2(5, 5), 10.0, 100.0))
	stage.layer_changed.connect(func(id: String) -> void: layer_events.append(id))
	stage.view_changed.connect(func(m: float, jump: String) -> void: views.append([m, jump]))


func _layer(id: String, mpu: float, lo: float, hi: float, home: float, color: Color) -> ZoomLayer:
	var l := ZoomLayer.new()
	l.layer_id = id
	l.meters_per_unit = mpu
	l.min_view = lo
	l.max_view = hi
	l.home_view = home
	stage.add_layer(l)
	var rect := ColorRect.new()
	rect.color = color
	rect.size = Vector2(1280, 720)
	l.viewport.add_child(rect)
	return l


func test_only_parent_visible_far_out() -> void:
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 100.0))
	assert_true(parent.visible)
	assert_false(child.visible)
	assert_eq(parent.modulate.a, 1.0)


func test_child_fades_in_band() -> void:
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 20.0))
	assert_true(parent.visible and child.visible)
	assert_between(child.modulate.a, 1e-3, 1.0 - 1e-3)
	assert_eq(parent.modulate.a, 1.0)
	assert_true(child.get_index() > parent.get_index(), "the child draws over its parent")


func test_handoff_emits_layer_changed_once() -> void:
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 50.0))
	assert_eq(layer_events, ["parent"] as Array[String])
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 9.0))
	assert_eq(stage.camera().layer, "child")
	stage.set_camera(ZoomCamera.make("child", Vector2.ZERO, 80.0))
	assert_eq(layer_events, ["parent", "child"] as Array[String])


func test_inactive_layers_not_live() -> void:
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 100.0))
	assert_eq(parent.viewport.render_target_update_mode, SubViewport.UPDATE_ALWAYS)
	assert_eq(parent.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(child.viewport.render_target_update_mode, SubViewport.UPDATE_DISABLED)
	assert_eq(child.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 20.0))
	assert_eq(child.viewport.render_target_update_mode, SubViewport.UPDATE_ALWAYS, "a fading child is drawn")
	assert_eq(child.mouse_filter, Control.MOUSE_FILTER_IGNORE, "but only the camera's layer takes input")


func test_screen_layer_round_trip() -> void:
	assert_eq(parent.size, Vector2(1280, 720))
	var q := parent.screen_to_layer(Vector2(100, 200), 50.0, Vector2(3, 4))
	var p := parent.layer_to_screen(q, 50.0, Vector2(3, 4))
	assert_near(p.x, 100.0, 1e-3)
	assert_near(p.y, 200.0, 1e-3)
	assert_eq(parent.screen_to_layer(Vector2(640, 360), 50.0, Vector2(3, 4)), Vector2(3, 4))
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 100.0))
	var back := stage.active_to_screen(stage.screen_to_active(Vector2(900, 100)))
	assert_near(back.x, 900.0, 1e-3)
	assert_near(back.y, 100.0, 1e-3)


func test_zoom_at_screen_keeps_point_under_cursor() -> void:
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 100.0))
	var under := stage.screen_to_active(Vector2(900, 100))
	stage.zoom_at_screen(2.0, Vector2(900, 100))
	assert_near(stage.camera().view, 50.0, 1e-6)
	var now := stage.screen_to_active(Vector2(900, 100))
	assert_near(now.x, under.x, 1e-3)
	assert_near(now.y, under.y, 1e-3)


## Dragging the content right moves the camera left.
func test_pan_screen_follows_the_drag() -> void:
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 72.0))
	stage.pan_screen(Vector2(100, 0))
	assert_near(stage.camera().center.x, 5.0 - 10.0, 1e-4)


func test_go_home_uses_home_view() -> void:
	stage.go_home("child")
	assert_eq(stage.camera().layer, "child")
	assert_eq(stage.camera().view, 50.0)


func test_view_changed_reports_jump_text_for_magnified_link() -> void:
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 100.0))
	assert_eq(views[views.size() - 1], [100.0, ""])
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 20.0))
	assert_eq(views[views.size() - 1], [20.0, "Skipping ahead ×100"])
	child.meters_per_unit = 0.1
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 20.0))
	assert_eq(views[views.size() - 1][1], "", "a link that doesn't magnify skips nothing")


## After a resize (or the first layout) the camera is applied again, so layers
## that size their content from the container stay right.
func test_resize_reapplies_camera() -> void:
	stage.set_camera(ZoomCamera.make("parent", Vector2(5, 5), 100.0))
	var before := views.size()
	stage.size = Vector2(640, 360)
	await wait_frames(2)
	assert_eq(parent.size, Vector2(640, 360))
	assert_true(views.size() > before, "the camera was applied again")
	assert_eq(stage.camera().view, 100.0)
