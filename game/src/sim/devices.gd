class_name Devices
extends RefCounted
## Electrical constants and the LED junction model (exact values from the plan).

const BATTERY_OHMS := 1.0
const LED_N := 2.0
const VT := 0.025852
const LED_SERIES_OHMS := 5.0
## Junction voltage at 20 mA; the terminal voltage adds 5 Ω × 20 mA = 0.1 V.
const LED_VF_20MA := {"red": 1.90, "yellow": 2.00, "green": 2.10, "blue": 2.90}
const LED_LIT_AMPS := 0.0005
const LED_FULL_AMPS := 0.020
const LED_MAX_AMPS := 0.030
const RESISTOR_DEFAULT_WATTS := 0.25
const AMMETER_OHMS := 0.1
const AMMETER_FUSE_AMPS := 0.5
const VOLTMETER_OHMS := 1.0e7
const CONNECTOR_G := 1000.0
const SHORT_AMPS := 1.0
const GMIN := 1e-12
## exp() argument cap for the junction model, to avoid overflow.
const MAX_EXP_ARG := 80.0


static func led_nvt() -> float:
	return LED_N * VT


static func led_isat(color: String) -> float:
	return 0.02 / exp(float(LED_VF_20MA.get(color, LED_VF_20MA["red"])) / led_nvt())


static func led_vcrit(isat: float) -> float:
	var nvt := led_nvt()
	return nvt * log(nvt / (sqrt(2.0) * isat))


## SPICE-style junction voltage limiting between Newton iterations.
static func pnjlim(vnew: float, vold: float, vt: float, vcrit: float) -> float:
	if vnew > vcrit and absf(vnew - vold) > 2.0 * vt:
		if vold > 0.0:
			var arg := 1.0 + (vnew - vold) / vt
			return vold + vt * log(arg) if arg > 0.0 else vcrit
		return vt * log(vnew / vt)
	return vnew
