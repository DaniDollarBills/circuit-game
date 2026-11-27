class_name SfxBank
extends RefCounted
## The synthesized effects, made on a worker thread (render_all) and handed
## out on the main thread. Kept apart from the Audio node, so the node can be
## freed while the worker runs; Audio waits for the worker as it leaves.

var _streams := {}
var _lock := Mutex.new()


func render_all() -> void:
	for sound in Sfx.NAMES:
		var stream := Sfx.make(sound)
		_lock.lock()
		if not _streams.has(sound):
			_streams[sound] = stream
		_lock.unlock()


## The effect, made now if the worker hasn't reached it yet (rare).
func stream(sound: String) -> AudioStreamWAV:
	_lock.lock()
	var s: AudioStreamWAV = _streams.get(sound)
	_lock.unlock()
	if s == null:
		s = Sfx.make(sound)
		_lock.lock()
		_streams[sound] = s
		_lock.unlock()
	return s


func count() -> int:
	_lock.lock()
	var n := _streams.size()
	_lock.unlock()
	return n
