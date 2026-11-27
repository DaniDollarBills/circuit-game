extends TestCase
## Every 3D layer, not just the board, follows the quality setting: its
## anti-aliasing, and how sharp it renders on a high-density screen.

var _old_size := Vector2i.ZERO
var _old_scale := Vector2i.ZERO


func before_each() -> void:
	_old_size = tree.root.size
	_old_scale = tree.root.content_scale_size


func after_each() -> void:
	tree.root.size = _old_size
	tree.root.content_scale_size = _old_scale


func test_title_and_wire_layers_follow_the_quality_setting() -> void:
	# A 2× screen, scaled the way Main scales the window: two screen pixels
	# per layout pixel.
	tree.root.size = Vector2i(1280, 720)
	tree.root.content_scale_size = Vector2i(640, 360)
	await wait_frames(1)
	var scripts := {
		"globe": load("res://src/scenes/title/globe_layer.gd"),
		"atom": load("res://src/scenes/title/atom_layer.gd"),
		"closeup": load("res://src/scenes/wire/wire_closeup_layer.gd"),
		"copper": load("res://src/scenes/wire/copper_layer.gd"),
	}
	for name in scripts:
		var l: ZoomLayer = scripts[name].new()
		l.size = Vector2(320, 200)
		add_to_tree(l)
		await wait_frames(1)
		l.quality = "low"
		await wait_frames(1)
		assert_eq(l.viewport.msaa_3d, Viewport.MSAA_2X, name + " low")
		assert_eq(l.viewport.size, Vector2i(320, 200), name + " low renders at 1×")
		l.quality = "high"
		await wait_frames(1)
		assert_eq(l.viewport.msaa_3d, Viewport.MSAA_4X, name + " high")
		assert_eq(l.viewport.size, Vector2i(640, 400), name + " high renders at the screen's 2×")
