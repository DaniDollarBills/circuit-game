class_name LevelSession
extends RefCounted
## Where the player is in one lesson: reading its Learn deck, trying, building,
## or passed. Plain data moved along by static functions, so it can be tested
## without a scene. Steps are guidance and never block passing.

var level_id := ""
## "learn", "try", "build" or "passed".
var phase := "learn"
## The Learn deck card showing: 0 is the goals card, deck_size() - 1 the closing one.
var card_index := 0
var hint_tier := 0
var goal_results: Array[Dictionary] = []
var test_report: Dictionary = {}
var used_hints := false
## One result per level step.
var step_results: Array[Dictionary] = []


## `auto` plays the lesson first: its Learn deck, then its Try it. Without it,
## or when the lesson has neither, building starts at once.
static func start(level: LevelDef, auto: bool) -> LevelSession:
	var s := LevelSession.new()
	s.level_id = level.id
	if auto and level.deck_size() > 0:
		s.phase = "learn"
	elif auto and level.has_try():
		s.phase = "try"
	else:
		s.phase = "build"
	return s


## Past the closing card, the lesson goes on to Try it (or straight to building).
static func next_card(s: LevelSession, level: LevelDef) -> void:
	if s.phase != "learn":
		return
	s.card_index += 1
	if s.card_index >= level.deck_size():
		_after_learn(s, level)


static func back_card(s: LevelSession) -> void:
	if s.phase == "learn":
		s.card_index = maxi(0, s.card_index - 1)


static func skip_learn(s: LevelSession, level: LevelDef) -> void:
	if s.phase == "learn":
		_after_learn(s, level)


static func _after_learn(s: LevelSession, level: LevelDef) -> void:
	s.card_index = 0
	s.phase = "try" if level.has_try() else "build"


## Re-evaluates goals and steps. A level without tests passes as soon as every
## goal passes; a level with tests waits for run_tests().
static func update(s: LevelSession, level: LevelDef, ctx: Dictionary) -> void:
	_evaluate(s, level, ctx)
	if s.phase == "build" and level.tests.is_empty() and _all_pass(s.goal_results):
		s.phase = "passed"


static func run_tests(s: LevelSession, level: LevelDef, circuit: Circuit, ctx: Dictionary) -> void:
	_evaluate(s, level, ctx)
	s.test_report = LevelTests.run(level, circuit)
	if s.phase == "build" and _all_pass(s.goal_results) and bool(s.test_report["pass"]):
		s.phase = "passed"


static func hint(s: LevelSession, level: LevelDef) -> void:
	s.hint_tier = mini(s.hint_tier + 1, level.hints.size())
	s.used_hints = true


static func _evaluate(s: LevelSession, level: LevelDef, ctx: Dictionary) -> void:
	s.goal_results = Goals.evaluate_all(level.goals, ctx)
	s.step_results = Goals.evaluate_all(level.steps.map(func(st: Dictionary) -> Dictionary: return st["check"]), ctx)


static func _all_pass(results: Array[Dictionary]) -> bool:
	for r in results:
		if not r["pass"]:
			return false
	return true
