class_name GestureHand
extends Control
## The moving hand that shows a gesture where it's done: tap, drag, long
## press, pinch, scroll or a key. It loops until stopped, and follows the
## player's last input (a fingertip or a pointer). With Reduced motion it
## holds still at the start, with an arrow to where a drag ends.

## The press, the move, and the pause before it loops.
const PRESS_S := 0.3
const MOVE_S := 0.9
const LOOP_S := 1.8

var mode := "touch"
var still := false

var _gesture := ""
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _key := ""
var _t := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func play(gesture: String, from: Vector2, to := Vector2.ZERO, key := "") -> void:
	_gesture = gesture
	_from = from
	_to = to
	_key = key
	_t = 0.0
	mode = InputMode.current()
	visible = true
	queue_redraw()


## Moves the gesture's ends (the screen moved) without restarting it.
func retarget(from: Vector2, to := Vector2.ZERO) -> void:
	_from = from
	_to = to
	queue_redraw()


func gesture() -> String:
	return _gesture


func stop() -> void:
	_gesture = ""
	visible = false


func playing() -> bool:
	return _gesture != ""


## Moves time on by `seconds` (tests; _process does it while showing).
func advance(seconds: float) -> void:
	_t += seconds
	queue_redraw()


func _process(delta: float) -> void:
	if playing() and is_visible_in_tree() and not still:
		advance(delta)


## Where the hand is pressing now: a drag presses, eases to its end and
## rests there until the loop starts again.
func hand_position() -> Vector2:
	if _gesture != "drag" or still:
		return _from
	var k := clampf((fmod(_t, LOOP_S) - PRESS_S) / MOVE_S, 0.0, 1.0)
	return _from.lerp(_to, 0.5 - 0.5 * cos(PI * k))


func _pressed() -> bool:
	var c := fmod(_t, LOOP_S)
	match _gesture:
		"tap", "key":
			return c > PRESS_S and c < PRESS_S + 0.25
		"drag":
			return c > PRESS_S * 0.5 and c < PRESS_S + MOVE_S
		"long_press":
			return c > PRESS_S and c < LOOP_S - 0.2
	return false


func _draw() -> void:
	if not playing():
		return
	var at := hand_position()
	match _gesture:
		"drag":
			_trail(_from, _to)
		"long_press":
			var grow := clampf((fmod(_t, LOOP_S) - PRESS_S) / (LOOP_S - PRESS_S - 0.2), 0.0, 1.0)
			draw_arc(_from, 22.0, -PI / 2.0, -PI / 2.0 + TAU * grow, 32, Palette.color("lavender"), 4.0, true)
		"pinch":
			var spread := 18.0 + (0.0 if still else 22.0 * (0.5 - 0.5 * cos(TAU * fmod(_t, LOOP_S) / LOOP_S)))
			if mode == "touch":
				HandArt.draw(self, _from + Vector2(-spread, -spread) * 0.7, "touch", true)
				HandArt.draw(self, _from + Vector2(spread, spread) * 0.7, "touch", true)
				return
			_wheel(_from)
			return
		"scroll":
			_wheel(_from)
			return
		"key":
			_keycap(_from + Vector2(0, -48), _key)
	HandArt.draw(self, at, mode, _pressed())


## A dotted line from the start of a drag to its end, with an arrowhead.
func _trail(a: Vector2, b: Vector2) -> void:
	var ink := Color(Palette.color("lavender"), 0.9)
	var n := maxi(int(a.distance_to(b) / 14.0), 1)
	for i in n:
		draw_circle(a.lerp(b, float(i) / n), 3.0, ink, true, -1.0, true)
	var dir := (b - a).normalized()
	var side := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([b, b - dir * 14.0 + side * 8.0, b - dir * 14.0 - side * 8.0]), ink)


## A mouse with its wheel and up/down arrows: scroll to zoom.
func _wheel(at: Vector2) -> void:
	var ink := Palette.color("ink")
	var body := Rect2(at - Vector2(14, 20), Vector2(28, 40))
	draw_rect(body, Color.WHITE)
	draw_rect(body, ink, false, 2.0)
	var nudge := 0.0 if still else 3.0 * sin(TAU * fmod(_t, LOOP_S) / LOOP_S)
	draw_rect(Rect2(at + Vector2(-3, -13 + nudge), Vector2(6, 10)), Palette.color("lavender"))
	for side in [-1.0, 1.0]:
		var tip := at + Vector2(26, side * 18.0)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-7, -side * 9.0), tip + Vector2(7, -side * 9.0)]), ink)


func _keycap(at: Vector2, key: String) -> void:
	var font := get_theme_default_font()
	var w := maxf(36.0, font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 20.0)
	var r := Rect2(at - Vector2(w / 2.0, 18), Vector2(w, 36))
	var down := _pressed()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.color("lilac") if down else Color.WHITE
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Palette.color("ink")
	sb.draw(get_canvas_item(), r)
	draw_string(font, r.position + Vector2(10, 25), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Palette.color("ink"))
