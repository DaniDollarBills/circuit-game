extends TestCase
## Spec §11: lo-fi ambient music, looping forever without a click.

const MUSIC := "res://assets/audio/ambient_loop.ogg"


## A short render of the same score: every voice wraps at the loop's end.
func test_music_loops_without_a_click() -> void:
	var rate := 16000
	var out := MusicScore.render(4.0, rate)
	for ch in ["left", "right"]:
		var s: PackedFloat32Array = out[ch]
		var n := s.size()
		assert_eq(n, 4 * rate)
		# The step from the last sample back to the first is like any other.
		var jump := absf(s[0] - s[n - 1])
		var typical := 0.0
		for i in range(1, n):
			typical = maxf(typical, absf(s[i] - s[i - 1]))
		assert_true(jump <= typical * 1.01 + 0.001, "%s seam step %.4f vs largest step %.4f" % [ch, jump, typical])
		var w := rate / 20
		var head := 0.0
		var tail := 0.0
		var peak := 0.0
		for i in w:
			head += absf(s[i])
			tail += absf(s[n - w + i])
		for v in s:
			peak = maxf(peak, absf(v))
		assert_true(absf(head - tail) <= 0.3 * maxf(head, tail) + 0.001, "%s: level jumps at the seam" % ch)
		assert_true(peak <= 0.8 and peak >= 0.2, "%s peaks at %.2f" % [ch, peak])


func test_the_loop_ships_and_loops() -> void:
	var m := load(MUSIC) as AudioStreamOggVorbis
	assert_true(m != null, "the music is imported")
	if m == null:
		return
	assert_true(m.loop, "set to loop")
	assert_between(m.get_length(), 95.0, 97.0)


func test_music_follows_the_volume() -> void:
	var audio := Audio.new()
	add_to_tree(audio)
	audio.apply_settings({"sound": true, "music_volume": 0.5})
	assert_true(audio.music_playing())
	assert_near(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), 0.5, 0.01)
	audio.apply_settings({"sound": true, "music_volume": 0.0})
	assert_false(audio.music_playing(), "volume 0 stops the music")
