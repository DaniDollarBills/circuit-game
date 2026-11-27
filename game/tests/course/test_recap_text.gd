extends TestCase
## The recap's "your numbers": {part.quantity} templates filled from the
## player's own simulated circuit.


func _l1_loop(ohms: float) -> SimOutcome:
	var c := Levels.by_id("ch1.light-it-up").solution.copy()
	return Simulator.simulate(CircuitEdits.set_props(c, "R1", {"ohms": ohms}))


func test_fill_known_circuit() -> void:
	var out := _l1_loop(220.0)
	assert_eq(RecapText.fill("Your loop carried {L1.mA}.", out.circuit, out.result), "Your loop carried 13.8 mA.")
	assert_eq(RecapText.fill("{R1.ohms} gave {L1.mA}", out.circuit, out.result), "220 Ω gave 13.8 mA")


func test_fill_follows_the_circuit() -> void:
	var out := _l1_loop(150.0)
	assert_eq(RecapText.fill("{L1.mA}", out.circuit, out.result), "19.9 mA", "(5 − 1.90) ÷ 156 Ω")


func test_fill_missing_part_is_dash() -> void:
	var out := _l1_loop(220.0)
	assert_eq(RecapText.fill("Z9 carried {Z9.mA}.", out.circuit, out.result), "Z9 carried —.")


func test_plain_text_unchanged() -> void:
	var out := _l1_loop(220.0)
	assert_eq(RecapText.fill("No numbers {here}.", out.circuit, out.result), "No numbers {here}.")


## A short across Lesson 7's loop: the battery's own heat, current² × its 1 Ω,
## about 25 W (its "W", what it delivers, is next to nothing then).
func test_battery_heat_in_a_short() -> void:
	var c := Levels.by_id("ch1.light-it-up").solution.copy()
	var fine := Simulator.simulate(c)
	assert_true(Readouts.value("B1", "heat", fine.circuit, fine.result) < 0.01, "a working loop barely warms it")
	var shorted := Simulator.simulate(CircuitEdits.add_wire(c, "B1", "pos", "B1", "neg"))
	assert_near(Readouts.value("B1", "heat", shorted.circuit, shorted.result), 25.0, 0.5)
	assert_eq(Readouts.text({"part": "B1", "quantity": "heat"}, shorted.circuit, shorted.result), "Battery pack heat: 25.00 W")


## Lesson 8: tray parts are named in the order they're placed, so "the
## resistor" is found by its kind: the one still working, not a burnt one.
func test_recap_names_a_part_by_kind() -> void:
	var c := Circuit.new()
	c.parts.append(Part.make("B1", "battery", -6, 0))
	c.parts.append(Part.make("R1", "resistor", 0, -4, 0, {"ohms": 47.0, "watts": 0.25, "burnt": true}, false))
	c.parts.append(Part.make("R2", "resistor", -2, 0, 90, {"ohms": 47.0, "watts": 1.0}, false))
	c = CircuitEdits.add_wire(c, "B1", "pos", "R2", "a")
	c = CircuitEdits.add_wire(c, "R2", "b", "B1", "neg")
	var out := Simulator.simulate(c)
	assert_eq(RecapText.fill("Your resistor made {resistor.W} of heat.", out.circuit, out.result), "Your resistor made 0.51 W of heat.")
