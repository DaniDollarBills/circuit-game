extends TestCase
## Checkpoint C fixes I3–I5: the selection follows every interaction and shows
## in 3D, moves and selected pins are previewed, and letting go of a wire on
## its own start pin does nothing.


func _circuit() -> Circuit:
	var c := Circuit.new()
	c.parts.append(Part.make("B1", "battery", -6, 0))
	c.parts.append(Part.make("R1", "resistor", -2, -4))
	c.parts.append(Part.make("S1", "switch", 4, -4))
	c.parts.append(Part.make("L1", "led", 6, 2, 90))
	c.wires.append(Wire.make("w1", "B1", "pos", "R1", "a"))
	return c


func _ctx(c: Circuit, pin_r := 0.35) -> Dictionary:
	return {"circuit": c, "tray": [], "tray_used": [], "pin_r": pin_r, "wire_r": pin_r * 0.8}


func _center(c: Circuit, id: String) -> Vector2:
	return CircuitGeometry.part_rect(c.find_part(id)).get_center()


func _commits(effects: Array[Dictionary]) -> Array:
	return effects.filter(func(e: Dictionary) -> bool: return e["type"] == "commit")


func test_selection_follows_the_last_interaction() -> void:
	var ctl := EditorController.new()
	var c := _circuit()
	var path := CircuitGeometry.wire_path(c, c.find_wire("w1"))
	ctl.handle({"type": "tap", "at": (path[0] + path[1]) / 2.0}, _ctx(c))
	assert_eq(ctl.selection, "w1")
	var r1 := _center(c, "R1")
	ctl.handle({"type": "drag_start", "at": r1}, _ctx(c))
	var moved: Circuit = _commits(ctl.handle({"type": "drag_end", "at": r1 + Vector2(0, 3)}, _ctx(c)))[0]["circuit"]
	assert_eq(ctl.selection, "R1", "a move selects the part")
	var toggled: Circuit = _commits(ctl.handle({"type": "tap", "at": _center(moved, "S1")}, _ctx(moved)))[0]["circuit"]
	assert_eq(ctl.selection, "S1", "toggling a switch selects it")
	var gone: Circuit = _commits(ctl.handle({"type": "key", "key": "delete"}, _ctx(toggled)))[0]["circuit"]
	assert_eq(gone.find_part("S1"), null)
	assert_true(gone.find_wire("w1") != null, "the old wire selection is not what gets deleted")


func test_release_on_the_start_pin_does_nothing() -> void:
	var ctl := EditorController.new()
	var c := _circuit()
	var anode := Vector2(CircuitGeometry.pin_position(c.find_part("L1"), "anode"))
	ctl.handle({"type": "drag_start", "at": anode}, _ctx(c, 1.83))
	ctl.handle({"type": "drag_move", "at": anode + Vector2(0.4, 0.2)}, _ctx(c, 1.83))
	assert_eq(ctl.handle({"type": "drag_end", "at": anode + Vector2(0.3, 0.1)}, _ctx(c, 1.83)), [] as Array[Dictionary])


func test_pin_selection_survives_a_pan() -> void:
	var ctl := EditorController.new()
	var c := _circuit()
	var pos := Vector2(CircuitGeometry.pin_position(c.find_part("R1"), "b"))
	ctl.handle({"type": "tap", "at": pos}, _ctx(c))
	assert_eq(ctl.mode["kind"], "pin_selected")
	ctl.handle({"type": "drag_start", "at": Vector2(0, 8), "screen": Vector2(400, 600)}, _ctx(c))
	ctl.handle({"type": "drag_move", "at": Vector2(1, 8), "screen": Vector2(420, 600)}, _ctx(c))
	ctl.handle({"type": "drag_end", "at": Vector2(1, 8)}, _ctx(c))
	assert_eq(ctl.mode["kind"], "pin_selected", "panning keeps the first pin of a tap-tap wire")


func _layer(view_style: String) -> EditorLayer:
	var layer: EditorLayer = load("res://src/editor/editor_layer.tscn").instantiate()
	layer.size = Vector2(1280, 720)
	add_to_tree(layer)
	var st := Progress.DEFAULT_SETTINGS.duplicate()
	st["view_style"] = view_style
	var out := Simulator.simulate(_circuit())
	layer.set_state(out.circuit, out.result, st, {}, [])
	layer.set_live(true, true)
	layer.apply_view(layer.fit_center(), layer.fit_view())
	return layer


func test_moving_and_selected_pin_are_previewed() -> void:
	for style in ["physical", "schematic"]:
		var layer := _layer(style)
		var r1 := layer.grid_to_screen(_center(layer.circuit, "R1"))
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		down.position = r1
		layer._gui_input(down)
		var move := InputEventMouseMotion.new()
		move.position = r1 + Vector2(0, 90)
		move.button_mask = MOUSE_BUTTON_MASK_LEFT
		layer._gui_input(move)
		assert_true(layer.circuit_view.preview.has("part"), "%s: the moved part follows the finger" % style)
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.position = move.position
		layer._gui_input(up)
		var pin := layer.pin_screen_pos("S1", "a")
		for pressed in [true, false]:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT
			e.pressed = pressed
			e.position = pin
			layer._gui_input(e)
		assert_true(layer.circuit_view.preview.has("pin"), "%s: the first pin of a tap-tap wire is marked" % style)


func test_selection_is_drawn_in_3d() -> void:
	var layer := _layer("physical")
	var r1 := layer.grid_to_screen(_center(layer.circuit, "R1"))
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = r1
		layer._gui_input(e)
	assert_eq(layer.workbench.selection, "R1")
	assert_true(layer.workbench.selection_node() != null, "a selection outline is in the scene")
