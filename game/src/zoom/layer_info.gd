class_name LayerInfo
extends RefCounted
## A zoom layer's real-world scale and how far its camera may zoom.

var id := ""
var meters_per_unit := 1.0
var min_view := 1.0
var max_view := 1.0


static func make(layer_id: String, mpu: float, smallest_view: float, largest_view: float) -> LayerInfo:
	var i := LayerInfo.new()
	i.id = layer_id
	i.meters_per_unit = mpu
	i.min_view = smallest_view
	i.max_view = largest_view
	return i
