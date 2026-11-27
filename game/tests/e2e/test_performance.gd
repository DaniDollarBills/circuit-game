extends TestCase


## A 100-resistor ladder: a battery feeding 50 rungs, each a 220 Ω in series
## and a 1 kΩ across to the return rail.
func test_solver_speed() -> void:
	var c := Circuit.new()
	c.parts.append(Part.make("B1", "battery", -6, 0))
	var prev := ["B1", "pos"]
	for i in 50:
		var series := Part.make("RS%d" % i, "resistor", i * 6, -4, 0, {"ohms": 220.0})
		var shunt := Part.make("RP%d" % i, "resistor", i * 6 + 4, 0, 90, {"ohms": 1000.0})
		c.parts.append(series)
		c.parts.append(shunt)
		c.wires.append(Wire.make("ws%d" % i, prev[0], prev[1], series.id, "a"))
		c.wires.append(Wire.make("wp%d" % i, series.id, "b", shunt.id, "a"))
		c.wires.append(Wire.make("wr%d" % i, shunt.id, "b", "B1", "neg"))
		prev = [series.id, "b"]
	var t0 := Time.get_ticks_usec()
	var out := Simulator.simulate(c)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	assert_true(out.result.converged)
	assert_true(ms < 100.0, "took %.1f ms" % ms)
