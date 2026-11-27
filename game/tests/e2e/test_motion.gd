extends TestCase
## Reduced motion: the current-flow dots hold still and the title shows a
## slideshow instead of the zoom.

var _dir := ""
var e2e: E2E


func before_each() -> void:
	_dir = "user://test_motion_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)
	e2e = E2E.new(tree)


func after_each() -> void:
	e2e.stop()
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func test_reduced_motion() -> void:
	var p := Progress.defaults()
	p.settings["reduced_motion"] = true
	ProgressStorage.save(p, _dir.path_join("progress.json"))
	await e2e.start(_dir.path_join("progress.json"))
	var title := e2e.screen() as TitleScreen
	assert_true(title.get("_slideshow"), "the title shows a slideshow")
	var cam_before := title.stage.camera()
	await e2e.seconds(0.5)
	assert_eq(title.stage.camera().view, cam_before.view, "no zooming within a slide")
	e2e.game().open_level("ch1.light-it-up", true)
	await e2e.frames(4)
	var s := e2e.screen() as LevelScreen
	e2e.game().commit(s.game.state.level.solution)
	await e2e.frames(3)
	var flow := s.editor.flow_view
	assert_true(flow.reduced_motion)
	assert_false(flow.flows.is_empty(), "current is flowing")
	var phase_before := flow.t
	await e2e.seconds(0.3)
	assert_eq(flow.t, phase_before, "the flow dots hold still")
