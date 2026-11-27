extends TestCase

const CH1_IDS := ["ch1.light-it-up", "ch1.pop", "ch1.push-and-flow", "ch1.on-and-off", "ch1.both", "ch1.either",
		"ch1.short-circuit", "ch1.too-hot", "ch1.inside-the-wire"]
const CH1_TITLES := ["Light it up", "Pop!", "Push and flow", "On and off", "Both switches", "Either switch",
		"Short circuit!", "Too hot to handle", "Inside the wire"]
const LAYERS := ["editor", "wire.closeup", "wire.copper"]
const FORMULAS := ["led_resistor", "ohms_law", "power"]
const MOODS := ["happy", "curious", "wow", "oops"]


func _ctx(c: Circuit, layer := "editor", seen := {}, flags := {}) -> Dictionary:
	var out := Simulator.simulate(c)
	return {"circuit": out.circuit, "sim": out.result, "zoom_layer": layer, "zoom_seen": seen, "ui_flags": flags}


func _all_pass(results: Array[Dictionary]) -> bool:
	return results.all(func(r: Dictionary) -> bool: return r["pass"])


## A goal plus every goal nested inside it.
func _flatten(g: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = [g]
	if g.get("kind") == "all":
		for inner in g["goals"]:
			out.append_array(_flatten(inner))
	return out


## The flags and zoom layers a level's steps ask for.
func _step_needs(level: LevelDef) -> Dictionary:
	var flags := {}
	var seen := {}
	for st in level.steps:
		for g in _flatten(st["check"]):
			if g["kind"] == "ui_flag":
				flags[g["flag"]] = true
			elif g["kind"] == "zoom_reached":
				seen[g["layer"]] = true
	return {"flags": flags, "seen": seen}


func _part_by_id(c: Circuit, id: String) -> Part:
	for p in c.parts:
		if p.id == id:
			return p
	return null


## A part a level can refer to: in the start circuit or the solution, by id or label.
func _find(level: LevelDef, name: String) -> Part:
	var p := level.circuit.find_part(name)
	return p if p != null else level.solution.find_part(name)


func _check_refs(level: LevelDef, g: Dictionary, where: String) -> void:
	var at := "%s %s" % [level.id, where]
	assert_true(g.get("kind") in Goals.KINDS, "%s: unknown goal kind %s" % [at, g.get("kind")])
	if g.has("part"):
		assert_true(_find(level, g["part"]) != null, "%s: no part %s" % [at, g["part"]])
	for side in ["a", "b"]:
		if g.has(side):
			var spec: String = g[side]
			var p := _find(level, spec.get_slice(":", 0))
			var pin := spec.get_slice(":", 1)
			assert_true(p != null and (pin == "*" or Catalog.has_pin(p.kind, pin)), "%s: bad pin %s" % [at, spec])
	if g.has("part_kind"):
		assert_true(Catalog.has_kind(g["part_kind"]), "%s: no kind %s" % [at, g["part_kind"]])
	if g.has("layer"):
		assert_true(g["layer"] in LAYERS, "%s: no layer %s" % [at, g["layer"]])
	if g.has("flag"):
		var flag: String = g["flag"]
		var what := flag.get_slice(":", 0)
		var arg := flag.get_slice(":", 1)
		var known := flag == "tested" or flag == "datasheet:tray"
		match what:
			"datasheet", "value":
				known = known or _find(level, arg) != null
			"formula":
				known = arg in FORMULAS
			"selected":
				known = level.circuit.find_wire(arg) != null
		assert_true(known, "%s: unknown flag %s" % [at, flag])


## Every line of on-screen copy in a level, course text included: card text,
## analogy breaks, Go deeper lines, worked steps, steps' whys, the try prompt
## and pokes, recap points, and questions with their choices and why lines.
func _lines(level: LevelDef) -> PackedStringArray:
	var out := PackedStringArray([level.summary])
	out.append_array(level.learn_goals)
	for group in [level.learn, level.outro, level.hints, level.steps, level.facts, level.pokes]:
		for item in group:
			if str(item.get("text", "")) != "":
				out.append(item["text"])
	for c in level.learn:
		for key in ["breaks", "deeper"]:
			if str(c.get(key, "")) != "":
				out.append(c[key])
		out.append_array(c.get("steps", PackedStringArray()))
	for st in level.steps:
		if str(st.get("why", "")) != "":
			out.append(st["why"])
	if level.try_prompt != "":
		out.append(level.try_prompt)
	out.append_array(level.recap)
	for q in level.questions:
		out.append(q["prompt"])
		for ch in q["choices"]:
			out.append(ch["text"])
			out.append(ch["why"])
	if not level.star.is_empty():
		out.append(level.star["text"])
	return out


func test_nine_ch1_levels_in_order() -> void:
	assert_eq(Levels.chapter_ids("ch1"), PackedStringArray(CH1_IDS))
	assert_eq(Levels.all().map(func(l: LevelDef) -> String: return l.title), CH1_TITLES)
	assert_eq(Levels.by_id("ch1.pop").title, "Pop!")
	assert_true(Levels.by_id("ch1.nope") == null)


func test_ids_unique() -> void:
	var level_ids := {}
	for l in Levels.all():
		assert_false(level_ids.has(l.id), "duplicate level " + l.id)
		level_ids[l.id] = true
		for c in [l.circuit, l.solution]:
			var ids := {}
			for p in c.parts:
				assert_false(ids.has(p.id), "%s: duplicate id %s" % [l.id, p.id])
				ids[p.id] = true
			for w in c.wires:
				assert_false(ids.has(w.id), "%s: duplicate id %s" % [l.id, w.id])
				ids[w.id] = true


func test_every_solution_passes() -> void:
	for l in Levels.all():
		var needs := _step_needs(l)
		var ctx := _ctx(l.solution, "wire.copper" if l.kind == "zoom" else "editor", needs["seen"], needs["flags"])
		for r in Goals.evaluate_all(l.goals, ctx):
			assert_true(r["pass"], "%s goal: %s" % [l.id, r["message"]])
		var report := LevelTests.run(l, l.solution)
		assert_true(report["pass"], "%s tests: %s" % [l.id, report["cases"]])
		for i in l.steps.size():
			var r := Goals.evaluate(l.steps[i]["check"], ctx)
			assert_true(r["pass"], "%s step %d: %s" % [l.id, i + 1, r["message"]])


func test_every_level_follows_lesson_rules() -> void:
	for l in Levels.all():
		assert_eq(LessonRules.problems(l), PackedStringArray(), l.id)


func test_every_level_has_valid_steps() -> void:
	for l in Levels.all():
		assert_between(l.steps.size(), 2, 5, l.id)
		for i in l.steps.size():
			for g in _flatten(l.steps[i]["check"]):
				_check_refs(l, g, "step %d" % (i + 1))
		for g in l.goals:
			_check_refs(l, g, "goal")
		for t in l.tests:
			for g in t["expect"]:
				_check_refs(l, g, "test " + t["name"])
			for s in t["set"]:
				assert_true(_find(l, s["target"]) != null, "%s test target %s" % [l.id, s["target"]])
		if not l.star.is_empty():
			_check_refs(l, l.star["goal"], "star")
		assert_true(l.formula == "" or l.formula in FORMULAS, l.id)


func test_no_build_level_passes_at_start() -> void:
	for l in Levels.all():
		if l.kind != "build":
			continue
		var goals_pass := _all_pass(Goals.evaluate_all(l.goals, _ctx(l.circuit)))
		var tests_pass: bool = LevelTests.run(l, l.circuit)["pass"]
		assert_false(goals_pass and tests_pass, l.id + " is already solved at the start")


func test_start_parts_are_locked() -> void:
	for l in Levels.all():
		for p in l.circuit.parts:
			assert_true(p.locked, "%s: %s" % [l.id, p.id])


func test_solutions_use_only_start_and_tray_parts() -> void:
	for l in Levels.all():
		for p in l.circuit.parts:
			assert_true(_part_by_id(l.solution, p.id) != null, "%s: the solution drops %s" % [l.id, p.id])
		var used := {}
		for p in l.solution.parts:
			var start := _part_by_id(l.circuit, p.id)
			if start != null:
				assert_eq(start.kind, p.kind, l.id)
				continue
			var from_tray := p.tray >= 0 and p.tray < l.tray.size()
			assert_true(from_tray, "%s: %s isn't from the tray" % [l.id, p.id])
			if from_tray:
				assert_eq(l.tray[p.tray]["kind"], p.kind, l.id)
				used[p.tray] = int(used.get(p.tray, 0)) + 1
		for t in used:
			assert_true(used[t] <= int(l.tray[t]["count"]), "%s uses tray item %d too often" % [l.id, t])


func test_glossary_terms_exist() -> void:
	var markup := RegEx.create_from_string("\\[\\[(.+?)\\]\\]")
	for l in Levels.all():
		for line in _lines(l):
			for m in markup.search_all(line):
				var inner := m.get_string(1)
				if inner.begins_with("="):
					continue
				var ref := inner.get_slice("|", 0)
				assert_true(GlossaryText.resolve(ref) != "", "%s: unknown term [[%s]]" % [l.id, ref])


func test_hint_highlights_exist() -> void:
	for l in Levels.all():
		for h in l.hints:
			for spot in h["highlight"]:
				if spot.has("part"):
					var p := _find(l, spot["part"])
					assert_true(p != null, "%s: no part %s" % [l.id, spot["part"]])
					if p != null and spot.has("pin"):
						assert_true(Catalog.has_pin(p.kind, spot["pin"]), "%s: no pin %s" % [l.id, spot["pin"]])
				if spot.has("wire"):
					assert_true(l.circuit.find_wire(spot["wire"]) != null, "%s: no wire %s" % [l.id, spot["wire"]])


## Three tiers; only the third shows the solution, except in the zoom level.
func test_three_hint_tiers() -> void:
	for l in Levels.all():
		assert_eq(l.hints.size(), 3, l.id)
		if l.hints.size() != 3:
			continue
		assert_false(l.hints[0]["show_solution"] or l.hints[1]["show_solution"], l.id)
		assert_eq(l.hints[2]["show_solution"], l.kind != "zoom", l.id)


func test_copy_limits() -> void:
	var sentence_end := RegEx.create_from_string("[.!?](\\s|$)")
	for l in Levels.all():
		for line in _lines(l):
			var plain := GlossaryText.plain(line)
			var words := plain.split(" ", false).size()
			var sentences := maxi(1, sentence_end.search_all(plain).size())
			assert_true(words <= 30, "%s: %d words: %s" % [l.id, words, plain])
			assert_true(sentences <= 2, "%s: %d sentences: %s" % [l.id, sentences, plain])


func test_moods_are_known() -> void:
	for l in Levels.all():
		assert_false(l.learn.is_empty() or l.outro.is_empty(), l.id)
		for line in l.learn + l.outro:
			assert_true(line["mood"] in MOODS, "%s: mood %s" % [l.id, line["mood"]])


func test_chapters_list_13_and_ch1_playable() -> void:
	assert_eq(Chapters.ALL.size(), 13)
	for i in Chapters.ALL.size():
		var ch: Dictionary = Chapters.ALL[i]
		assert_eq(ch["id"], "ch%d" % (i + 1))
		assert_eq(ch["playable"], i == 0, ch["id"])
	assert_eq(Chapters.ALL[0], {"id": "ch1", "title": "Spark", "era": "1800s", "blurb": "Electricity: loops, LEDs and switches", "playable": true})
	assert_eq(Chapters.ALL[12]["title"], "Thinking Machines")


func test_l2_star_only_with_150() -> void:
	var l := Levels.by_id("ch1.pop")
	var values: Array = l.tray.map(func(t: Dictionary) -> float: return float(t["props"]["ohms"]))
	assert_eq(values, [47.0, 100.0, 150.0, 220.0, 330.0, 1000.0])
	for ohms in values:
		var out := Simulator.simulate(CircuitEdits.set_props(l.solution, "R1", {"ohms": ohms}))
		var ctx := {"circuit": out.circuit, "sim": out.result, "zoom_layer": "editor", "zoom_seen": {}, "ui_flags": {}}
		var results := Goals.evaluate_all(l.goals, ctx)
		var star: bool = Goals.evaluate(l.star["goal"], ctx)["pass"]
		var ma := float(out.result.part_amps["L1"]) * 1000.0
		match ohms:
			47.0:
				assert_true(out.circuit.find_part("L1").props.get("burnt", false), "47 Ω burns the LED")
				assert_false(_all_pass(results))
			100.0:
				assert_false(results[0]["pass"])
				assert_near(ma, 29.1, 0.05)
			150.0:
				assert_true(_all_pass(results) and star, "150 Ω passes with the star")
				assert_near(ma, 19.9, 0.05)
			_:
				assert_true(_all_pass(results), "%d Ω passes" % ohms)
				assert_false(star, "%d Ω earns no star" % ohms)


func test_l8_quarter_watt_burns_one_watt_passes() -> void:
	var l := Levels.by_id("ch1.too-hot")
	var quarter := Simulator.simulate(CircuitEdits.set_props(l.solution, "R1", {"watts": 0.25}))
	assert_true(quarter.circuit.find_part("R1").props.get("burnt", false))
	var qctx := {"circuit": quarter.circuit, "sim": quarter.result, "zoom_layer": "editor", "zoom_seen": {}, "ui_flags": {}}
	assert_false(_all_pass(Goals.evaluate_all(l.goals, qctx)))
	var one := Simulator.simulate(l.solution)
	assert_eq(one.damage.size(), 0)
	assert_near(float(one.result.part_watts["R1"]), 0.51, 0.005)


func test_every_fact_has_source() -> void:
	for l in Levels.all():
		for f in l.facts:
			assert_false(str(f["text"]).is_empty() or str(f["source"]).is_empty(), l.id)


func test_glossary_definition_lengths() -> void:
	assert_eq(Glossary.ENTRIES.size(), 58)
	for term in Glossary.ENTRIES:
		var e: Dictionary = Glossary.ENTRIES[term]
		assert_false(str(e["title"]).is_empty(), term)
		var simple: int = str(e["simple"]).split(" ", false).size()
		var precise: int = str(e["precise"]).split(" ", false).size()
		assert_true(simple <= 30, "%s simple: %d words" % [term, simple])
		assert_true(precise <= 40, "%s precise: %d words" % [term, precise])


func test_jargon_list_in_glossary() -> void:
	var words := ["electricity", "charge", "electron", "atom", "nucleus", "proton", "neutron", "element", "coulomb",
			"joule", "silicon", "silica", "crystal lattice", "internet", "undersea cable", "circuit", "conductor",
			"insulator", "current", "conventional current", "voltage", "resistance", "amp", "milliamp", "mA", "volt",
			"ohm", "Ohm's law", "LED", "diode", "semiconductor", "resistor", "carbon film", "tolerance", "battery",
			"internal resistance", "switch", "series", "parallel", "short circuit", "fuse", "current meter",
			"voltage meter", "burden", "input resistance", "power", "watt", "datasheet", "forward voltage",
			"absolute maximum", "standard values", "wavelength", "polarity", "anode", "cathode"]
	for w in words:
		var terms: PackedStringArray = GlossaryText.render(w, {})["terms"]
		assert_eq(terms.size(), 1, "%s → %s" % [w, terms])


## Datasheet rows link glossary terms, so every one must be defined.
func test_datasheet_terms_exist() -> void:
	for kind in Catalog.PARTS:
		for props in [{}, {"watts": 1.0}]:
			for row in Catalog.datasheet(Part.make("X1", kind, 0, 0, 0, props)):
				if row["term"] != "":
					assert_true(Glossary.ENTRIES.has(row["term"]), "%s: %s" % [kind, row["term"]])



## Checkpoint B (C2): energy in a circuit travels through the field around the
## wires, not with the drifting electrons, so the first definitions must not
## say otherwise.
func test_core_definitions_are_physically_right() -> void:
	assert_eq(Glossary.ENTRIES["electricity"]["simple"], "What electric charges do: they push and pull on each other, and flow through wires as a current.")
	assert_eq(Glossary.ENTRIES["current"]["simple"], "How much electric charge flows past a point each second. Measured in amps.")
	assert_eq(Levels.by_id("ch1.too-hot").learn[0]["text"], "Resistors turn electrical energy into heat. That's how toasters work!")


## Checkpoint B (C3, M1): history stated exactly.
func test_history_facts_exact() -> void:
	assert_eq(Levels.by_id("ch1.light-it-up").facts[0]["text"], "The first practical visible-light LED, made in 1962, could only glow red.")
	assert_eq(Levels.by_id("ch1.on-and-off").facts[0]["text"], "'[[bit|Bit]]' is short for 'binary digit'. It was first used this way in 1947.")


## Checkpoint B (I8): every source is something a reader can look up.
func test_fact_sources_are_citations() -> void:
	var expect := {
		"ch1.light-it-up": "Applied Physics Letters 1, 82 (1962)",
		"ch1.on-and-off": "Bell System Technical Journal 27",
		"ch1.short-circuit": "IEC 60898-1",
		"ch1.too-hot": "U.S. Department of Energy",
		"ch1.inside-the-wire": "Kittel",
	}
	for id in expect:
		assert_true(str(Levels.by_id(id).facts[0]["source"]).contains(expect[id]), id)


## Checkpoint B (I6): the AND and OR gates of L5 and L6 are defined.
func test_logic_gates_defined() -> void:
	assert_eq(GlossaryText.resolve("AND gate"), "logic gate")
	assert_eq(GlossaryText.resolve("OR gate"), "logic gate")
	assert_true("logic gate" in GlossaryText.render(Levels.by_id("ch1.both").outro[1]["text"], {})["terms"])
	assert_true("logic gate" in GlossaryText.render(Levels.by_id("ch1.either").outro[1]["text"], {})["terms"])
