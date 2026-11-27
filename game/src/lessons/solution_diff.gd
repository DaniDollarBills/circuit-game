class_name SolutionDiff
extends RefCounted
## What separates the player's circuit from the level's solution, for the
## "here's one way" hint: ghost parts to place, ghost wires to draw, values to
## change, and wires and parts to take out.
##
## It compares connections, not individual wires: the same connections made with
## different wires count as right, and so does a resistor or switch turned the
## other way round. Switches count as open, since flipping one is testing, not
## building. Everything is named with the player's ids, and ghost parts get ids
## the player's board doesn't use.

## Switch positions are part of testing a circuit, not of building it.
const IGNORED_PROPS: PackedStringArray = ["closed"]
## Two-pin parts that work the same either way round.
const SYMMETRIC: PackedStringArray = ["resistor", "switch"]


## Pins joined by wires (union-find over "part:pin" keys).
class Nets:
	var _parent := {}

	func find(k: String) -> String:
		var root := k
		while _parent.has(root) and _parent[root] != root:
			root = _parent[root]
		while _parent.has(k) and _parent[k] != root:
			var next: String = _parent[k]
			_parent[k] = root
			k = next
		return root

	func join(a: String, b: String) -> void:
		var ra := find(a)
		var rb := find(b)
		if ra != rb:
			_parent[ra] = rb
			_parent[rb] = rb

	func same(a: String, b: String) -> bool:
		return find(a) == find(b)


static func compute(current: Circuit, solution: Circuit) -> Dictionary:
	var to_current := _map_parts(current, solution)
	var have_all := Nets.new()
	for w in current.wires:
		have_all.join(Netlist.key(w.a_part, w.a_pin), Netlist.key(w.b_part, w.b_pin))
	var flipped := _orient(solution, to_current, have_all)

	var want := Nets.new()
	var wanted_wires: Array = []
	for sw in solution.wires:
		var ends := _ends(sw, to_current, flipped)
		if not ends.is_empty():
			want.join(ends[0], ends[1])
			wanted_wires.append(ends)

	var remove := PackedStringArray()
	var have := Nets.new()
	for w in current.wires:
		var ka := Netlist.key(w.a_part, w.a_pin)
		var kb := Netlist.key(w.b_part, w.b_pin)
		if want.same(ka, kb):
			have.join(ka, kb)
		else:
			remove.append(w.id)

	var wires: Array[Dictionary] = []
	for ends in wanted_wires:
		if not have.same(ends[0], ends[1]):
			var a: PackedStringArray = ends[0].split(":")
			var b: PackedStringArray = ends[1].split(":")
			wires.append({"a_part": a[0], "a_pin": a[1], "b_part": b[0], "b_pin": b[1]})
			have.join(ends[0], ends[1])

	var parts: Array[Part] = []
	var props: Array[Dictionary] = []
	var taken := current.copy()
	for sp in solution.parts:
		if not to_current.has(sp.id):
			var ghost := sp.copy()
			ghost.id = CircuitEdits.next_id(taken, sp.id.rstrip("0123456789"))
			taken.parts.append(ghost)
			parts.append(ghost)
			continue
		var cp := _part_by_id(current, to_current[sp.id])
		for key in sp.props:
			if not key in IGNORED_PROPS and not same_value(cp.props.get(key), sp.props[key]):
				props.append({"part": cp.id, "key": key, "value": sp.props[key]})

	var used := {}
	for id in to_current.values():
		used[id] = true
	var remove_parts := PackedStringArray()
	for p in current.parts:
		if not used.has(p.id) and not p.locked:
			remove_parts.append(p.id)
	return {"parts": parts, "wires": wires, "props": props, "remove_wires": remove, "remove_parts": remove_parts}


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


## For each resistor or switch, whether the player's board uses it turned round:
## the way that already makes more of the solution's connections wins.
static func _orient(solution: Circuit, to_current: Dictionary, have: Nets) -> Dictionary:
	var flipped := {}
	for sp in solution.parts:
		if not sp.kind in SYMMETRIC or not to_current.has(sp.id):
			continue
		var score := [0, 0]
		for turn in [false, true]:
			flipped[sp.id] = turn
			for sw in solution.wires:
				if sw.a_part != sp.id and sw.b_part != sp.id:
					continue
				var ends := _ends(sw, to_current, flipped)
				if not ends.is_empty() and have.same(ends[0], ends[1]):
					score[int(turn)] += 1
		flipped[sp.id] = score[1] > score[0]
	return flipped


## A solution wire's two ends as current "part:pin" keys, or [] when an end's
## part isn't on the board.
static func _ends(sw: Wire, to_current: Dictionary, flipped: Dictionary) -> Array:
	if not (to_current.has(sw.a_part) and to_current.has(sw.b_part)):
		return []
	return [
		Netlist.key(to_current[sw.a_part], _pin(sw.a_part, sw.a_pin, flipped)),
		Netlist.key(to_current[sw.b_part], _pin(sw.b_part, sw.b_pin, flipped)),
	]


static func _pin(part_id: String, pin: String, flipped: Dictionary) -> String:
	if not flipped.get(part_id, false):
		return pin
	return "b" if pin == "a" else "a"


static func _part_by_id(c: Circuit, id: String) -> Part:
	for p in c.parts:
		if p.id == id:
			return p
	return null
