class_name CircuitDiff
extends RefCounted
## What changed between two circuits, as the actions a player takes: placed,
## moved, rotated, wired, deleted. Lesson 0 ticks its steps from these.


static func actions(before: Circuit, after: Circuit) -> PackedStringArray:
	var out := PackedStringArray()
	var old_parts := {}
	for p in before.parts:
		old_parts[p.id] = p
	var new_parts := {}
	for p in after.parts:
		new_parts[p.id] = p
		var was: Part = old_parts.get(p.id)
		if was == null:
			_add(out, "placed")
		else:
			if was.x != p.x or was.y != p.y:
				_add(out, "moved")
			if was.rot != p.rot:
				_add(out, "rotated")
	var old_wires := {}
	for w in before.wires:
		old_wires[w.id] = true
	var new_wires := {}
	for w in after.wires:
		new_wires[w.id] = true
		if not old_wires.has(w.id):
			_add(out, "wired")
	for id in old_parts:
		if not new_parts.has(id):
			_add(out, "deleted")
	for id in old_wires:
		if not new_wires.has(id):
			_add(out, "deleted")
	return out


static func _add(out: PackedStringArray, action: String) -> void:
	if not action in out:
		out.append(action)
