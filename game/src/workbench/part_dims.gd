class_name PartDims
extends RefCounted
## Real part sizes in millimeters, and the map between the board grid and the
## 3D workbench: 1 world unit = 1 cm, the grid pitch is 2.54 mm, and the board
## top is at y = 0.

const GRID_MM := 2.54
## World units (cm) per grid unit.
const GRID := 0.254

## 5 mm LED: dome and flange diameters, height from the flange's underside to
## the top of the dome, square leads 0.5 mm, 2.54 mm apart; the flat on the
## cathode side is 2.5 mm from the axis.
const LED_DOME_D := 5.0
const LED_FLANGE_D := 5.8
const LED_HEIGHT := 8.6
const LED_LEAD := 0.5
const LED_LEAD_PITCH := 2.54
const LED_FLAT := 2.5
## A new 5 mm LED's legs below its rim, uncut: about 25 mm, with the + (anode)
## leg a little longer (typically 1–2 mm) so the two can be told apart.
const LED_CATHODE_LEG := 25.4
const LED_ANODE_LEG := 27.4
## Resistor bodies, length × diameter: ¼ W carbon film and 1 W metal film.
const RESISTOR_BODY := Vector2(6.3, 2.4)
const RESISTOR_1W_BODY := Vector2(11.0, 4.5)
const RESISTOR_LEAD_D := 0.6
## Mini toggle switch body, length × width × height, and its lever.
const SWITCH_BODY := Vector3(13, 8, 10)
const SWITCH_LEVER := 10.0
## AA cell length × diameter, and a 4 × AA holder, length × width × height.
const AA_CELL := Vector2(50.5, 14.5)
const AA_HOLDER := Vector3(63, 58, 15)
## 22 AWG jumper wire.
const WIRE_COPPER_D := 0.64
const WIRE_INSULATION_D := 1.4
## Perfboard: FR-4 thickness, hole and tinned pad diameters.
const BOARD_THICK := 1.6
const HOLE_D := 1.0
const PAD_D := 1.8
## Handheld multimeter, length × width × height.
const MULTIMETER := Vector3(150, 75, 35)


## Millimeters to world units.
static func mm(x: float) -> float:
	return x / 10.0


static func grid_to_world(p: Vector2) -> Vector3:
	return Vector3(p.x * GRID, 0.0, p.y * GRID)


static func world_to_grid(v: Vector3) -> Vector2:
	return Vector2(v.x / GRID, v.z / GRID)
