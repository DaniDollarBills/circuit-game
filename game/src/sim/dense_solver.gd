class_name DenseSolver
extends RefCounted
## Solves A·x = b with Gaussian elimination and partial pivoting.


## `a` is row-major n×n. Returns an empty array when the matrix is singular
## (any pivot below 1e-15) — and also for n = 0, so callers handle that first.
static func solve(a: PackedFloat64Array, b: PackedFloat64Array, n: int) -> PackedFloat64Array:
	var m := a.duplicate()
	var r := b.duplicate()
	for col in n:
		var pivot := col
		var best := absf(m[col * n + col])
		for row in range(col + 1, n):
			var v := absf(m[row * n + col])
			if v > best:
				best = v
				pivot = row
		if best < 1e-15:
			return PackedFloat64Array()
		if pivot != col:
			for k in n:
				var t := m[col * n + k]
				m[col * n + k] = m[pivot * n + k]
				m[pivot * n + k] = t
			var tr := r[col]
			r[col] = r[pivot]
			r[pivot] = tr
		var d := m[col * n + col]
		for row in range(col + 1, n):
			var f := m[row * n + col] / d
			if f == 0.0:
				continue
			for k in range(col, n):
				m[row * n + k] -= f * m[col * n + k]
			r[row] -= f * r[col]
	var x := PackedFloat64Array()
	x.resize(n)
	for row in range(n - 1, -1, -1):
		var s := r[row]
		for k in range(row + 1, n):
			s -= m[row * n + k] * x[k]
		x[row] = s / m[row * n + row]
	return x
