extends Node3D
## The real-looking workbench with every kind of part: the L1 circuit with live
## current, a meter loop with two multimeters, an LED burnt straight across a
## battery, and a row of spare parts. --view=<grid units> and --center=<x>,<y>
## frame the camera; --quality=<preset> overrides auto.

var bench: Workbench3D


func _ready() -> void:
	var settings := Progress.DEFAULT_SETTINGS.duplicate()
	var view := 80.0
	var center := Vector2(2, 18)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--view="):
			view = float(arg.substr(7))
		elif arg.begins_with("--center="):
			var xy := arg.substr(9).split(",")
			center = Vector2(float(xy[0]), float(xy[1]))
		elif arg.begins_with("--quality="):
			settings["quality"] = arg.substr(10)
	var c := Circuit.new()
	_loop(c, "1", Vector2(0, 0), {"ohms": 220.0}, {"color": "red"})
	_meter_loop(c, Vector2(0, 14))
	c.parts.append(Part.make("B3", "battery", -6, 28))
	c.parts.append(Part.make("L3", "led", -2, 24, 0, {"color": "green"}))
	c.wires.append(Wire.make("w31", "B3", "pos", "L3", "anode"))
	c.wires.append(Wire.make("w32", "L3", "cathode", "B3", "neg"))
	c.parts.append(Part.make("R9", "resistor", -4, 36, 0, {"ohms": 47.0, "watts": 1.0}))
	c.parts.append(Part.make("S1", "switch", 4, 36, 0, {"label": "A"}))
	c.parts.append(Part.make("S2", "switch", 4, 40, 0, {"label": "B", "closed": true}))
	c.parts.append(Part.make("L9", "led", -4, 40, 0, {"color": "yellow"}))
	c.parts.append(Part.make("R8", "resistor", 10, 38, 90, {"ohms": 1000.0}))
	var out := Simulator.simulate(c)
	bench = Workbench3D.new()
	add_child(bench)
	bench.set_state(out.circuit, out.result, settings, {}, [])
	bench.apply_view(center, view)


func _loop(c: Circuit, n: String, at: Vector2, r_props: Dictionary, led_props: Dictionary) -> void:
	var b := "B" + n
	var r := "R" + n
	var l := "L" + n
	c.parts.append(Part.make(b, "battery", int(at.x) - 6, int(at.y)))
	c.parts.append(Part.make(r, "resistor", int(at.x) - 2, int(at.y) - 4, 0, r_props))
	c.parts.append(Part.make(l, "led", int(at.x) + 6, int(at.y), 90, led_props))
	c.wires.append(Wire.make("w%s1" % n, b, "pos", r, "a"))
	c.wires.append(Wire.make("w%s2" % n, r, "b", l, "anode"))
	c.wires.append(Wire.make("w%s3" % n, l, "cathode", b, "neg"))


func _meter_loop(c: Circuit, at: Vector2) -> void:
	var x := int(at.x)
	var y := int(at.y)
	c.parts.append(Part.make("B2", "battery", x - 6, y))
	c.parts.append(Part.make("R2", "resistor", x - 2, y - 4, 0, {"ohms": 500.0, "adjustable": true}))
	c.parts.append(Part.make("M1", "ammeter", x + 6, y, 90))
	c.parts.append(Part.make("V1", "voltmeter", x - 2, y - 7))
	c.wires.append(Wire.make("w21", "B2", "pos", "R2", "a"))
	c.wires.append(Wire.make("w22", "R2", "b", "M1", "a"))
	c.wires.append(Wire.make("w23", "M1", "b", "B2", "neg"))
	c.wires.append(Wire.make("w24", "V1", "pos", "R2", "a"))
	c.wires.append(Wire.make("w25", "V1", "neg", "R2", "b"))
