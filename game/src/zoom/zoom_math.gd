class_name ZoomMath
extends RefCounted
## Pure camera math for the endless zoom: zooming about a point, moving between
## a layer and its child, and cross-fading the two near a hand-off. Every
## function returns new cameras and leaves its inputs alone (except resolve(),
## which remembers the dynamic link it hands off through).

## The child starts fading in when the view is this many times its hand-off size.
const BAND := 4.0
const MAX_HOPS := 8


## Zooms in by `factor` (2 halves the view) while `focus` stays put on screen.
static func zoom_at(cam: ZoomCamera, factor: float, focus: Vector2) -> ZoomCamera:
	return ZoomCamera.make(cam.layer, focus + (cam.center - focus) / factor, cam.view / factor)


static func pan(cam: ZoomCamera, delta: Vector2) -> ZoomCamera:
	return ZoomCamera.make(cam.layer, cam.center + delta, cam.view)


static func to_child(cam: ZoomCamera, link: ZoomLink) -> ZoomCamera:
	var s := link.child_max_view / link.parent_min_view
	return ZoomCamera.make(link.child, (cam.center - link.anchor) * s, cam.view * s)


static func to_parent(cam: ZoomCamera, link: ZoomLink) -> ZoomCamera:
	var s := link.child_max_view / link.parent_min_view
	return ZoomCamera.make(link.parent, cam.center / s + link.anchor, cam.view / s)


## The first static link out of the camera's layer; otherwise what
## `dynamic.call(layer, center)` offers (a layer such as the editor decides
## from what is under the camera, like the nearest wire); otherwise null.
static func child_link(cam: ZoomCamera, links: Array[ZoomLink], dynamic: Callable) -> ZoomLink:
	for l in links:
		if l.parent == cam.layer and not l.dynamic:
			return l
	if dynamic.is_valid():
		return dynamic.call(cam.layer, cam.center)
	return null


static func parent_link(cam: ZoomCamera, links: Array[ZoomLink]) -> ZoomLink:
	for l in links:
		if l.child == cam.layer:
			return l
	return null


## Hands the camera to the child below the link's `parent_min_view`, or back to
## the parent above its `child_max_view`, up to MAX_HOPS times; then clamps the
## view to the layer's limits. A dynamic link used on the way in is added to
## `links` (replacing an older one to the same child) so the way back matches.
static func resolve(cam: ZoomCamera, infos: Dictionary, links: Array[ZoomLink], dynamic: Callable) -> ZoomCamera:
	var c := cam.copy()
	for hop in MAX_HOPS:
		var down := child_link(c, links, dynamic)
		if down != null and c.view < down.parent_min_view:
			if not down in links:
				_remember(down, links)
			c = to_child(c, down)
			continue
		var up := parent_link(c, links)
		if up != null and c.view > up.child_max_view:
			c = to_parent(c, up)
			continue
		break
	var info: LayerInfo = infos.get(c.layer)
	if info != null:
		c.view = clampf(c.view, info.min_view, info.max_view)
	return c


## The layers to draw, parent first: the camera's own layer fully opaque, plus
## its child fading in across the band above the hand-off.
static func blend(cam: ZoomCamera, links: Array[ZoomLink], dynamic: Callable) -> Array[Dictionary]:
	var out: Array[Dictionary] = [{"layer": cam.layer, "alpha": 1.0, "cam": cam}]
	var link := child_link(cam, links, dynamic)
	if link != null and cam.view < link.parent_min_view * BAND:
		var t := log(link.parent_min_view * BAND / cam.view) / log(BAND)
		out.append({"layer": link.child, "alpha": smoothstep(0.0, 1.0, t), "cam": to_child(cam, link)})
	return out


## How many times smaller the visible distance gets at the hand-off; above
## about 1.5 the zoom is skipping ahead rather than showing every scale.
static func magnification(link: ZoomLink, infos: Dictionary) -> float:
	var parent: LayerInfo = infos[link.parent]
	var child: LayerInfo = infos[link.child]
	return (link.parent_min_view * parent.meters_per_unit) / (link.child_max_view * child.meters_per_unit)


static func meters_visible(cam: ZoomCamera, infos: Dictionary) -> float:
	return cam.view * (infos[cam.layer] as LayerInfo).meters_per_unit


## Dynamic links are kept only for the way back up; looking down, the dynamic
## callable decides afresh (the camera may now be over another wire).
static func _remember(link: ZoomLink, links: Array[ZoomLink]) -> void:
	for i in range(links.size() - 1, -1, -1):
		if links[i].child == link.child and links[i].dynamic:
			links.remove_at(i)
	link.dynamic = true
	links.append(link)
