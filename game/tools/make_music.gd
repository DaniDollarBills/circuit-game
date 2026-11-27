extends SceneTree
## Renders the music loop (MusicScore: 96 s, 32 kHz, stereo) to the WAV
## named after `--`; tools/make_music.sh then encodes it to Ogg Vorbis.

const Score := preload("res://tools/music_score.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var path := args[0] if not args.is_empty() else "user://ambient_loop.wav"
	var out: Dictionary = Score.render(96.0, 32000)
	var l: PackedFloat32Array = out["left"]
	var r: PackedFloat32Array = out["right"]
	var bytes := PackedByteArray()
	bytes.resize(l.size() * 4)
	for i in l.size():
		bytes.encode_s16(i * 4, clampi(roundi(l[i] * 32767.0), -32768, 32767))
		bytes.encode_s16(i * 4 + 2, clampi(roundi(r[i] * 32767.0), -32768, 32767))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 32000
	w.stereo = true
	w.data = bytes
	var err := w.save_to_wav(path)
	if err != OK:
		push_error("cannot write %s (%d)" % [path, err])
		quit(1)
		return
	print("wrote ", path)
	quit()
