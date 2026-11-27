extends TestCase
## The credits and license texts, inside the game: the Android app has no
## folder beside it to carry them.


func test_licenses_page_shows_every_license() -> void:
	var game := Game.new()
	add_to_tree(game)
	game.boot("user://test_licenses_%d.json" % randi())
	var sheet := SettingsSheet.new()
	sheet.game = game
	add_to_tree(sheet)
	sheet.open()
	sheet.licenses_button().pressed.emit()
	var page := sheet.licenses_page()
	assert_true(page.is_visible_in_tree(), "the Licenses button opens the page")
	var titles := page.section_titles()
	for t in ["Credits", "Nunito", "DejaVu Sans", "Earth imagery", "Godot Engine"]:
		assert_true(t in titles, "%s in %s" % [t, titles])
	for t in titles:
		assert_true(page.section_text(t).length() > 200, t + " has its text")
	assert_true(page.section_text("Godot Engine").contains("MIT") or page.section_text("Godot Engine").contains("Permission is hereby granted"))
	page.back_button().pressed.emit()
	assert_false(page.is_visible_in_tree(), "Back returns to the settings")


## Every exported build carries the files the page reads.
func test_license_files_ship_in_every_preset() -> void:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK)
	for section in cfg.get_sections():
		if section.ends_with(".options"):
			continue
		var filters := str(cfg.get_value(section, "include_filter", "")).split(",", false)
		for path in LicensesPage.FILES.values():
			var rel := str(path).trim_prefix("res://")
			assert_true(Array(filters).any(func(f: String) -> bool: return rel.match(f.strip_edges())), "%s ships %s" % [cfg.get_value(section, "name"), rel])


## MIT, BSD and zlib-style licenses ask for the copyright notices themselves:
## the in-game page (the Android app's only copy) carries every one.
func test_godot_section_carries_every_copyright_notice() -> void:
	var text := LicensesPage.godot_text()
	var missing := PackedStringArray()
	for c in Engine.get_copyright_info():
		for part in c["parts"]:
			for line in part["copyright"]:
				if not text.contains(str(line)):
					missing.append("%s: %s" % [c["name"], line])
	assert_eq(missing.size(), 0, "missing %d, e.g. %s" % [missing.size(), missing.slice(0, 2)])
