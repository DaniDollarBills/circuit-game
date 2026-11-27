class_name Netlist
extends RefCounted
## Turns a circuit into nets (groups of pins joined by wires or closed switches),
## devices (parts that conduct between nets), and components (nets joined by
## devices). Each component with a battery gets a reference net at 0 V; nets in
## components without a battery are floating.

const CONNECTOR_G := Devices.CONNECTOR_G

var net_of: Dictionary = {}
var net_count := 0
var component_count := 0
var component_of_net := PackedInt32Array()
var reference_net: Dictionary = {}
var floating: Dictionary = {}
var devices: Array[Dictionary] = []
var connectors: Array[Dictionary] = []
var voltmeters: Array[Part] = []


static func key(part_id: String, pin: String) -> String:
	return part_id + ":" + pin


static func build(c: Circuit) -> Netlist:
	var n := Netlist.new()
	var parent := {}
	for p in c.parts:
		for pin in Catalog.pin_names(p.kind):
			var k := key(p.id, pin)
			parent[k] = k
	for w in c.wires:
		var ka := key(w.a_part, w.a_pin)
		var kb := key(w.b_part, w.b_pin)
		if parent.has(ka) and parent.has(kb):
			_union(parent, ka, kb)
			n.connectors.append({"id": w.id, "kind": "wire", "a": ka, "b": kb, "g": CONNECTOR_G})
	for p in c.parts:
		if p.kind == "switch" and bool(p.props.get("closed", false)):
			var ka := key(p.id, "a")
			var kb := key(p.id, "b")
			_union(parent, ka, kb)
			n.connectors.append({"id": p.id, "kind": "switch", "a": ka, "b": kb, "g": CONNECTOR_G})

	var net_by_root := {}
	for p in c.parts:
		for pin in Catalog.pin_names(p.kind):
			var k := key(p.id, pin)
			var root: String = _find(parent, k)
			if not net_by_root.has(root):
				net_by_root[root] = n.net_count
				n.net_count += 1
			n.net_of[k] = net_by_root[root]

	for p in c.parts:
		var burnt := bool(p.props.get("burnt", false))
		match p.kind:
			"battery", "resistor", "led", "ammeter":
				if not burnt:
					n.devices.append(_device(n, p))
			"voltmeter":
				n.devices.append(_device(n, p))
				n.voltmeters.append(p)

	var comp_parent := PackedInt32Array()
	comp_parent.resize(n.net_count)
	for i in n.net_count:
		comp_parent[i] = i
	for d in n.devices:
		var nets: PackedInt32Array = d["nets"]
		_union_int(comp_parent, nets[0], nets[1])
	n.component_of_net.resize(n.net_count)
	var comp_by_root := {}
	for i in n.net_count:
		var root := _find_int(comp_parent, i)
		if not comp_by_root.has(root):
			comp_by_root[root] = n.component_count
			n.component_count += 1
		n.component_of_net[i] = comp_by_root[root]

	for d in n.devices:
		if d["kind"] == "battery":
			var neg: int = d["nets"][1]
			var comp := n.component_of_net[neg]
			if not n.reference_net.has(comp):
				n.reference_net[comp] = neg
	for i in n.net_count:
		if not n.reference_net.has(n.component_of_net[i]):
			n.floating[i] = true
	return n


static func _device(n: Netlist, p: Part) -> Dictionary:
	var nets := PackedInt32Array()
	for pin in Catalog.pin_names(p.kind):
		nets.append(n.net_of[key(p.id, pin)])
	return {"part": p, "kind": p.kind, "nets": nets}


static func _find(parent: Dictionary, k: String) -> String:
	var root := k
	while parent[root] != root:
		root = parent[root]
	while parent[k] != root:
		var nxt: String = parent[k]
		parent[k] = root
		k = nxt
	return root


static func _union(parent: Dictionary, a: String, b: String) -> void:
	var ra := _find(parent, a)
	var rb := _find(parent, b)
	if ra != rb:
		parent[rb] = ra


static func _find_int(parent: PackedInt32Array, i: int) -> int:
	while parent[i] != i:
		parent[i] = parent[parent[i]]
		i = parent[i]
	return i


static func _union_int(parent: PackedInt32Array, a: int, b: int) -> void:
	var ra := _find_int(parent, a)
	var rb := _find_int(parent, b)
	if ra != rb:
		parent[rb] = ra
