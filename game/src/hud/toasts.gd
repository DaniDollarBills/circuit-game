class_name Toasts
extends VBoxContainer
## Short messages stacked at the top of the screen; each stays 2.5 s and fades.

const LIFE_S := 2.5
const FADE_S := 0.3

var game: Game
var _items: Array[Dictionary] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 8)
	alignment = BoxContainer.ALIGNMENT_BEGIN


func show_text(text: String, sparkle := false) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	if sparkle:
		var star := Sparkle.new()
		star.animate = not bool(game.state.progress.settings.get("reduced_motion", false))
		row.add_child(star)
	var label := HudText.make(game, text)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	add_child(panel)
	_items.append({"node": panel, "label": label, "left": LIFE_S})


## The texts of the toasts on screen, newest last.
func texts() -> PackedStringArray:
	var out := PackedStringArray()
	for it in _items:
		out.append((it["label"] as RichTextLabel).get_parsed_text())
	return out


func _process(delta: float) -> void:
	for it in _items.duplicate():
		it["left"] -= delta
		var node: Control = it["node"]
		node.modulate.a = clampf(it["left"] / FADE_S, 0.0, 1.0)
		if it["left"] <= 0.0:
			_items.erase(it)
			node.queue_free()


## A small four-pointed star that twinkles beside a badge toast.
class Sparkle:
	extends Control

	var animate := true
	var _t := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(28, 28)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if animate:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var k := 1.0 + 0.15 * sin(_t * 8.0)
		var pts := PackedVector2Array()
		for i in 8:
			var a := TAU * i / 8.0 - PI / 2.0 + _t
			pts.append(c + Vector2.from_angle(a) * (11.0 * k if i % 2 == 0 else 3.5))
		draw_colored_polygon(pts, Palette.color("spark").darkened(0.15))
