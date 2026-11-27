class_name DcSolver
extends RefCounted
## DC operating point by modified nodal analysis with Newton iterations.
## LEDs are a series resistance plus a Shockley junction (internal node between).

const MAX_ITERATIONS := 100
const VOLT_TOLERANCE := 1e-9
const JUNCTION_TOLERANCE := 1e-6


static func solve(n: Netlist) -> DcSolution:
	var sol := DcSolution.new()
	var var_of_net := PackedInt32Array()
	var_of_net.resize(n.net_count)
	var unknowns := 0
	var ref_nets := {}
	for comp in n.reference_net:
		ref_nets[n.reference_net[comp]] = true
	for i in n.net_count:
		if n.floating.has(i) or ref_nets.has(i):
			var_of_net[i] = -1
		else:
			var_of_net[i] = unknowns
			unknowns += 1

	# LEDs in powered components get an internal node.
	var leds: Array[Dictionary] = []
	for d in n.devices:
		if d["kind"] == "led" and not n.floating.has(d["nets"][0]):
			var isat := Devices.led_isat(str(d["part"].props.get("color", "red")))
			leds.append({"device": d, "internal": unknowns, "isat": isat, "vcrit": Devices.led_vcrit(isat)})
			unknowns += 1

	var x := PackedFloat64Array()
	x.resize(unknowns)
	var vd := PackedFloat64Array()
	vd.resize(leds.size())
	var result := _newton(n, var_of_net, leds, unknowns, 1.0, x, vd)
	if not result["converged"]:
		x.fill(0.0)
		vd.fill(0.0)
		# Source stepping: ramp the batteries up in 10 steps, warm-starting each.
		# Only the final full-voltage step decides convergence.
		for step in range(1, 11):
			result = _newton(n, var_of_net, leds, unknowns, step / 10.0, x, vd)
	sol.converged = result["converged"]
	sol.iterations = result["iterations"]
	_fill_outputs(sol, n, var_of_net, leds, x)
	return sol


## Runs Newton at a battery scale `s`, updating `x` and `vd` in place.
static func _newton(n: Netlist, var_of_net: PackedInt32Array, leds: Array[Dictionary], unknowns: int,
		s: float, x: PackedFloat64Array, vd: PackedFloat64Array) -> Dictionary:
	if unknowns == 0:
		return {"converged": true, "iterations": 0}
	var nvt := Devices.led_nvt()
	for iteration in MAX_ITERATIONS:
		var g := PackedFloat64Array()
		g.resize(unknowns * unknowns)
		var rhs := PackedFloat64Array()
		rhs.resize(unknowns)
		for i in unknowns:
			g[i * unknowns + i] += Devices.GMIN
		for d in n.devices:
			var nets: PackedInt32Array = d["nets"]
			var a := var_of_net[nets[0]]
			var b := var_of_net[nets[1]]
			match d["kind"]:
				"resistor":
					_stamp_g(g, unknowns, a, b, 1.0 / maxf(float(d["part"].props.get("ohms", 220.0)), 1e-3))
				"battery":
					var volts := float(d["part"].props.get("volts", 5.0)) * s
					_stamp_g(g, unknowns, a, b, 1.0 / Devices.BATTERY_OHMS)
					_stamp_i(rhs, b, a, volts / Devices.BATTERY_OHMS)
				"voltmeter":
					_stamp_g(g, unknowns, a, b, 1.0 / Devices.VOLTMETER_OHMS)
				"ammeter":
					_stamp_g(g, unknowns, a, b, 1.0 / Devices.AMMETER_OHMS)
		for k in leds.size():
			var led: Dictionary = leds[k]
			var nets: PackedInt32Array = led["device"]["nets"]
			var anode := var_of_net[nets[0]]
			var cathode := var_of_net[nets[1]]
			var internal: int = led["internal"]
			_stamp_g(g, unknowns, anode, internal, 1.0 / Devices.LED_SERIES_OHMS)
			var v_now := _v(x, internal) - _v(x, cathode)
			vd[k] = Devices.pnjlim(v_now, vd[k], nvt, led["vcrit"])
			var e := exp(minf(vd[k] / nvt, Devices.MAX_EXP_ARG))
			var isat: float = led["isat"]
			var gd := isat / nvt * e + Devices.GMIN
			var ieq := isat * (e - 1.0) - gd * vd[k]
			_stamp_g(g, unknowns, internal, cathode, gd)
			_stamp_i(rhs, internal, cathode, ieq)
		var x_new := DenseSolver.solve(g, rhs, unknowns)
		if x_new.is_empty():
			return {"converged": false, "iterations": iteration + 1}
		var max_dx := 0.0
		for i in unknowns:
			max_dx = maxf(max_dx, absf(x_new[i] - x[i]))
		var junction_ok := true
		for k in leds.size():
			var nets: PackedInt32Array = leds[k]["device"]["nets"]
			var vj := _v(x_new, leds[k]["internal"]) - _v(x_new, var_of_net[nets[1]])
			if absf(vj - vd[k]) > JUNCTION_TOLERANCE:
				junction_ok = false
		for i in unknowns:
			x[i] = x_new[i]
		if max_dx < VOLT_TOLERANCE and junction_ok:
			return {"converged": true, "iterations": iteration + 1}
	return {"converged": false, "iterations": MAX_ITERATIONS}


static func _fill_outputs(sol: DcSolution, n: Netlist, var_of_net: PackedInt32Array,
		leds: Array[Dictionary], x: PackedFloat64Array) -> void:
	sol.net_volts.resize(n.net_count)
	for i in n.net_count:
		if n.floating.has(i):
			sol.net_volts[i] = NAN
		else:
			sol.net_volts[i] = _v(x, var_of_net[i])
	var internal_of := {}
	for led in leds:
		internal_of[led["device"]["part"].id] = led["internal"]
	for d in n.devices:
		var p: Part = d["part"]
		var nets: PackedInt32Array = d["nets"]
		if n.floating.has(nets[0]):
			sol.device_amps[p.id] = 0.0
			sol.device_watts[p.id] = 0.0
			continue
		var va := sol.net_volts[nets[0]]
		var vb := sol.net_volts[nets[1]]
		var amps := 0.0
		var watts := 0.0
		match d["kind"]:
			"resistor":
				var ohms := maxf(float(p.props.get("ohms", 220.0)), 1e-3)
				amps = (va - vb) / ohms
				watts = amps * amps * ohms
			"battery":
				amps = (float(p.props.get("volts", 5.0)) - (va - vb)) / Devices.BATTERY_OHMS
				watts = (va - vb) * amps
			"led":
				var vint := _v(x, internal_of[p.id])
				amps = (va - vint) / Devices.LED_SERIES_OHMS
				watts = amps * (va - vb)
			"voltmeter":
				amps = (va - vb) / Devices.VOLTMETER_OHMS
				watts = amps * (va - vb)
			"ammeter":
				amps = (va - vb) / Devices.AMMETER_OHMS
				watts = amps * amps * Devices.AMMETER_OHMS
		sol.device_amps[p.id] = amps
		sol.device_watts[p.id] = watts


static func _v(x: PackedFloat64Array, index: int) -> float:
	return 0.0 if index < 0 else x[index]


## Conductance g between unknowns a and b (-1 is the component's reference).
static func _stamp_g(g: PackedFloat64Array, n: int, a: int, b: int, value: float) -> void:
	if a >= 0:
		g[a * n + a] += value
	if b >= 0:
		g[b * n + b] += value
	if a >= 0 and b >= 0:
		g[a * n + b] -= value
		g[b * n + a] -= value


## A current `value` leaving node `from` and entering node `to` through the source.
static func _stamp_i(rhs: PackedFloat64Array, from: int, to: int, value: float) -> void:
	if from >= 0:
		rhs[from] -= value
	if to >= 0:
		rhs[to] += value
