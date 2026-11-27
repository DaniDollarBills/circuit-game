class_name CurrentFlow
extends RefCounted
## Works out how much current runs along each wire and closed switch.
## Inside one net, every connector is a conductance between pins, and each pin
## injects the current its device pushes into the net. Solving that small
## network gives every connector's current (a→b positive).


static func connector_amps(n: Netlist, s: DcSolution) -> Dictionary:
	var injection := _pin_injections(n, s)
	var pins_by_net := {}
	for k in n.net_of:
		var net: int = n.net_of[k]
		if not pins_by_net.has(net):
			pins_by_net[net] = PackedStringArray()
		pins_by_net[net].append(k)
	var edges_by_net := {}
	for e in n.connectors:
		var net: int = n.net_of[e["a"]]
		if not edges_by_net.has(net):
			edges_by_net[net] = []
		edges_by_net[net].append(e)

	var out := {}
	for net in edges_by_net:
		var pins: PackedStringArray = pins_by_net[net]
		var edges: Array = edges_by_net[net]
		var index := {}
		for i in pins.size():
			index[pins[i]] = i
		var m := pins.size() - 1
		var phi := PackedFloat64Array()
		phi.resize(pins.size())
		if m > 0:
			# Laplacian with pin 0 held at 0 V (row and column 0 removed).
			var lap := PackedFloat64Array()
			lap.resize(m * m)
			var rhs := PackedFloat64Array()
			rhs.resize(m)
			for e in edges:
				var a: int = index[e["a"]] - 1
				var b: int = index[e["b"]] - 1
				var g: float = e["g"]
				if a >= 0:
					lap[a * m + a] += g
				if b >= 0:
					lap[b * m + b] += g
				if a >= 0 and b >= 0:
					lap[a * m + b] -= g
					lap[b * m + a] -= g
			for i in range(1, pins.size()):
				rhs[i - 1] = injection.get(pins[i], 0.0)
			var sol := DenseSolver.solve(lap, rhs, m)
			if sol.size() == m:
				for i in m:
					phi[i + 1] = sol[i]
		for e in edges:
			var g: float = e["g"]
			out[e["id"]] = g * (phi[index[e["a"]]] - phi[index[e["b"]]])
	return out


## Current each device pushes into the net at each of its pins.
static func _pin_injections(n: Netlist, s: DcSolution) -> Dictionary:
	var inj := {}
	for d in n.devices:
		var p: Part = d["part"]
		var amps: float = s.device_amps.get(p.id, 0.0)
		var pins := Catalog.pin_names(p.kind)
		var k0 := Netlist.key(p.id, pins[0])
		var k1 := Netlist.key(p.id, pins[1])
		var sign := 1.0 if d["kind"] == "battery" else -1.0
		inj[k0] = inj.get(k0, 0.0) + sign * amps
		inj[k1] = inj.get(k1, 0.0) - sign * amps
	return inj
