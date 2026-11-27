class_name Audio
extends Node
## Plays the game's sounds and music, on their own buses under Master, and
## follows the Sound and Music settings (Sound off silences everything).
## Silent while the app is in the background. The effects are synthesized on
## a worker thread as it starts, so no first play stalls a frame. Main owns
## the one Audio node; screens find it in the "audio" group (and do without
## it in tests).

const POOL := 6
## Effects sit under the music and leave room for several at once (passing a
## level plays four together); a limiter on Master catches the rest.
const SFX_DB := -8.0
const MUSIC := "res://assets/audio/ambient_loop.ogg"

## Every sound played since the start, by name (for tests).
var played: Array[String] = []
var sound_on := true
var music_volume := 0.5

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _bank := SfxBank.new()
var _music: AudioStreamPlayer
var _configured := false
var _task := -1


func _ready() -> void:
	add_to_group("audio")
	for bus in ["Music", "Sfx"]:
		_ensure_bus(bus)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"), SFX_DB)
	_ensure_limiter()
	_task = WorkerThreadPool.add_task(_bank.render_all, false, "Synthesize sound effects")
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Sfx"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	if ResourceLoader.exists(MUSIC):
		_music.stream = load(MUSIC)
	add_child(_music)


func apply_settings(settings: Dictionary) -> void:
	sound_on = bool(settings.get("sound", true))
	music_volume = clampf(float(settings.get("music_volume", 0.5)), 0.0, 1.0)
	# The music waits for the saved settings, so a saved "Music 0" never blips.
	_configured = true
	_apply_music()


## How many effects are synthesized and waiting.
func ready_sounds() -> int:
	return _bank.count()


func play(sound: String) -> void:
	if not sound_on or not is_inside_tree():
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _bank.stream(sound)
	p.play()
	played.append(sound)


## Plays the loop at the Music volume, or stops it at zero.
func _apply_music() -> void:
	var i := AudioServer.get_bus_index("Music")
	if i < 0 or _music == null:
		return
	var on := _configured and sound_on and music_volume > 0.001
	AudioServer.set_bus_mute(i, not on)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(music_volume, 0.001)))
	if on and not _music.playing and _music.stream != null and is_inside_tree():
		_music.play()
	elif not on and _music.playing:
		_music.stop()


func music_playing() -> bool:
	return _music != null and _music.playing


func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			AudioServer.set_bus_mute(0, true)
		NOTIFICATION_APPLICATION_RESUMED:
			AudioServer.set_bus_mute(0, false)


static func _ensure_limiter() -> void:
	for i in AudioServer.get_bus_effect_count(0):
		if AudioServer.get_bus_effect(0, i) is AudioEffectHardLimiter:
			return
	AudioServer.add_bus_effect(0, AudioEffectHardLimiter.new())


static func _ensure_bus(bus: String) -> void:
	if AudioServer.get_bus_index(bus) >= 0:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus)
	AudioServer.set_bus_send(i, "Master")
