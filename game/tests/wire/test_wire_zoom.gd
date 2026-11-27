extends TestCase

var _dir := ""


func before_each() -> void:
	_dir = "user://test_wire_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)


func after_each() -> void:
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _layer() -> EditorLayer:
	var layer: EditorLayer = load("res://src/editor/editor_layer.tscn").instantiate()
	layer.size = Vector2(1280, 720)
	add_to_tree(layer)
	var out := Simulator.simulate(Levels.by_id("ch1.light-it-up").solution)
	layer.set_state(out.circuit, out.result, Progress.DEFAULT_SETTINGS.duplicate(), {}, [])
	return layer


## A point in the middle of w1's first segment, away from any pin.
func _on_w1(c: Circuit) -> Dictionary:
	var path := CircuitGeometry.wire_path(c, c.find_wire("w1"))
	return {"at": (path[0] + path[1]) / 2.0, "dir": (path[1] - path[0]).normalized()}


func test_dynamic_child_near_wire() -> void:
	var layer := _layer()
	var spot := _on_w1(layer.circuit)
	var link := layer.dynamic_child(spot["at"] + Vector2(0.1, 0.1))
	assert_true(link != null)
	if link != null:
		assert_eq([link.parent, link.child, link.parent_min_view, link.child_max_view], ["editor", "wire.closeup", 3.0, 762.0])
		assert_true(link.anchor.distance_to(spot["at"]) < 0.2, "anchored on the wire, got %s" % link.anchor)


func test_dynamic_child_null_away_from_wires() -> void:
	var layer := _layer()
	assert_eq(layer.dynamic_child(Vector2(40, 40)), null)


func test_closeup_receives_amps_and_direction() -> void:
	var layer := _layer()
	var closeup := WireCloseupLayer.new()
	add_to_tree(closeup)
	layer.closeup = closeup
	var spot := _on_w1(layer.circuit)
	layer.dynamic_child(spot["at"])
	var amps := float(layer.sim.wire_amps["w1"])
	assert_near(closeup.amps, absf(amps), 1e-9)
	var conventional: Vector2 = spot["dir"] * signf(amps)
	assert_true(closeup.direction.distance_to(conventional) < 1e-4, "arrows follow conventional current: %s" % closeup.direction)


func test_l9_zoom_to_copper_passes() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	var game := Game.new()
	add_to_tree(game)
	game.boot(_dir.path_join("progress.json"))
	game.open_level("ch1.inside-the-wire", true)
	var s: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
	s.game = game
	host.add_child(s)
	await wait_frames(4)
	while game.state.session.phase in ["learn", "try"]:
		if game.state.session.phase == "learn":
			game.skip_learn()
		else:
			game.finish_try()
	await wait_frames(2)
	var at := s.editor.grid_to_screen(_on_w1(s.editor.circuit)["at"])
	for i in 80:
		if s.stage.camera().layer == "wire.copper":
			break
		if s.stage.camera().layer == "editor":
			s.editor.zoom_at(1.25, at)
		else:
			s.stage.zoom_at_screen(1.25, at)
	await wait_frames(2)
	assert_eq(s.stage.camera().layer, "wire.copper")
	assert_eq(game.state.session.phase, "passed")


func test_electrons_drift_against_conventional_current() -> void:
	var copper := CopperLayer.new()
	add_to_tree(copper)
	copper.set_flow(0.0138, Vector2.RIGHT)
	assert_eq(copper.drift_direction(), Vector2.LEFT)
	assert_near(CopperLayer.drift_speed(0.0138), 0.5 * log(0.0138 / 1e-5) / log(10.0), 1e-9)
	assert_eq(CopperLayer.drift_speed(1e-7), 0.0, "no visible drift without real current")
