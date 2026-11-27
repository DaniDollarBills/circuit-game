class_name Achievements
extends RefCounted
## Badges, with their exact copy. newly_earned() lists the ones whose condition
## now holds and that aren't recorded yet; the caller records them.

const ALL: Array[Dictionary] = [
	{"id": "first_light", "name": "First Light", "description": "Light your first LED."},
	{"id": "magic_smoke", "name": "Magic Smoke", "description": "Burn out a part. Every engineer does it!"},
	{"id": "on_spec", "name": "Right on Spec", "description": "Earn the 18–20 mA star."},
	{"id": "ohms_apprentice", "name": "Ohm's Apprentice", "description": "Use Ohm's law to hit 10 mA."},
	{"id": "logic_begins", "name": "Logic Begins", "description": "Build the both-switches and either-switch circuits."},
	{"id": "deep_diver", "name": "Deep Diver", "description": "Zoom all the way into a wire."},
	{"id": "word_collector", "name": "Word Collector", "description": "Learn 20 new words."},
	{"id": "spark_graduate", "name": "Spark Graduate", "description": "Finish every Chapter 1 lesson."},
]


static func newly_earned(p: Progress, ch1_ids: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for a in ALL:
		var id: String = a["id"]
		if not p.achievements.has(id) and _holds(id, p, ch1_ids):
			out.append(id)
	return out


static func _holds(id: String, p: Progress, ch1_ids: PackedStringArray) -> bool:
	match id:
		"first_light":
			return p.completed.has("ch1.light-it-up")
		"magic_smoke":
			return int(p.stats.get("parts_burnt", 0)) >= 1
		"on_spec":
			return p.completed.has("ch1.pop") and bool(p.completed["ch1.pop"]["star"])
		"ohms_apprentice":
			return p.completed.has("ch1.push-and-flow")
		"logic_begins":
			return p.completed.has("ch1.both") and p.completed.has("ch1.either")
		"deep_diver":
			return p.completed.has("ch1.inside-the-wire")
		"word_collector":
			return p.seen_terms.size() >= 20
		"spark_graduate":
			if ch1_ids.is_empty():
				return false
			for level_id in ch1_ids:
				if not p.completed.has(level_id):
					return false
			return true
	return false
