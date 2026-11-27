class_name MistakeWhy
extends RefCounted
## Why? for each mistake Pip points out: what happened, in physics, in a
## sentence or two. Keyed by the openings of the mistake messages.

const WHY := {
	"Pop!": "Current heats an LED's tiny chip. Above its 30 mA absolute maximum, the chip overheats and is damaged for good.",
	"Short circuit!": "A path from + to − with almost no resistance leaves only the battery's own 1 Ω to limit the current: about 5 A.",
	"The LED is backwards": "An LED is a diode: current only goes in at its + leg (the anode) and out at its − leg (the cathode).",
	"Careful:": "Above 20 mA an LED runs hotter than it was made for, so it wears out much sooner. Its datasheet says 20 mA.",
	"Something burned out": "Each part can only turn so much power into heat. Past its rating it overheats and is damaged for good.",
}


## The why for a mistake message; "" for a message that isn't one.
static func for_message(m: String) -> String:
	for opening in WHY:
		if m.begins_with(opening):
			return WHY[opening]
	return ""
