class_name Part
extends RefCounted
## One part on the board. Positions are grid units (1 unit = 2.54 mm), y points
## down, and `rot` is 0, 90, 180 or 270 degrees clockwise.

var id: String
var kind: String
var x: int
var y: int
var rot: int
var props: Dictionary = {}
var locked := false
## Index of the tray item this part came from; -1 for parts placed by the level.
var tray := -1


## Missing props are filled from the catalog defaults.
static func make(part_id: String, part_kind: String, px: int, py: int, rotation := 0,
		part_props := {}, is_locked := false) -> Part:
	var p := Part.new()
	p.id = part_id
	p.kind = part_kind
	p.x = px
	p.y = py
	p.rot = posmod(rotation, 360)
	p.props = Catalog.defaults(part_kind).duplicate(true)
	p.props.merge(part_props.duplicate(true), true)
	p.locked = is_locked
	return p


func copy() -> Part:
	var p := Part.new()
	p.id = id
	p.kind = kind
	p.x = x
	p.y = y
	p.rot = rot
	p.props = props.duplicate(true)
	p.locked = locked
	p.tray = tray
	return p
