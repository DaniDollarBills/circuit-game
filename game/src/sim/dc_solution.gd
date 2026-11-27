class_name DcSolution
extends RefCounted
## Result of a DC operating-point solve. Voltages are relative to each powered
## component's reference net; floating nets are NAN.

var converged := false
var iterations := 0
## True when plain Newton failed and the source-stepping fallback ran.
var stepped := false
var net_volts := PackedFloat64Array()
## Part id → amps. Battery: out of `pos`. Resistor, ammeter: a→b. LED: anode→cathode.
## Voltmeter: pos→neg. Devices in floating components carry 0.
var device_amps: Dictionary = {}
var device_watts: Dictionary = {}
