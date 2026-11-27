extends TestCase
## The title screen's words: tappable, and defined when they first appear.

var _dir := ""


func before_each() -> void:
	_dir = "user://test_title_%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(_dir)


func after_each() -> void:
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _title() -> Control:
	var game := Game.new()
	add_to_tree(game)
	game.boot(_dir.path_join("progress.json"))
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	var t: Control = load("res://src/screens/title_screen.tscn").instantiate()
	t.set("game", game)
	t.set("autoplay", false)
	host.add_child(t)
	await wait_frames(3)
	return t


## Every glossary term `text` uses.
func _terms(text: String) -> PackedStringArray:
	return GlossaryText.render(text, {}, true, true)["new_terms"]


func test_tapping_an_underlined_word_opens_its_definition() -> void:
	var t := await _title()
	var game: Game = t.get("game")
	game.term_requested.emit("silicon")
	await wait_frames(1)
	var popup: GlossaryPopup = t.get("glossary_popup")
	assert_true(popup != null and popup.visible, "the title shows the word's definition")
	assert_eq(popup.term, "silicon")


func test_the_atoms_go_deeper_text_defines_its_words() -> void:
	var t := await _title()
	var game: Game = t.get("game")
	var words := _terms(AtomLayer.GO_DEEPER)
	assert_true("nucleus" in words and "electron" in words, str(words))
	t.call("_on_layer", "title.atom")
	await wait_frames(1)
	for w in words:
		assert_true(game.state.progress.seen_terms.has(w), "%s is defined when the atom shows" % w)
	var shown: PackedStringArray = t.call("shown_subtitles")
	assert_true("nucleus" in shown, "the new word gets a subtitle: %s" % shown)


func test_title_layers_follow_the_quality_setting() -> void:
	var t := await _title()
	var game: Game = t.get("game")
	game.set_setting("quality", "low")
	await wait_frames(1)
	for id in t.get("layers"):
		assert_eq((t.get("layers")[id] as ZoomLayer).quality, "low", id)
	game.set_setting("quality", "ultra")
	await wait_frames(1)
	for id in t.get("layers"):
		assert_eq((t.get("layers")[id] as ZoomLayer).viewport.msaa_3d, Viewport.MSAA_4X, id)


## The caption and its definitions sit over photos of Earth, coast and sand,
## which can be nearly white: a dark backing keeps them readable on anything
## (spec §11: 7:1 for main text and links, 4.5:1 for secondary text).
func test_caption_and_definitions_are_readable_over_white() -> void:
	var t := await _title()
	t.call("_on_layer", "title.coast")
	await wait_frames(1)
	var caption: RichTextLabel = t.get("_caption")
	var scrim: PanelContainer = null
	var n: Node = caption.get_parent()
	while n != null and scrim == null:
		if n is PanelContainer:
			scrim = n
		n = n.get_parent()
	assert_true(scrim != null, "the caption has a backing panel")
	if scrim == null:
		return
	var bg := (scrim.get_theme_stylebox("panel") as StyleBoxFlat).bg_color
	var over_white := Color.WHITE.lerp(Color(bg.r, bg.g, bg.b), bg.a)
	assert_true(Palette.contrast_ratio(caption.get_theme_color("default_color"), over_white) >= 7.0, "caption")
	assert_true(Palette.contrast_ratio(Color(GlossaryText.LINK_NIGHT), over_white) >= 7.0, "links")
	var subtitles: Control = t.get("_subtitles")
	assert_true(scrim.is_ancestor_of(subtitles) and scrim.is_ancestor_of(t.get("_deeper")), "the definitions sit on it too")
	for line in subtitles.get_children():
		assert_true(Palette.contrast_ratio((line as Label).get_theme_color("font_color"), over_white) >= 4.5, (line as Label).text)


func test_coast_cable_and_label_can_be_seen() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_to_tree(host)
	var coast: TitleLayer = load("res://src/scenes/title/coast_layer.gd").new()
	host.add_child(coast)
	coast.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await wait_frames(2)
	var label: Label3D = null
	for l in coast.find_children("*", "Label3D", true, false):
		if (l as Label3D).text.begins_with("Undersea cable"):
			label = l
	assert_true(label != null and label.no_depth_test, "the label draws over the ground, not half inside it")
	assert_true(label.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM and label.offset.y >= 8.0, "the label sits above the cable, not over it")
	for view: float in [coast.min_view, coast.home_view, coast.max_view]:
		coast.apply_view(Vector2.ZERO, view)
		var px: float = 2.0 * float(coast.get("cable_radius")) / (view / coast.size.y)
		assert_true(px >= 2.0, "the cable is %.2f px wide at view %s" % [px, view])
