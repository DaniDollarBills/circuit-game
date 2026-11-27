class_name Catalog
extends RefCounted
## Every part kind: title, footprint, pins (in a fixed order) and defaults, plus
## real-world datasheet rows. Pin offsets are grid units at rotation 0.

const PARTS := {
	"battery": {
		"title": "Battery pack (4 × AA)", "size": Vector2i(2, 4),
		"pins": [["pos", Vector2i(0, -2)], ["neg", Vector2i(0, 2)]],
		"defaults": {"volts": 5.0},
	},
	"resistor": {
		"title": "Resistor", "size": Vector2i(4, 1),
		"pins": [["a", Vector2i(-2, 0)], ["b", Vector2i(2, 0)]],
		"defaults": {"ohms": 220.0, "adjustable": false, "watts": 0.25},
	},
	"led": {
		"title": "LED", "size": Vector2i(2, 1),
		"pins": [["anode", Vector2i(-1, 0)], ["cathode", Vector2i(1, 0)]],
		"defaults": {"color": "red"},
	},
	"switch": {
		"title": "Switch", "size": Vector2i(4, 1),
		"pins": [["a", Vector2i(-2, 0)], ["b", Vector2i(2, 0)]],
		"defaults": {"closed": false},
	},
	"ammeter": {
		"title": "Current meter", "size": Vector2i(2, 2),
		"pins": [["a", Vector2i(-1, 0)], ["b", Vector2i(1, 0)]],
		"defaults": {},
	},
	"voltmeter": {
		"title": "Voltage meter", "size": Vector2i(2, 2),
		"pins": [["pos", Vector2i(-1, 0)], ["neg", Vector2i(1, 0)]],
		"defaults": {},
	},
}

## 1 W resistors have bigger bodies, so their leads are 15.24 mm apart.
const ONE_WATT_PINS := [["a", Vector2i(-3, 0)], ["b", Vector2i(3, 0)]]
const ONE_WATT_SIZE := Vector2i(6, 1)

const LED_DATA := {
	"red": {"name": "Red", "nm": 625, "vf": "2.0"},
	"yellow": {"name": "Yellow", "nm": 590, "vf": "2.1"},
	"green": {"name": "Green", "nm": 570, "vf": "2.2"},
	"blue": {"name": "Blue", "nm": 470, "vf": "3.0"},
}


static func has_kind(kind: String) -> bool:
	return PARTS.has(kind)


static func title(kind: String) -> String:
	return PARTS[kind]["title"]


static func defaults(kind: String) -> Dictionary:
	return PARTS[kind]["defaults"] if PARTS.has(kind) else {}


static func pins(kind: String, props := {}) -> Array:
	if kind == "resistor" and _is_one_watt(props):
		return ONE_WATT_PINS
	return PARTS[kind]["pins"]


static func size(kind: String, props := {}) -> Vector2i:
	if kind == "resistor" and _is_one_watt(props):
		return ONE_WATT_SIZE
	return PARTS[kind]["size"]


static func pin_names(kind: String) -> PackedStringArray:
	var out := PackedStringArray()
	for entry in PARTS[kind]["pins"]:
		out.append(entry[0])
	return out


static func has_pin(kind: String, pin: String) -> bool:
	return PARTS.has(kind) and pin in pin_names(kind)


## Datasheet rows {label, value, term}; `term` is a glossary key or "".
static func datasheet(p: Part) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	match p.kind:
		"battery":
			rows.append(_row("Voltage", "%.1f V" % float(p.props.get("volts", 5.0)), "voltage"))
			rows.append(_row("Cells", "4 × AA, partly used", ""))
			rows.append(_row("Internal resistance", "1 Ω", "internal resistance"))
			rows.append(_row("Short-circuit current", "5 A, gets hot!", "short circuit"))
		"resistor":
			var watts := float(p.props.get("watts", 0.25))
			var trimmer := bool(p.props.get("adjustable", false))
			rows.append(_row("Resistance", format_ohms(float(p.props.get("ohms", 220.0))), "resistance"))
			# Trimmers like the common 3386 are ±10%; fixed film resistors ±5%.
			rows.append(_row("Tolerance", "±10%" if trimmer else "±5%", "tolerance"))
			rows.append(_row("Power rating", _format_watts(watts), "power"))
			if trimmer:
				rows.append(_row("Type", "Cermet trimmer", "trimmer"))
			else:
				rows.append(_row("Type", "Metal film" if watts >= 1.0 else "Carbon film",
						"metal film" if watts >= 1.0 else "carbon film"))
		"led":
			var d: Dictionary = LED_DATA.get(str(p.props.get("color", "red")), LED_DATA["red"])
			rows.append(_row("Color", "%s, %d nm" % [d["name"], d["nm"]], "wavelength"))
			rows.append(_row("Forward voltage", "%s V at 20 mA" % d["vf"], "forward voltage"))
			rows.append(_row("Recommended current", "20 mA", "current"))
			rows.append(_row("Absolute maximum", "30 mA", "absolute maximum"))
			rows.append(_row("Polarity", "+ anode (long leg), − cathode (flat side)", "polarity"))
		"switch":
			rows.append(_row("Type", "SPST toggle (single-pole, single-throw)", "switch"))
			rows.append(_row("State", "Closed" if p.props.get("closed", false) else "Open", ""))
		"ammeter":
			rows.append(_row("Measures", "Current, placed in series", "ammeter"))
			rows.append(_row("Burden", "0.1 Ω", "burden"))
			rows.append(_row("Fuse", "500 mA", "fuse"))
		"voltmeter":
			rows.append(_row("Measures", "Voltage, placed in parallel", "voltmeter"))
			rows.append(_row("Input resistance", "10 MΩ", "input resistance"))
	return rows


## 220 → "220 Ω", 1000 → "1 kΩ", 4700 → "4.7 kΩ", 1e7 → "10 MΩ".
static func format_ohms(ohms: float) -> String:
	if ohms >= 1_000_000.0:
		return _trim(ohms / 1_000_000.0) + " MΩ"
	if ohms >= 1000.0:
		return _trim(ohms / 1000.0) + " kΩ"
	return _trim(ohms) + " Ω"


static func _format_watts(watts: float) -> String:
	if is_equal_approx(watts, 0.25):
		return "0.25 W (¼ W)"
	if is_equal_approx(watts, 0.5):
		return "0.5 W (½ W)"
	return _trim(watts) + " W"


static func _trim(v: float) -> String:
	return ("%.2f" % v).rstrip("0").rstrip(".")


static func _is_one_watt(props: Dictionary) -> bool:
	return float(props.get("watts", 0.25)) >= 1.0


static func _row(label: String, value: String, term: String) -> Dictionary:
	return {"label": label, "value": value, "term": term}
