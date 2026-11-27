class_name Sfx
extends RefCounted
## The game's sound effects, synthesized: sine tones and soft noise shaped
## by envelopes (spec §11: "soft clicks, chimes"). Made in code, so no
## recording needs a license, and the same every time.

const RATE := 44100
const NAMES: PackedStringArray = ["click", "place", "connect", "light", "pop", "success", "word", "badge", "test_pass", "test_fail"]
## Loud enough to hear, with headroom: −1.4 dBFS.
const PEAK := 0.85


static func make(name: String) -> AudioStreamWAV:
	var s := _render(name)
	_normalize(s)
	return _to_wav(s)


static func _render(name: String) -> PackedFloat32Array:
	var s: PackedFloat32Array
	match name:
		"click":
			# A soft tick: a bright, very short ping with a breath of noise.
			s = _buf(0.03)
			_tone(s, 2200.0, 0.0, 0.004, 1.0, 0.0008)
			_noise(s, 0.0, 0.002, 0.3, 11, 0.5)
		"place":
			# A wooden "tock": a falling mid tone and its octave.
			s = _buf(0.12)
			_tone(s, 520.0, 0.0, 0.025, 1.0, 0.002, 380.0)
			_tone(s, 1040.0, 0.0, 0.012, 0.25, 0.002, 760.0)
		"connect":
			# Two quick clicks: the wire's ends meeting their pins.
			s = _buf(0.12)
			_tone(s, 2800.0, 0.0, 0.005, 1.0, 0.0008)
			_tone(s, 3400.0, 0.045, 0.006, 0.9, 0.0008)
		"light":
			# A bell-like chime: C6 and G6, ringing out.
			s = _buf(0.75)
			_tone(s, 1046.5, 0.0, 0.22, 0.7, 0.005)
			_tone(s, 1568.0, 0.012, 0.18, 0.5, 0.005)
			_tone(s, 2093.0, 0.0, 0.08, 0.15, 0.005)
		"pop":
			# A muffled pop: a burst of dark noise over a low thump.
			s = _buf(0.25)
			_noise(s, 0.0, 0.035, 1.0, 7, 0.25)
			_tone(s, 60.0, 0.0, 0.04, 0.9, 0.002)
			_tone(s, 120.0, 0.0, 0.02, 0.3, 0.002, 60.0)
		"success":
			# A C major arpeggio up to the octave.
			s = _buf(0.88)
			var notes := [523.25, 659.25, 783.99, 1046.5]
			for i in notes.size():
				_tone(s, notes[i], i * 0.11, 0.25, 0.6, 0.004)
				_tone(s, notes[i] * 2.0, i * 0.11, 0.1, 0.15, 0.004)
		"word":
			# One soft chime: A5 and E6.
			s = _buf(0.55)
			_tone(s, 880.0, 0.0, 0.18, 0.6, 0.005)
			_tone(s, 1318.5, 0.008, 0.12, 0.35, 0.005)
		"badge":
			# A sparkle: three high partials, one after another, over C6.
			s = _buf(0.65)
			_tone(s, 1046.5, 0.0, 0.25, 0.3, 0.005)
			for i in 3:
				_tone(s, [2093.0, 2637.0, 3136.0][i], i * 0.04, 0.15, 0.4, 0.003)
		"test_pass":
			# Rising: E5 then A5.
			s = _buf(0.34)
			_tone(s, 659.25, 0.0, 0.09, 0.6, 0.004)
			_tone(s, 880.0, 0.14, 0.12, 0.6, 0.004)
		"test_fail":
			# Falling, and softer: A4 then E4.
			s = _buf(0.34)
			_tone(s, 440.0, 0.0, 0.09, 0.55, 0.004)
			_tone(s, 329.63, 0.14, 0.12, 0.55, 0.004)
		_:
			push_error("Unknown sound: " + name)
			s = _buf(0.03)
	return s


static func _buf(seconds: float) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(roundi(seconds * RATE))
	return s


## Adds a sine from `start` (s): an `attack`-long rise, then a decay with time
## constant `tau`, gliding to `f_end` over 60 ms when one is given.
static func _tone(s: PackedFloat32Array, f: float, start: float, tau: float, amp: float, attack: float, f_end := -1.0) -> void:
	var phase := 0.0
	for i in range(roundi(start * RATE), s.size()):
		var t := (i - start * RATE) / RATE
		var env := t / attack if t < attack else exp(-(t - attack) / tau)
		if env < 0.0005 and t > attack:
			break
		var freq := f if f_end < 0.0 else lerpf(f, f_end, minf(t / 0.06, 1.0))
		phase += TAU * freq / RATE
		s[i] += amp * env * sin(phase)


## Adds seeded noise from `start`, decaying with `tau`, through a one-pole
## low-pass (`smooth` near 0 is dark, 1 is bright).
static func _noise(s: PackedFloat32Array, start: float, tau: float, amp: float, seed_value: int, smooth: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var y := 0.0
	for i in range(roundi(start * RATE), s.size()):
		var t := (i - start * RATE) / RATE
		var env := exp(-t / tau)
		if env < 0.0005:
			break
		y += smooth * (rng.randf_range(-1.0, 1.0) - y)
		s[i] += amp * env * y


## Scales to PEAK and fades the last 5 ms, so nothing clicks at the end.
static func _normalize(s: PackedFloat32Array) -> void:
	var peak := 0.0
	for v in s:
		peak = maxf(peak, absf(v))
	var k := PEAK / peak if peak > 0.0 else 1.0
	var fade := mini(roundi(0.005 * RATE), s.size())
	for i in s.size():
		var tail := float(s.size() - 1 - i)
		s[i] *= k * minf(tail / fade, 1.0)


static func _to_wav(s: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(s.size() * 2)
	for i in s.size():
		bytes.encode_s16(i * 2, clampi(roundi(s[i] * 32767.0), -32768, 32767))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w
