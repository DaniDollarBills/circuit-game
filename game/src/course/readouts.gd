class_name Readouts
extends RefCounted
## Live values from the simulation, for Try it's readouts and the recap's
## "your numbers": a part's current, voltage, power, resistance or meter
## reading, written the way the game writes numbers. A part that's missing,
## floating or unreadable reads "—", never "nan".

const QUANTITIES: PackedStringArray = ["mA", "V", "W", "ohms", "reading"]
const NONE := "—"


## The value in the quantity's own unit (mA, V, W, Ω; a meter's reading in mA
## or V); NAN when it can't be read.
static func value(part_id: String, quantity: String, circuit: Circuit, sim: SimResult) -> float:
	var p := circuit.find_part(part_id) if circuit != null else null
	if p == null or sim == null:
		return NAN
	match quantity:
		"mA":
			return absf(float(sim.part_amps.get(p.id, NAN))) * 1000.0
		"W":
			return absf(float(sim.part_watts.get(p.id, NAN)))
		"V":
			var pins := Catalog.pin_names(p.kind)
			if pins.size() < 2:
				return NAN
			return absf(sim.pin_volts(p.id, pins[0]) - sim.pin_volts(p.id, pins[1]))
		"ohms":
			return float(p.props.get("ohms", NAN))
		"reading":
			var raw := float(sim.meter.get(p.id, NAN))
			return absf(raw) * 1000.0 if p.kind == "ammeter" else raw
	return NAN


static func format(quantity: String, v: float) -> String:
	if not is_finite(v):
		return NONE
	match quantity:
		"mA":
			return "%.1f mA" % v
		"W":
			return "%.2f W" % v
		"V":
			return "%.2f V" % v
		"ohms":
			return Catalog.format_ohms(v)
	return NONE


## The value with its unit: a meter's reading in mA (current) or V (voltage).
static func text_value(part_id: String, quantity: String, circuit: Circuit, sim: SimResult) -> String:
	var v := value(part_id, quantity, circuit, sim)
	if quantity == "reading":
		var p := circuit.find_part(part_id) if circuit != null else null
		return format("mA" if p != null and p.kind == "ammeter" else "V", v)
	return format(quantity, v)


## "LED: 13.8 mA": the part's label (or its title), then its value.
static func text(r: Dictionary, circuit: Circuit, sim: SimResult) -> String:
	var id := str(r.get("part", ""))
	var p := circuit.find_part(id) if circuit != null else null
	var name := id
	if p != null:
		var label := str(p.props.get("label", ""))
		name = label if label != "" else Catalog.title(p.kind)
	return "%s: %s" % [name, text_value(id, str(r.get("quantity", "")), circuit, sim)]
