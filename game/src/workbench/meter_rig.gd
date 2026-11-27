class_name MeterRig
extends RefCounted
## Where the equipment beside the board sits: battery holders on the desk to
## the left, multimeters to the right, each row level with the middle of the
## board and stepping outward with gaps, so nothing overlaps and the leads stay
## short. Positions are the base centers, on the mat.

## Footprints on the desk, x × z, cm.
const FOOTPRINT_HOLDER := Vector2(5.8, 6.3)
const FOOTPRINT_METER := Vector2(7.5, 15.0)
## Heights above the mat, cm (the multimeter's dial stands a little proud).
const HEIGHT_HOLDER := 1.5
const HEIGHT_METER := 4.1
const GAP := 1.5
## The perfboard reaches this many holes past the circuit on every side.
const MARGIN_HOLES := 4


## The perfboard's footprint in world x/z: the circuit's grid bounds plus the
## margin (a 20 × 14 board when the circuit is empty).
static func board_rect(c: Circuit) -> Rect2:
	var grid := Rect2()
	var first := true
	for p in c.parts:
		var r := CircuitGeometry.part_rect(p)
		grid = r if first else grid.merge(r)
		first = false
	for w in c.wires:
		for pt in CircuitGeometry.wire_path(c, w):
			grid = grid.expand(pt)
	if first:
		grid = Rect2(-10, -7, 20, 14)
	grid = grid.grow(MARGIN_HOLES)
	return Rect2(grid.position * PartDims.GRID, grid.size * PartDims.GRID)


## The height of the tallest piece of equipment beside the board, in cm.
static func tallest(c: Circuit) -> float:
	var top := 0.0
	for p in c.parts:
		if p.kind == "battery":
			top = maxf(top, HEIGHT_HOLDER)
		elif p.kind == "ammeter" or p.kind == "voltmeter":
			top = maxf(top, HEIGHT_METER)
	return top


## Each battery holder's and meter's box, in world units.
static func boxes(c: Circuit) -> Array[AABB]:
	var out: Array[AABB] = []
	var spots := place(c)
	for id in spots:
		var battery := c.find_part(id).kind == "battery"
		var foot: Vector2 = FOOTPRINT_HOLDER if battery else FOOTPRINT_METER
		var at: Vector3 = spots[id]
		out.append(AABB(at - Vector3(foot.x / 2.0, 0, foot.y / 2.0), Vector3(foot.x, HEIGHT_HOLDER if battery else HEIGHT_METER, foot.y)))
	return out


## The board plus every piece of equipment beside it, in world x/z.
static func content_rect(c: Circuit) -> Rect2:
	var r := board_rect(c)
	var spots := place(c)
	for id in spots:
		var size: Vector2 = FOOTPRINT_HOLDER if c.find_part(id).kind == "battery" else FOOTPRINT_METER
		var at: Vector3 = spots[id]
		r = r.merge(Rect2(Vector2(at.x, at.z) - size / 2.0, size))
	return r


static func place(c: Circuit) -> Dictionary:
	var board := board_rect(c)
	var y := -PartDims.mm(PartDims.BOARD_THICK)
	var out := {}
	var mid := board.get_center().y
	var left_x := board.position.x - GAP
	var right_x := board.end.x + GAP
	for p in c.parts:
		if p.kind == "battery":
			out[p.id] = Vector3(left_x - FOOTPRINT_HOLDER.x / 2.0, y, mid)
			left_x -= FOOTPRINT_HOLDER.x + GAP
		elif p.kind == "ammeter" or p.kind == "voltmeter":
			out[p.id] = Vector3(right_x + FOOTPRINT_METER.x / 2.0, y, mid)
			right_x += FOOTPRINT_METER.x + GAP
	return out
