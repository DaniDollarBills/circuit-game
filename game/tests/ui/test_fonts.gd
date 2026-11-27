extends TestCase
## The web build has no system fonts to borrow from, so every character the
## game writes has to be in the fonts it writes with.


## Every non-ASCII character inside a string literal under `dir`, mapped to a
## file that uses it.
func _string_chars(dir: String, out: Dictionary) -> void:
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".gd"):
			continue
		for line in FileAccess.get_file_as_string(dir.path_join(f)).split("\n"):
			if line.strip_edges().begins_with("#"):
				continue
			var quoted := false
			for i in line.length():
				var ch := line[i]
				if ch == "\"":
					quoted = not quoted
				elif quoted and ch.unicode_at(0) > 127:
					out[ch] = dir.path_join(f)
	for d in DirAccess.get_directories_at(dir):
		_string_chars(dir.path_join(d), out)


func test_fonts_cover_every_character_the_game_writes() -> void:
	var chars := {}
	_string_chars("res://src", chars)
	assert_true(chars.has("Ω") and chars.has("✓"), "the scan finds the ohm sign and the tick")
	var theme := PastelTheme.build()
	var fonts := {
		"regular": theme.default_font,
		"bold": theme.get_font("bold_font", "RichTextLabel"),
		"heading": theme.get_font("font", "HeadingLabel"),
		"board": DrawKit._font(false),
		"board bold": DrawKit._font(true),
	}
	for name in fonts:
		var f: Font = fonts[name]
		var missing := PackedStringArray()
		for ch in chars:
			if not f.has_char(ch.unicode_at(0)):
				missing.append("%s in %s" % [ch, str(chars[ch]).get_file()])
		assert_eq(", ".join(missing), "", name)
