class_name HintButton
extends IconButton
## The lightbulb. Each press shows the next hint: words first, then
## highlights, then ghost parts and wires to tap into place.


static func create() -> HintButton:
	var b := HintButton.new()
	b.icon_name = "bulb"
	b.text = "Hint"
	b.tooltip_text = "Show a hint"
	b.custom_minimum_size = Vector2(108, 52)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return b
