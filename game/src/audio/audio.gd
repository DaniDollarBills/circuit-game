class_name Audio
extends Node
## Plays the game's sounds and music, on their own buses under Master, and
## follows the Sound and Music settings. Silent while the app is in the
## background. Main owns the one Audio node; screens find it in the "audio"
## group (and do without it in tests).

const POOL := 6
const MUSIC := "res://assets/audio/ambient_loop.ogg"

## Every sound played since the start, by name (for tests).
var played: Array[String] = []
var sound_on := true
var music_volume := 0.5

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _streams := {}
var _music: AudioStreamPlayer


func _ready() -> void:
	add_to_group("audio")
	for bus in ["Music", "Sfx"]:
		_ensure_bus(bus)
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
	_apply_music()


func apply_settings(settings: Dictionary) -> void:
	sound_on = bool(settings.get("sound", true))
	music_volume = clampf(float(settings.get("music_volume", 0.5)), 0.0, 1.0)
	_apply_music()


func play(sound: String) -> void:
	if not sound_on or not is_inside_tree():
		return
	if not _streams.has(sound):
		_streams[sound] = Sfx.make(sound)
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _streams[sound]
	p.play()
	played.append(sound)


## Plays the loop at the Music volume, or stops it at zero.
func _apply_music() -> void:
	var i := AudioServer.get_bus_index("Music")
	if i < 0 or _music == null:
		return
	var on := music_volume > 0.001
	AudioServer.set_bus_mute(i, not on)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(music_volume, 0.001)))
	if on and not _music.playing and _music.stream != null and is_inside_tree():
		_music.play()
	elif not on and _music.playing:
		_music.stop()


func music_playing() -> bool:
	return _music != null and _music.playing


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			AudioServer.set_bus_mute(0, true)
		NOTIFICATION_APPLICATION_RESUMED:
			AudioServer.set_bus_mute(0, false)


static func _ensure_bus(bus: String) -> void:
	if AudioServer.get_bus_index(bus) >= 0:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus)
	AudioServer.set_bus_send(i, "Master")
