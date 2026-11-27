class_name LevelTests
extends RefCounted
## Runs a level's test cases against the player's circuit, the way an engineer
## checks a design: set the inputs, measure, compare. The player's circuit is
## never changed. A level without tests has nothing to disprove, so it passes.


static func run(level: LevelDef, c: Circuit) -> Dictionary:
	var cases: Array[Dictionary] = []
	var all_pass := true
	for t in level.tests:
		var report := _run_case(t, c)
		cases.append(report)
		all_pass = all_pass and bool(report["pass"])
	return {"pass": all_pass, "cases": cases}


static func _run_case(t: Dictionary, c: Circuit) -> Dictionary:
	var circuit := c
	var messages := PackedStringArray()
	for s in t.get("set", []):
		var p := circuit.find_part(str(s["target"]))
		if p == null:
			messages.append("Missing part: %s" % s["target"])
			continue
		circuit = CircuitEdits.set_props(circuit, p.id, {s["prop"]: s["value"]})
	if messages.is_empty():
		var out := Simulator.simulate(circuit)
		var ctx := {"circuit": out.circuit, "sim": out.result, "zoom_layer": "", "zoom_seen": {}, "ui_flags": {}}
		for r in Goals.evaluate_all(t.get("expect", []), ctx):
			if not r["pass"]:
				messages.append(r["message"])
	return {"name": t["name"], "pass": messages.is_empty(), "messages": messages}
