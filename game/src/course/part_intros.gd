class_name PartIntros
extends RefCounted
## Meet the part: what each part is, what it does, which leg is which, where
## you'd find one, one number from its datasheet, and what's inside. Keys name
## a part's kind and variant (a 1 W resistor and a trimmer are their own).

const KEYS: PackedStringArray = ["battery", "wire", "resistor", "resistor_1w", "trimmer", "led", "switch", "ammeter", "voltmeter"]

## {title, does, legs: [{pin, chip, text}], where, spec: {text, source}, inside: diagram id, deeper}.
## `chip` labels the leg on the 3D model; `text` explains it.
const INTROS := {
	"battery": {
		"title": "Battery pack",
		"does": "Four AA [[cell|cells]] in a row. Together they push a current out of the + end, round your circuit, and back into the − end.",
		"legs": [
			{"pin": "pos", "chip": "+", "text": "Red [[lead]], +: the current comes out here."},
			{"pin": "neg", "chip": "−", "text": "Black [[lead]], −: the current comes back in here."},
		],
		"where": "TV remotes, toys, torches and game controllers.",
		"spec": {"text": "Four new AA cells give about 6 V. Their push falls as they're used, and this pack gives 5 V.",
				"source": "IEC 60086-2 (LR6 alkaline cells, 1.5 V nominal)"},
		"inside": "aa_cell_inside",
		"deeper": "Inside each cell a chemical reaction pushes electrons out of the − end. The pack also has about 1 Ω of resistance inside it.",
	},
	"wire": {
		"title": "Jumper wire",
		"does": "Copper inside plastic. It joins one part's metal end to another's, so current can flow between them.",
		"legs": [
			{"pin": "a", "chip": "end", "text": "Either end can go first: a wire works both ways round."},
			{"pin": "b", "chip": "end", "text": "The plastic outside keeps it from touching other metal."},
		],
		"where": "Inside every device, and in the walls of your home.",
		"spec": {"text": "This is 22 gauge wire: solid copper 0.644 mm thick.", "source": "ASTM B258 (American Wire Gauge)"},
		"inside": "charges_in_wire",
		"deeper": "Copper conducts well because each atom lends an electron to a sea of free electrons that can move through the metal.",
	},
	"resistor": {
		"title": "Resistor",
		"does": "It makes it harder for current to flow. That keeps the current low, so an LED doesn't burn out.",
		"legs": [
			{"pin": "a", "chip": "leg", "text": "Either leg can go first: a resistor works the same both ways round."},
			{"pin": "b", "chip": "leg", "text": "Its stripes tell you its value."},
		],
		"where": "Inside almost every electronic device, from chargers to TVs.",
		"spec": {"text": "Stripes show its value: red, red, brown means 220 Ω, and gold means within 5%.",
				"source": "IEC 60062 (resistor color code)"},
		"inside": "resistor_inside",
		"deeper": "A thin carbon film is cut in a spiral round a ceramic rod. The longer and thinner the path, the higher the resistance.",
	},
	"resistor_1w": {
		"title": "1 W resistor",
		"does": "A bigger resistor. It can safely turn up to 1 watt into heat, four times as much as a ¼ W one.",
		"legs": [
			{"pin": "a", "chip": "leg", "text": "Either leg can go first: it works the same both ways round."},
			{"pin": "b", "chip": "leg", "text": "Its legs are farther apart because its body is bigger."},
		],
		"where": "Power supplies, chargers and heaters.",
		"spec": {"text": "Rated 1 W: it can turn 1 watt of electrical energy into heat without overheating.",
				"source": "IEC 60115-1 (rated dissipation of fixed resistors)"},
		"inside": "resistor_1w_inside",
		"deeper": "A bigger body has more surface to shed heat into the air, so it can take more power before it overheats.",
	},
	"trimmer": {
		"title": "Trimmer",
		"does": "A resistor you can adjust. Turning its dial changes how much it resists the current.",
		"legs": [
			{"pin": "a", "chip": "leg", "text": "The track: a strip inside that resists the current. This leg joins one end of it."},
			{"pin": "b", "chip": "leg", "text": "The wiper: a contact that slides along the track as you turn the dial."},
		],
		"where": "Inside radios and gadgets, set once at the factory.",
		"spec": {"text": "Its dial goes from 100 Ω to 2 kΩ here. It is rated ½ W: it can safely turn half a watt into heat.",
				"source": "This part's datasheet (tap the part to read it)"},
		"inside": "trimmer_inside",
		"deeper": "Real trimmers have a third leg at the track's other end. Using one end and the wiper makes it an adjustable resistor.",
	},
	"led": {
		"title": "LED",
		"does": "It glows when current flows through it the right way, and blocks current going the wrong way.",
		"legs": [
			{"pin": "anode", "chip": "+ (anode)", "text": "Long leg, + (anode): it goes toward the battery's +."},
			{"pin": "cathode", "chip": "− (cathode)", "text": "Short leg, − (cathode): it's on the side with the flat edge."},
		],
		"where": "Indicator lights, torches, screens and light bulbs.",
		"spec": {"text": "While it glows, a red LED uses about 2 V of the battery's 5 V push.",
				"source": "E. F. Schubert, Light-Emitting Diodes, 2nd ed., Cambridge University Press (2006)"},
		"inside": "led_inside",
		"deeper": "The chip is a tiny crystal of semiconductor. As current crosses it, electrons give up energy as light.",
	},
	"switch": {
		"title": "Switch",
		"does": "It opens or closes the loop. Closed joins its two legs so current flows; open leaves a gap.",
		"legs": [
			{"pin": "a", "chip": "leg", "text": "One leg: a switch works both ways round."},
			{"pin": "b", "chip": "leg", "text": "The other leg. Flip the lever to join or part them."},
		],
		"where": "Light switches, [[=power]] buttons and keyboards.",
		"spec": {"text": "This one is single-pole, single-throw: it joins or splits just one pair of legs.",
				"source": "P. Horowitz and W. Hill, The Art of Electronics, 3rd ed., Cambridge University Press (2015)"},
		"inside": "switch_inside",
		"deeper": "Inside, a springy metal strip snaps against a contact, so the switch is firmly on or off and never stuck halfway.",
	},
	"ammeter": {
		"title": "Current meter",
		"does": "It measures current in milliamps. It goes in the loop, so all the current flows through it.",
		"legs": [
			{"pin": "a", "chip": "+", "text": "Red lead, +: current goes in here."},
			{"pin": "b", "chip": "−", "text": "Black lead, −: current comes out here."},
		],
		"where": "On every electronics bench, as one setting of a handheld meter.",
		"spec": {"text": "It adds only 0.1 Ω to your loop, and a 500 mA fuse protects it.",
				"source": "This part's datasheet (tap the part to read it)"},
		"inside": "meter_inside",
		"deeper": "Inside, the current flows through a tiny resistor. The meter measures the small voltage [[across]] it and works out the current.",
	},
	"voltmeter": {
		"title": "Voltage meter",
		"does": "It measures voltage, the push between two points. Its probes go [[across]] a part, not in the loop.",
		"legs": [
			{"pin": "pos", "chip": "+", "text": "Red probe, +: put it on the side nearer the battery's +."},
			{"pin": "neg", "chip": "−", "text": "Black probe, −: put it on the other side."},
		],
		"where": "On every electronics bench, as one setting of a handheld meter.",
		"spec": {"text": "It has 10 MΩ (10 million ohms) inside, so it barely changes the circuit it measures.",
				"source": "This part's datasheet (tap the part to read it)"},
		"inside": "meter_inside",
		"deeper": "So little current flows into it that it hardly disturbs the circuit, the way a light touch hardly moves a scale.",
	},
}


## The intro key for a part: its kind, or the 1 W resistor or the trimmer.
static func key_for(p: Part) -> String:
	if p.kind == "resistor":
		if bool(p.props.get("adjustable", false)):
			return "trimmer"
		if float(p.props.get("watts", 0.25)) >= 1.0:
			return "resistor_1w"
	return p.kind


## The intro for `key`; empty for an unknown key.
static func get_intro(key: String) -> Dictionary:
	return INTROS.get(key, {})


## A part to show for `key` (its defaults, or the variant's props).
static func sample_part(key: String) -> Part:
	match key:
		"resistor":
			return Part.make("R1", "resistor", 0, 0, 0, {"ohms": 220.0})
		"resistor_1w":
			return Part.make("R1", "resistor", 0, 0, 0, {"ohms": 47.0, "watts": 1.0})
		"trimmer":
			return Part.make("R1", "resistor", 0, 0, 0, {"ohms": 1000.0, "adjustable": true, "watts": 0.5})
	return Part.make("P1", key, 0, 0) if Catalog.has_kind(key) else null
