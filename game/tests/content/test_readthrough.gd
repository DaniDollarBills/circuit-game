extends TestCase
## Task 17: a beginner's read-through of Lessons 2–9 found the places a
## newcomer gets lost, and a few physics slips. Each test pins one fix, named
## for what the reader hit.


## Every line of a level's on-screen copy (as test_content's _lines).
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
	return out


func _all(id: String) -> String:
	return "\n".join(_lines(Levels.by_id(id)))


func _cards(id: String, type: String) -> Array:
	return Levels.by_id(id).learn.filter(func(c: Dictionary) -> bool: return c["type"] == type)


## Every line of the Meet-the-part cards.
func _intro_lines() -> PackedStringArray:
	var out := PackedStringArray()
	for key in PartIntros.KEYS:
		var e := PartIntros.get_intro(key)
		out.append_array([e["does"], e["where"], e["spec"]["text"], e["deeper"]])
		for leg in e["legs"]:
			out.append(leg["text"])
	return out


## Reader, B1: Lesson 2 divided volts by amps, in amps, before Lesson 3
## taught units or Ohm's law.
func test_lesson2_explains_dividing_before_the_worked_example() -> void:
	var l := Levels.by_id("ch1.pop")
	var before := ""
	for c in l.learn:
		if c["type"] == "worked":
			break
		before += str(c.get("text", "")) + "\n"
	assert_true("Volts ÷ amps gives ohms" in before, before)
	assert_true("thousandth of an amp" in before, before)


## Reader, B7: "÷ 20 mA" reads as 3 ÷ 20. Every division by a current is
## written in amps.
func test_no_line_divides_by_milliamps() -> void:
	var re := RegEx.create_from_string("÷ [0-9.]+ mA")
	for l in Levels.all():
		for line in _lines(l):
			assert_true(re.search(line) == null, "%s: %s" % [l.id, line])


## Reader, B6: "allows only 5 V the wrong way round" (with a 5 V battery) was
## on neither the datasheet nor the bench. Backwards, the LED stays dark.
func test_lesson2_backwards_led() -> void:
	assert_false("wrong way round" in _all("ch1.pop"))
	assert_true("backwards" in str(_cards("ch1.pop", "idea")[0]["deeper"]))


## Reader, B13: Lesson 2 offers the 330 Ω straight after "150 Ω" with no
## word that it's safe but dim.
func test_lesson2_says_330_is_safe_but_dim() -> void:
	assert_true("dimmer" in str(Levels.by_id("ch1.pop").pokes[1]["text"]))


## Reader, B2 and C: three power formulas (V × I, I × I × R, V² ÷ R), a
## calculator that disagreed with the Why, and "how hot" answered in watts.
func test_one_power_formula() -> void:
	for id in ["ch1.short-circuit", "ch1.too-hot"]:
		var text := _all(id)
		assert_false("I × I" in text, id)
		assert_false("²" in text, id)
	var worked: Dictionary = _cards("ch1.too-hot", "worked")[0]
	assert_false(str(worked["text"]).begins_with("How hot"), "heat each second, not a temperature")
	var steps := "\n".join(worked["steps"])
	assert_true("V = I × R" in steps and "P = V × I" in steps, steps)
	assert_true("0.53 W" in str(worked["deeper"]), "says why the calculator gets 0.53 W")
	for st in Levels.by_id("ch1.too-hot").steps:
		assert_false("0.51 W" in str(st["why"]), "a why next to the calculator's 0.53 W: %s" % st["why"])


## Reader, B2: Lesson 7 gave 25 W before watts were taught.
func test_lesson7_says_what_a_watt_is() -> void:
	var steps := "\n".join(_cards("ch1.short-circuit", "worked")[0]["steps"])
	assert_true("[[watt|watts]]" in steps, steps)
	assert_true("5 V × 5 A = 25 W" in steps, steps)


## Reader, B4: "across" was never explained, and a resistor across the
## battery, straight after Lesson 7, looked like a short.
func test_across_is_defined_and_linked() -> void:
	assert_true(bool(Glossary.ENTRIES["across"]["explicit_only"]), "everyday English too, so linked only when marked")
	var lines := PackedStringArray()
	for l in Levels.all():
		lines.append_array(_lines(l))
	lines.append_array(_intro_lines())
	var linked := RegEx.create_from_string("\\[\\[across(\\|[^\\]]*)?\\]\\]")
	for line in lines:
		assert_false("across" in linked.sub(line, "", true).to_lower(), "an unlinked across: " + line)
	assert_true("isn't a short" in _all("ch1.too-hot"))


## Reader, B3: "in a row" and "side by side" mean the same in everyday
## English, and "one side of each switch" meant a leg.
func test_series_and_parallel_say_what_they_mean() -> void:
	for id in ["ch1.both", "ch1.either"]:
		var text := _all(id).to_lower()
		for phrase in ["in a row", "side by side", "side of each"]:
			assert_false(phrase in text, "%s: %s" % [id, phrase])
	assert_true("one after the other" in _all("ch1.both"))
	assert_true("separate paths" in _all("ch1.either"))
	for term in ["series", "parallel"]:
		assert_false("side by side" in str(Glossary.ENTRIES[term]["simple"]), term)


## Reader, B10: Lesson 6's recap said the current is the same without why.
func test_lesson6_recap_says_why() -> void:
	assert_true("because the resistor sets it" in "\n".join(Levels.by_id("ch1.either").recap))


## Reader, B5: the hidden short runs from the resistor to the LED and never
## touches the battery, but the step said "+ straight to −".
func test_lesson7_short_away_from_the_battery() -> void:
	var find: Dictionary = Levels.by_id("ch1.short-circuit").steps[0]
	assert_false("straight to" in str(find["text"]), find["text"])
	assert_true("plain wire" in str(find["why"]), find["why"])


## Reader, C: "cut the power" linked to power in watts, a different meaning.
func test_lesson7_cuts_off_the_current() -> void:
	for line in _lines(Levels.by_id("ch1.short-circuit")):
		assert_false("power" in GlossaryText.render(line, {})["terms"], line)


## Reader, B8: nobody said I means current; "10 MΩ", "½ W", "track" and
## "wiper" went unexplained; nothing asked for the voltage meter's reading.
func test_lesson3_explains_its_words() -> void:
	var text := _all("ch1.push-and-flow")
	assert_true("I is current" in text)
	assert_true("intensité" in text, "why the letter I")
	var l := Levels.by_id("ch1.push-and-flow")
	assert_true(l.readouts.any(func(r: Dictionary) -> bool: return r["part"] == "V1"), "the voltage meter's reading")
	assert_true("both meters" in l.try_prompt, l.try_prompt)
	assert_true("million ohms" in str(PartIntros.get_intro("voltmeter")["spec"]["text"]))
	var trimmer := PartIntros.get_intro("trimmer")
	assert_true("half a watt" in str(trimmer["spec"]["text"]), trimmer["spec"]["text"])
	var legs := "\n".join(trimmer["legs"].map(func(g: Dictionary) -> String: return str(g["text"])))
	assert_true("The track: a strip" in legs and "The wiper: a contact" in legs, legs)


## Reader, B9: closed means on, the opposite of a door or a tap.
func test_lesson4_says_closed_means_on() -> void:
	assert_true("closed means on" in _all("ch1.on-and-off"))


## Reader, B11 and C: nothing before Lesson 8 said the resistors were ¼ W;
## a rating is a long-term limit, but the bench burns a part at once.
func test_lesson8_names_the_quarter_watt_rating_first() -> void:
	var l := Levels.by_id("ch1.too-hot")
	var rating := -1
	var meet := -1
	for i in l.learn.size():
		if rating < 0 and "¼ W" in str(l.learn[i].get("text", "")):
			rating = i
		if l.learn[i]["type"] == "meet":
			meet = i
	assert_true(rating >= 0 and rating < meet, "the ¼ W card comes before the 1 W one")
	assert_true("strict" in str(l.learn[rating].get("deeper", "")), "the bench burns a part at once")
	assert_false("burns above" in "\n".join(l.recap))
	assert_true("can be damaged" in MistakeWhy.for_burnt("resistor"))


## Reader, C: a toaster is about a thousand watts, not "hundreds".
func test_toaster_wattage() -> void:
	var real: Dictionary = _cards("ch1.too-hot", "real")[0]
	assert_true("a thousand watts" in str(real["text"]), real["text"])
	assert_true("Department of Energy" in str(real["source"]))


## Reader, B12: why being negative sends electrons toward +, and what the
## + signs on the copper atoms are.
func test_lesson9_says_why_electrons_go_to_plus() -> void:
	assert_true("attract" in _all("ch1.inside-the-wire"))
	var lattice: Dictionary = Levels.by_id("ch1.inside-the-wire").learn.filter(
			func(c: Dictionary) -> bool: return c.get("diagram", "") == "copper_lattice")[0]
	assert_true("+ signs" in str(lattice["deeper"]), lattice["deeper"])


## Reader, D: Lesson 9's "Switch the picture" linked the verb to the switch.
func test_lesson9_switch_the_picture_is_a_verb() -> void:
	var terms: PackedStringArray = GlossaryText.render(Levels.by_id("ch1.inside-the-wire").try_prompt, {})["terms"]
	assert_false("switch" in terms, str(terms))


## Reader, B13: Lesson 2's history card repeated Lesson 1's fact, Lesson 3's
## fact its history card, Lesson 7's fact its Real card (and Lesson 9's fact
## its drift card). Within a lesson no source is cited twice, and no history
## card or fact retells an earlier lesson's. (Lesson 9's Franklin and Thomson
## cards tell the story Lesson 1 only hints at in a Go deeper, on purpose.)
## A source that starts with another is the same citation, with more added.
func test_no_story_told_twice() -> void:
	var stories := {}
	for l in Levels.all():
		var here := {}
		var cited: Array = l.learn.map(func(c: Dictionary) -> Array: return [str(c.get("source", "")), c["type"] == "history"])
		cited.append_array(l.facts.map(func(f: Dictionary) -> Array: return [str(f.get("source", "")), true]))
		for entry in cited:
			var src: String = entry[0]
			if src == "":
				continue
			for before in here:
				assert_false(_same(src, before), "%s cites twice: %s" % [l.id, src])
			here[src] = true
			if entry[1]:
				for before in stories:
					assert_false(_same(src, before), "%s retells %s's story: %s" % [l.id, stories[before], src])
		for entry in cited:
			if entry[1] and entry[0] != "":
				stories[entry[0]] = l.id


func _same(a: String, b: String) -> bool:
	return a.begins_with(b) or b.begins_with(a)


## Reader, D: "sped up" on the pictures was never explained. Lesson 1's first
## moving picture says what it means.
func test_sped_up_explained_on_the_first_moving_picture() -> void:
	var first: Dictionary = Levels.by_id("ch1.light-it-up").learn[0]
	assert_eq(first.get("diagram", ""), "charges_in_wire")
	assert_true("sped up" in str(first.get("deeper", "")), str(first.get("deeper", "")))


## Final review: Lesson 8 said every resistor so far was ¼ W, but Lesson 3's
## trimmer is ½ W. The claim is about fixed resistors, and every one placed
## before Lesson 8 is ¼ W.
func test_every_fixed_resistor_before_lesson_8_is_a_quarter_watt() -> void:
	var cards := Levels.by_id("ch1.too-hot").learn.filter(
			func(c: Dictionary) -> bool: return "¼ W" in str(c.get("text", "")))
	assert_true("fixed resistor" in str(cards[0]["text"]), cards[0]["text"])
	for l in Levels.all():
		if l.id == "ch1.too-hot":
			break
		var parts: Array = []
		for c in [l.circuit, l.solution, l.try_circuit]:
			if c != null:
				parts.append_array(c.parts)
		for item in l.tray + l.try_tray:
			parts.append(Part.make("?", item["kind"], 0, 0, 0, item.get("props", {})))
		for p in parts:
			if p.kind == "resistor" and not bool(p.props.get("adjustable", false)):
				assert_eq(float(p.props.get("watts", 0.25)), 0.25, "%s: %s" % [l.id, p.props])


## Final review: the chapter summary kept "side-by-side paths", the words the
## read-through found confusing.
func test_chapter_summary_says_what_series_and_parallel_mean() -> void:
	var text := "\n".join(Chapters.SUMMARY["ch1"]).to_lower()
	for phrase in ["in a row", "side by side", "side-by-side"]:
		assert_false(phrase in text, phrase)


## Final review: the water analogy's second "break" (the push races along
## while the water drifts) isn't one: a pressure wave in a full pipe also
## outruns the water.
func test_analogy_breaks_are_real() -> void:
	var a: Dictionary = _cards("ch1.push-and-flow", "analogy")[0]
	var breaks := str(a["breaks"])
	assert_false("light" in breaks or "races" in breaks, breaks)
	assert_true("spills nothing" in breaks, breaks)


## Final review, and the spec ("using your own circuit's numbers"): the
## switch lessons' recaps had none of the player's numbers.
func test_every_recap_has_the_players_numbers() -> void:
	for l in Levels.all():
		# Lesson 0's recap is about the controls: it has no circuit to quote.
		if l.recap.is_empty() or l.kind == "tutorial":
			continue
		var templated := false
		for point in l.recap:
			templated = templated or ("{" in point and "}" in point)
		assert_true(templated, l.id)
