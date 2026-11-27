class_name LessonRules
extends RefCounted
## What keeps a lesson teachable, as a list of problems: empty when the lesson
## is fine. The content tests hold every lesson to it; each problem names the
## lesson and where.

const CARD_TYPES: PackedStringArray = ["idea", "analogy", "worked", "meet", "control", "real", "history", "tour"]
const MOODS: PackedStringArray = ["happy", "curious", "wow", "oops"]
## Parts of the level screen a Lesson 0 tour card can spotlight.
const TOUR_TARGETS: PackedStringArray = ["board", "tray", "battery", "top_bar", "map_button", "edit_buttons", "tool_buttons",
		"column", "hint"]


static func problems(l: LevelDef) -> PackedStringArray:
	var out := PackedStringArray()
	if not l.learn_goals.is_empty() and (l.learn_goals.size() < 2 or l.learn_goals.size() > 3):
		out.append("%s: %d learn goals (want 2 or 3)" % [l.id, l.learn_goals.size()])
	for i in l.learn.size():
		_card_problems(l.learn[i], "%s card %d" % [l.id, i + 1], out)
	for i in l.questions.size():
		_question_problems(l.questions[i], "%s question %d" % [l.id, i + 1], out)
	for p in l.recap:
		if p.strip_edges() == "":
			out.append("%s: an empty recap point" % l.id)
	if l.has_try():
		if l.pokes.is_empty():
			out.append("%s: a Try it with nothing to try" % l.id)
		if l.try_path.is_empty():
			out.append("%s: a Try it with no path for the tests to walk" % l.id)
	return out


static func _card_problems(c: Dictionary, where: String, out: PackedStringArray) -> void:
	var type := str(c.get("type", ""))
	if not type in CARD_TYPES:
		out.append("%s: unknown card type %s" % [where, type])
		return
	if not str(c.get("mood", "")) in MOODS:
		out.append("%s: unknown mood %s" % [where, c.get("mood")])
	if type != "meet" and str(c.get("text", "")).strip_edges() == "":
		out.append("%s: no text" % where)
	var diagram := str(c.get("diagram", ""))
	if diagram != "" and not Diagrams.has(diagram):
		out.append("%s: no diagram called %s" % [where, diagram])
	match type:
		"analogy":
			if str(c.get("breaks", "")).strip_edges() == "":
				out.append("%s: an analogy must say where it breaks" % where)
		"worked":
			if (c.get("steps", PackedStringArray()) as PackedStringArray).size() < 2:
				out.append("%s: a worked example needs at least two steps" % where)
		"meet":
			if PartIntros.get_intro(str(c.get("part", ""))).is_empty():
				out.append("%s: no part intro called %s" % [where, c.get("part")])
		"control":
			if str(c.get("diagram", "")) == "":
				out.append("%s: a New control card with no demo" % where)
		"history":
			if str(c.get("source", "")).strip_edges() == "":
				out.append("%s: a history card with no source" % where)
		"tour":
			if not str(c.get("target", "")) in TOUR_TARGETS:
				out.append("%s: unknown tour target %s" % [where, c.get("target")])


static func _question_problems(q: Dictionary, where: String, out: PackedStringArray) -> void:
	var choices: Array = q.get("choices", [])
	if str(q.get("prompt", "")).strip_edges() == "":
		out.append("%s: no prompt" % where)
	if choices.size() != 3:
		out.append("%s: %d choices (want 3)" % [where, choices.size()])
	var correct := choices.filter(func(ch: Dictionary) -> bool: return bool(ch.get("correct", false))).size()
	if correct != 1:
		out.append("%s: %d correct choices (want 1)" % [where, correct])
	for ch in choices:
		if str(ch.get("why", "")).strip_edges() == "" or str(ch.get("text", "")).strip_edges() == "":
			out.append("%s: a choice without its text or explanation" % where)
			break
