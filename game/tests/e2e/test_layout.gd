extends TestCase
## Turning a phone or resizing the window mid-level keeps the circuit in
## view and reflows the HUD.

var _dir := ""
var e2e: E2E


func before_each() -> void:
	_dir = "user://test_layout_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)
	e2e = E2E.new(tree)


func after_each() -> void:
	e2e.stop()
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func test_resize_keeps_circuit_visible() -> void:
	await e2e.start(_dir.path_join("progress.json"))
	e2e.game().open_level("ch1.both", true)
	await e2e.frames(4)
	var s := e2e.screen() as LevelScreen
	for size in [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]:
		await e2e.resize(size)
		var view := Rect2(Vector2.ZERO, Vector2(size))
		var covered: Array[Rect2] = [s.top_bar.get_global_rect()]
		if s.tray.visible:
			covered.append(s.tray.get_global_rect())
		for p in s.game.state.level.circuit.parts:
			for pin in Catalog.pin_names(p.kind):
				var at := e2e.pin(s, p.id, pin)
				assert_true(view.has_point(at), "%s: %s.%s at %s is on screen" % [size, p.id, pin, at])
				for r in covered:
					assert_false(r.has_point(at), "%s: %s.%s at %s is under the HUD" % [size, p.id, pin, at])
