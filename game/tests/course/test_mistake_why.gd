extends TestCase
## Why? for every mistake Pip points out: the physics in a sentence or two.


func test_every_mistake_has_a_why() -> void:
	for prefix in LevelScreen.MISTAKES:
		assert_true(MistakeWhy.for_message(prefix + " and more words.") != "", prefix)


func test_unknown_message_has_no_why() -> void:
	assert_eq(MistakeWhy.for_message("Well done."), "")


func test_whys_say_why() -> void:
	assert_true("diode" in MistakeWhy.for_message("The LED is backwards. Swap its wires."))
	assert_true("1 Ω" in MistakeWhy.for_message("Short circuit! Find the wire."))
	assert_true("30 mA" in MistakeWhy.for_message("Pop! Too much current burned out the LED."))


func test_whys_keep_copy_limits() -> void:
	var sentence_end := RegEx.create_from_string("[.!?](\\s|$)")
	for prefix in LevelScreen.MISTAKES:
		var plain := GlossaryText.plain(MistakeWhy.for_message(prefix + " x"))
		assert_true(plain.split(" ", false).size() <= 30, plain)
		assert_true(maxi(1, sentence_end.search_all(plain).size()) <= 2, plain)
