class_name FlowView
extends Node2D
## Current in the Schematic view: sparks moving along each wire, faster for
## more current (or still arrows when reduced motion is on).

var flows: Array[Dictionary] = []
var center := Vector2.ZERO
var ppu := 32.0
var size := Vector2(1280, 720)
var reduced_motion := false
var t := 0.0


func set_flows(c: Circuit, sim: SimResult, settings: Dictionary) -> void:
	flows.clear()
	reduced_motion = bool(settings.get("reduced_motion", false))
	if sim == null:
		return
	for w in c.wires:
		var amps := WireArt.display_amps(float(sim.wire_amps.get(w.id, 0.0)), settings)
		if absf(amps) >= 1e-5:
			flows.append({"path": CircuitGeometry.wire_path(c, w), "amps": amps})
	queue_redraw()


func _process(delta: float) -> void:
	if not flows.is_empty() and not reduced_motion:
		t += delta
		queue_redraw()


func _draw() -> void:
	draw_set_transform(size / 2.0 - center * ppu)
	var spark := Palette.color("spark")
	var ink := Palette.color("ink")
	for f in flows:
		var path: PackedVector2Array = f["path"]
		if reduced_motion:
			_arrow(path, float(f["amps"]) > 0.0, ink)
			continue
		for d in WireArt.dots(path, f["amps"], t):
			DrawKit.circle(self, d, 0.11, spark, Color(ink, 0.6), 0.03, ppu)
	draw_set_transform(Vector2.ZERO)


## A still arrow at the middle of the longest segment, pointing the way the
## current flows.
func _arrow(path: PackedVector2Array, forward: bool, color: Color) -> void:
	var best := 1
	for i in range(1, path.size()):
		if path[i - 1].distance_to(path[i]) > path[best - 1].distance_to(path[best]):
			best = i
	var a := path[best - 1]
	var b := path[best]
	var dir := (b - a).normalized() * (1.0 if forward else -1.0)
	var mid := (a + b) / 2.0
	var side := Vector2(-dir.y, dir.x)
	DrawKit.poly(self, PackedVector2Array([mid + dir * 0.25, mid - dir * 0.2 + side * 0.18, mid - dir * 0.2 - side * 0.18]), color, color, 0.02, ppu)
