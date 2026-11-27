extends TestCase


func test_meter_rig_places_off_board_without_overlap() -> void:
	var c := TestCircuits.meter_loop(500.0)
	c.parts.append(Part.make("B2", "battery", 0, 8))
	c.parts.append(Part.make("M2", "ammeter", 8, 8))
	var spots := MeterRig.place(c)
	var board := MeterRig.board_rect(c)
	assert_eq(spots.size(), 5)
	var rects := {}
	for id in spots:
		var size: Vector2 = MeterRig.FOOTPRINT_HOLDER if c.find_part(id).kind == "battery" else MeterRig.FOOTPRINT_METER
		var at: Vector3 = spots[id]
		rects[id] = Rect2(Vector2(at.x, at.z) - size / 2.0, size)
	for id in ["B1", "B2"]:
		assert_true((rects[id] as Rect2).end.x < board.position.x, "%s sits left of the board" % id)
	for id in ["M1", "V1", "M2"]:
		assert_true((rects[id] as Rect2).position.x > board.end.x, "%s sits right of the board" % id)
	var ids := spots.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			assert_false((rects[ids[i]] as Rect2).intersects(rects[ids[j]]), "%s and %s overlap" % [ids[i], ids[j]])


## Headless: the camera math works without rendering anything.
func test_screen_to_grid_round_trip() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_to_tree(vp)
	var bench := Workbench3D.new()
	vp.add_child(bench)
	var out := Simulator.simulate(TestCircuits.compact_loop())
	bench.set_state(out.circuit, out.result, Progress.DEFAULT_SETTINGS, {}, [])
	bench.apply_view(Vector2(0, -1), 20.0)
	for s in [Vector2(640, 360), Vector2(100, 600), Vector2(1200, 80)]:
		var g := bench.screen_to_grid(s)
		var back := bench.grid_to_screen(g)
		assert_near(back.x, s.x, 0.5, str(s))
		assert_near(back.y, s.y, 0.5, str(s))
	var top := bench.screen_to_grid(Vector2(640, 0))
	var bottom := bench.screen_to_grid(Vector2(640, 720))
	assert_near(bottom.y - top.y, 20.0, 0.05, "the view frames 20 grid units of board height")
	assert_near((top.y + bottom.y) / 2.0, -1.0, 0.05, "centered on the view's center")


func test_set_state_builds_parts_wires_and_labels() -> void:
	var bench := Workbench3D.new()
	add_to_tree(bench)
	var out := Simulator.simulate(TestCircuits.compact_loop())
	bench.set_state(out.circuit, out.result, Progress.DEFAULT_SETTINGS, {}, [])
	for id in ["B1", "R1", "L1"]:
		assert_true(bench.part_node(id) != null, id)
	assert_eq(bench.wire_count(), 3)
	assert_true(bench.label_texts().has("13.8 mA"))
	var quiet := Progress.DEFAULT_SETTINGS.duplicate()
	quiet["show_values"] = false
	bench.set_state(out.circuit, out.result, quiet, {}, [])
	assert_eq(bench.label_texts().size(), 0)


## Lessons 5 and 6 name their switches A and B. The bench shows each
## switch's name, even with values hidden, so the player can tell them apart.
func test_switch_names_show_on_the_bench() -> void:
	var bench := Workbench3D.new()
	add_to_tree(bench)
	var c := TestCircuits.compact_loop()
	c.parts.append(Part.make("SW1", "switch", 4, -4, 0, {"label": "A"}))
	c.parts.append(Part.make("SW2", "switch", 4, -9, 0, {"label": "B"}))
	c.parts.append(Part.make("SW3", "switch", 4, -14))
	var out := Simulator.simulate(c)
	var quiet := Progress.DEFAULT_SETTINGS.duplicate()
	quiet["show_values"] = false
	bench.set_state(out.circuit, out.result, quiet, {}, [])
	assert_eq(bench.label_texts(), PackedStringArray(["Switch A", "Switch B"]))


## Nothing hangs over the mat's edge: it is the smallest standard cutting-mat
## size (A4 to A1) that holds the board and all the equipment beside it.
func test_mat_holds_board_and_equipment() -> void:
	var bench := Workbench3D.new()
	add_to_tree(bench)
	var c := TestCircuits.meter_loop(500.0)
	c.parts.append(Part.make("M2", "ammeter", 8, 8))
	var out := Simulator.simulate(c)
	bench.set_state(out.circuit, out.result, Progress.DEFAULT_SETTINGS, {}, [])
	var mat := bench.mat_rect()
	assert_true(mat.encloses(MeterRig.board_rect(c)))
	var spots := MeterRig.place(c)
	for id in spots:
		var size: Vector2 = MeterRig.FOOTPRINT_HOLDER if c.find_part(id).kind == "battery" else MeterRig.FOOTPRINT_METER
		var at: Vector3 = spots[id]
		assert_true(mat.encloses(Rect2(Vector2(at.x, at.z) - size / 2.0, size)), id)
	assert_true(Vector2(mat.size.x, mat.size.y) in [Vector2(30, 22), Vector2(45, 30), Vector2(60, 45), Vector2(90, 60)], str(mat.size))
