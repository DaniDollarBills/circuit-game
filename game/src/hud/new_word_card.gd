class_name NewWordCard
extends PanelContainer
## The first time a word appears, this card slides in from the side with its
## plain meaning and, under More precisely, the expert one. It stays 8 s or
## until tapped; a tap opens the full definition.

signal finished(card: NewWordCard)

const LIFE_S := 8.0
const SLIDE_S := 0.25

var game: Game
var term := ""
var left := LIFE_S

var _slide := 0.0
var _animate := true


static func make(g: Game, t: String) -> NewWordCard:
	var card := NewWordCard.new()
	card.game = g
	card.term = t
	return card


func _ready() -> void:
	custom_minimum_size = Vector2(300, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_animate = not bool(game.state.progress.settings.get("reduced_motion", false))
	var e: Dictionary = Glossary.ENTRIES.get(term, {"title": term, "simple": "", "precise": ""})
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var tag := Label.new()
	tag.text = "New word"
	tag.add_theme_font_size_override("font_size", 13)
	var pill := StyleBoxFlat.new()
	pill.bg_color = Palette.color("mint")
	pill.set_corner_radius_all(9)
	pill.content_margin_left = 8
	pill.content_margin_right = 8
	tag.add_theme_stylebox_override("normal", pill)
	tag.add_theme_color_override("font_color", Palette.color("ink", false))
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(tag)
	var title := Label.new()
	title.text = e["title"]
	title.add_theme_font_size_override("font_size", 19)
	col.add_child(title)
	# Plain text here: the card itself is the definition, and it must not
	# mark the words it uses as seen.
	for line in [[e["simple"], 15, "ink"], ["More precisely", 12, "ink_soft"], [e["precise"], 13, "ink_soft"]]:
		var l := Label.new()
		l.text = line[0]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", line[1])
		# Theme colors, so switching Night on recolors a card already showing.
		l.theme_type_variation = "SoftLabel" if line[2] == "ink_soft" else ""
		col.add_child(l)
	_slide = 0.0 if _animate else 1.0


func _gui_input(event: InputEvent) -> void:
	var press := event is InputEventMouseButton and (event as InputEventMouseButton).pressed
	var touch := event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed
	if press or touch:
		accept_event()
		game.term_requested.emit(term)
		finish()


func _process(delta: float) -> void:
	if _slide < 1.0:
		_slide = minf(_slide + delta / SLIDE_S, 1.0)
	modulate.a = _slide
	left -= delta
	if left <= 0.0:
		finish()


## 0 when it starts sliding in, 1 once it's in place.
func slide_progress() -> float:
	return ease(_slide, 0.4)


func finish() -> void:
	if left > -INF:
		left = -INF
		finished.emit(self)
