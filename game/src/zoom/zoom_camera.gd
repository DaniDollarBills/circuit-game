class_name ZoomCamera
extends RefCounted
## Where the camera looks: a layer, the point at the middle of the screen, and
## the visible height, all in that layer's units.

var layer := ""
var center := Vector2.ZERO
var view := 1.0


static func make(layer_id: String, at: Vector2, visible_height: float) -> ZoomCamera:
	var c := ZoomCamera.new()
	c.layer = layer_id
	c.center = at
	c.view = visible_height
	return c


func copy() -> ZoomCamera:
	return ZoomCamera.make(layer, center, view)
