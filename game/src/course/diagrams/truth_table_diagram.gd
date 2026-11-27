extends Diagram
## Lessons 5 and 6: every case of two switches, A and B, and what the LED did.
## Row n is A = n >> 1 and B = n & 1 (0 open, 1 closed). A row fills in once
## Try it has seen its case, from what the LED really did; until then the
## LED shows "?". On a Learn card, a soft highlight walks down the cases.

const LED_TINT := Color("#FF8F9A")
const COLS: Array[float] = [132.0, 204.0, 284.0]

## Per row: -1 not seen yet, 0 the LED was dark, 1 it was lit.
var _results: Array[int] = [-1, -1, -1, -1]


## The row for switch A and switch B closed or open.
static func row_of(a_closed: bool, b_closed: bool) -> int:
	return (2 if a_closed else 0) + (1 if b_closed else 0)


func results() -> Array:
	var out: Array = []
	out.assign(_results)
	return out


## Try it saw row `row`'s case, with the LED lit or not. The first sighting
## stays.
func mark(row: int, lit: bool) -> void:
	if row < 0 or row > 3 or _results[row] != -1:
		return
	_results[row] = 1 if lit else 0
	queue_redraw()


func _paint(time: float) -> void:
	label(Vector2(COLS[0], 22), "A", 18.0, col("ink"), true)
	label(Vector2(COLS[1], 22), "B", 18.0, col("ink"), true)
	label(Vector2(COLS[2], 22), "LED", 18.0, col("ink"), true)
	line(PackedVector2Array([Vector2(90, 38), Vector2(326, 38)]), col("ink_soft"), 1.5)
	var walk := -1 if still else int(fmod(time / 1.2, 4.0))
	for row in 4:
		var y := 58.0 + row * 34.0
		var seen := _results[row]
		var fill := Color(0, 0, 0, 0)
		if seen == 1:
			fill = col("mint")
		elif seen == 0:
			fill = col("line")
		elif row == walk:
			fill = Color(col("lavender"), 0.35)
		var under := col("paper").blend(fill)
		if fill.a > 0.0:
			box(Rect2(94, y - 15, 230, 30), 8.0, fill)
		label(Vector2(COLS[0], y), str(row >> 1), 18.0, col("ink"), true, under)
		label(Vector2(COLS[1], y), str(row & 1), 18.0, col("ink"), true, under)
		if seen < 0:
			label(Vector2(COLS[2], y), "?", 18.0, col("ink_soft"), true, under)
		else:
			var lit := seen == 1
			if lit:
				DrawKit.glow(self, Vector2(COLS[2] - 16, y), 10.0, Color(LED_TINT, 0.7), _k)
			dot(Vector2(COLS[2] - 16, y), 6.0, LED_TINT if lit else Color("#8A8494"), Palette.color("ink"), 1.0)
			label(Vector2(COLS[2] + 10, y), "1 on" if lit else "0 off", 15.0, col("ink"), true, under)
	label(Vector2(208, 204), "0 = open, 1 = closed", 13.0, col("ink_soft"))
