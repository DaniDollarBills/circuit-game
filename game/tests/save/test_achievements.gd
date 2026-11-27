extends TestCase

const CH1 := ["ch1.light-it-up", "ch1.pop", "ch1.push-and-flow", "ch1.on-and-off", "ch1.both", "ch1.either",
		"ch1.short-circuit", "ch1.too-hot", "ch1.inside-the-wire"]


func _ids() -> PackedStringArray:
	return PackedStringArray(CH1)


func test_badge_copy() -> void:
	assert_eq(Achievements.ALL.size(), 8)
	assert_eq(Achievements.ALL[0], {"id": "first_light", "name": "First Light", "description": "Light your first LED."})
	assert_eq(Achievements.ALL[2], {"id": "on_spec", "name": "Right on Spec", "description": "Earn the 18–20 mA star."})
	assert_eq(Achievements.ALL[7], {"id": "spark_graduate", "name": "Spark Graduate", "description": "Finish every Chapter 1 lesson."})


func test_first_light_earned_once() -> void:
	var p := Progress.defaults()
	assert_eq(Achievements.newly_earned(p, _ids()), PackedStringArray())
	p.mark_complete("ch1.light-it-up", false, 5)
	assert_eq(Achievements.newly_earned(p, _ids()), PackedStringArray(["first_light"]))
	p.achievements["first_light"] = 5
	assert_eq(Achievements.newly_earned(p, _ids()), PackedStringArray())


func test_magic_smoke_after_first_burn() -> void:
	var p := Progress.defaults()
	assert_false("magic_smoke" in Achievements.newly_earned(p, _ids()))
	p.stats["parts_burnt"] = 1
	assert_eq(Achievements.newly_earned(p, _ids()), PackedStringArray(["magic_smoke"]))


func test_level_badges_follow_their_levels() -> void:
	var p := Progress.defaults()
	p.mark_complete("ch1.pop", false, 1)
	p.mark_complete("ch1.both", false, 1)
	assert_eq(Achievements.newly_earned(p, _ids()), PackedStringArray(), "no star, and only one logic level")
	p.mark_complete("ch1.pop", true, 2)
	p.mark_complete("ch1.either", false, 2)
	p.mark_complete("ch1.push-and-flow", false, 2)
	p.mark_complete("ch1.inside-the-wire", false, 2)
	assert_eq(Achievements.newly_earned(p, _ids()),
			PackedStringArray(["on_spec", "ohms_apprentice", "logic_begins", "deep_diver"]))


func test_word_collector_at_20_terms() -> void:
	var p := Progress.defaults()
	for i in 19:
		p.seen_terms["t%d" % i] = 1
	assert_false("word_collector" in Achievements.newly_earned(p, _ids()))
	p.seen_terms["t19"] = 1
	assert_true("word_collector" in Achievements.newly_earned(p, _ids()))


func test_spark_graduate_needs_all_nine() -> void:
	var p := Progress.defaults()
	for i in 8:
		p.mark_complete(CH1[i], false, 1)
	assert_false("spark_graduate" in Achievements.newly_earned(p, _ids()))
	p.mark_complete(CH1[8], false, 1)
	assert_true("spark_graduate" in Achievements.newly_earned(p, _ids()))
	assert_false("spark_graduate" in Achievements.newly_earned(p, PackedStringArray()), "an empty chapter never counts")


## Code review (checkpoint S): Lesson 0 joined Chapter 1, but the badge is for
## its lessons. A v0.2.0 player who never saw Lesson 0 still graduates.
func test_spark_graduate_counts_lessons_not_the_tutorial() -> void:
	var s := GameState.new()
	s.progress = Progress.defaults()
	for id in Levels.chapter_ids("ch1"):
		if Levels.by_id(id).kind != "tutorial":
			s.progress.mark_complete(id, false, 1)
	s.check_achievements(2)
	assert_true(s.progress.achievements.has("spark_graduate"), str(s.progress.achievements))
