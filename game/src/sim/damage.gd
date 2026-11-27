class_name Damage
extends RefCounted
## What burns out: LEDs above their 30 mA absolute maximum, resistors above
## their power rating, and ammeter fuses above 500 mA.


## Entries {part, reason, ratio}, largest overload first.
static func detect(_c: Circuit, n: Netlist, s: DcSolution, _flows: Dictionary) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for d in n.devices:
		var p: Part = d["part"]
		var amps: float = s.device_amps.get(p.id, 0.0)
		match d["kind"]:
			"led":
				if amps > Devices.LED_MAX_AMPS:
					found.append({"part": p.id, "reason": "overcurrent", "ratio": amps / Devices.LED_MAX_AMPS})
			"resistor":
				var watts: float = s.device_watts.get(p.id, 0.0)
				var rating := float(p.props.get("watts", Devices.RESISTOR_DEFAULT_WATTS))
				if watts > rating:
					found.append({"part": p.id, "reason": "overheat", "ratio": watts / rating})
			"ammeter":
				if absf(amps) > Devices.AMMETER_FUSE_AMPS:
					found.append({"part": p.id, "reason": "fuse", "ratio": absf(amps) / Devices.AMMETER_FUSE_AMPS})
	found.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x["ratio"] > y["ratio"])
	return found
