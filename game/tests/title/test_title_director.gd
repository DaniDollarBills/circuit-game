extends TestCase


func _director() -> TitleDirector:
	return TitleDirector.new(TitleChain.infos(), TitleChain.links())


func test_director_reaches_atom() -> void:
	var d := _director()
	var cam := ZoomCamera.make("title.globe", Vector2.ZERO, 30000.0)
	var t := 0.0
	var seen := {}
	while t < 60.0 and not d.finished:
		cam = d.step(cam, 1.0 / 60.0)
		seen[cam.layer] = true
		t += 1.0 / 60.0
	assert_true(d.finished)
	assert_eq(cam.layer, "title.atom")
	assert_true(t < 30.0, "took %.1f s" % t)
	assert_eq(seen.size(), 6, "passes through every layer: %s" % [seen.keys()])


func test_skip_goes_to_atom() -> void:
	var d := _director()
	var cam := d.skip_to_end()
	assert_eq(cam.layer, "title.atom")
	assert_eq(cam.view, 400.0)
	assert_true(d.finished)


func test_slideshow_order() -> void:
	assert_eq(_director().slideshow_order(),
			PackedStringArray(["title.globe", "title.coast", "title.beach", "title.grain", "title.silica", "title.atom"]))
