extends TestCase


func _infos() -> Dictionary:
	return {
		"parent": LayerInfo.make("parent", 1.0, 0.1, 1000.0),
		"child": LayerInfo.make("child", 0.01, 1.0, 100.0),
		"solo": LayerInfo.make("solo", 1.0, 1.0, 100.0),
	}


func _links() -> Array[ZoomLink]:
	return [ZoomLink.make("parent", "child", Vector2(5, 5), 10.0, 100.0)]


func test_zoom_at_keeps_focus_fixed() -> void:
	var cam := ZoomCamera.make("parent", Vector2(0, 0), 100.0)
	var focus := Vector2(30, -20)
	var z := ZoomMath.zoom_at(cam, 2.0, focus)
	assert_near(z.view, 50.0, 1e-12)
	var before := (focus - cam.center) / cam.view
	var after := (focus - z.center) / z.view
	assert_near(after.x, before.x, 1e-12)
	assert_near(after.y, before.y, 1e-12)
	assert_eq(cam.view, 100.0, "the input camera is unchanged")


func test_pan_moves_center() -> void:
	var p := ZoomMath.pan(ZoomCamera.make("parent", Vector2(1, 2), 10.0), Vector2(3, -4))
	assert_eq(p.center, Vector2(4, -2))
	assert_eq(p.view, 10.0)


## Vector2 is single precision in standard Godot builds, so the round trip is
## exact to about 1e-7 of the value, not 1e-9.
func test_child_parent_inverse() -> void:
	var link := _links()[0]
	var cam := ZoomCamera.make("parent", Vector2(7.3, 2.1), 8.0)
	var child := ZoomMath.to_child(cam, link)
	assert_eq(child.layer, "child")
	assert_near(child.view, 80.0, 1e-9)
	var back := ZoomMath.to_parent(child, link)
	assert_eq(back.layer, "parent")
	assert_near(back.center.x, 7.3, 1e-6)
	assert_near(back.center.y, 2.1, 1e-6)
	assert_near(back.view, 8.0, 1e-9)


func test_resolve_hands_off_below_parent_min() -> void:
	var r := ZoomMath.resolve(ZoomCamera.make("parent", Vector2(5, 5), 9.0), _infos(), _links(), Callable())
	assert_eq(r.layer, "child")
	assert_near(r.view, 90.0, 1e-9)
	assert_near(r.center.length(), 0.0, 1e-9)
	assert_eq(ZoomMath.resolve(ZoomCamera.make("parent", Vector2(5, 5), 11.0), _infos(), _links(), Callable()).layer, "parent")


func test_resolve_clamps_without_child() -> void:
	assert_eq(ZoomMath.resolve(ZoomCamera.make("solo", Vector2.ZERO, 0.5), _infos(), _links(), Callable()).view, 1.0)
	assert_eq(ZoomMath.resolve(ZoomCamera.make("solo", Vector2.ZERO, 500.0), _infos(), _links(), Callable()).view, 100.0)


func test_resolve_returns_to_parent() -> void:
	var r := ZoomMath.resolve(ZoomCamera.make("child", Vector2(20, -10), 150.0), _infos(), _links(), Callable())
	assert_eq(r.layer, "parent")
	assert_near(r.view, 15.0, 1e-9)
	assert_near(r.center.x, 5.0 + 2.0, 1e-9)
	assert_near(r.center.y, 5.0 - 1.0, 1e-9)


func _wire_link(layer: String, center: Vector2) -> ZoomLink:
	return ZoomLink.make("parent", "child", Vector2(2, 3), 10.0, 100.0) if layer == "parent" else null


func test_dynamic_child_used_when_no_static() -> void:
	var links: Array[ZoomLink] = []
	var cam := ZoomCamera.make("parent", Vector2(2, 3), 5.0)
	assert_true(ZoomMath.child_link(cam, links, _wire_link) != null)
	var r := ZoomMath.resolve(cam, _infos(), links, _wire_link)
	assert_eq(r.layer, "child")
	assert_near(r.view, 50.0, 1e-9)
	assert_true(ZoomMath.child_link(ZoomCamera.make("child", Vector2.ZERO, 50.0), links, _wire_link) == null)


## The link a dynamic hand-off used is kept, so zooming back out lands where the
## camera went in; a newer link to the same child replaces it.
func test_resolve_remembers_dynamic_link_for_the_way_back() -> void:
	var links: Array[ZoomLink] = []
	ZoomMath.resolve(ZoomCamera.make("parent", Vector2(2, 3), 5.0), _infos(), links, _wire_link)
	assert_eq(links.size(), 1)
	var back := ZoomMath.resolve(ZoomCamera.make("child", Vector2.ZERO, 150.0), _infos(), links, _wire_link)
	assert_eq(back.layer, "parent")
	assert_near(back.center.x, 2.0, 1e-9)
	assert_near(back.center.y, 3.0, 1e-9)
	ZoomMath.resolve(ZoomCamera.make("parent", Vector2(2, 3), 5.0), _infos(), links, _wire_link)
	assert_eq(links.size(), 1)


func test_blend_child_alpha_0_at_band_edge_1_at_min() -> void:
	var links := _links()
	assert_eq(ZoomMath.blend(ZoomCamera.make("parent", Vector2(5, 5), 41.0), links, Callable()).size(), 1)
	var edge := ZoomMath.blend(ZoomCamera.make("parent", Vector2(5, 5), 40.0 * (1.0 - 1e-9)), links, Callable())
	assert_eq(edge.size(), 2)
	assert_eq(edge[0]["layer"], "parent")
	assert_eq(edge[0]["alpha"], 1.0)
	assert_eq(edge[1]["layer"], "child")
	assert_true(edge[1]["alpha"] < 1e-6)
	var at_min := ZoomMath.blend(ZoomCamera.make("parent", Vector2(5, 5), 10.0), links, Callable())
	assert_near(at_min[1]["alpha"], 1.0, 1e-9)


func test_blend_mid_band_between() -> void:
	var cam := ZoomCamera.make("parent", Vector2(6, 4), 20.0)
	var b := ZoomMath.blend(cam, _links(), Callable())
	assert_eq(b.size(), 2)
	assert_between(b[1]["alpha"], 1e-3, 1.0 - 1e-3)
	var child: ZoomCamera = b[1]["cam"]
	assert_eq(child.layer, "child")
	assert_near(child.view, 200.0, 1e-9)
	assert_near(child.center.x, 10.0, 1e-9)


func test_magnification_grain_to_silica() -> void:
	var link := ZoomLink.make("grain", "silica", Vector2.ZERO, 0.5, 60.0)
	var infos := {"grain": LayerInfo.make("grain", 1e-5, 0.1, 10.0), "silica": LayerInfo.make("silica", 1e-10, 1.0, 60.0)}
	assert_near(ZoomMath.magnification(link, infos), 833.333, 1e-3)


func test_meters_visible() -> void:
	assert_near(ZoomMath.meters_visible(ZoomCamera.make("child", Vector2.ZERO, 50.0), _infos()), 0.5, 1e-12)
