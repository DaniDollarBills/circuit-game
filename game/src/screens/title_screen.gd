class_name TitleScreen
extends Control
## The title screen. A placeholder until Task 18 adds the zoom from Earth down
## to a silicon atom.

var game: Game


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	var title := Label.new()
	title.theme_type_variation = "HeadingLabel"
	title.text = "Circuit"
	title.add_theme_font_size_override("font_size", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var tagline := Label.new()
	tagline.text = "From a single spark to thinking machines"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tagline)
	var play := Button.new()
	play.name = "Play"
	play.text = "Play"
	play.custom_minimum_size = Vector2(200, 0)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(func() -> void: game.open_map())
	box.add_child(play)
