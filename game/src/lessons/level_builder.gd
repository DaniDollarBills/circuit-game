class_name LevelBuilder
extends RefCounted
## Builds a LevelDef with chained calls; every method returns the builder.
## Solution edits are kept in order and applied to a copy of the start circuit
## by done(), after every tray item is known.

var _level := LevelDef.new()
var _edits: Array[Dictionary] = []


func _init(level_id: String, chapter: String, title: String) -> void:
	_level.id = level_id
	_level.chapter = chapter
	_level.title = title


func summary(t: String) -> LevelBuilder:
	_level.summary = t
	return self


func kind(k: String) -> LevelBuilder:
	_level.kind = k
	return self


func part(part_id: String, part_kind: String, x: int, y: int, rot := 0, props := {}, locked := true) -> LevelBuilder:
	_level.circuit.parts.append(Part.make(part_id, part_kind, x, y, rot, props, locked))
	return self


func wire(wire_id: String, a_part: String, a_pin: String, b_part: String, b_pin: String, locked := true,
		via: Array[Vector2i] = []) -> LevelBuilder:
	_level.circuit.wires.append(Wire.make(wire_id, a_part, a_pin, b_part, b_pin, locked, via))
	return self


func tray(part_kind: String, props := {}, count := 1) -> LevelBuilder:
	_level.tray.append({"kind": part_kind, "props": props.duplicate(true), "count": count})
	return self


func goal(g: Dictionary) -> LevelBuilder:
	_level.goals.append(g)
	return self


func test(case_name: String, inputs: Array, expect: Array) -> LevelBuilder:
	_level.tests.append({"name": case_name, "set": inputs, "expect": expect})
	return self


func hint(text: String, highlight := [], show_solution := false) -> LevelBuilder:
	_level.hints.append({"text": text, "highlight": highlight, "show_solution": show_solution})
	return self


func solution_part(part_id: String, part_kind: String, x: int, y: int, rot := 0, props := {}) -> LevelBuilder:
	_edits.append({"op": "part", "part": Part.make(part_id, part_kind, x, y, rot, props)})
	return self


func solution_wire(a_part: String, a_pin: String, b_part: String, b_pin: String) -> LevelBuilder:
	_edits.append({"op": "wire", "a_part": a_part, "a_pin": a_pin, "b_part": b_part, "b_pin": b_pin})
	return self


func solution_props(part_id: String, patch: Dictionary) -> LevelBuilder:
	_edits.append({"op": "props", "id": part_id, "patch": patch.duplicate(true)})
	return self


func solution_remove_wire(wire_id: String) -> LevelBuilder:
	_edits.append({"op": "remove_wire", "id": wire_id})
	return self


func learn_goals(goals: Array) -> LevelBuilder:
	_level.learn_goals = PackedStringArray(goals)
	return self


## One idea, with an optional diagram, Go deeper line and source.
func idea(text: String, diagram := "", mood := "curious", deeper := "", source := "") -> LevelBuilder:
	return _card({"type": "idea", "text": text, "diagram": diagram, "mood": mood, "deeper": deeper, "source": source})


## A picture analogy and where it stops being true.
func analogy(text: String, breaks: String, diagram: String, deeper := "") -> LevelBuilder:
	return _card({"type": "analogy", "text": text, "breaks": breaks, "diagram": diagram, "mood": "curious", "deeper": deeper})


## A formula solved one step at a time.
func worked(text: String, steps: Array, source := "") -> LevelBuilder:
	return _card({"type": "worked", "text": text, "steps": PackedStringArray(steps), "mood": "curious", "source": source})


## A Meet the part card for a PartIntros key.
func meet(part_key: String) -> LevelBuilder:
	return _card({"type": "meet", "text": "", "part": part_key, "mood": "happy"})


## A new control, shown with the moving hand in a diagram.
func control(text: String, diagram: String) -> LevelBuilder:
	return _card({"type": "control", "text": text, "diagram": diagram, "mood": "happy"})


func real(text: String, diagram := "") -> LevelBuilder:
	return _card({"type": "real", "text": text, "diagram": diagram, "mood": "happy"})


func history(text: String, source: String) -> LevelBuilder:
	return _card({"type": "history", "text": text, "source": source, "mood": "wow"})


## Lesson 0's tour: a card that spotlights part of the screen.
func tour(text: String, target: String, mood := "happy") -> LevelBuilder:
	return _card({"type": "tour", "text": text, "target": target, "mood": mood})


func _card(c: Dictionary) -> LevelBuilder:
	_level.learn.append(c)
	return self


func outro(text: String, mood := "wow") -> LevelBuilder:
	_level.outro.append({"text": text, "mood": mood})
	return self


func fact(text: String, source: String) -> LevelBuilder:
	_level.facts.append({"text": text, "source": source})
	return self


func star(g: Dictionary, text: String) -> LevelBuilder:
	_level.star = {"goal": g, "text": text}
	return self


func step(text: String, check: Dictionary) -> LevelBuilder:
	_level.steps.append({"text": text, "check": check})
	return self


## Why the last step matters.
func why(text: String) -> LevelBuilder:
	_level.steps[-1]["why"] = text
	return self


## The moving hand's demo for the last step: {gesture, from, to?, key?,
## mouse?} where `mouse` overrides the gesture for mouse players.
func demo(spec: Dictionary) -> LevelBuilder:
	_level.steps[-1]["demo"] = spec.duplicate(true)
	return self


func try_it(prompt: String) -> LevelBuilder:
	_level.try_prompt = prompt
	return self


func try_part(part_id: String, part_kind: String, x: int, y: int, rot := 0, props := {}, locked := true) -> LevelBuilder:
	_level.try_circuit.parts.append(Part.make(part_id, part_kind, x, y, rot, props, locked))
	return self


func try_wire(wire_id: String, a_part: String, a_pin: String, b_part: String, b_pin: String, locked := false,
		via: Array[Vector2i] = []) -> LevelBuilder:
	_level.try_circuit.wires.append(Wire.make(wire_id, a_part, a_pin, b_part, b_pin, locked, via))
	return self


func try_tray(part_kind: String, props := {}, count := 1) -> LevelBuilder:
	_level.try_tray.append({"kind": part_kind, "props": props.duplicate(true), "count": count})
	return self


func poke(text: String, check: Dictionary) -> LevelBuilder:
	_level.pokes.append({"text": text, "check": check})
	return self


func readout(part_id: String, quantity: String) -> LevelBuilder:
	_level.readouts.append({"part": part_id, "quantity": quantity})
	return self


## The next circuit a player could reach while trying: `edit` applied to the
## last one (the try circuit to begin with).
func try_path_edit(edit: Callable) -> LevelBuilder:
	var last: Circuit = _level.try_path[-1] if not _level.try_path.is_empty() else _level.try_circuit
	var next: Circuit = edit.call(last.copy())
	_level.try_path.append(next)
	return self


func recap(text: String) -> LevelBuilder:
	_level.recap.append(text)
	return self


## A quick question: three choices, one correct, each with its explanation.
func question(prompt: String, choices: Array) -> LevelBuilder:
	_level.questions.append({"prompt": prompt, "choices": choices.duplicate(true)})
	return self


func formula(formula_name: String) -> LevelBuilder:
	_level.formula = formula_name
	return self


func done() -> LevelDef:
	var s := _level.circuit.copy()
	for e in _edits:
		match e["op"]:
			"part":
				var p: Part = (e["part"] as Part).copy()
				p.tray = _tray_index(p.kind, p.props)
				s.parts.append(p)
			"wire":
				s.wires.append(Wire.make(CircuitEdits.next_id(s, "w"), e["a_part"], e["a_pin"], e["b_part"], e["b_pin"]))
			"props":
				s = CircuitEdits.set_props(s, e["id"], e["patch"])
			"remove_wire":
				var id: String = e["id"]
				s.wires = s.wires.filter(func(w: Wire) -> bool: return w.id != id)
	_level.solution = s
	return _level


## The first tray item of this kind whose props (filled from the catalog
## defaults) all match; -1 when none does.
func _tray_index(part_kind: String, props: Dictionary) -> int:
	for i in _level.tray.size():
		var item: Dictionary = _level.tray[i]
		if item["kind"] != part_kind:
			continue
		var want := Catalog.defaults(part_kind).duplicate(true)
		want.merge(item["props"], true)
		var matches := true
		for key in want:
			if not SolutionDiff.same_value(props.get(key), want[key]):
				matches = false
				break
		if matches:
			return i
	return -1
