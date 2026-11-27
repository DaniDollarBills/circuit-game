class_name EditorController
extends RefCounted
## The editing rules: what a tap, drag, long press or key does to the board.
## Pure: gestures come in (positions in grid units, plus "screen" in pixels),
## effects come out for the editor layer to carry out:
## commit{circuit}, menu{part|wire, at}, value{part}, datasheet{part},
## selected{id}, camera_zoom{factor, at}, camera_pan{delta}, toast{text}.

const ID_PREFIX := {"battery": "B", "resistor": "R", "led": "L", "switch": "SW", "ammeter": "M", "voltmeter": "V"}

## idle; placing{tray, ghost, has_ghost}; pin_selected{part, pin};
## wiring{from_part, from_pin, to, snap_part, snap_pin}; moving{part, grab, at};
## panning{last}
var mode: Dictionary = {"kind": "idle"}
var selection := ""


func begin_placing(tray_index: int) -> void:
	mode = {"kind": "placing", "tray": tray_index, "ghost": Vector2.ZERO, "has_ghost": false}


func cancel() -> void:
	mode = {"kind": "idle"}


func handle(g: Dictionary, ctx: Dictionary) -> Array[Dictionary]:
	match str(g.get("type", "")):
		"tap":
			return _tap(g["at"], ctx)
		"long_press", "secondary_tap":
			return _menu(g["at"], ctx)
		"drag_start":
			return _drag_start(g, ctx)
		"drag_move":
			return _drag_move(g, ctx)
		"drag_end":
			return _drag_end(g["at"], ctx)
		"drag_cancel":
			cancel()
		"hover":
			if mode["kind"] == "placing":
				mode["ghost"] = (g["at"] as Vector2).round()
				mode["has_ghost"] = true
		"zoom":
			return [{"type": "camera_zoom", "factor": g["factor"], "at": g["at"]}]
		"pan":
			return [{"type": "camera_pan", "delta": g["delta"]}]
		"key":
			return _key(str(g.get("key", "")), ctx)
	return []


## What is under the pointer: the layer's own pick when it has one (the 3D
## view picks what is drawn), otherwise the flat hit test.
static func _hit(c: Circuit, at: Vector2, ctx: Dictionary) -> Dictionary:
	if ctx.has("hit"):
		return ctx["hit"]
	return HitTest.at(c, at, ctx["pin_r"], ctx["wire_r"])


func _tap(at: Vector2, ctx: Dictionary) -> Array[Dictionary]:
	var c: Circuit = ctx["circuit"]
	var hit := _hit(c, at, ctx)
	if mode["kind"] == "placing":
		if hit["kind"] == "empty":
			return _place(at, ctx)
		cancel()
	match hit["kind"]:
		"pin":
			if mode["kind"] == "pin_selected" and not (mode["part"] == hit["part"] and mode["pin"] == hit["pin"]):
				var from := mode
				cancel()
				return _connect(c, from["part"], from["pin"], hit["part"], hit["pin"])
			if mode["kind"] == "pin_selected":
				cancel()
				return []
			mode = {"kind": "pin_selected", "part": hit["part"], "pin": hit["pin"]}
			selection = hit["part"]
			return []
		"part":
			cancel()
			var p := _part(c, hit["part"])
			selection = p.id
			if bool(p.props.get("burnt", false)):
				return [{"type": "menu", "part": p.id, "at": at}]
			if p.kind == "switch":
				return [{"type": "commit", "circuit": CircuitEdits.set_props(c, p.id, {"closed": not bool(p.props.get("closed", false))})}]
			if p.kind == "resistor" and bool(p.props.get("adjustable", false)):
				return [{"type": "value", "part": p.id}]
			return [{"type": "datasheet", "part": p.id}]
		"wire":
			cancel()
			selection = hit["wire"]
			return [{"type": "selected", "id": hit["wire"]}]
	cancel()
	selection = ""
	return []


func _place(at: Vector2, ctx: Dictionary) -> Array[Dictionary]:
	var i: int = mode["tray"]
	cancel()
	var tray: Array = ctx.get("tray", [])
	var used: Array = ctx.get("tray_used", [])
	if i < 0 or i >= tray.size() or (i < used.size() and int(used[i]) >= int(tray[i].get("count", 1))):
		return []
	var c: Circuit = ctx["circuit"]
	var item: Dictionary = tray[i]
	var spot := Vector2i(at.round())
	var p := Part.make(CircuitEdits.next_id(c, ID_PREFIX.get(item["kind"], "P")), item["kind"], spot.x, spot.y, 0, item.get("props", {}))
	p.tray = i
	selection = p.id
	return [{"type": "commit", "circuit": CircuitEdits.add_part(c, p)}]


func _menu(at: Vector2, ctx: Dictionary) -> Array[Dictionary]:
	var c: Circuit = ctx["circuit"]
	var hit := _hit(c, at, ctx)
	cancel()
	match hit["kind"]:
		"pin", "part":
			selection = hit["part"]
			return [{"type": "menu", "part": hit["part"], "at": at}]
		"wire":
			selection = hit["wire"]
			return [{"type": "menu", "wire": hit["wire"], "at": at}]
	return []


func _drag_start(g: Dictionary, ctx: Dictionary) -> Array[Dictionary]:
	var c: Circuit = ctx["circuit"]
	var at: Vector2 = g["at"]
	var hit := _hit(c, at, ctx)
	if hit["kind"] == "pin":
		mode = {"kind": "wiring", "from_part": hit["part"], "from_pin": hit["pin"], "to": at, "snap_part": "", "snap_pin": ""}
	elif hit["kind"] == "part" and not _part(c, hit["part"]).locked:
		var p := _part(c, hit["part"])
		mode = {"kind": "moving", "part": p.id, "grab": at - Vector2(p.x, p.y), "at": at}
		selection = p.id
	else:
		# A pan keeps the first pin of a tap-tap wire waiting.
		var resume: Dictionary = mode.duplicate() if mode["kind"] == "pin_selected" else {}
		mode = {"kind": "panning", "last": g.get("screen", Vector2.ZERO), "resume": resume}
	return []


func _drag_move(g: Dictionary, ctx: Dictionary) -> Array[Dictionary]:
	var at: Vector2 = g["at"]
	match mode["kind"]:
		"wiring":
			mode["to"] = at
			var snap: Array = ctx["snap"] if ctx.has("snap") else _snap(ctx["circuit"], at, 1.5 * float(ctx["pin_r"]))
			mode["snap_part"] = snap[0]
			mode["snap_pin"] = snap[1]
		"moving":
			mode["at"] = at
		"panning":
			var screen: Vector2 = g.get("screen", Vector2.ZERO)
			var delta: Vector2 = screen - mode["last"]
			mode["last"] = screen
			return [{"type": "camera_pan", "delta": delta}]
	return []


func _drag_end(at: Vector2, ctx: Dictionary) -> Array[Dictionary]:
	var c: Circuit = ctx["circuit"]
	var m := mode
	cancel()
	match m["kind"]:
		"panning":
			if not (m.get("resume", {}) as Dictionary).is_empty():
				mode = m["resume"]
		"wiring":
			var start := Vector2(CircuitGeometry.pin_position(_part(c, m["from_part"]), m["from_pin"])) if _part(c, m["from_part"]) != null else at
			var snap: Array
			if ctx.has("snap"):
				snap = ctx["snap"]
				if snap[0] == m["from_part"] and snap[1] == m["from_pin"]:
					return []
			else:
				# Let go back on the start pin: nothing happens.
				if at.distance_to(start) <= float(ctx["pin_r"]):
					return []
				snap = _snap(c, at, 1.5 * float(ctx["pin_r"]), m)
			if snap[0] == "":
				return [{"type": "toast", "text": "Drop the wire on a metal dot."}]
			return _connect(c, m["from_part"], m["from_pin"], snap[0], snap[1])
		"moving":
			var spot := Vector2i((at - (m["grab"] as Vector2)).round())
			var p := _part(c, m["part"])
			if p != null and spot != Vector2i(p.x, p.y):
				return [{"type": "commit", "circuit": CircuitEdits.move_part(c, p.id, spot.x, spot.y)}]
	return []


func _connect(c: Circuit, a_part: String, a_pin: String, b_part: String, b_pin: String) -> Array[Dictionary]:
	match CircuitEdits.can_add_wire(c, a_part, a_pin, b_part, b_pin):
		"":
			return [{"type": "commit", "circuit": CircuitEdits.add_wire(c, a_part, a_pin, b_part, b_pin)}]
		"duplicate":
			return [{"type": "toast", "text": "Those are already connected."}]
	return []


func _key(key: String, ctx: Dictionary) -> Array[Dictionary]:
	var c: Circuit = ctx["circuit"]
	match key:
		"cancel":
			cancel()
		"rotate":
			if _part(c, selection) != null:
				var turned := CircuitEdits.rotate_part(c, selection)
				if turned != c:
					return [{"type": "commit", "circuit": turned}]
		"delete":
			var out := c
			if _part(c, selection) != null:
				out = CircuitEdits.delete_part(c, selection)
			elif c.find_wire(selection) != null:
				out = CircuitEdits.delete_wire(c, selection)
			if out != c:
				selection = ""
				return [{"type": "commit", "circuit": out}]
	return []


## The nearest pin other than the one being dragged from, within `r`.
func _snap(c: Circuit, at: Vector2, r: float, m := {}) -> Array:
	var from_part: String = (m if not m.is_empty() else mode).get("from_part", "")
	var from_pin: String = (m if not m.is_empty() else mode).get("from_pin", "")
	var best := ["", ""]
	var best_d := r
	for p in c.parts:
		for pin in Catalog.pin_names(p.kind):
			if p.id == from_part and pin == from_pin:
				continue
			var d := at.distance_to(Vector2(CircuitGeometry.pin_position(p, pin)))
			if d <= best_d:
				best_d = d
				best = [p.id, pin]
	return best


static func _part(c: Circuit, id: String) -> Part:
	for p in c.parts:
		if p.id == id:
			return p
	return null
