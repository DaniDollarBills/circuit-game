extends TestCase
## Lesson 1, "Light it up", read the way a beginner reads it (checkpoint S,
## the beginner read-through): which way the charges really go, why one gap
## stops the whole loop, and why the LED needs its resistor.


func _l1() -> LevelDef:
	return Levels.by_id("ch1.light-it-up")


func _card(diagram: String) -> Dictionary:
	for c in _l1().learn:
		if str(c.get("diagram", "")) == diagram:
			return c
	return {}


func _index(diagram: String) -> int:
	var l := _l1()
	for i in l.learn.size():
		if str(l.learn[i].get("diagram", "")) == diagram:
			return i
	return -1


## The charges that move in a metal wire are electrons, which leave a battery's
## − end. So the + to − direction is the current's, and the lesson says why,
## before the parts.
func test_charges_and_current_direction_agree() -> void:
	var push := _card("battery_push")
	assert_true("current" in str(push["text"]), push["text"])
	assert_false("charges out of" in str(push["text"]), "electrons leave the − end, not the +")
	var direction := _card("current_direction")
	assert_true("before anyone knew about electrons" in str(direction.get("deeper", "")), str(direction.get("deeper", "")))
	var first_meet := -1
	for i in _l1().learn.size():
		if _l1().learn[i]["type"] == "meet":
			first_meet = i
			break
	assert_true(_index("current_direction") < first_meet, "the direction is settled before the parts")
	var battery := PartIntros.get_intro("battery")
	assert_false("charges out of" in str(battery["does"]), battery["does"])
	assert_true("current" in str(battery["does"]), battery["does"])
	for leg in battery["legs"]:
		assert_false("charges" in str(leg["text"]), leg["text"])


## Runners far from a gap would keep running; a chain's links all stop together.
func test_gap_explained_with_a_chain() -> void:
	var loop := str(_card("loop_flow")["text"])
	assert_true("chain" in loop, loop)
	assert_false("runner" in loop, loop)
	assert_true("chain" in str(_card("loop_gap")["text"]), str(_card("loop_gap")["text"]))


func test_says_why_the_led_needs_its_resistor() -> void:
	assert_true("burn" in str(PartIntros.get_intro("resistor")["does"]), PartIntros.get_intro("resistor")["does"])
	var recap := " ".join(_l1().recap)
	assert_true("burn" in recap, recap)


## "Your loop carried 13.8 mA." Is that good? The recap says.
func test_recap_puts_the_current_in_context() -> void:
	for line in _l1().recap:
		if "{L1.mA}" in line:
			assert_true("safe" in line, line)
			return
	assert_true(false, "a recap line shows the loop's current")


## The resistor in Lesson 1 is 220 Ω, so the card's color code is its own.
func test_resistor_card_reads_this_lessons_resistor() -> void:
	var spec := str(PartIntros.get_intro("resistor")["spec"]["text"])
	assert_true("red, red, brown means 220 Ω" in spec, spec)
	assert_eq(float(PartIntros.sample_part("resistor").props["ohms"]), 220.0)


## "This pack is partly used": why use a used battery? Say what's true instead.
func test_battery_card_explains_its_5_v() -> void:
	var spec := str(PartIntros.get_intro("battery")["spec"]["text"])
	assert_false("partly used" in spec, spec)
	assert_true("6 V" in spec and "5 V" in spec, spec)
