extends TestCase
## Checkpoint C, I7: turning a phone or resizing the window keeps the whole
## circuit inside the board area.

var _dir := ""


func before_each() -> void:
	_dir = "user://test_resize_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)


func after_each() -> void:
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _pins_outside(s: LevelScreen) -> PackedStringArray:
	var out := PackedStringArray()
	var area := s.editor.safe_rect.grow(4.0)
	for p in s.game.state.level.circuit.parts:
		for pin in Catalog.pin_names(p.kind):
			var at := s.editor.pin_screen_pos(p.id, pin)
			if not area.has_point(at):
				out.append("%s.%s at %s" % [p.id, pin, at])
	return out


func test_resize_to_portrait_and_back_keeps_pins_in_view() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	var game := Game.new()
	add_to_tree(game)
	game.boot(_dir.path_join("progress.json"))
	game.open_level("ch1.on-and-off", true)
	var s: LevelScreen = load("res://src/screens/level_screen.tscn").instantiate()
	s.game = game
	host.add_child(s)
	await wait_frames(4)
	assert_eq(_pins_outside(s), PackedStringArray(), "landscape")
	for size in [Vector2(390, 844), Vector2(844, 390), Vector2(1280, 720)]:
		host.size = size
		await wait_frames(4)
		assert_eq(_pins_outside(s), PackedStringArray(), "after resizing to %s" % size)
