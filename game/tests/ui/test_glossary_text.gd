extends TestCase


func _link(term: String, shown: String) -> String:
	return "[url=%s][color=%s]%s[/color][/url]" % [term, GlossaryText.LINK_LIGHT, shown]


func test_render_explicit_markup() -> void:
	var r := GlossaryText.render("Can you light the [[led|LED]]?", {})
	assert_eq(r["bbcode"], "Can you light the %s?" % _link("led", "LED"))
	assert_eq(r["terms"], PackedStringArray(["led"]))
	var unknown := GlossaryText.render("A [[switch]] and a [[nonsense|thing]].", {})
	assert_eq(unknown["bbcode"], "A %s and a thing." % _link("switch", "switch"))


func test_render_no_link_escape() -> void:
	var r := GlossaryText.render("Georg [[=Ohm]] published his law in 1827.", {})
	assert_eq(r["bbcode"], "Georg Ohm published his law in 1827.")
	assert_eq(r["terms"], PackedStringArray())


func test_render_autolinks_first_occurrence_only() -> void:
	var r := GlossaryText.render("Current flows. More current, more light.", {})
	assert_eq(r["bbcode"], "%s flows. More current, more light." % _link("current", "Current"))


## A term the author linked by hand isn't also auto-linked elsewhere.
func test_render_markup_term_not_autolinked_elsewhere() -> void:
	var r := GlossaryText.render("Current, then [[current|this]].", {})
	assert_eq(r["bbcode"], "Current, then %s." % _link("current", "this"))


func test_render_plural_and_possessive() -> void:
	var r := GlossaryText.render("Resistors limit the battery's current.", {})
	assert_eq(r["bbcode"], "%s limit the %s %s." % [_link("resistor", "Resistors"), _link("battery", "battery's"),
			_link("current", "current")])
	assert_eq(GlossaryText.render("Two switches.", {})["terms"], PackedStringArray(["switch"]))


func test_render_longest_match_first() -> void:
	var r := GlossaryText.render("Check the forward voltage.", {})
	assert_eq(r["terms"], PackedStringArray(["forward voltage"]))
	assert_eq(r["bbcode"], "Check the %s." % _link("forward voltage", "forward voltage"))


func test_render_alias() -> void:
	assert_eq(GlossaryText.render("Read the current meter.", {})["terms"], PackedStringArray(["ammeter"]))
	assert_eq(GlossaryText.render("About 20 mA flows.", {})["terms"], PackedStringArray(["milliamp"]))


func test_render_explicit_only_not_autolinked() -> void:
	var r := GlossaryText.render("It's a bit dim.", {})
	assert_eq(r["bbcode"], "It's a bit dim.")
	assert_eq(r["terms"], PackedStringArray())
	assert_eq(GlossaryText.render("That's a [[bit]]!", {})["terms"], PackedStringArray(["bit"]))


func test_render_new_terms_excludes_seen() -> void:
	var r := GlossaryText.render("The resistor limits the current.", {"current": 100})
	assert_eq(r["terms"], PackedStringArray(["resistor", "current"]))
	assert_eq(r["new_terms"], PackedStringArray(["resistor"]))


## Acronyms and unit symbols keep their capitals, so "led" the verb and "Ma"
## stay plain words.
func test_render_acronyms_match_case() -> void:
	var r := GlossaryText.render("His work led to the LED. Ma waved.", {})
	assert_eq(r["terms"], PackedStringArray(["led"]))
	assert_eq(r["bbcode"], "His work led to the %s. Ma waved." % _link("led", "LED"))
	assert_eq(GlossaryText.render("Two LEDs.", {})["terms"], PackedStringArray(["led"]))


func test_render_without_autolink_keeps_markup_links() -> void:
	var r := GlossaryText.render("Light an LED with a [[resistor]].", {}, false)
	assert_eq(r["terms"], PackedStringArray(["resistor"]))
	assert_eq(r["bbcode"], "Light an LED with a %s." % _link("resistor", "resistor"))


func test_render_escapes_brackets() -> void:
	assert_eq(GlossaryText.render("Press [Test].", {})["bbcode"], "Press [lb]Test].")


func test_plain_strips_markup() -> void:
	assert_eq(GlossaryText.plain("Georg [[=Ohm]], the [[led|LED]] and a [[switch]]."), "Georg Ohm, the LED and a switch.")


func test_resolve_terms_and_aliases() -> void:
	assert_eq(GlossaryText.resolve("led"), "led")
	assert_eq(GlossaryText.resolve("Ohm's law"), "ohms law")
	assert_eq(GlossaryText.resolve("Current meter"), "ammeter")
	assert_eq(GlossaryText.resolve("flux capacitor"), "")


## Checkpoint B (I5): unit symbols are defined where they appear, right after a
## number; a lone letter such as "switch A" stays plain.
func test_render_unit_symbols_after_numbers() -> void:
	var r := GlossaryText.render("Resistor = (5 V − 2.0 V) ÷ 0.020 A, so 150 Ω and ¼ W.", {})
	assert_eq(r["terms"], PackedStringArray(["resistor", "volt", "amp", "ohm", "watt"]))
	assert_eq(GlossaryText.render("A 1 kΩ resistor", {})["terms"], PackedStringArray(["ohm", "resistor"]))
	assert_eq(GlossaryText.render("The battery says 5V", {})["terms"], PackedStringArray(["battery", "volt"]))
	assert_eq(GlossaryText.render("Switch A and B, and 4 × AA cells.", {})["terms"], PackedStringArray(["switch"]))


## Checkpoint B (I7): links meet the spec's 7:1 contrast for main text, in
## both themes.
func test_link_color_meets_7_to_1() -> void:
	assert_true(GlossaryText.render("[[switch]]", {})["bbcode"].contains(GlossaryText.LINK_LIGHT))
	assert_true(GlossaryText.render("[[switch]]", {}, true, true)["bbcode"].contains(GlossaryText.LINK_NIGHT))
	for bg in ["cream", "paper"]:
		assert_true(Palette.contrast_ratio(Color(GlossaryText.LINK_LIGHT), Palette.color(bg)) >= 7.0, bg)
		assert_true(Palette.contrast_ratio(Color(GlossaryText.LINK_NIGHT), Palette.color(bg, true)) >= 7.0, bg + " at night")
