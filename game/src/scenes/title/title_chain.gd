class_name TitleChain
extends RefCounted
## The title's zoom: from the whole Earth down to one silicon atom on a
## beach. Shared by the title screen, its director and the tests.

const ORDER: PackedStringArray = ["title.globe", "title.coast", "title.beach", "title.grain", "title.silica", "title.atom"]
## id: [meters per unit, min view, max view, home view]
const LAYERS := {
	"title.globe": [1000.0, 300.0, 40000.0, 30000.0],
	"title.coast": [10.0, 20.0, 40000.0, 4000.0],
	"title.beach": [0.01, 1.5, 30000.0, 3000.0],
	"title.grain": [1e-5, 0.4, 2000.0, 150.0],
	"title.silica": [1e-10, 3.0, 60.0, 30.0],
	"title.atom": [1e-12, 200.0, 400.0, 400.0],
}
## The silica patch the camera dives into: 3 × 3 × 3 cells centered on the origin.
const SILICA_CELLS := Vector3i(3, 3, 3)
const SILICA_A := 7.16


static func infos() -> Dictionary:
	var out := {}
	for id in LAYERS:
		var l: Array = LAYERS[id]
		out[id] = LayerInfo.make(id, l[0], l[1], l[2])
	return out


static func home(id: String) -> float:
	return float(LAYERS[id][3])


static func links() -> Array[ZoomLink]:
	return [
		ZoomLink.make("title.globe", "title.coast", Vector2.ZERO, 400.0, 40000.0),
		ZoomLink.make("title.coast", "title.beach", Vector2.ZERO, 30.0, 30000.0),
		ZoomLink.make("title.beach", "title.grain", Vector2.ZERO, 2.0, 2000.0),
		# Too small to follow continuously: the scale bar says it skips ahead.
		ZoomLink.make("title.grain", "title.silica", Vector2.ZERO, 0.5, 60.0),
		ZoomLink.make("title.silica", "title.atom", atom_anchor(), 4.0, 400.0),
	] as Array[ZoomLink]


## The silica patch, centered on the origin (Å) and tilted so its tetrahedra
## show in depth.
static func silica_patch() -> Dictionary:
	var s := Lattice.silica(SILICA_CELLS, SILICA_A)
	var shift := -Vector3(SILICA_CELLS) * SILICA_A / 2.0
	var tilt := Basis.from_euler(Vector3(deg_to_rad(22.0), deg_to_rad(-34.0), 0.0))
	for key in ["si", "o"]:
		var pts: PackedVector3Array = s[key]
		for i in pts.size():
			pts[i] = tilt * (pts[i] + shift)
		s[key] = pts
	return s


## Where the atom layer opens: the Si atom nearest the patch's center, seen
## face-on (layer x right, y down).
static func atom_anchor() -> Vector2:
	var si := Lattice.nearest(silica_patch()["si"], Vector3.ZERO)
	return Vector2(si.x, -si.y)
