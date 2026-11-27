class_name LicensesPage
extends VBoxContainer
## The credits, and every license text the game's parts must travel with,
## inside the game: the Android app has no folder beside it to hold them.
## A page of the Settings card, opened by its Licenses button.

signal closed

const FILES := {
	"Credits": "res://assets/third_party/CREDITS.md",
	"Nunito": "res://assets/fonts/LICENSE",
	"DejaVu Sans": "res://assets/fonts/LICENSE-DejaVu.txt",
	"Earth imagery": "res://assets/third_party/naturalearth/LICENSE-Apache-2.0.md",
}

var game: Game

var _back: Button
var _sections := {}


func _ready() -> void:
	# Legal text: its words aren't game vocabulary to introduce.
	add_to_group("definitions")
	add_theme_constant_override("separation", 8)
	var top := HBoxContainer.new()
	var title := Label.new()
	title.text = "Credits and licenses"
	title.theme_type_variation = "HeadingLabel"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HudText.font_size(title, 22, game)
	top.add_child(title)
	_back = Button.new()
	_back.text = "Back"
	_back.pressed.connect(func() -> void:
		visible = false
		closed.emit())
	top.add_child(_back)
	add_child(top)
	visible = false


## Shows the page, building its sections the first time.
func show_page() -> void:
	if _sections.is_empty():
		for t in FILES:
			_add_section(t, FileAccess.get_file_as_string(FILES[t]))
		_add_section("Godot Engine", godot_text())
	visible = true


func section_titles() -> PackedStringArray:
	return PackedStringArray(_sections.keys())


func section_text(t: String) -> String:
	return str(_sections.get(t, ""))


func back_button() -> Button:
	return _back


## Godot's own license, the libraries built into it, and their license texts.
static func godot_text() -> String:
	var t := Engine.get_license_text() + "\n\nBuilt into Godot Engine:\n"
	for c in Engine.get_copyright_info():
		var kinds := PackedStringArray()
		for part in c["parts"]:
			kinds.append(str(part["license"]))
		t += "• %s (%s)\n" % [c["name"], ", ".join(kinds)]
	var info := Engine.get_license_info()
	for license_name in info:
		t += "\n%s\n\n%s\n" % [license_name, info[license_name]]
	return t


func _add_section(t: String, text: String) -> void:
	_sections[t] = text
	var heading := Label.new()
	heading.text = t
	heading.theme_type_variation = "HeadingLabel"
	HudText.font_size(heading, 18, game)
	add_child(heading)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HudText.font_size(body, 13, game)
	add_child(body)
