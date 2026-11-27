class_name SolutionDiff
extends RefCounted
## What separates the player's circuit from the level's solution, for the
## "here's one way" hint: ghost parts to place, ghost wires to draw, values to
## change and wires to take out. Everything is named with the player's part ids.

## Switch positions are part of testing a circuit, not of building it.
const IGNORED_PROPS: PackedStringArray = ["closed"]


static func compute(current: Circuit, solution: Circuit) -> Dictionary:
	var to_current := _map_parts(current, solution)
	var parts: Array[Part] = []
	var props: Array[Dictionary] = []
	for sp in solution.parts:
		if not to_current.has(sp.id):
			parts.append(sp.copy())
			continue
		var cp := _part_by_id(current, to_current[sp.id])
		for key in sp.props:
			if not key in IGNORED_PROPS and not same_value(cp.props.get(key), sp.props[key]):
				props.append({"part": cp.id, "key": key, "value": sp.props[key]})

	var have := {}
	for w in current.wires:
		have[_pair(w.a_part, w.a_pin, w.b_part, w.b_pin)] = true
	var wanted := {}
	var wires: Array[Dictionary] = []
	for sw in solution.wires:
		if not (to_current.has(sw.a_part) and to_current.has(sw.b_part)):
			continue
		var a: String = to_current[sw.a_part]
		var b: String = to_current[sw.b_part]
		var k := _pair(a, sw.a_pin, b, sw.b_pin)
		wanted[k] = true
		if not have.has(k):
			wires.append({"a_part": a, "a_pin": sw.a_pin, "b_part": b, "b_pin": sw.b_pin})

	var remove := PackedStringArray()
	for w in current.wires:
		if not wanted.has(_pair(w.a_part, w.a_pin, w.b_part, w.b_pin)):
			remove.append(w.id)
	return {"parts": parts, "wires": wires, "props": props, "remove_wires": remove}


## Prop values match: numbers numerically (150 and 150.0 agree), anything else
## only with the same type.
static func same_value(a: Variant, b: Variant) -> bool:
	var numeric := [TYPE_INT, TYPE_FLOAT]
	if typeof(a) in numeric and typeof(b) in numeric:
		return is_equal_approx(float(a), float(b))
	return typeof(a) == typeof(b) and a == b


## Solution part id → current part id. Tray parts pair up by tray index, in
## order; every other part pairs with the current part of the same id.
static func _map_parts(current: Circuit, solution: Circuit) -> Dictionary:
	var by_tray := {}
	for p in current.parts:
		if p.tray >= 0:
			if not by_tray.has(p.tray):
				by_tray[p.tray] = []
			by_tray[p.tray].append(p.id)
	var taken := {}
	var out := {}
	for sp in solution.parts:
		if sp.tray >= 0:
			var ids: Array = by_tray.get(sp.tray, [])
			var n: int = taken.get(sp.tray, 0)
			if n < ids.size():
				out[sp.id] = ids[n]
				taken[sp.tray] = n + 1
		elif _part_by_id(current, sp.id) != null:
			out[sp.id] = sp.id
	return out


static func _part_by_id(c: Circuit, id: String) -> Part:
	for p in c.parts:
		if p.id == id:
			return p
	return null


## The same key whichever end is listed first.
static func _pair(a_part: String, a_pin: String, b_part: String, b_pin: String) -> String:
	var x := Netlist.key(a_part, a_pin)
	var y := Netlist.key(b_part, b_pin)
	return x + "|" + y if x < y else y + "|" + x
