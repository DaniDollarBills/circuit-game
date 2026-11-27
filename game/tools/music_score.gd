class_name MusicScore
extends RefCounted
## The game's music (spec §11: lo-fi ambient), as code: soft detuned pads
## through a gentle low-pass, a sparse felt-piano melody, faint vinyl
## crackle and a small echo, over Dmaj9 → Bm7 → Gmaj7 → Asus, twice.
##
## Everything repeats exactly over `length`: each frequency makes a whole
## number of cycles in it, the chord fades and the piano's tails wrap round,
## and the echo and filter run over two passes and keep the second, settled
## one. So the loop's end flows into its start with no click.
## tools/make_music.sh renders and encodes it; the tests render short loops.

const CHORDS := [
	[146.83, 185.0, 220.0, 277.18, 329.63],  # Dmaj9: D3 F#3 A3 C#4 E4
	[123.47, 146.83, 185.0, 220.0, 293.66],  # Bm7: B2 D3 F#3 A3 D4
	[98.0, 123.47, 146.83, 185.0, 220.0],  # Gmaj7(9): G2 B2 D3 F#3 A3
	[110.0, 146.83, 164.81, 185.0, 246.94],  # Asus: A2 D3 E3 F#3 B3
]
## The melody's notes: D major pentatonic, two octaves up.
const MELODY := [587.33, 659.25, 739.99, 880.0, 987.77, 1174.66, 1318.51]
const SEED := 2026


## {left, right}: `length` seconds at `rate`, peaking at 0.7.
static func render(length: float, rate: int) -> Dictionary:
	var n := roundi(length * rate)
	var seg := length / 8.0
	var fade := minf(2.0, seg * 0.3)
	var pad_l := PackedFloat32Array()
	var pad_r := PackedFloat32Array()
	pad_l.resize(n)
	pad_r.resize(n)
	var lfo := maxf(1.0, roundf(0.08 * length)) / length
	for i in n:
		var t := float(i) / rate
		var k := int(t / seg) % 8
		var p := fmod(t, seg)
		var weights := {k % 4: 1.0}
		if p < fade / 2.0:
			var a := _ease(0.5 + p / fade)
			weights = {k % 4: a, posmod(k - 1, 8) % 4: 1.0 - a}
		elif p > seg - fade / 2.0:
			var b := _ease(0.5 + (seg - p) / fade)
			weights = {k % 4: b, (k + 1) % 8 % 4: 1.0 - b}
		var swell := 0.85 + 0.15 * sin(TAU * lfo * t)
		var l := 0.0
		var r := 0.0
		for c in weights:
			var w: float = weights[c] * swell
			if w < 0.001:
				continue
			for f in CHORDS[c]:
				l += w * (sin(TAU * _q(f * 0.9988, length) * t) + 0.3 * sin(TAU * _q(f * 2.0012, length) * t))
				r += w * (sin(TAU * _q(f * 1.0012, length) * t) + 0.3 * sin(TAU * _q(f * 1.9988, length) * t))
		pad_l[i] = 0.05 * l
		pad_r[i] = 0.05 * r
	_lowpass(pad_l, 1400.0, rate)
	_lowpass(pad_r, 1400.0, rate)
	var dry_l := pad_l
	var dry_r := pad_r
	_piano(dry_l, dry_r, length, rate)
	_crackle(dry_l, dry_r, length, rate)
	var out_l := dry_l.duplicate()
	var out_r := dry_r.duplicate()
	_echo(out_l, out_r, dry_l, dry_r, roundi(0.375 * rate))
	var peak := 0.0
	for i in n:
		peak = maxf(peak, maxf(absf(out_l[i]), absf(out_r[i])))
	var k := 0.7 / peak if peak > 0.0 else 1.0
	for i in n:
		out_l[i] *= k
		out_r[i] *= k
	return {"left": out_l, "right": out_r}


## The nearest frequency that makes a whole number of cycles in `length`.
static func _q(f: float, length: float) -> float:
	return maxf(1.0, roundf(f * length)) / length


static func _ease(x: float) -> float:
	return 0.5 - 0.5 * cos(PI * clampf(x, 0.0, 1.0))


## Soft notes on a seeded pattern: three to five per chord, each a felt-piano
## tone (a few partials, fast attack, slow decay) whose tail wraps round.
static func _piano(l: PackedFloat32Array, r: PackedFloat32Array, length: float, rate: int) -> void:
	var n := l.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var seg := length / 8.0
	var tail := mini(roundi(4.0 * rate), n)
	for k in 8:
		for j in rng.randi_range(3, 5):
			var start := roundi((k * seg + rng.randf() * seg * 0.9) * rate)
			var f: float = MELODY[rng.randi_range(0, MELODY.size() - 1)]
			var amp := rng.randf_range(0.10, 0.18)
			var pan := rng.randf_range(0.3, 0.7)
			for i in tail:
				var t := float(i) / rate
				var env := minf(t / 0.006, 1.0) * exp(-t / 1.1) * minf((tail - i) / (0.5 * rate), 1.0)
				var v := amp * env * (sin(TAU * f * t) + 0.35 * sin(TAU * 2.0 * f * t) + 0.12 * sin(TAU * 3.0 * f * t) + 0.05 * sin(TAU * 4.01 * f * t))
				var at := (start + i) % n
				l[at] += v * (1.0 - pan)
				r[at] += v * pan


## Faint vinyl: a few soft ticks a second and a whisper of hiss.
static func _crackle(l: PackedFloat32Array, r: PackedFloat32Array, length: float, rate: int) -> void:
	var n := l.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 1
	for i in n:
		var hiss := 0.002 * rng.randf_range(-1.0, 1.0)
		l[i] += hiss
		r[i] += hiss
	for c in roundi(length * 3.0):
		var at := rng.randi_range(0, n - 1)
		var amp := rng.randf_range(0.01, 0.03) * (1.0 if rng.randf() < 0.5 else -1.0)
		var side := rng.randf()
		for i in 8:
			var v := amp * exp(-i / 2.0)
			l[(at + i) % n] += v * (1.0 - side)
			r[(at + i) % n] += v * side


## A one-pole low-pass, run over two passes so it starts settled.
static func _lowpass(s: PackedFloat32Array, cutoff: float, rate: int) -> void:
	var a := 1.0 - exp(-TAU * cutoff / rate)
	var y := 0.0
	for sweep in 2:
		for i in s.size():
			y += a * (s[i] - y)
			if sweep == 1:
				s[i] = y
	return


## A ping-pong echo (feedback 0.35, a quarter of the level), over two passes.
static func _echo(out_l: PackedFloat32Array, out_r: PackedFloat32Array, dry_l: PackedFloat32Array, dry_r: PackedFloat32Array, delay: int) -> void:
	var n := dry_l.size()
	var buf_l := PackedFloat32Array()
	var buf_r := PackedFloat32Array()
	buf_l.resize(n)
	buf_r.resize(n)
	for sweep in 2:
		for i in n:
			var j := posmod(i - delay, n)
			var el := dry_l[i] + 0.35 * buf_r[j]
			var er := dry_r[i] + 0.35 * buf_l[j]
			buf_l[i] = el
			buf_r[i] = er
			if sweep == 1:
				out_l[i] = dry_l[i] + 0.25 * buf_r[j]
				out_r[i] = dry_r[i] + 0.25 * buf_l[j]
