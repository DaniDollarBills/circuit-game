extends TestCase
## Checkpoint C fixes: the 3D camera follows a view-style switch (I6), zoom
## and pan are exact in the tilted 3D view (I8), the camera never ends up
## inside tall equipment (I9), Explain uses magnitudes (I11), the board can
## render at screen resolution (I12), and the quality setting reaches it (I13).


func _layer(view_style: String, c: Circuit, quality := "auto") -> EditorLayer:
	var layer: EditorLayer = load("res://src/editor/editor_layer.tscn").instantiate()
	layer.size = Vector2(1280, 720)
	add_to_tree(layer)
	layer.size = Vector2(1280, 720)
	var st := Progress.DEFAULT_SETTINGS.duplicate()
	st["view_style"] = view_style
	st["quality"] = quality
	var out := Simulator.simulate(c)
	layer.set_state(out.circuit, out.result, st, {}, [])
	layer.set_live(true, true)
	layer.apply_view(layer.fit_center(), layer.fit_view())
	return layer


func _staged(c: Circuit) -> EditorLayer:
	var stage := ZoomStage.new()
	stage.size = Vector2(1280, 720)
	add_to_tree(stage)
	var layer: EditorLayer = load("res://src/editor/editor_layer.tscn").instantiate()
	stage.add_layer(layer)
	var st := Progress.DEFAULT_SETTINGS.duplicate()
	var out := Simulator.simulate(c)
	layer.set_state(out.circuit, out.result, st, {}, [])
	stage.set_camera(ZoomCamera.make("editor", layer.fit_center(), layer.fit_view()))
	return layer


func test_switching_to_the_real_view_resyncs_the_camera() -> void:
	var layer := _layer("schematic", TestCircuits.compact_loop())
	layer.apply_view(Vector2(8, 6), 10.0)
	var st := layer.settings.duplicate()
	st["view_style"] = "physical"
	layer.set_state(layer.circuit, layer.sim, st, {}, [])
	var px := layer.workbench.grid_to_screen(Vector2(8, 6))
	assert_true(px.distance_to(layer.size / 2.0) < layer.size.y * 0.1, "the view's center is mid-screen, got %s" % px)


func test_wheel_zoom_keeps_the_point_under_the_cursor() -> void:
	var layer := _staged(TestCircuits.compact_loop())
	await wait_frames(1)
	for cursor in [Vector2(1000, 150), Vector2(300, 620)]:
		var g: Vector2 = layer.screen_to_grid(cursor)
		layer._zoom(1.15, cursor)
		assert_true(layer.workbench.grid_to_screen(g).distance_to(cursor) < 1.0, "zoom at %s drifted to %s" % [cursor, layer.workbench.grid_to_screen(g)])


func test_drag_pan_keeps_the_board_under_the_finger() -> void:
	var layer := _staged(TestCircuits.compact_loop())
	await wait_frames(1)
	for at in [Vector2(900, 150), Vector2(500, 650)]:
		var g: Vector2 = layer.screen_to_grid(at)
		var to: Vector2 = at + Vector2(-40, 100)
		layer._apply_effect({"type": "camera_pan", "delta": to - at}, {"screen": to})
		assert_true(layer.workbench.grid_to_screen(g).distance_to(to) < 1.0, "the point under the finger moved to %s, not %s" % [layer.workbench.grid_to_screen(g), to])


func test_camera_stays_above_tall_equipment() -> void:
	var c := TestCircuits.meter_loop(500.0)
	var layer := _layer("physical", c)
	var at: Vector3 = MeterRig.place(c)["M1"]
	layer.apply_view(Vector2(at.x, at.z) / PartDims.GRID, 3.0)
	assert_true(layer.workbench.camera.global_position.y > MeterRig.HEIGHT_METER + 0.2, "camera at %s" % layer.workbench.camera.global_position)


func test_explain_uses_magnitudes_for_a_reversed_resistor() -> void:
	var c := Circuit.new()
	c.parts.append(Part.make("B1", "battery", -6, 0))
	c.parts.append(Part.make("R1", "resistor", -2, -4))
	c.parts.append(Part.make("L1", "led", 6, 0, 90))
	c.wires.append(Wire.make("w1", "B1", "pos", "R1", "b"))
	c.wires.append(Wire.make("w2", "R1", "a", "L1", "anode"))
	c.wires.append(Wire.make("w3", "L1", "cathode", "B1", "neg"))
	var out := Simulator.simulate(c)
	var negative := RegEx.create_from_string("[-−]\\d")
	for line in Explain.part(out.circuit.find_part("R1"), out.result):
		assert_true(negative.search(line) == null, line)


func test_board_can_render_at_screen_resolution() -> void:
	for style in ["physical", "schematic"]:
		var layer := _layer(style, TestCircuits.compact_loop())
		var before := layer.pin_screen_pos("L1", "anode")
		layer.set_resolution_scale(2.0)
		assert_eq(layer.viewport.size, Vector2i(2560, 1440), style)
		assert_eq(layer.viewport.size_2d_override, Vector2i(1280, 720), style)
		assert_true(layer.pin_screen_pos("L1", "anode").distance_to(before) < 1.0, "%s: positions stay in layout pixels" % style)


func test_quality_setting_reaches_the_board() -> void:
	assert_eq(Quality.current_method(), RenderingServer.get_current_rendering_method())
	var low := _layer("physical", TestCircuits.compact_loop(), "low")
	assert_eq(low.viewport.msaa_3d, Viewport.MSAA_2X)
	var high := _layer("physical", TestCircuits.compact_loop(), "high")
	assert_eq(high.viewport.msaa_3d, Viewport.MSAA_4X)
