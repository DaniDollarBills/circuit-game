class_name E12
extends RefCounted
## The E12 series (IEC 60063): the 12 standard resistor values in every decade.
## Every E12 value is also in E24, the usual series for ±5% resistors.

const BASE: PackedFloat64Array = [10.0, 12.0, 15.0, 18.0, 22.0, 27.0, 33.0, 39.0, 47.0, 56.0, 68.0, 82.0]
## Relative slack so that 150.00000000000003 still counts as 150.
const EPS := 1e-9


static func values(lo := 10.0, hi := 10000.0) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	if not (lo > 0.0) or hi < lo:
		return out
	for k in range(_decade(lo) - 2, _decade(hi) + 2):
		for b in BASE:
			var v := _scaled(b, k)
			if v >= lo * (1.0 - EPS) and v <= hi * (1.0 + EPS):
				out.append(v)
	return out


## The smallest standard value that is at least `r`, or NAN for r ≤ 0.
static func at_or_above(r: float) -> float:
	if not (r > 0.0) or is_inf(r):
		return NAN
	var k := _decade(r)
	for d in range(k - 2, k + 2):
		for b in BASE:
			var v := _scaled(b, d)
			if v >= r * (1.0 - EPS):
				return v
	return NAN


static func _decade(x: float) -> int:
	return floori(log(x) / log(10.0))


## b × 10^k, computed so whole-number values come out exact.
static func _scaled(b: float, k: int) -> float:
	return b * pow(10.0, k) if k >= 0 else b / pow(10.0, -k)
