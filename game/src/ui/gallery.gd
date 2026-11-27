extends Control
## Dev-only style gallery: buttons, cards, text and every palette swatch.
## Pass --night (after "--") to see the night variant.

func _ready() -> void:
	var night := "--night" in OS.get_cmdline_user_args()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = PastelTheme.build(night)
	var bg := ColorRect.new()
	bg.color = Palette.color("cream", night)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	margin.add_child(col)

	var heading := Label.new()
	heading.theme_type_variation = "HeadingLabel"
	heading.text = "Circuit — style gallery" + (" (night)" if night else "")
	col.add_child(heading)

	var body := Label.new()
	body.text = "Electricity only flows around a full loop: out of the battery's + side and back into −."
	col.add_child(body)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for t in ["Start", "Test it", "Hint"]:
		var b := Button.new()
		b.text = t
		row.add_child(b)
	var off := Button.new()
	off.text = "Locked"
	off.disabled = true
	row.add_child(off)
	col.add_child(row)

	var card := PanelContainer.new()
	var card_text := RichTextLabel.new()
	card_text.bbcode_enabled = true
	card_text.fit_content = true
	card_text.custom_minimum_size = Vector2(560, 0)
	card_text.text = "[b]New word: Resistor[/b]\nA part that limits current, like a narrow section of pipe."
	card.add_child(card_text)
	col.add_child(card)

	var swatches := GridContainer.new()
	swatches.columns = 9
	swatches.add_theme_constant_override("h_separation", 10)
	swatches.add_theme_constant_override("v_separation", 10)
	for n in Palette.NAMES:
		var cell := VBoxContainer.new()
		var chip := ColorRect.new()
		chip.color = Palette.color(n, night)
		chip.custom_minimum_size = Vector2(110, 44)
		cell.add_child(chip)
		var label := Label.new()
		label.text = n
		label.add_theme_font_size_override("font_size", 14)
		cell.add_child(label)
		swatches.add_child(cell)
	col.add_child(swatches)
