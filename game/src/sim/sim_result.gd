class_name SimResult
extends RefCounted
## Everything the game shows about a simulated circuit.

var converged := false
var net_of: Dictionary = {}
var net_volts := PackedFloat64Array()
var floating: Dictionary = {}
var component_of_net := PackedInt32Array()
## Part id → amps (battery: out of pos; others: first pin → second pin).
var part_amps: Dictionary = {}
var part_watts: Dictionary = {}
## Wire id → amps from its `a` end to its `b` end.
var wire_amps: Dictionary = {}
## Closed switch id → amps a→b.
var connector_amps: Dictionary = {}
## Ammeter: amps a→b. Voltmeter: V(pos) − V(neg). NAN when not readable.
var meter: Dictionary = {}
## Batteries delivering more than 1 A.
var shorts: Array[String] = []


func pin_volts(part_id: String, pin: String) -> float:
	var k := Netlist.key(part_id, pin)
	if not net_of.has(k):
		return NAN
	var net: int = net_of[k]
	return NAN if floating.has(net) else net_volts[net]


func is_floating(part_id: String, pin: String) -> bool:
	var k := Netlist.key(part_id, pin)
	return not net_of.has(k) or floating.has(net_of[k])
