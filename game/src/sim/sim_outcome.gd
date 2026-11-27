class_name SimOutcome
extends RefCounted
## The result of simulate(): the final readings, the circuit with any burnt
## parts marked, and what burned (in order).

var result: SimResult
var circuit: Circuit
var damage: Array[Dictionary] = []
