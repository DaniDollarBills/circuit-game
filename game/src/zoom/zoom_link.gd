class_name ZoomLink
extends RefCounted
## How a child layer sits inside its parent. The camera hands over to the child
## when the parent's view shrinks below `parent_min_view`; at that moment the
## child shows `child_max_view` units, centered on `anchor` (in parent units).

var parent := ""
var child := ""
var anchor := Vector2.ZERO
var parent_min_view := 1.0
var child_max_view := 1.0
## True once resolve() has kept this link, made on the fly by a layer, for the
## way back up.
var dynamic := false


static func make(parent_id: String, child_id: String, at: Vector2, min_view: float, max_view: float) -> ZoomLink:
	var l := ZoomLink.new()
	l.parent = parent_id
	l.child = child_id
	l.anchor = at
	l.parent_min_view = min_view
	l.child_max_view = max_view
	return l
