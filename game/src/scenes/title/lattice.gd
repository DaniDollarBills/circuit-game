class_name Lattice
extends RefCounted
## Crystal positions in ångströms, for the title's closest zooms.


## Idealized cristobalite (the high-temperature form of silica, SiO₂): Si on
## diamond sites (an FCC lattice plus a (¼,¼,¼) basis) and an O at the middle
## of every Si–Si bond, so each Si has four O around it and each O bridges two
## Si. With a = 7.16 Å the Si–O bond is 1.550 Å.
static func silica(cells: Vector3i, a := 7.16) -> Dictionary:
	var fcc := fcc(cells, a)
	var si := PackedVector3Array()
	var o := PackedVector3Array()
	var quarter := Vector3.ONE * a / 4.0
	var bonds := [Vector3(1, 1, 1), Vector3(1, -1, -1), Vector3(-1, 1, -1), Vector3(-1, -1, 1)]
	var limit := Vector3(cells) * a
	for p in fcc:
		si.append(p)
		var b := p + quarter
		if b.x < limit.x and b.y < limit.y and b.z < limit.z:
			si.append(b)
	for p in fcc:
		# Each FCC-site Si bonds to four basis-site Si at a/4 · (±1, ±1, ±1).
		for d in bonds:
			var mid: Vector3 = p + (d as Vector3) * a / 8.0
			if mid.x >= 0.0 and mid.y >= 0.0 and mid.z >= 0.0 and mid.x < limit.x and mid.y < limit.y and mid.z < limit.z:
				o.append(mid)
	return {"si": si, "o": o}


## Face-centered cubic sites (copper: a = 3.615 Å, nearest neighbors 2.556 Å).
static func fcc(cells: Vector3i, a := 3.615) -> PackedVector3Array:
	var out := PackedVector3Array()
	var basis := [Vector3(0, 0, 0), Vector3(0, 0.5, 0.5), Vector3(0.5, 0, 0.5), Vector3(0.5, 0.5, 0)]
	for i in cells.x:
		for j in cells.y:
			for k in cells.z:
				for b in basis:
					out.append((Vector3(i, j, k) + (b as Vector3)) * a)
	return out


## The point of `pts` nearest `to`.
static func nearest(pts: PackedVector3Array, to: Vector3) -> Vector3:
	var best := Vector3.INF
	var best_d := INF
	for p in pts:
		var d := p.distance_squared_to(to)
		if d < best_d:
			best_d = d
			best = p
	return best
