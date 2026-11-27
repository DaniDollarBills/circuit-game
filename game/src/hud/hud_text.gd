class_name HudText
extends RefCounted
## Puts copy on screen through the glossary: every glossary word becomes a
## tappable link, and words the player meets for the first time are recorded
## in the Notebook, which brings up their New word card.


## A wrapping RichTextLabel that grows to fit its text and opens a word's
## definition when its link is tapped.
static func label(game: Game, font_size := 0) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font_size > 0:
		HudText.font_size(l, font_size, game, ["normal_font_size", "bold_font_size"])
	l.meta_clicked.connect(func(meta: Variant) -> void: game.term_requested.emit(str(meta)))
	return l


## Shows `text` in `l`, in bold if asked. Re-rendering the same text is skipped.
## `autolink` off links only [[ ]] markup (a source's words are a citation).
static func put(l: RichTextLabel, text: String, game: Game, bold := false, autolink := true) -> void:
	var p := game.state.progress
	var night := bool(p.settings.get("night", false))
	var key := "%s|%s|%s|%s" % [night, bold, autolink, text]
	if l.get_meta("hud_text", "") == key:
		return
	l.set_meta("hud_text", key)
	l.set_meta("hud_src", text)
	l.set_meta("hud_bold", bold)
	l.set_meta("hud_autolink", autolink)
	if not l.is_in_group("hud_text"):
		l.add_to_group("hud_text")
	var r := GlossaryText.render(text, p.seen_terms, autolink, night)
	l.text = "[b]%s[/b]" % r["bbcode"] if bold else r["bbcode"]
	if not (r["new_terms"] as PackedStringArray).is_empty():
		game.mark_terms_seen(r["new_terms"])


## How much the Large text setting enlarges the sizes the HUD sets itself
## (the theme's own sizes grow by the same 1.25).
static func text_scale(game: Game) -> float:
	return 1.25 if bool(game.state.progress.settings.get("large_text", false)) else 1.0


## Gives `c` a font size that follows the Large text setting: `base` at normal
## size; refresh_sizes() applies a change to every control set this way.
static func font_size(c: Control, base: int, game: Game, slots: Array = ["font_size"]) -> void:
	c.set_meta("hud_size", base)
	c.set_meta("hud_size_slots", slots)
	if not c.is_in_group("hud_sized"):
		c.add_to_group("hud_sized")
	for slot in slots:
		c.add_theme_font_size_override(slot, roundi(base * text_scale(game)))


static func refresh_sizes(tree: SceneTree, game: Game) -> void:
	var k := text_scale(game)
	for n in tree.get_nodes_in_group("hud_sized"):
		var c := n as Control
		for slot in c.get_meta("hud_size_slots", ["font_size"]):
			c.add_theme_font_size_override(slot, roundi(int(c.get_meta("hud_size")) * k))


## Renders every HUD label again: link colors are baked into the text, so a
## night switch needs this (unchanged labels are skipped).
static func refresh_all(tree: SceneTree, game: Game) -> void:
	for n in tree.get_nodes_in_group("hud_text"):
		var l := n as RichTextLabel
		if l != null and l.has_meta("hud_src"):
			put(l, str(l.get_meta("hud_src")), game, bool(l.get_meta("hud_bold", false)), bool(l.get_meta("hud_autolink", true)))


## Introduces the glossary words in the plain text (labels, buttons) under
## `root` that the player hasn't met: they're marked seen, so the screen shows
## their New word cards (or, on the title, subtitles). Definitions themselves
## (the "definitions" group) are skipped.
static func introduce_in(game: Game, root: Node) -> void:
	var seen := game.state.progress.seen_terms
	var fresh := PackedStringArray()
	for n in [root] + root.find_children("*", "Control", true, false):
		var c := n as Control
		if c == null or not c.is_visible_in_tree() or _in_definition(c):
			continue
		var text := ""
		if c is Label:
			text = (c as Label).text
		elif c is Button:
			text = (c as Button).text
		if text.strip_edges() == "":
			continue
		for t in GlossaryText.render(text, seen, true)["new_terms"]:
			if not t in fresh:
				fresh.append(t)
	if not fresh.is_empty():
		game.mark_terms_seen(fresh)


static func _in_definition(n: Node) -> bool:
	while n != null:
		if n.is_in_group("definitions"):
			return true
		n = n.get_parent()
	return false


## A label with `text` already in it.
static func make(game: Game, text: String, font_size := 0, bold := false) -> RichTextLabel:
	var l := label(game, font_size)
	put(l, text, game, bold)
	return l
