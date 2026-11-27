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
