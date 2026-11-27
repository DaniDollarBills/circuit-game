extends Control
## Every part kind in each state on a cream board, for checking the art by eye.
## --zoom=<n> magnifies around the LED row to check that edges stay crisp.

const BASE_PPU := 22.0

var zoom := 1.0
var focus := Vector2.ZERO
var _items: Array[Dictionary] = []
var _wires: Array[Dictionary] = []
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--zoom="):
			zoom = maxf(float(arg.substr(7)), 0.1)
	if zoom > 1.0:
		focus = Vector2(-11, 1)
	_build()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _item(p: Part, caption: String, vis := {}, selected := false, highlighted := false) -> void:
	var v := {"brightness": 0.0, "burnt": false, "hot": false, "reading": "", "closed": false,
			"color": str(p.props.get("color", "red")), "label": str(p.props.get("label", ""))}
	v.merge(vis, true)
	if bool(v["burnt"]):
		p.props["burnt"] = true
	_items.append({"part": p, "caption": caption, "vis": v, "selected": selected, "highlighted": highlighted})


func _build() -> void:
	_item(Part.make("B1", "battery", -24, -10), "battery")
	_item(Part.make("B2", "battery", -19, -10), "hot (short)", {"hot": true})
	_item(Part.make("B3", "battery", -14, -10), "selected", {}, true)
	_item(Part.make("B4", "battery", -8, -10, 90), "turned 90°")
	_item(Part.make("R1", "resistor", 0, -11, 0, {"ohms": 220.0}), "220 Ω")
	_item(Part.make("R2", "resistor", 7, -11, 0, {"ohms": 47.0, "watts": 1.0}), "1 W")
	_item(Part.make("R3", "resistor", 14, -11, 0, {"ohms": 1000.0, "adjustable": true}), "adjustable")
	_item(Part.make("R4", "resistor", 21, -11, 0, {"ohms": 47.0}), "burnt", {"burnt": true})
	_item(Part.make("R5", "resistor", 3, -6, 0, {"ohms": 150.0}), "hint highlight", {}, false, true)
	_item(Part.make("R6", "resistor", 11, -6, 90, {"ohms": 330.0}), "turned 90°")
	var leds := [["off", "red", 0.0], ["dim", "red", 0.25], ["bright", "red", 1.0], ["yellow", "yellow", 0.7],
			["green", "green", 0.7], ["blue", "blue", 0.7]]
	for i in leds.size():
		_item(Part.make("L%d" % i, "led", -24 + 5 * i, 1, 0, {"color": leds[i][1]}), leds[i][0], {"brightness": leds[i][2]})
	_item(Part.make("L7", "led", 6, 1), "burnt", {"burnt": true})
	_item(Part.make("L8", "led", 11, 1, 0, {"color": "green"}), "selected", {"brightness": 0.5}, true)
	_item(Part.make("L9", "led", 16, 1, 90, {"color": "blue"}), "turned 90°", {"brightness": 0.9})
	_item(Part.make("S1", "switch", -22, 7, 0, {"label": "A"}), "open")
	_item(Part.make("S2", "switch", -15, 7, 0, {"label": "B", "closed": true}), "closed", {"closed": true})
	_item(Part.make("S3", "switch", -9, 7, 90, {"label": "S"}), "turned 90°")
	_item(Part.make("M1", "ammeter", -2, 7), "current meter", {"reading": "13.8 mA"})
	_item(Part.make("V1", "voltmeter", 4, 7), "voltage meter", {"reading": "4.99 V"})
	_item(Part.make("M2", "ammeter", 10, 7), "not connected", {"reading": "—"})
	for i in 4:
		var y := 12.5
		var x0 := -24.0 + 12.0 * i
		var path := PackedVector2Array([Vector2(x0, y), Vector2(x0 + 4, y), Vector2(x0 + 4, y + 2), Vector2(x0 + 9, y + 2)])
		var specs := [[0.0, false, "0 V"], [2.5, false, "2.5 V"], [5.0, false, "5 V, patterns on"], [0.0, true, "floating"]]
		_wires.append({"path": path, "volts": specs[i][0], "floating": specs[i][1], "caption": specs[i][2], "amps": 0.0 if specs[i][1] else 0.0138})


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.color("cream"))
	var ppu := BASE_PPU * zoom
	draw_set_transform(size / 2.0 - focus * ppu)
	var half := size / 2.0 / ppu
	for gx in range(floori(focus.x - half.x), ceili(focus.x + half.x) + 1):
		for gy in range(floori(focus.y - half.y), ceili(focus.y + half.y) + 1):
			draw_rect(Rect2(Vector2(gx, gy) * ppu - Vector2.ONE, Vector2(2, 2)), Palette.color("line"))
	for w in _wires:
		var path: PackedVector2Array = w["path"]
		DrawKit.polyline(self, path, WireArt.color_for_volts(w["volts"], w["floating"]), 0.22, ppu)
		for dash in WireArt.pattern_dashes(path, w["volts"], true):
			DrawKit.polyline(self, dash, Palette.color("ink"), 0.08, ppu)
		for dot in WireArt.dots(path, w["amps"], _t):
			DrawKit.circle(self, dot, 0.11, Palette.color("spark"), Palette.color("ink"), 0.03, ppu)
		DrawKit.text(self, path[path.size() - 1] + Vector2(-2.5, 1.0), w["caption"], 0.45, Palette.color("ink_soft"), false, ppu)
	for item in _items:
		var p: Part = item["part"]
		DrawKit.draw_ops(self, PartArt.ops(p, item["vis"], item["selected"], item["highlighted"]), Vector2(p.x, p.y), p.rot, ppu)
		var below := CircuitGeometry.part_rect(p).end.y + (2.2 if p.kind in ["resistor", "switch", "ammeter", "voltmeter"] else 1.4)
		DrawKit.text(self, Vector2(CircuitGeometry.part_rect(p).get_center().x, below), item["caption"], 0.45, Palette.color("ink_soft"), false, ppu)
	draw_set_transform(Vector2.ZERO)
