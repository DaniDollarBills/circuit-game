class_name TitleDirector
extends RefCounted
## Plays the title zoom: each layer zooms in at its own pace toward the next
## layer's anchor until the camera reaches the silicon atom.

## Natural-log zoom per second in each layer.
const RATES := {"title.globe": 0.9, "title.coast": 1.8, "title.beach": 2.4, "title.grain": 2.4, "title.silica": 0.9, "title.atom": 0.5}
## The zoom eases in over the first second.
const RAMP_S := 1.0

var finished := false

var _infos: Dictionary
var _links: Array[ZoomLink]
var _t := 0.0


func _init(infos: Dictionary, links: Array[ZoomLink]) -> void:
	_infos = infos
	_links = links


func step(cam: ZoomCamera, dt: float) -> ZoomCamera:
	if finished:
		return cam
	_t += dt
	var ramp := clampf(_t / RAMP_S, 0.0, 1.0)
	var rate: float = RATES.get(cam.layer, 1.0)
	var link := ZoomMath.child_link(cam, _links, Callable())
	var toward := link.anchor if link != null else cam.center
	var next := ZoomMath.resolve(ZoomMath.zoom_at(cam, exp(rate * ramp * dt), toward), _infos, _links, Callable())
	if next.layer == TitleChain.ORDER[TitleChain.ORDER.size() - 1]:
		finished = true
		return skip_to_end()
	return next


## The end of the zoom: the silicon atom at its home view.
func skip_to_end() -> ZoomCamera:
	finished = true
	return ZoomCamera.make("title.atom", Vector2.ZERO, TitleChain.home("title.atom"))


## For reduced motion: every layer's home view in turn.
func slideshow_order() -> PackedStringArray:
	return TitleChain.ORDER
