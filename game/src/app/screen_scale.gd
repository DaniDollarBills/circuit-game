class_name ScreenScale
extends RefCounted
## How many screen pixels one layout pixel covers. Text and buttons keep a
## comfortable physical size: never less than one layout pixel per screen point
## (so a phone shows a phone-sized layout, not a shrunken desktop one), and a big
## window scales up until its shorter side shows DESIGN_SHORT_SIDE layout pixels.

const DESIGN_SHORT_SIDE := 720.0


## `points` is the screen's pixels per point (2 on a Retina Mac, 3 on most
## phones, 1 on an ordinary monitor).
static func factor(window_px: Vector2i, points: float) -> float:
	var short_side := float(mini(window_px.x, window_px.y))
	return maxf(maxf(points, 1.0), short_side / DESIGN_SHORT_SIDE)


## The layout size for a window; zero for a window with no area yet.
static func logical_size(window_px: Vector2i, points: float) -> Vector2i:
	if window_px.x < 1 or window_px.y < 1:
		return Vector2i.ZERO
	var k := factor(window_px, points)
	return Vector2i(roundi(window_px.x / k), roundi(window_px.y / k))


## The current screen's pixels per point. Phones that report no scale use
## their density (160 dpi is one point, as on Android).
static func screen_points(screen: int) -> float:
	var points := DisplayServer.screen_get_scale(screen)
	if OS.has_feature("mobile"):
		points = maxf(points, DisplayServer.screen_get_dpi(screen) / 160.0)
	return points
