class_name GoDeeper
extends RefCounted
## Where the game simplifies real life, it says so: the "Go deeper" notes.


static func for_part(p: Part) -> String:
	match p.kind:
		"led":
			return "Go deeper: a real LED rarely pops the instant it passes its 30 mA absolute maximum. It runs hotter and wears out sooner, and far more current destroys it. The game pops it at the limit so the danger is easy to see."
		"resistor":
			return "Go deeper: a real resistor pushed past its power rating gets hotter and hotter, drifts in value, then chars or burns. The game burns it right at the rating."
		"ammeter":
			return "Go deeper: a real current meter adds a little resistance (its burden) and has a fuse. The game's meter adds 0.1 Ω and its 500 mA fuse blows at once; a real fuse takes a moment, and blows faster the bigger the overload."
		"voltmeter":
			return "Go deeper: the voltage meter draws a tiny current through its 10 MΩ input, like a real one, so it barely changes the circuit it measures."
		"battery":
			return "Go deeper: a real battery's voltage sags slowly as it runs down, and its internal resistance grows. The game keeps it at a steady 5 V behind 1 Ω."
	return ""
