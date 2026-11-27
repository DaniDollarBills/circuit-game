extends TestCase
## Checkpoint C, C1: in the real view a tap hits what is drawn there, not the
## spot on the board plane behind it.

var effects: Array = []


func _layer() -> EditorLayer:
	var c := Circuit.new()
	c.parts.append(Part.make("B1", "battery", -6, 0))
	c.parts.append(Part.make("R1", "resistor", -2, -4))
	c.parts.append(Part.make("S1", "switch", 4, -4))
	c.parts.append(Part.make("L1", "led", 6, 2, 90))
	var layer: EditorLayer = load("res://src/editor/editor_layer.tscn").instantiate()
	layer.size = Vector2(1280, 720)
	add_to_tree(layer)
	layer.size = Vector2(1280, 720)
	var out := Simulator.simulate(c)
	layer.set_state(out.circuit, out.result, Progress.DEFAULT_SETTINGS.duplicate(), {}, [])
	layer.set_live(true, true)
	layer.apply_view(layer.fit_center(), layer.fit_view())
	effects.clear()
	layer.commit_requested.connect(func(cc: Circuit) -> void: effects.append({"commit": cc}))
	layer.datasheet_requested.connect(func(id: String) -> void: effects.append({"datasheet": id}))
	return layer


func _top(layer: EditorLayer, part_id: String, node_name: String) -> Vector2:
	var n := layer.workbench.part_node(part_id).find_child(node_name, true, false) as MeshInstance3D
	var box := n.global_transform * n.mesh.get_aabb()
	return layer.workbench.camera.unproject_position(box.get_center() + Vector3(0, box.size.y / 2.0, 0))


func _tap(layer: EditorLayer, at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		layer._gui_input(e)


func test_tapping_the_switch_lever_toggles_it() -> void:
	var layer := _layer()
	_tap(layer, _top(layer, "S1", "tip"))
	assert_eq(effects.size(), 1)
	if effects.size() == 1:
		assert_true(effects[0].has("commit") and (effects[0]["commit"] as Circuit).find_part("S1").props["closed"])


func test_tapping_the_led_dome_opens_its_datasheet() -> void:
	var layer := _layer()
	var dome := layer.workbench.part_node("L1").find_child("epoxy", true, false) as Node3D
	var box := AABB()
	var first := true
	for m in dome.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var at := layer.workbench.camera.unproject_position(box.get_center() + Vector3(0, box.size.y * 0.4, 0))
	var picked := layer.pick_3d(at)
	_tap(layer, at)
	assert_eq(effects, [{"datasheet": "L1"}], "picked %s at %s" % [picked, at])


func test_dragging_from_the_top_of_a_battery_post_starts_a_wire() -> void:
	var layer := _layer()
	var from := _top(layer, "B1", "post_pos")
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = from
	layer._gui_input(down)
	var move := InputEventMouseMotion.new()
	move.position = from + Vector2(60, 30)
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	layer._gui_input(move)
	assert_eq(layer.controller.mode["kind"], "wiring")
	assert_eq(layer.controller.mode.get("from_part", ""), "B1")


## Zoomed out, a small LED's legs sit within a finger's width of its whole
## dome; a tap on the dome still means the LED, not a leg.
func test_tapping_a_small_led_dome_opens_its_datasheet() -> void:
	var layer := _layer()
	layer.apply_view(layer.fit_center(), 60.0)
	var dome := layer.workbench.part_node("L1").find_child("epoxy", true, false) as Node3D
	var box := AABB()
	var first := true
	for m in dome.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	_tap(layer, layer.workbench.camera.unproject_position(box.get_center() + Vector3(0, box.size.y * 0.35, 0)))
	assert_eq(effects, [{"datasheet": "L1"}])
