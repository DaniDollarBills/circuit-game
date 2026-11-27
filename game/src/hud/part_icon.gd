class_name PartIcon
extends Control
## A part's circuit symbol, centered and scaled to fit, for the tray and the
## datasheet card.

var part: Part:
	set(value):
		part = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if part == null:
		return
	var ops := PartArt.ops(part, {}, false, false)
	var tile := Rect2()
	for op in ops:
		if op.get("tag", "") == "tile":
			tile = op["rect"]
	if tile.size.x <= 0.0 or tile.size.y <= 0.0:
		return
	var ppu := minf(size.x / (tile.size.x + 0.6), size.y / (tile.size.y + 0.6))
	var origin := size / 2.0 / ppu - tile.get_center()
	DrawKit.draw_ops(self, ops, origin, 0, ppu)
