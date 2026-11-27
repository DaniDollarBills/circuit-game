class_name ExplainPopover
extends PanelContainer
## "Why these numbers?": a part's values worked out with its real numbers
## (Explain.part), and for a burnt part the Go deeper note on how the game
## simplifies failure.

var game: Game
var part_id := ""

var _title: RichTextLabel
var _lines: VBoxContainer
var _deeper: RichTextLabel


func _ready() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	# Narrower on a phone, and scrolls when it is still too tall.
	CardFit.wrap(self, col)
	var top := HBoxContainer.new()
	col.add_child(top)
	_title = HudText.label(game)
	top.add_child(_title)
	var close_b := IconButton.make("close", "Close")
	close_b.custom_minimum_size = Vector2(IconButton.MIN_TOUCH, IconButton.MIN_TOUCH)
	close_b.pressed.connect(func() -> void: visible = false)
	top.add_child(close_b)
	_lines = VBoxContainer.new()
	col.add_child(_lines)
	_deeper = HudText.label(game, 14)
	col.add_child(_deeper)
	visible = false


func open(p: Part, sim: SimResult, at: Vector2) -> void:
	refresh(p, sim)
	visible = true
	reset_size()
	var host := get_parent_area_size()
	position = Vector2(clampf(at.x - size.x / 2.0, 8.0, maxf(host.x - size.x - 8.0, 8.0)), clampf(at.y + 24.0, 8.0, maxf(host.y - size.y - 8.0, 8.0)))


## Fills in the numbers again, in place, for the circuit as it is now.
func refresh(p: Part, sim: SimResult) -> void:
	part_id = p.id
	HudText.put(_title, "Why: %s %s" % [Catalog.title(p.kind), p.id], game, true)
	for c in _lines.get_children():
		_lines.remove_child(c)
		c.queue_free()
	for line in Explain.part(p, sim):
		_lines.add_child(HudText.make(game, line, 16))
	var deeper := GoDeeper.for_part(p) if bool(p.props.get("burnt", false)) else ""
	_deeper.visible = deeper != ""
	if deeper != "":
		HudText.put(_deeper, deeper, game)
	reset_size()


func line_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for c in _lines.get_children():
		if c is RichTextLabel and not c.is_queued_for_deletion():
			out.append((c as RichTextLabel).get_parsed_text())
	return out
