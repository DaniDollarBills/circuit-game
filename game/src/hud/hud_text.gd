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
		for slot in ["normal_font_size", "bold_font_size"]:
			l.add_theme_font_size_override(slot, font_size)
	l.meta_clicked.connect(func(meta: Variant) -> void: game.term_requested.emit(str(meta)))
	return l


## Shows `text` in `l`, in bold if asked. Re-rendering the same text is skipped.
static func put(l: RichTextLabel, text: String, game: Game, bold := false) -> void:
	var p := game.state.progress
	var night := bool(p.settings.get("night", false))
	var key := "%s|%s|%s" % [night, bold, text]
	if l.get_meta("hud_text", "") == key:
		return
	l.set_meta("hud_text", key)
	var r := GlossaryText.render(text, p.seen_terms, true, night)
	l.text = "[b]%s[/b]" % r["bbcode"] if bold else r["bbcode"]
	if not (r["new_terms"] as PackedStringArray).is_empty():
		game.mark_terms_seen(r["new_terms"])


## A label with `text` already in it.
static func make(game: Game, text: String, font_size := 0, bold := false) -> RichTextLabel:
	var l := label(game, font_size)
	put(l, text, game, bold)
	return l
