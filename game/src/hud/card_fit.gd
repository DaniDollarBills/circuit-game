class_name CardFit
extends RefCounted
## Cards (datasheet, calculator, settings, Notebook, definitions…) fit the
## screen they're on: on a small phone they get narrower, and when they're
## still too tall their content scrolls, so every row and button stays
## reachable.


## Puts `content` in a vertical scroll area inside `card`; returns the area.
static func wrap(card: Container, content: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	card.add_child(scroll)
	return scroll


## Gives `card` `width` (at most the area's) and the height of its content (or
## `height`, when given), at most the area's: past that it scrolls. Then moves
## it as near `at` (its top-left) as it can while staying inside `area`.
static func fit(card: Control, width: float, area: Rect2, at: Vector2, height := -1.0) -> void:
	var w := minf(width, area.size.x)
	var h := height
	if h < 0.0:
		var scroll := card.get_node_or_null("Scroll") as ScrollContainer
		if scroll != null and scroll.get_child_count() > 0:
			var pad := card.get_theme_stylebox("panel").get_minimum_size()
			h = (scroll.get_child(0) as Control).get_combined_minimum_size().y + pad.y
		else:
			card.size = Vector2(w, 0)
			card.reset_size()
			h = card.size.y
	card.size = Vector2(w, minf(h, area.size.y))
	card.position = at.clamp(area.position, (area.end - card.size).max(area.position)).round()
