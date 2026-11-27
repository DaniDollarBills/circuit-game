class_name GestureRecognizer
extends RefCounted
## Turns raw pointer events into gestures: tap, long press, secondary tap,
## drag, pinch (zoom + pan), wheel and trackpad zoom. Pure: time is passed in.
##
## A second finger during a drag cancels the drag and starts a pinch; after one
## finger of a pinch lifts, the other is ignored until every finger is up, so a
## pinch never ends in a stray tap or drag.

const DRAG_PX := 8.0
const LONG_PRESS_S := 0.45
const WHEEL_STEP := 1.15

## "idle", "pressed", "dragging", "long_pressed", "pinch" or "ignore".
var _mode := "idle"
## id → {start, pos, t0, button}
var _pointers := {}
var _primary := -1
var _pinch_ids: Array[int] = []
var _pinch_dist := 0.0
var _pinch_mid := Vector2.ZERO


func down(id: int, pos: Vector2, t: float, button := MOUSE_BUTTON_LEFT) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _pointers.has(id):
		# Its release never arrived (focus moved away mid-gesture): start over.
		out.append_array(reset())
	_pointers[id] = {"start": pos, "pos": pos, "t0": t, "button": button}
	match _mode:
		"idle":
			_mode = "pressed"
			_primary = id
		"pressed", "dragging", "long_pressed":
			if _mode == "dragging":
				out.append({"type": "drag_cancel"})
			_mode = "pinch"
			_pinch_ids = [_primary, id]
			_pinch_dist = _pinch_distance()
			_pinch_mid = _pinch_midpoint()
	return out


func move(id: int, pos: Vector2, t: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not _pointers.has(id):
		return out
	_pointers[id]["pos"] = pos
	match _mode:
		"pressed":
			if id != _primary:
				return out
			var start: Vector2 = _pointers[id]["start"]
			if pos.distance_to(start) > DRAG_PX:
				if _pointers[id]["button"] == MOUSE_BUTTON_LEFT:
					_mode = "dragging"
					out.append({"type": "drag_start", "at": start})
					out.append({"type": "drag_move", "at": pos})
				else:
					_mode = "ignore"
		"dragging":
			if id == _primary:
				out.append({"type": "drag_move", "at": pos})
		"pinch":
			if id in _pinch_ids:
				var dist := _pinch_distance()
				var mid := _pinch_midpoint()
				out.append({"type": "zoom", "at": mid, "factor": dist / _pinch_dist if _pinch_dist > 0.0 else 1.0})
				out.append({"type": "pan", "delta": mid - _pinch_mid})
				_pinch_dist = dist
				_pinch_mid = mid
	return out


func up(id: int, pos: Vector2, t: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not _pointers.has(id):
		return out
	var p: Dictionary = _pointers[id]
	_pointers.erase(id)
	match _mode:
		"pressed":
			if id == _primary:
				var kind := "tap" if p["button"] == MOUSE_BUTTON_LEFT else "secondary_tap"
				out.append({"type": kind, "at": p["start"]})
		"dragging":
			if id == _primary:
				out.append({"type": "drag_end", "at": pos})
		"pinch":
			if id in _pinch_ids:
				_mode = "ignore"
	if _pointers.is_empty():
		_mode = "idle"
		_primary = -1
	elif id == _primary and _mode != "ignore":
		_mode = "ignore"
	return out


## A pointer the system took back (a cancelled touch): it ends without a tap
## or a drop, and a drag in progress is cancelled. Other fingers still down
## are ignored until they lift.
func cancel(id: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not _pointers.has(id):
		return out
	_pointers.erase(id)
	if _mode == "dragging" and id == _primary:
		out.append({"type": "drag_cancel"})
	if _pointers.is_empty():
		_mode = "idle"
		_primary = -1
	else:
		_mode = "ignore"
	return out


## Forgets every pointer (focus lost, or the layer stopped taking input); a
## drag in progress is cancelled.
func reset() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _mode == "dragging":
		out.append({"type": "drag_cancel"})
	_pointers.clear()
	_mode = "idle"
	_primary = -1
	_pinch_ids = []
	return out


## Fires a long press once a left press has been held still long enough.
func tick(t: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _mode == "pressed" and _pointers.has(_primary):
		var p: Dictionary = _pointers[_primary]
		if p["button"] == MOUSE_BUTTON_LEFT and t - float(p["t0"]) >= LONG_PRESS_S:
			_mode = "long_pressed"
			out.append({"type": "long_press", "at": p["start"]})
	return out


## Positive steps zoom in (one step = ×1.15).
func wheel(pos: Vector2, steps: float) -> Array[Dictionary]:
	return [{"type": "zoom", "at": pos, "factor": pow(WHEEL_STEP, steps)}]


## A trackpad pinch.
func magnify(pos: Vector2, factor: float) -> Array[Dictionary]:
	return [{"type": "zoom", "at": pos, "factor": factor}]


## A trackpad two-finger scroll.
func pan_gesture(delta: Vector2) -> Array[Dictionary]:
	return [{"type": "pan", "delta": delta}]


func _pinch_distance() -> float:
	return (_pointers[_pinch_ids[0]]["pos"] as Vector2).distance_to(_pointers[_pinch_ids[1]]["pos"])


func _pinch_midpoint() -> Vector2:
	return ((_pointers[_pinch_ids[0]]["pos"] as Vector2) + (_pointers[_pinch_ids[1]]["pos"] as Vector2)) / 2.0
