extends TestCase


func test_ink_on_cream_at_least_7() -> void:
	var r := Palette.contrast_ratio(Palette.color("ink"), Palette.color("cream"))
	assert_true(r >= 7.0, "ratio %.2f" % r)
	assert_near(r, 10.46, 0.05)


func test_ink_soft_on_cream_at_least_4_5() -> void:
	var r := Palette.contrast_ratio(Palette.color("ink_soft"), Palette.color("cream"))
	assert_true(r >= 4.5, "ratio %.2f" % r)
	assert_near(r, 4.94, 0.05)


func test_night_ink_on_night_cream_at_least_7() -> void:
	var r := Palette.contrast_ratio(Palette.color("ink", true), Palette.color("cream", true))
	assert_true(r >= 7.0, "ratio %.2f" % r)
	assert_near(r, 13.86, 0.05)


func test_all_tokens_resolve_in_both_themes() -> void:
	assert_eq(Palette.NAMES.size(), 17)
	for n in Palette.NAMES:
		assert_true(Palette.color(n).a > 0.0, n)
		assert_true(Palette.color(n, true).a > 0.0, n + " (night)")


func test_night_overrides_only_base_tokens() -> void:
	assert_eq(Palette.color("cream", true), Color("#24212F"))
	assert_eq(Palette.color("lavender", true), Palette.color("lavender"))


func test_led_tints() -> void:
	assert_eq(Palette.led_tint("red"), Color("#FF8F9A"))
	assert_eq(Palette.led_tint("blue"), Color("#8FC2FF"))


func test_theme_button_has_rounded_style() -> void:
	var theme := PastelTheme.build()
	var sb := theme.get_stylebox("normal", "Button")
	assert_true(sb is StyleBoxFlat)
	assert_eq((sb as StyleBoxFlat).corner_radius_top_left, 16)


func test_large_text_scales_default_font() -> void:
	assert_eq(PastelTheme.build(false, true).default_font_size, 22)
	assert_eq(PastelTheme.build().default_font_size, 18)


func test_button_text_is_readable_in_both_themes() -> void:
	for night in [false, true]:
		var theme := PastelTheme.build(night)
		for state in ["normal", "hover", "pressed"]:
			var fill := (theme.get_stylebox(state, "Button") as StyleBoxFlat).bg_color
			var text := theme.get_color("font_color", "Button")
			var r := Palette.contrast_ratio(text, fill)
			assert_true(r >= 4.5, "%s %s contrast %.2f" % ["night" if night else "light", state, r])


## Checkpoint S: "Go deeper", "Look inside" and "Skip Lesson 0" read as plain
## text. A flat button keeps its plain fill but has an edge you can see (3:1
## against the card, WCAG's mark for a control's outline), and its text keeps
## 4.5:1 on the card and on its hover and pressed tints.
func test_flat_buttons_look_like_buttons() -> void:
	for night in [false, true]:
		var theme := PastelTheme.build(night)
		var card := Palette.color("paper", night)
		var text := theme.get_color("font_color", "FlatButton")
		for state in ["normal", "hover", "pressed"]:
			var sb := theme.get_stylebox(state, "FlatButton") as StyleBoxFlat
			var where := "%s %s" % ["night" if night else "light", state]
			assert_true(sb != null and sb.border_width_left >= 1, where + ": an outline")
			if sb == null:
				continue
			assert_true(Palette.contrast_ratio(sb.border_color, card) >= 3.0, "%s: outline %.2f" % [where, Palette.contrast_ratio(sb.border_color, card)])
			var fill := card.blend(sb.bg_color) if sb.draw_center else card
			assert_true(Palette.contrast_ratio(text, fill) >= 4.5, "%s: text %.2f" % [where, Palette.contrast_ratio(text, fill)])


## Every flat button in the course cards uses those edges (a Button marked
## `flat` draws no edge at all).
func test_course_flat_buttons_are_not_bare() -> void:
	var game := Game.new()
	add_to_tree(game)
	var path := "user://test_palette_flat_%d.json" % randi()
	game.boot(path)
	var deck := LessonDeck.new()
	deck.game = game
	add_to_tree(deck)
	var meet := MeetPartCard.make(game, "led")
	add_to_tree(meet)
	await wait_frames(1)
	for b in [deck.skip_button(), deck.deeper_button(), meet.deeper_button(), meet.inside_button()]:
		assert_eq(str((b as Button).theme_type_variation), "FlatButton", (b as Button).text)
		assert_false((b as Button).flat, (b as Button).text + " draws its edge")
	DirAccess.remove_absolute(path)
