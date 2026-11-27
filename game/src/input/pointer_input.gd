class_name PointerInput
extends Node
## Feeds touch, mouse, wheel and trackpad events to a GestureRecognizer and
## emits the gestures. Mouse events that Godot emulates from touch are ignored,
## so a touch never counts twice. Pass PointerInput.now() as the time.

signal gesture(g: Dictionary)

const MOUSE_ID := 1000

var recognizer := GestureRecognizer.new()


static func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _process(_delta: float) -> void:
	_emit(recognizer.tick(now()))


## Drops whatever gesture is under way (a drag is cancelled, not dropped).
func reset() -> void:
	_emit(recognizer.reset())


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		reset()


func feed(e: InputEvent, t: float) -> void:
	if e is InputEventScreenTouch:
		var touch := e as InputEventScreenTouch
		if touch.canceled:
			_emit(recognizer.cancel(touch.index))
		elif touch.pressed:
			_emit(recognizer.down(touch.index, touch.position, t))
		else:
			_emit(recognizer.up(touch.index, touch.position, t))
	elif e is InputEventScreenDrag:
		var drag := e as InputEventScreenDrag
		_emit(recognizer.move(drag.index, drag.position, t))
	elif e is InputEventMouseButton:
		if e.device == InputEvent.DEVICE_ID_EMULATION:
			return
		var b := e as InputEventMouseButton
		match b.button_index:
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if b.pressed:
					var steps := b.factor if b.factor > 0.0 else 1.0
					_emit(recognizer.wheel(b.position, steps if b.button_index == MOUSE_BUTTON_WHEEL_UP else -steps))
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if b.canceled:
					_emit(recognizer.cancel(MOUSE_ID))
				elif b.pressed:
					_emit(recognizer.down(MOUSE_ID, b.position, t, b.button_index))
				else:
					_emit(recognizer.up(MOUSE_ID, b.position, t))
	elif e is InputEventMouseMotion:
		if e.device != InputEvent.DEVICE_ID_EMULATION:
			_emit(recognizer.move(MOUSE_ID, (e as InputEventMouseMotion).position, t))
	elif e is InputEventMagnifyGesture:
		var m := e as InputEventMagnifyGesture
		_emit(recognizer.magnify(m.position, m.factor))
	elif e is InputEventPanGesture:
		_emit(recognizer.pan_gesture((e as InputEventPanGesture).delta))


func _emit(gs: Array[Dictionary]) -> void:
	for g in gs:
		gesture.emit(g)
