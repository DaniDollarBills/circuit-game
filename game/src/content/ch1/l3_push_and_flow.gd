extends RefCounted
## Level 3, "Push and flow": use Ohm's law to set exactly 10 mA.


static func build() -> LevelDef:
	var b := LevelBuilder.new("ch1.push-and-flow", "ch1", "Push and flow")
	b.summary("Use Ohm's law to set exactly 10 mA.")
	b.part("B1", "battery", -6, 0).part("R1", "resistor", -2, -4, 0, {"ohms": 1000.0, "adjustable": true, "watts": 0.5})
	b.part("M1", "ammeter", 6, 0, 90).part("V1", "voltmeter", -2, -7)
	b.wire("w1", "B1", "pos", "R1", "a").wire("w2", "R1", "b", "M1", "a").wire("w3", "M1", "b", "B1", "neg")
	b.wire("w4", "V1", "pos", "R1", "a").wire("w5", "V1", "neg", "R1", "b")
	b.goal({"kind": "meter_reads", "part": "M1", "target": 0.010, "tolerance": 0.0005}).goal({"kind": "no_damage"})
	b.formula("ohms_law")
	b.idea("[[voltage|Voltage]] is the push and [[current|current]] is the flow. [[resistance|Resistance]] makes flowing harder.", "", "curious")
	b.idea("Tap the resistor and turn its dial until the [[ammeter|current meter]] shows 10 mA.", "", "happy")
	b.step("Tap the resistor to open its dial.", {"kind": "ui_flag", "flag": "value:R1"})
	b.step("Use Ohm's law: R = 5 V ÷ 0.010 A.", {"kind": "ui_flag", "flag": "formula:ohms_law"})
	b.step("Turn the dial until the meter reads 10 mA.", {"kind": "meter_reads", "part": "M1", "target": 0.010, "tolerance": 0.0005})
	b.hint("More resistance means less current. Is the meter too high or too low?")
	b.hint("Try about 500 ohms.", [{"part": "R1"}])
	b.hint("Set the resistor to 500 ohms.", [], true)
	b.solution_props("R1", {"ohms": 500.0})
	b.outro("That's [[ohms law|Ohm's law]]: current equals voltage divided by resistance.", "wow")
	b.outro("5 volts ÷ 500 ohms = 0.01 amps, which is 10 milliamps.", "happy")
	b.fact("Georg [[=Ohm]] published his law in 1827.", "G. S. Ohm, Die galvanische Kette, mathematisch bearbeitet, 1827")
	return b.done()
