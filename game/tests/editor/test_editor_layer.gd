extends TestCase

var commits: Array[Circuit] = []


func _layer(view_style: String) -> EditorLayer:
	commits.clear()
	var layer: EditorLayer = load("res://src/editor/editor_layer.tscn").instantiate()
	layer.size = Vector2(1280, 720)
	add_to_tree(layer)
	layer.size = Vector2(1280, 720)
	var level := Levels.by_id("ch1.light-it-up")
	var settings := Progress.DEFAULT_SETTINGS.duplicate()
	settings["view_style"] = view_style
	var out := Simulator.simulate(level.circuit)
	layer.set_state(out.circuit, out.result, settings, {}, [])
	layer.set_live(true, true)
	layer.apply_view(Vector2(0, -1), layer.fit_view())
	layer.commit_requested.connect(func(c: Circuit) -> void:
		commits.append(c)
		var o := Simulator.simulate(c)
		layer.set_state(o.circuit, o.result, settings, {}, []))
	return layer


func _drag(layer: EditorLayer, from: Vector2, to: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = from
	layer._gui_input(down)
	for k in range(1, 6):
		var move := InputEventMouseMotion.new()
		move.position = from.lerp(to, k / 5.0)
		move.button_mask = MOUSE_BUTTON_MASK_LEFT
		layer._gui_input(move)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = to
	layer._gui_input(up)


func _wire_l1(view_style: String) -> void:
	var layer := _layer(view_style)
	await wait_frames(2)
	for w in [["B1", "pos", "R1", "a"], ["R1", "b", "L1", "anode"], ["L1", "cathode", "B1", "neg"]]:
		_drag(layer, layer.pin_screen_pos(w[0], w[1]), layer.pin_screen_pos(w[2], w[3]))
	assert_eq(commits.size(), 3, view_style)
	if commits.size() == 3:
		var out := Simulator.simulate(commits[2])
		assert_true(Goals.evaluate({"kind": "led_lit", "part": "L1"}, {"circuit": out.circuit, "sim": out.result})["pass"], view_style)


func test_wire_l1_in_the_workbench() -> void:
	await _wire_l1("physical")


func test_wire_l1_in_the_schematic() -> void:
	await _wire_l1("schematic")


func test_fit_view_holds_the_circuit() -> void:
	var layer := _layer("schematic")
	assert_true(layer.fit_view() >= 12.0)
	var b1 := layer.pin_screen_pos("B1", "pos")
	assert_true(Rect2(Vector2.ZERO, layer.size).has_point(b1), str(b1))


## Value labels in the schematic never sit on a part, its own text, or each other.
func test_schematic_labels_stay_clear() -> void:
	for id in ["ch1.light-it-up", "ch1.push-and-flow", "ch1.too-hot"]:
		var level := Levels.by_id(id)
		var out := Simulator.simulate(level.solution)
		var labels := CircuitView.placed_labels(out.circuit, out.result)
		var boxes: Array[Rect2] = []
		for l in labels:
			var text: String = l["text"]
			var box := Vector2(0.25 * text.length() + 0.2, 0.6)
			var r := Rect2((l["at"] as Vector2) - box / 2.0, box)
			for p in out.circuit.parts:
				assert_false(CircuitView.footprint(p).intersects(r), "%s: %s on %s" % [id, text, p.id])
			for b in boxes:
				assert_false(b.intersects(r), "%s: %s overlaps another label" % [id, text])
			boxes.append(r)
