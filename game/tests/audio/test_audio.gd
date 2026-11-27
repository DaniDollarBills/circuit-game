extends TestCase
## Spec §11: soft clicks and chimes, made in code; Sound off means silent.


func test_every_effect_is_short_clean_and_repeatable() -> void:
	for name in Sfx.NAMES:
		var a := Sfx.make(name)
		assert_eq(a.format, AudioStreamWAV.FORMAT_16_BITS, name)
		assert_eq(a.mix_rate, Sfx.RATE, name)
		var frames := a.data.size() / 2
		var ms := 1000.0 * frames / Sfx.RATE
		assert_between(ms, 20.0, 900.0, "%s lasts %.0f ms" % [name, ms])
		var peak := 0.0
		for i in frames:
			peak = maxf(peak, absf(a.data.decode_s16(i * 2) / 32768.0))
		assert_true(peak <= 0.89 and peak >= 0.2, "%s peaks at %.2f" % [name, peak])
		assert_eq(Sfx.make(name).data, a.data, name + " is the same every time")


func test_sound_off_plays_nothing() -> void:
	var audio := Audio.new()
	add_to_tree(audio)
	audio.apply_settings({"sound": false, "music_volume": 0.5})
	audio.play("click")
	assert_eq(audio.played, [] as Array[String])
	assert_false(audio.music_playing(), "Sound off silences the music too")
	audio.apply_settings({"sound": true, "music_volume": 0.5})
	audio.play("click")
	assert_eq(audio.played, ["click"] as Array[String])
	assert_true(audio.is_in_group("audio"))


func test_old_save_gets_sound_defaults() -> void:
	var old := Progress.defaults().to_dict()
	(old["settings"] as Dictionary).erase("sound")
	(old["settings"] as Dictionary).erase("music_volume")
	var p := Progress.from_dict(old)
	assert_eq(p.settings["sound"], true)
	assert_eq(p.settings["music_volume"], 0.5)
	assert_true(Progress.is_valid_setting("music_volume", 0.25))
	assert_false(Progress.is_valid_setting("music_volume", 1.5))
	assert_false(Progress.is_valid_setting("music_volume", -0.1))
	assert_false(Progress.is_valid_setting("sound", "yes"))


func test_settings_sheet_has_sound_and_music() -> void:
	var game := Game.new()
	add_to_tree(game)
	game.boot("user://test_audio_%d.json" % randi())
	var sheet := SettingsSheet.new()
	sheet.game = game
	add_to_tree(sheet)
	sheet.open()
	sheet.toggle("sound").button_pressed = false
	assert_eq(game.state.progress.settings["sound"], false)
	sheet.music_slider().value = 0.2
	assert_near(float(game.state.progress.settings["music_volume"]), 0.2, 0.001)


## The first play of a sound must not stall a frame to synthesize it: they're
## made on a worker thread as the game starts.
func test_effects_are_made_before_they_play() -> void:
	var audio := Audio.new()
	add_to_tree(audio)
	for i in 300:
		if audio.ready_sounds() == Sfx.NAMES.size():
			break
		await wait_frames(1)
	assert_eq(audio.ready_sounds(), Sfx.NAMES.size())


## Passing Level 1 starts four sounds at once (and opening it, two word
## chimes): together, at the effects bus's level, they stay under full scale,
## and a limiter guards the master.
func test_effects_together_never_clip() -> void:
	var audio := Audio.new()
	add_to_tree(audio)
	var gain := db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sfx")))
	for group in [["success", "badge", "connect", "light"], ["word", "word"]]:
		var mix := PackedFloat32Array()
		for name in group:
			var data := Sfx.make(name).data
			var n := data.size() / 2
			if mix.size() < n:
				mix.resize(n)
			for i in n:
				mix[i] += data.decode_s16(i * 2) / 32768.0
		var peak := 0.0
		for v in mix:
			peak = maxf(peak, absf(v))
		assert_true(peak * gain <= 0.95, "%s peaks at %.2f" % [group, peak * gain])
	var limited := false
	for i in AudioServer.get_bus_effect_count(0):
		limited = limited or AudioServer.get_bus_effect(0, i) is AudioEffectHardLimiter
	assert_true(limited, "a limiter on Master")


## Every effect ends in a smooth fade, not a cut while it still rings.
func test_effect_tails_fade_smoothly() -> void:
	for name in Sfx.NAMES:
		var data := Sfx.make(name).data
		var n := data.size() / 2
		var last := roundi(0.005 * Sfx.RATE)
		var peak := 0.0
		for i in range(n - last, n):
			peak = maxf(peak, absf(data.decode_s16(i * 2) / 32768.0))
		assert_true(peak <= 0.02, "%s's last 5 ms reach %.3f" % [name, peak])
