class_name CircuitHistory
extends RefCounted
## Undo/redo over immutable circuit snapshots. Keeps at most LIMIT undo steps.

const LIMIT := 100

var present: Circuit
var _past: Array[Circuit] = []
var _future: Array[Circuit] = []


func _init(start: Circuit) -> void:
	present = start


## Committing the present instance again (a refused edit) is ignored.
func commit(next: Circuit) -> void:
	if next == present:
		return
	_past.append(present)
	if _past.size() > LIMIT:
		_past.pop_front()
	present = next
	_future.clear()


func undo() -> bool:
	if _past.is_empty():
		return false
	_future.append(present)
	present = _past.pop_back()
	return true


func redo() -> bool:
	if _future.is_empty():
		return false
	_past.append(present)
	present = _future.pop_back()
	return true


func can_undo() -> bool:
	return not _past.is_empty()


func can_redo() -> bool:
	return not _future.is_empty()
