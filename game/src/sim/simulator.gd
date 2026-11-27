class_name Simulator
extends RefCounted
## Solves a circuit, burns out the most overloaded part (if any), and repeats
## until nothing else burns, up to 10 burns.

const MAX_BURNS := 10


static func simulate(c: Circuit) -> SimOutcome:
	var out := SimOutcome.new()
	var circuit := c
	while true:
		var n := Netlist.build(circuit)
		var s := DcSolver.solve(n)
		var flows := CurrentFlow.connector_amps(n, s)
		var found := Damage.detect(circuit, n, s, flows)
		if found.is_empty() or out.damage.size() >= MAX_BURNS:
			out.result = _result(circuit, n, s, flows)
			out.circuit = circuit
			return out
		out.damage.append(found[0])
		circuit = CircuitEdits.set_props(circuit, found[0]["part"], {"burnt": true})
	return out


static func _result(c: Circuit, n: Netlist, s: DcSolution, flows: Dictionary) -> SimResult:
	var r := SimResult.new()
	r.converged = s.converged
	r.net_of = n.net_of
	r.net_volts = s.net_volts
	r.floating = n.floating
	r.component_of_net = n.component_of_net
	r.part_amps = s.device_amps.duplicate()
	r.part_watts = s.device_watts.duplicate()
	for e in n.connectors:
		if e["kind"] == "wire":
			r.wire_amps[e["id"]] = flows.get(e["id"], 0.0)
		else:
			r.connector_amps[e["id"]] = flows.get(e["id"], 0.0)
	for p in c.parts:
		if not r.part_amps.has(p.id):
			r.part_amps[p.id] = r.connector_amps.get(p.id, 0.0)
		match p.kind:
			"ammeter":
				var readable := not bool(p.props.get("burnt", false)) and not r.is_floating(p.id, "a")
				r.meter[p.id] = r.part_amps[p.id] if readable else NAN
			"voltmeter":
				r.meter[p.id] = _voltmeter_reading(r, p)
			"battery":
				if absf(r.part_amps.get(p.id, 0.0)) > Devices.SHORT_AMPS:
					r.shorts.append(p.id)
	return r


## Readable when both probes are on powered nets of the same component.
static func _voltmeter_reading(r: SimResult, p: Part) -> float:
	var kp := Netlist.key(p.id, "pos")
	var kn := Netlist.key(p.id, "neg")
	if r.is_floating(p.id, "pos") or r.is_floating(p.id, "neg"):
		return NAN
	if r.component_of_net[r.net_of[kp]] != r.component_of_net[r.net_of[kn]]:
		return NAN
	return r.net_volts[r.net_of[kp]] - r.net_volts[r.net_of[kn]]
