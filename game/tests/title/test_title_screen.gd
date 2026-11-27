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
