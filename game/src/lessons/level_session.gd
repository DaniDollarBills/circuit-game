class_name LevelSession
extends RefCounted
## Where the player is in one level: reading the intro, building, or passed.
## Plain data moved along by static functions, so it can be tested without a
## scene. Steps are guidance and never block passing.

var level_id := ""
## "intro", "build" or "passed".
var phase := "intro"
var intro_index := 0
var hint_tier := 0
var goal_results: Array[Dictionary] = []
var test_report: Dictionary = {}
var used_hints := false
## One result per level step.
var step_results: Array[Dictionary] = []


## A level without intro lines starts straight in "build".
static func start(level: LevelDef) -> LevelSession:
	var s := LevelSession.new()
	s.level_id = level.id
	s.phase = "intro" if not level.intro.is_empty() else "build"
	return s


static func next_intro(s: LevelSession, level: LevelDef) -> void:
	if s.phase != "intro":
		return
	s.intro_index += 1
	if s.intro_index >= level.intro.size():
		s.phase = "build"


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
