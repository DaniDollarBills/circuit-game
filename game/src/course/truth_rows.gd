class_name TruthRows
extends RefCounted
## Lessons 5 and 6: which case two switches labeled A and B are in, and
## whether the LED (L1) is lit then. Row n is A = n >> 1 and B = n & 1
## (0 open, 1 closed), as in the truth table picture.


## The row for the circuit's switches A and B; -1 when it hasn't both.
static func row(c: Circuit) -> int:
	var a := _switch(c, "A")
	var b := _switch(c, "B")
	if a == null or b == null:
		return -1
	return (2 if bool(a.props.get("closed", false)) else 0) + (1 if bool(b.props.get("closed", false)) else 0)


static func lit(c: Circuit, sim: SimResult) -> bool:
	var ctx := {"circuit": c, "sim": sim, "zoom_layer": "editor", "zoom_seen": {}, "ui_flags": {}}
	return bool(Goals.evaluate({"kind": "led_lit", "part": "L1"}, ctx)["pass"])


static func _switch(c: Circuit, label: String) -> Part:
	for p in c.parts:
		if p.kind == "switch" and str(p.props.get("label", "")) == label:
			return p
	return null
