class_name CircuitIO
extends RefCounted
## Versioned JSON for circuits. Loading validates everything and returns null
## (without printing errors) when the data is unusable.

const FORMAT := 1


static func to_dict(c: Circuit) -> Dictionary:
	var parts := []
	for p in c.parts:
		parts.append({
			"id": p.id, "kind": p.kind, "x": p.x, "y": p.y, "rot": p.rot,
			"props": p.props.duplicate(true), "locked": p.locked, "tray": p.tray,
		})
	var wires := []
	for w in c.wires:
		var via := []
		for v in w.via:
			via.append([v.x, v.y])
		wires.append({
			"id": w.id, "a": [w.a_part, w.a_pin], "b": [w.b_part, w.b_pin],
			"locked": w.locked, "via": via,
		})
	return {"format": FORMAT, "parts": parts, "wires": wires}


static func to_json(c: Circuit) -> String:
	return JSON.stringify(to_dict(c))


static func from_json(s: String) -> Circuit:
	var json := JSON.new()
	if json.parse(s) != OK or not (json.data is Dictionary):
		return null
	return from_dict(json.data)


static func from_dict(d: Dictionary) -> Circuit:
	if not _is_number(d.get("format")) or int(d["format"]) != FORMAT:
		return null
	if not (d.get("parts") is Array) or not (d.get("wires") is Array):
		return null
	var c := Circuit.new()
	var ids := {}
	for pd in d["parts"]:
		var p := _part_from(pd)
		if p == null or ids.has(p.id):
			return null
		ids[p.id] = p
		c.parts.append(p)
	var wire_ids := {}
	for wd in d["wires"]:
		var w := _wire_from(wd)
		if w == null or wire_ids.has(w.id):
			return null
		if not ids.has(w.a_part) or not ids.has(w.b_part):
			return null
		if not Catalog.has_pin(ids[w.a_part].kind, w.a_pin) or not Catalog.has_pin(ids[w.b_part].kind, w.b_pin):
			return null
		wire_ids[w.id] = true
		c.wires.append(w)
	return c


static func _part_from(pd: Variant) -> Part:
	if not (pd is Dictionary):
		return null
	var id: Variant = pd.get("id")
	var kind: Variant = pd.get("kind")
	if not (id is String) or (id as String).is_empty() or not (kind is String) or not Catalog.has_kind(kind):
		return null
	for key in ["x", "y", "rot"]:
		if not _is_number(pd.get(key)):
			return null
	var rot := int(pd["rot"])
	if not rot in [0, 90, 180, 270]:
		return null
	var props: Variant = pd.get("props", {})
	if not (props is Dictionary):
		return null
	for v in (props as Dictionary).values():
		if typeof(v) == TYPE_FLOAT and not is_finite(v):
			return null
	var p := Part.make(id, kind, int(pd["x"]), int(pd["y"]), rot, props, bool(pd.get("locked", false)))
	p.tray = int(pd.get("tray", -1)) if _is_number(pd.get("tray", -1)) else -1
	return p


static func _wire_from(wd: Variant) -> Wire:
	if not (wd is Dictionary):
		return null
	var id: Variant = wd.get("id")
	var a: Variant = wd.get("a")
	var b: Variant = wd.get("b")
	if not (id is String) or (id as String).is_empty() or not _is_endpoint(a) or not _is_endpoint(b):
		return null
	var via: Array[Vector2i] = []
	var raw_via: Variant = wd.get("via", [])
	if not (raw_via is Array):
		return null
	for v in raw_via:
		if not (v is Array) or v.size() != 2 or not _is_number(v[0]) or not _is_number(v[1]):
			return null
		via.append(Vector2i(int(v[0]), int(v[1])))
	return Wire.make(id, a[0], a[1], b[0], b[1], bool(wd.get("locked", false)), via)


static func _is_endpoint(v: Variant) -> bool:
	return v is Array and v.size() == 2 and v[0] is String and v[1] is String


static func _is_number(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT
