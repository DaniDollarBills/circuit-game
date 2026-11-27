class_name InputMode
extends RefCounted
## Whether the player is using a finger or a mouse, from the last input: the
## moving hand shows a fingertip or a pointer to match. Phones start on touch.

static var mode := ""


static func current() -> String:
	if mode == "":
		var touchy := OS.has_feature("mobile") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())
		return "touch" if touchy else "mouse"
	return mode


## Notes a real input event (a finger's emulated mouse events don't count).
static func note(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		mode = "touch"
	elif (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() < 2.0:
			return
		mode = "mouse"
