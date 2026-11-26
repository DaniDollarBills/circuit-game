# M1 "First Light" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A playable, downloadable first slice of *Circuit*. It has a title zoom from Earth down to a silicon atom, the pastel circuit editor with a real DC simulator, Chapter 1 "Spark" (8 levels with a guide, hints and tests), and a zoom into a wire down to copper atoms. Windows, macOS, Linux and web builds are produced by CI.

**Architecture:**
- A Godot 4.7.2 project in `game/`.
- Pure GDScript logic (circuit model, analog solver, lessons, saves, zoom math, gestures, editor rules) never touches nodes. It is tested headless by a small custom runner.
- Presentation is a thin layer of scenes. A `ZoomStage` stacks one `SubViewportContainer` per zoom level and cross-fades neighbors. The HUD is Godot `Control` UI with a generated pastel `Theme`.

**Tech Stack:**
- Godot 4.7.2-stable (standard build) and GDScript
- Xvfb with Mesa for screenshot captures
- GitHub Actions for tests and exports
- Nunito font (OFL)
- Natural Earth land data (public domain), converted with world-atlas 2.0.2 and topojson-client 3.1.0

**Spec:** `docs/superpowers/specs/2026-11-26-circuit-game-design.md`

## Global Constraints

**Engine and code**
- Godot **4.7.2-stable** standard (not .NET). Godot project root is `game/`, so `res://` = `game/`. GDScript only in M1.
- GDScript is statically typed everywhere: typed `var`, typed arrays (`Array[Part]`), return types, and a `class_name` on every reusable script. Indent with tabs.
- Pure-logic folders `src/circuit`, `src/sim`, `src/lessons`, `src/save`, `src/content` and the pure files listed in each task must not use `Node`, the `SceneTree` or autoloads. They must run under `--headless`.
- **No autoloads.** `Main` owns the `Game` node and injects it into screens (`screen.game = game`), so scenes are testable in isolation.

**Data conventions**
- Ids, pin names, part kinds, goal kinds, settings keys and Dictionary keys are **`String`**, never `StringName`. Pin keys are `"<part_id>:<pin>"`.
- Grid: 1 unit = 2.54 mm. The y axis points **down**. `rot` ∈ {0, 90, 180, 270} degrees **clockwise**. 90° maps (x, y) → (−y, x).
- World pixels per grid unit in 2D views: **32**.

**Electrical constants (exact)**

| Constant | Value |
|---|---|
| Battery | 5.0 V, internal resistance 1.0 Ω |
| LED ideality and thermal voltage | n = 2, Vt = 0.025852 V |
| LED series resistance | 5.0 Ω |
| LED junction voltage at 20 mA | red 1.90, yellow 2.00, green 2.10, blue 2.90 V |
| LED thresholds | lit ≥ 0.0005 A, full brightness 0.020 A, burns > 0.025 A |
| Resistor | burns > 0.25 W; adjustable range 100–2000 Ω, step 10 |
| Ammeter | burden 0.1 Ω (conductance 10 S) in current-flow only; fuse 0.5 A |
| Wire and closed-switch flow conductance | 1000 S |
| Battery "short" flag | > 1.0 A |
| gmin | 1e-12 S |

**Look**
- Light palette (exact hex): `cream #FFF8EF`, `paper #FFFFFF`, `ink #3D3A4B`, `ink_soft #6E6A80`, `line #E7E1F0`, `lavender #CDB8F0`, `lilac #E6DAFB`, `mint #BDEBD7`, `sky #BFDDF8`, `peach #FFD3B8`, `butter #FFF0A6`, `rose #F8C3D6`, `coral #FF9F8A`, `signal_low #B9B3D1`, `signal_high #FF8FAB`, `spark #FFE58A`, `metal #D9D6E6`.
- Night palette overrides: `cream #24212F`, `paper #2F2B3D`, `ink #F3EEFF`, `ink_soft #BDB6D6`, `line #3B3650`.
- LED tints: red `#FF8F9A`, yellow `#FFE27A`, green `#8FE3B0`, blue `#8FC2FF`.
- Font: Nunito 400/700/800 (`@fontsource/nunito@5.3.0` woff2 files), imported with MSDF enabled.

**Copy and interaction**
- Player-facing guide lines: at most 2 sentences and 30 words each. Glossary markup is `[[term]]` or `[[term|shown text]]`.
- Touch targets ≥ 44 px. The pin hit radius is at least 22 screen px and at least 0.35 grid units.

**Platform**
- Renderers: `forward_plus` on desktop, `mobile` on phones, `gl_compatibility` on the web. Every visual must work in `gl_compatibility`.
- The game makes no network calls at runtime.

**Commits**
- Commit messages use `feat:`, `fix:`, `test:`, `chore:` or `docs:` prefixes and end with the attribution lines the session requires.

## Review Focus

1. **Touch while wiring:** a second finger landing during a wire drag cancels the drag. No stray wire is created, and the camera pinches instead. Emulated mouse events from touch are ignored by the editor, so there is no double input. *Tests:* Task 13 `test_second_pointer_cancels_drag`, Task 15 `test_drag_cancel_while_wiring_commits_nothing`, Task 20 `test_touch_second_finger_cancels_wire`.
2. **Degenerate circuits never crash, hang or produce NaN.** This covers an empty board, a wire between two pins of one part, opposing batteries, a battery shorted by a switch or an ammeter, floating parts, and an LED straight across a battery. *Tests:* Task 6 edge-case tests and Task 7 `test_fuzz_never_nan`.
3. **Broken saves:** a corrupt file, an unknown version or an unwritable folder all start the game with defaults. Corrupt data is backed up, never lost silently. *Tests:* Task 9 storage tests.
4. **Rotating or resizing the window mid-level:** the circuit stays fully visible and the HUD reflows between landscape and portrait. *Tests:* Task 20 `test_resize_keeps_circuit_visible`.
5. **Undo after damage:** undo restores the unburnt part and re-simulates, so no stale burnt visuals or toasts remain. *Tests:* Task 16 `test_undo_after_burn_restores_part`.

## Execution notes

- **Permission:** Task 1 downloads the Godot binary (SHA-512 verified) and runs it. In this cloud environment, downloading and running that binary needs the owner's approval. Ask for it before starting Task 1.
- **Screenshot captures** need `apt-get install -y xvfb libgl1-mesa-dri mesa-vulkan-drivers`. Captures go to `build/captures/`, which is gitignored. Each capture step means: open the PNG and check it against the listed criteria before committing.
- **Running tests:** `tools/test.sh [filter]` runs everything, or only tests whose `path::name` contains the filter.

## File map

```
tools/godot.sh  tools/test.sh  tools/capture.sh  tools/export.sh  tools/make_land.mjs
.github/workflows/build.yml   .gitignore   README.md
game/project.godot  game/export_presets.cfg  game/icon.svg
game/assets/fonts/nunito-latin-{400,700,800}-normal.woff2  game/assets/fonts/LICENSE
game/data/land_110m.json
game/tools/capture.gd
game/src/app/        main.tscn main.gd game.gd game_state.gd
game/src/circuit/    part.gd wire.gd circuit.gd catalog.gd geometry.gd edits.gd history.gd circuit_io.gd
game/src/sim/        dense_solver.gd netlist.gd devices.gd dc_solution.gd dc_solver.gd current_flow.gd damage.gd sim_result.gd sim_outcome.gd simulator.gd
game/src/lessons/    level_def.gd level_builder.gd goals.gd level_tests.gd solution_diff.gd level_session.gd
game/src/save/       progress.gd progress_storage.gd
game/src/content/    glossary.gd chapters.gd levels.gd ch1/l1_light_it_up.gd … ch1/l8_inside_the_wire.gd
game/src/ui/         palette.gd pastel_theme.gd glossary_text.gd gallery.tscn gallery.gd
game/src/zoom/       zoom_camera.gd zoom_link.gd layer_info.gd zoom_math.gd scale_format.gd zoom_layer.gd zoom_stage.gd zoom_demo.tscn zoom_demo.gd
game/src/input/      gesture_recognizer.gd pointer_input.gd
game/src/editor/     draw_kit.gd resistor_bands.gd visual_state.gd part_art.gd wire_art.gd hit_test.gd editor_controller.gd circuit_view.gd flow_view.gd editor_layer.gd editor_layer.tscn art_gallery.tscn art_gallery.gd
game/src/screens/    title_screen.* map_screen.* level_screen.*
game/src/hud/        top_bar.gd parts_tray.gd goals_panel.gd test_sheet.gd hint_button.gd context_menu.gd value_popover.gd toasts.gd pip.gd guide_bubble.gd glossary_popup.gd settings_sheet.gd scale_bar.gd
game/src/scenes/title/ geo.gd lattice.gd land_texture.gd title_chain.gd globe_layer.gd coast_layer.gd beach_layer.gd grain_layer.gd silica_layer.gd atom_layer.gd title_director.gd
game/src/scenes/wire/  wire_closeup_layer.gd copper_layer.gd
game/tests/          run_tests.gd test_case.gd helpers/circuits.gd + test_*.gd mirroring src/
```

---

### Task 1: Toolchain, project skeleton and test runner

**Files:**
- Create: `tools/godot.sh`, `tools/test.sh`, `.gitignore`, `game/project.godot`, `game/icon.svg`, `game/src/app/main.tscn`, `game/src/app/main.gd`, `game/tests/test_case.gd`, `game/tests/run_tests.gd`, `game/tests/test_runner_selftest.gd`
- Modify: `README.md`

**Interfaces:**
- Produces:
  - `tools/godot.sh`: prints the absolute path of the Godot binary.
  - `tools/test.sh [filter]`: exits 0 only when every test passes.
  - `class_name TestCase extends RefCounted` with:
    - `var tree: SceneTree`
    - `var failures: PackedStringArray`
    - `assert_true(c: bool, msg := "")`, `assert_false(c: bool, msg := "")`
    - `assert_eq(actual: Variant, expected: Variant, msg := "")`
    - `assert_near(actual: float, expected: float, eps: float, msg := "")`
    - `assert_between(x: float, lo: float, hi: float, msg := "")`
    - `fail(msg: String)`
    - `wait_frames(n: int) -> void` (coroutine)
    - `add_to_tree(n: Node) -> Node` (adds to `tree.root`; freed automatically after the test)
    - optional hooks `before_each()` and `after_each()`

- [ ] **Step 1: Write `tools/godot.sh` exactly as follows (it verifies the download before running anything)**

```bash
#!/usr/bin/env bash
set -euo pipefail
VERSION="4.7.2-stable"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/.tools/godot-$VERSION"
BIN="$DIR/Godot_v${VERSION}_linux.x86_64"
if [ ! -x "$BIN" ]; then
  mkdir -p "$DIR"
  BASE="https://github.com/godotengine/godot/releases/download/$VERSION"
  curl -fsSL -o "$DIR/godot.zip" "$BASE/Godot_v${VERSION}_linux.x86_64.zip"
  curl -fsSL -o "$DIR/SHA512-SUMS.txt" "$BASE/SHA512-SUMS.txt"
  EXPECTED="$(grep " Godot_v${VERSION}_linux.x86_64.zip\$" "$DIR/SHA512-SUMS.txt" | cut -d' ' -f1)"
  echo "$EXPECTED  $DIR/godot.zip" | sha512sum -c - >/dev/null
  unzip -q -o "$DIR/godot.zip" -d "$DIR" && rm "$DIR/godot.zip"
fi
echo "$BIN"
```

- [ ] **Step 2: Write `tools/test.sh`.** It always re-imports first (this refreshes the `class_name` cache), then runs `"$GODOT" --headless --path "$ROOT/game" -s res://tests/run_tests.gd -- "--filter=${1:-}"` and propagates the exit code.

- [ ] **Step 3: Write the failing self-test `game/tests/test_runner_selftest.gd`**

```gdscript
extends TestCase

func test_assert_eq_records_failure() -> void:
	var t := TestCase.new()
	t.assert_eq(1, 2)
	assert_eq(t.failures.size(), 1)

func test_async_waits_frames() -> void:
	var before := Engine.get_process_frames()
	await wait_frames(2)
	assert_true(Engine.get_process_frames() >= before + 2)
```

- [ ] **Step 4: Run `tools/test.sh`.** Expected: a non-zero exit, because the runner doesn't exist yet.

- [ ] **Step 5: Implement `test_case.gd`, `run_tests.gd`, the project and the main scene.**
  - **Runner** (`extends SceneTree`):
    - Starts from `_initialize()` with an async `_run()`.
    - Recursively finds `res://tests/**/test_*.gd`.
    - For every method whose name starts with `test_`: creates a new instance, sets `tree`, calls `before_each`, runs `await Callable(inst, name).call()`, calls `after_each`, then frees nodes tracked by `add_to_tree`.
    - Prints `PASS <path>::<name>` or `FAIL <path>::<name>: <failures joined by "; ">`, then a final line `N passed, M failed`.
    - Calls `quit(1)` if M > 0 or N == 0, otherwise `quit(0)`.
    - Honors `--filter=` from `OS.get_cmdline_user_args()`.
  - **`project.godot` keys:**
    - `application/config/name="Circuit"`
    - `run/main_scene="res://src/app/main.tscn"`
    - `display/window/size/viewport_width=1280`, `viewport_height=720`
    - `window/stretch/mode="canvas_items"`, `window/stretch/aspect="expand"`
    - `window/handheld/orientation=6` (sensor)
    - `input_devices/pointing/emulate_mouse_from_touch=true`, `emulate_touch_from_mouse=false`
    - `rendering/renderer/rendering_method="forward_plus"`, `rendering_method.mobile="mobile"`
    - `rendering/anti_aliasing/quality/msaa_2d=2`
    - `rendering/environment/defaults/default_clear_color=Color(1, 0.972549, 0.937255, 1)`
  - **Main scene:** `main.tscn` is a full-rect `Control` named `Main` with a cream `ColorRect`.
  - **`.gitignore`:** `.tools/`, `game/.godot/`, `build/`.

- [ ] **Step 6: Run `tools/test.sh`.** Expected: `2 passed, 0 failed`, exit 0.

- [ ] **Step 7: Update the README** with a short "What this is" section, a link to the spec, and "Run the tests: `tools/test.sh`". Then commit: `git add -A && git commit -m "chore: Godot 4.7.2 project skeleton with headless test runner"`.

### Task 2: Pastel palette, theme, fonts and screenshot capture

**Files:**
- Create: `game/src/ui/palette.gd`, `game/src/ui/pastel_theme.gd`, `game/src/ui/gallery.tscn`, `game/src/ui/gallery.gd`, `game/tools/capture.gd`, `tools/capture.sh`, `game/assets/fonts/*` (three Nunito woff2 files and `LICENSE`, copied from `npm pack @fontsource/nunito@5.3.0`), `game/tests/ui/test_palette.gd`

**Interfaces:**
- Produces:
  - `Palette.color(name: String, night := false) -> Color`
  - `Palette.NAMES: PackedStringArray` (the 17 tokens in Global Constraints)
  - `Palette.led_tint(color: String) -> Color`
  - `Palette.contrast_ratio(a: Color, b: Color) -> float` (WCAG 2.x)
  - `PastelTheme.build(night := false, large_text := false) -> Theme`
  - `tools/capture.sh <res://scene.tscn> <out.png> [WxH] [rendering_method]`

- [ ] **Step 1: Write the failing tests in `test_palette.gd`:**
  - `test_ink_on_cream_at_least_7()` asserts `contrast_ratio(ink, cream) >= 7.0` (expected ≈ 10.5).
  - `test_ink_soft_on_cream_at_least_4_5()` (expected ≈ 4.9).
  - `test_night_ink_on_night_cream_at_least_7()` (expected ≈ 13.9).
  - `test_all_tokens_resolve_in_both_themes()` asserts every name in `NAMES` returns a non-transparent color for `night` false and true.
  - `test_theme_button_has_rounded_style()` asserts `theme.get_stylebox("normal", "Button")` is a `StyleBoxFlat` with `corner_radius_top_left == 16`.
  - `test_large_text_scales_default_font()` asserts `build(false, true).default_font_size == 22` and `build().default_font_size == 18`.
- [ ] **Step 2: Run `tools/test.sh test_palette`.** Expected: FAIL (`Palette` is not defined).
- [ ] **Step 3: Implement `Palette` and `PastelTheme`.**
  - Default font: Nunito Regular at 18 px (22 px with `large_text`).
  - `HeadingLabel` type variation: Nunito ExtraBold, 28 px.
  - Button styles for normal, hover, pressed, disabled and focus: `StyleBoxFlat` with a lilac/lavender fill, `corner_radius` 16, content margins 14/10, a 2 px border in ink at 15% alpha, `shadow_size` 6, shadow color ink at 12% alpha, offset (0, 3).
  - `PanelContainer`: paper fill, radius 20, shadow 10.
  - Label font color: ink.
  - After the first import, set `multichannel_signed_distance_field=true` in each font's `.import` file and re-import.
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Write `capture.gd` and `capture.sh`.**
  - `capture.gd` (`extends SceneTree`): reads `--scene=` and `--out=`, instantiates the scene under `root`, awaits 30 `process_frame`s, saves `root.get_texture().get_image()` with `save_png`, then quits.
  - `capture.sh`: wraps `xvfb-run -a -s "-screen 0 ${WxH}x24"` around `"$GODOT" --path game --rendering-method "${4:-gl_compatibility}" --resolution "$WxH" -s res://tools/capture.gd -- --scene=$1 --out=<absolute path>`.
- [ ] **Step 6: Visual check.** Run `tools/capture.sh res://src/ui/gallery.tscn build/captures/gallery.png` and open it. It passes if:
  - the background is cream
  - buttons are pastel, rounded and softly shadowed
  - the Nunito text is crisp
  - the night variant (gallery toggles with `--night`) has light text on deep plum
- [ ] **Step 7: Commit** with `feat: pastel palette, theme, Nunito fonts and capture tool`.

### Task 3: Circuit model and geometry

**Files:**
- Create: `game/src/circuit/{part,wire,circuit,catalog,geometry}.gd`, `game/tests/helpers/circuits.gd`, `game/tests/circuit/test_geometry.gd`, `game/tests/circuit/test_circuit.gd`

**Interfaces:**
- Produces:
  - `class_name Part extends RefCounted`:
    - `var id: String`, `var kind: String`, `var x: int`, `var y: int`, `var rot: int`
    - `var props: Dictionary` (keys: `volts`, `ohms`, `adjustable`, `color`, `closed`, `burnt`, `label`)
    - `var locked := false`
    - `var tray := -1` (index of the tray item the part came from; −1 for level parts)
    - `static func make(id: String, kind: String, x: int, y: int, rot := 0, props := {}, locked := false) -> Part` (missing props are filled from the catalog defaults)
    - `func copy() -> Part`
  - `class_name Wire extends RefCounted`:
    - `var id: String`, `var a_part: String`, `var a_pin: String`, `var b_part: String`, `var b_pin: String`
    - `var locked := false`
    - `var via: Array[Vector2i] = []` (author-placed waypoints; empty means auto-route)
    - `static func make(id, a_part, a_pin, b_part, b_pin, locked := false, via: Array[Vector2i] = []) -> Wire`
    - `func copy() -> Wire`
  - `class_name Circuit extends RefCounted`:
    - `var parts: Array[Part]`, `var wires: Array[Wire]`
    - `func copy() -> Circuit` (deep)
    - `func find_part(id_or_label: String) -> Part` (matches id first, then `props.label`; returns null when nothing matches)
    - `func find_wire(id: String) -> Wire`
    - `func wires_at(part_id: String, pin: String) -> Array[Wire]`
  - `Catalog.PARTS: Dictionary` (kind → `{title: String, size: Vector2i, pins: Array` of `[name, Vector2i]` in **this order**`, defaults: Dictionary}`):

    | kind | title | size | pins (rot 0) | defaults |
    |---|---|---|---|---|
    | `battery` | Battery pack | (2,4) | `pos` (0,−2), `neg` (0,2) | `{volts: 5.0}` |
    | `resistor` | Resistor | (4,1) | `a` (−2,0), `b` (2,0) | `{ohms: 220.0, adjustable: false}` |
    | `led` | LED | (2,1) | `anode` (−1,0), `cathode` (1,0) | `{color: "red"}` |
    | `switch` | Switch | (4,1) | `a` (−2,0), `b` (2,0) | `{closed: false}` |
    | `ammeter` | Current meter | (2,2) | `a` (−1,0), `b` (1,0) | `{}` |
    | `voltmeter` | Voltage meter | (2,2) | `pos` (−1,0), `neg` (1,0) | `{}` |

  - `Catalog.pin_names(kind) -> PackedStringArray` and `Catalog.title(kind) -> String`
  - `CircuitGeometry.rotate_offset(v: Vector2i, rot: int) -> Vector2i`
  - `CircuitGeometry.pin_position(p: Part, pin: String) -> Vector2i`
  - `CircuitGeometry.pin_outward(p: Part, pin: String) -> Vector2i` (the unit axis pointing from the part center toward the pin)
  - `CircuitGeometry.part_rect(p: Part) -> Rect2` (rotated bounds)
  - `CircuitGeometry.wire_path(c: Circuit, w: Wire) -> PackedVector2Array`
  - Test helper `class_name TestCircuits`:
    - `compact_loop(ohms := 220.0, color := "red") -> Circuit` (battery B1 at (−6,0); R1 at (−2,−4); L1 LED at (6,0) rot 90; wires w1 B1.pos→R1.a, w2 R1.b→L1.anode, w3 L1.cathode→B1.neg)
    - `battery_only() -> Circuit`
    - `with_wire(c, id, a_part, a_pin, b_part, b_pin) -> Circuit`

- [ ] **Step 1: Write the failing tests.**
  - `test_rotate_offset_cw()`: (2,0) maps to (0,2) at 90, (−2,0) at 180 and (0,−2) at 270; (0,−2) maps to (2,0) at 90.
  - `test_led_rot90_pins()`: LED at (4,0) rot 90 has its anode at (4,−1) and cathode at (4,1).
  - `test_part_rect_rotated()`: resistor at (0,0) rot 90 has rect `Rect2(-0.5, -2, 1, 4)`.
  - `test_pin_outward()`: resistor rot 0 pin `a` points (−1,0); battery `pos` points (0,−1).
  - `test_wire_path_compact_loop()`: w1 → `[(-6,-2),(-6,-4),(-4,-4)]`; w2 → `[(0,-4),(6,-4),(6,-1)]`; w3 → `[(6,1),(6,3),(-6,3),(-6,2)]`.
  - `test_wire_path_bracket()`: two switches A at (4,−4) and B at (4,−7); wire A.a→B.a → `[(2,-4),(1,-4),(1,-7),(2,-7)]`.
  - `test_wire_path_via()`: a wire with `via` [(−4,−6),(9,−6),(9,1)] from R1.a to L1.cathode → `[(-4,-4),(-4,-6),(9,-6),(9,1),(6,1)]`.
  - `test_find_part_by_label()` and `test_copy_is_deep()`.
- [ ] **Step 2: Run `tools/test.sh circuit/`.** Expected: FAIL.
- [ ] **Step 3: Implement.** `wire_path` uses this algorithm (the signature doesn't determine it):

```gdscript
# A, B = pin positions; P/Q = one-unit stubs along each pin's outward axis.
# via wires: [A] + via + [B]. Otherwise route an L between the stubs, leaving A along its axis.
var pts: Array[Vector2] = []
if not w.via.is_empty():
	pts.append(A); for v in w.via: pts.append(Vector2(v)); pts.append(B)
else:
	var P := A + Vector2(out_a); var Q := B + Vector2(out_b)
	var corner := Vector2(Q.x, P.y) if out_a.x != 0 else Vector2(P.x, Q.y)
	pts = [A, P, corner, Q, B]
# then: drop consecutive duplicates, then drop middle points collinear with both neighbors
```

- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: circuit model, part catalog and wire routing`.

### Task 4: Edits, undo history and save format

**Files:**
- Create: `game/src/circuit/{edits,history,circuit_io}.gd`, `game/tests/circuit/{test_edits,test_history,test_circuit_io}.gd`

**Interfaces:**
- Consumes: Task 3 types.
- Produces:
  - `CircuitEdits` static functions, all returning a **new** `Circuit` and never mutating their input:
    - `add_part(c, p: Part)`
    - `move_part(c, id, x: int, y: int)` (no-op on locked parts)
    - `rotate_part(c, id)` (adds 90 modulo 360; no-op on locked parts)
    - `delete_part(c, id)` (also removes attached wires; no-op on locked parts)
    - `set_props(c, id, patch: Dictionary)` (allowed on locked parts)
    - `can_add_wire(c, a_part, a_pin, b_part, b_pin) -> String` (returns `""` if OK, otherwise `"same pin"`, `"unknown pin"` or `"duplicate"`)
    - `add_wire(c, a_part, a_pin, b_part, b_pin) -> Circuit` (asserts `can_add_wire` is `""`)
    - `delete_wire(c, id)` (no-op on locked wires)
    - `next_id(c, prefix: String) -> String`
  - `class_name CircuitHistory extends RefCounted`:
    - `var present: Circuit`
    - `const LIMIT := 100`
    - `_init(start: Circuit)`
    - `commit(next: Circuit) -> void`
    - `undo() -> bool`, `redo() -> bool`
    - `can_undo() -> bool`, `can_redo() -> bool`
  - `CircuitIO`:
    - `const FORMAT := 1`
    - `to_dict(c) -> Dictionary` (`{format, parts: [...], wires: [...]}`)
    - `from_dict(d: Dictionary) -> Circuit` (returns null on a missing or unknown format, an unknown kind, a bad pin or a duplicate id)
    - `to_json(c) -> String`
    - `from_json(s: String) -> Circuit` (returns null on bad JSON)

- [ ] **Step 1: Write the failing tests.**
  - `test_add_part_returns_new_circuit_original_unchanged`
  - `test_move_locked_is_noop`
  - `test_rotate_cycles` (0 → 90 → 180 → 270 → 0)
  - `test_delete_part_removes_its_wires`
  - `test_set_props_on_locked_part`
  - `test_can_add_wire_reasons`: `"same pin"` for the same part and pin; `"duplicate"` for the same two pins in reverse order; `"unknown pin"` for `"zz"`
  - `test_delete_locked_wire_noop`
  - `test_next_id_skips_existing` (w1 and w2 present → `"w3"`)
  - History: `test_commit_undo_redo`, `test_commit_after_undo_clears_future`, `test_limit_100` (101 commits leave 100 undo steps), `test_undo_empty_returns_false`
  - IO: `test_round_trip_compact_loop` (`to_dict(from_json(to_json(c))) == to_dict(c)`), `test_rejects_bad_json`, `test_rejects_unknown_kind`, `test_rejects_wrong_format`, `test_round_trip_keeps_via_and_tray`
- [ ] **Step 2: Run `tools/test.sh circuit/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: circuit edits, undo history and versioned JSON`.

### Task 5: Dense linear solver and netlist

**Files:**
- Create: `game/src/sim/{dense_solver,netlist}.gd`, `game/tests/sim/{test_dense_solver,test_netlist}.gd`

**Interfaces:**
- Produces:
  - `DenseSolver.solve(a: PackedFloat64Array, b: PackedFloat64Array, n: int) -> PackedFloat64Array`
    - `a` is row-major n×n.
    - Uses Gaussian elimination with partial pivoting.
    - Returns an **empty** array if any |pivot| < 1e-15.
  - `class_name Netlist extends RefCounted`:
    - `var net_of: Dictionary` (pin key → net index)
    - `var net_count: int`
    - `var component_of_net: PackedInt32Array`
    - `var reference_net: Dictionary` (component index → reference net index, only for components containing a battery)
    - `var floating: Dictionary` (net index → true for nets in components without a battery)
    - `var devices: Array[Dictionary]` (`{part: Part, kind: String, nets: PackedInt32Array}` in catalog pin order, for unburnt batteries, resistors and LEDs)
    - `var connectors: Array[Dictionary]` (`{id: String, kind: "wire"|"switch"|"ammeter", a: String, b: String, g: float}`, where `a` and `b` are pin keys)
    - `var voltmeters: Array[Part]`
    - `static func build(c: Circuit) -> Netlist`
  - Merge rules:
    - Wires, closed switches and unburnt ammeters merge their two pin keys (union-find).
    - Nets are numbered in the order they are first seen, walking parts in circuit order and pins in catalog order.
    - Components are the union-find of nets joined by devices.
    - The reference net is the net of the `neg` pin of the first battery (by part order) in that component.

- [ ] **Step 1: Write the failing tests.**
  - `test_solves_2x2`: `[[2,1],[1,3]]·x = [4,7]` gives x = [1, 2] within 1e-12.
  - `test_needs_pivot`: `[[0,1],[1,0]]·x = [3,5]` gives x = [5, 3].
  - `test_singular_returns_empty`: `[[1,2],[2,4]]`.
  - `test_3x3`: `[[3,2,-1],[2,-2,4],[-1,0.5,-1]]·x = [1,-2,0]` gives x = [1,−2,−2].
  - `test_compact_loop_has_three_nets_and_reference`
  - `test_open_switch_separates_nets`, `test_closed_switch_merges`
  - `test_ammeter_merges_and_is_connector_g10`
  - `test_burnt_resistor_not_a_device`, `test_burnt_ammeter_is_open`
  - `test_isolated_resistor_nets_floating`
  - `test_two_battery_loops_two_references`
- [ ] **Step 2: Run `tools/test.sh sim/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: dense solver and netlist builder`.

### Task 6: Device models and the DC solver

**Files:**
- Create: `game/src/sim/{devices,dc_solution,dc_solver}.gd`, `game/tests/sim/test_dc_solver.gd`

**Interfaces:**
- Consumes: `Netlist`, `DenseSolver`.
- Produces:
  - `Devices` constants (the electrical constants in Global Constraints), plus:
    - `Devices.led_isat(color: String) -> float` = `0.02 / exp(vf_20ma / (2.0 * 0.025852))`
    - `Devices.pnjlim(vnew: float, vold: float, vt: float, vcrit: float) -> float`
  - `class_name DcSolution extends RefCounted`:
    - `var converged: bool`, `var iterations: int`
    - `var net_volts: PackedFloat64Array` (NAN for floating nets)
    - `var device_amps: Dictionary` (part id → amps). Battery: current out of `pos`. Resistor: a→b. LED: anode→cathode.
    - `var device_watts: Dictionary`
  - `DcSolver.solve(n: Netlist) -> DcSolution`

- [ ] **Step 1: Write the failing tests** (circuits built with `TestCircuits` and `CircuitEdits`):
  - `test_battery_1k`: current = 5/1001 within 1e-9.
  - `test_divider_midpoint`: 1k + 1k gives a midpoint of 2.49875 V within 1e-6 (relative to `neg`).
  - `test_red_led_150_ohm`: current between 0.0195 and 0.0202 (≈ 0.019874).
  - `test_red_led_220_ohm`: between 0.0135 and 0.0141 (≈ 0.013802).
  - `test_red_led_1k`: between 0.0030 and 0.0034 (≈ 0.003176).
  - `test_blue_led_220_ohm`: between 0.0090 and 0.0099 (≈ 0.009463).
  - `test_led_reversed_dark`: |I| < 1e-9.
  - `test_led_direct_on_battery`: converged and I > 0.4 A (≈ 0.489).
  - `test_two_batteries_series_1k`: 10/1002 within 1e-6.
  - `test_opposing_batteries_no_current`: |I| < 1e-9.
  - `test_shorted_battery_current_5a`: `device_amps["B1"]` is 5.0 within 1e-9.
  - `test_floating_part_nan_no_crash`
  - `test_no_battery_all_floating_converged`
- [ ] **Step 2: Run `tools/test.sh dc_solver`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
  - **Unknowns:** the nets of each powered component except its reference, plus one internal node per LED (between `Rs` and the junction).
  - **Stamps:**
    - resistor: conductance G = 1/R
    - battery: Norton equivalent, G = 1/R_int between `pos` and `neg`, with source V/R_int into `pos` and out of `neg`
    - LED: `Rs` from the anode to the internal node, and the junction from the internal node to the cathode
    - gmin from every unknown to its component reference
  - Floating nets are excluded and reported as NAN.
  - **Junction companion model at the limited voltage `vd`:**
    - `id = is*(exp(vd/vt)-1)`
    - `gd = is/vt*exp(vd/vt) + gmin`
    - `ieq = id - gd*vd`
    - Clamp `vd/vt ≤ 80`.
  - **Newton loop (the tests don't determine it):**

```gdscript
static func pnjlim(vnew: float, vold: float, vt: float, vcrit: float) -> float:
	if vnew > vcrit and absf(vnew - vold) > 2.0 * vt:
		if vold > 0.0:
			var arg := 1.0 + (vnew - vold) / vt
			return vold + vt * log(arg) if arg > 0.0 else vcrit
		return vt * log(vnew / vt)
	return vnew
# vcrit = vt * log(vt / (sqrt(2.0) * is)).
# Loop up to 100 times: stamp linear parts and each LED at vd[k] = pnjlim(v_now, vd[k]), solve,
# and converge when max|Δx| < 1e-9 V and every |v_junction - vd[k]| < 1e-6 V.
# If it fails: source stepping. Scale battery voltage by s = 0.1, 0.2, …, 1.0, warm-starting each step.
# The result is converged only if the final s = 1.0 step converges.
```

- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: DC solver with LED junction model and source stepping`.

### Task 7: Current flow, damage and the simulator

**Files:**
- Create: `game/src/sim/{current_flow,damage,sim_result,sim_outcome,simulator}.gd`, `game/tests/sim/{test_current_flow,test_damage,test_simulator}.gd`

**Interfaces:**
- Consumes: Tasks 5–6.
- Produces:
  - `CurrentFlow.connector_amps(n: Netlist, s: DcSolution) -> Dictionary` (connector id → amps from `a` to `b`)
  - `Damage.detect(c: Circuit, n: Netlist, s: DcSolution, flows: Dictionary) -> Array[Dictionary]` (entries `{part: String, reason: "overcurrent"|"overheat"|"fuse", ratio: float}`, sorted with the largest ratio first)
  - `class_name SimResult extends RefCounted`:
    - `var converged: bool`, `var net_of: Dictionary`, `var net_volts: PackedFloat64Array`, `var floating: Dictionary`
    - `var part_amps: Dictionary`, `var part_watts: Dictionary`, `var wire_amps: Dictionary`, `var connector_amps: Dictionary`
    - `var meter: Dictionary` (ammeter: amps a→b; voltmeter: V(pos)−V(neg); NAN if not readable)
    - `var shorts: Array[String]`
    - `func pin_volts(part_id: String, pin: String) -> float` (NAN if floating)
    - `func is_floating(part_id: String, pin: String) -> bool`
  - `class_name SimOutcome extends RefCounted`:
    - `var result: SimResult`
    - `var circuit: Circuit` (with `burnt` flags applied)
    - `var damage: Array[Dictionary]`
  - `Simulator.simulate(c: Circuit) -> SimOutcome`

- [ ] **Step 1: Write the failing tests.**
  - `test_loop_wires_carry_loop_current`: in `compact_loop(220)`, w1, w2 and w3 each carry +0.0138 A within 3e-4, in path direction.
  - `test_parallel_closed_switches_split_evenly`: each carries LED current / 2 within 1e-4, and the two sum to the LED current within 1e-6.
  - `test_ammeter_reads_series_current`: `TestCircuits.meter_loop(500.0)` reads 5/501 within 1e-5. Add this helper: B1, R1 (adjustable), ammeter M1 at (6,0) rot 90 and voltmeter V1 at (−2,−7), wired exactly as Chapter 1 L3 in Task 10.
  - `test_voltmeter_reads_resistor_drop`: ≈ 4.990 within 1e-3.
  - `test_led_burns_without_resistor`: damage == [L1 overcurrent], the outcome LED has `burnt == true`, and the final LED current is 0.
  - `test_resistor_overheats`: a battery straight across 47 Ω gives `"overheat"`.
  - `test_ammeter_fuse_blows_across_battery`: damage == [M1 fuse], the final battery current is 0, and `shorts` is empty.
  - `test_burn_order_highest_ratio_first`: a battery, a 10 Ω resistor and a red LED in series. The LED ratio is ≈ 7.5 and the resistor's ≈ 1.4; only L1 burns.
  - `test_short_flagged`: a battery with a wire from `pos` to `neg` gives `shorts == ["B1"]`.
  - `test_fuzz_never_nan`:
    - `RandomNumberGenerator.seed = 1234`.
    - 200 circuits, each with 1–8 random parts of every kind:
      - resistor ohms from [10, 47, 100, 220, 1000, 10000]
      - random LED colors
      - random switch states
    - 0–10 random wires between distinct pins.
    - Every outcome is `converged`, every non-floating net voltage and every part current is finite, and `damage.size() <= 10`.
- [ ] **Step 2: Run `tools/test.sh sim/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
  - **Flow, per net:**
    - The graph's vertices are that net's pin keys, and its edges are its connectors, weighted by `g`.
    - Injection at a pin = the current from the device into the net:
      - battery: `pos` +I, `neg` −I
      - resistor: `a` −I, `b` +I
      - LED: `anode` −I, `cathode` +I
      - voltmeter: 0
    - Pin the first vertex at 0, solve the Laplacian with `DenseSolver`, then each edge current = g·(φa − φb).
  - **Simulate:** loop up to 10 times: build → solve → flow → detect. When something is detected, burn only `damage[0]` (via `set_props` with `burnt: true`) and repeat.
  - **Voltmeter readable** = both pins non-floating and in the same component.
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: current flow, damage rules and simulate()`.

### Task 8: Level definitions, goals, level tests and solution diff

**Files:**
- Create: `game/src/lessons/{level_def,level_builder,goals,level_tests,solution_diff}.gd`, `game/tests/lessons/{test_goals,test_level_tests,test_solution_diff}.gd`

**Interfaces:**
- Consumes: `Simulator`, `SimResult`, circuit types.
- Produces:
  - `class_name LevelDef extends RefCounted`:
    - `id`, `chapter`, `title`, `summary: String`
    - `kind: String` (`"build"`|`"zoom"`)
    - `intro: Array[Dictionary]` (`{text, mood}`, where mood ∈ `happy|curious|wow|oops`)
    - `circuit: Circuit`
    - `tray: Array[Dictionary]` (`{kind, props, count}`)
    - `goals: Array[Dictionary]`
    - `tests: Array[Dictionary]` (`{name, set: [{target, prop, value}], expect: [goal…]}`)
    - `hints: Array[Dictionary]` (`{text, highlight: [{part?, pin?, wire?}], show_solution: bool}`)
    - `solution: Circuit`
    - `outro: Array[Dictionary]`, `facts: PackedStringArray`
    - `star: Dictionary` (`{goal, text}` or `{}`)
  - `LevelBuilder` (fluent; every method returns `self`):
    - `_init(id, chapter, title)`, `summary(t)`, `kind(k)`
    - `part(id, kind, x, y, rot := 0, props := {}, locked := true)`
    - `wire(id, a_part, a_pin, b_part, b_pin, locked := true, via: Array[Vector2i] = [])`
    - `tray(kind, props := {}, count := 1)`, `goal(g)`, `test(name, set, expect)`
    - `hint(text, highlight := [], show_solution := false)`
    - `solution_part(id, kind, x, y, rot, props)` (gets the tray index of the first tray item with the same kind and matching props)
    - `solution_wire(a_part, a_pin, b_part, b_pin)`, `solution_props(id, patch)`, `solution_remove_wire(id)`
    - `intro(text, mood := "happy")`, `outro(text, mood := "wow")`, `fact(t)`, `star(goal, text)`
    - `done() -> LevelDef` (the solution is the start circuit plus the solution edits)
  - `Goals.evaluate(goal: Dictionary, ctx: Dictionary) -> Dictionary` and `Goals.evaluate_all(goals, ctx) -> Array[Dictionary]`
    - `ctx = {circuit, sim: SimResult, zoom_layer: String}`
    - Result = `{pass: bool, message: String}`
  - Goal kinds:
    - `led_lit {part, min_ma?}`
    - `led_dark {part}`
    - `no_damage`
    - `no_short`
    - `meter_reads {part, target, tolerance}`
    - `uses {part_kind, min?, max?}`
    - `zoom_reached {layer}`
    - The `part` field matches a part id or a label.
  - `LevelTests.run(level: LevelDef, c: Circuit) -> Dictionary` returns `{pass: bool, cases: [{name, pass, messages: PackedStringArray}]}`. Each case works on a copy of the circuit: apply `set` via `set_props`, then simulate. A missing target fails the case with `"Missing part: <target>"`.
  - `SolutionDiff.compute(current: Circuit, solution: Circuit) -> Dictionary` returns `{parts: Array[Part], wires: Array[Dictionary], props: Array[Dictionary], remove_wires: PackedStringArray}`.
    - Solution parts that came from the tray map to current parts with the same `tray` index, in order.
    - A ghost wire is listed only when both of its endpoints exist in `current`.

- [ ] **Step 1: Write the failing tests.** Messages are exact copy, and `{ma}` is formatted with one decimal.
  - `led_lit`, checked in this order:
    1. burnt → `"Pop! The LED burned out from too much current. Hold it to replace it, then add a resistor."`
    2. any short → `"Short circuit! The current is taking a shortcut around your parts."`
    3. LED pin floating, or no current with no reverse voltage → `"The loop isn't closed yet. Current needs a full path from + back to −."`
    4. V(cathode) − V(anode) > 0.5 V → `"The LED is backwards. Flip it so its + side points toward the battery's +."`
    5. current < 0.0005 A → `"A little current flows, but not enough to see. Try a smaller resistor."`
    6. below `min_ma` → `"It's glowing, but dimly ({ma} mA). Can you make it brighter?"`
    7. pass → `"Lit! {ma} mA flowing."`
  - `led_dark`: pass `"The LED is off."`, fail `"The LED is still on."`
  - `no_damage`: pass `"Nothing is burned."`, fail `"Something burned out. Replace it to continue."`
  - `no_short`: pass `"No short circuits."`, fail `"Short circuit! Find the wire that skips your parts."`
  - `meter_reads`:
    - pass: `"The meter reads {v}."`
    - fail: `"The meter reads {v}. Aim for {t} (±{tol})."`
    - Ammeter values in mA with 1 decimal; voltmeter values in V with 2 decimals.
    - Unreadable: `"The meter isn't connected yet."`
  - `uses`: fail `"Add a {title} from the tray."` (min) or `"Use at most {max} of the {title} part."` (max).
  - `zoom_reached`: pass `"You made it inside!"`, fail `"Keep zooming in."`
  - Test names:
    - `test_led_lit_each_diagnosis` (one circuit per branch: burnt, short, open, reversed, too dim, dim with `min_ma` 10 using 1 kΩ, pass with 220 Ω)
    - `test_meter_reads_formats_units`
    - `test_uses_min_max`
    - `test_zoom_reached_reads_ctx`
    - `test_level_tests_series_pass`
    - `test_level_tests_parallel_fails_both_rule` (case `"A on, B off: LED off"` fails)
    - `test_level_tests_missing_target`
    - `test_solution_diff_lists_missing_tray_part_and_wires`
    - `test_solution_diff_ghost_wire_needs_both_ends`
    - `test_solution_diff_props_and_removals`
- [ ] **Step 2: Run `tools/test.sh lessons/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: level definitions, goal diagnosis, level tests and solution diff`.

### Task 9: Level session, progress and safe storage

**Files:**
- Create: `game/src/lessons/level_session.gd`, `game/src/save/{progress,progress_storage}.gd`, `game/tests/lessons/test_level_session.gd`, `game/tests/save/test_progress.gd`, `game/tests/save/test_storage.gd`

**Interfaces:**
- Consumes: Task 8.
- Produces:
  - `class_name LevelSession extends RefCounted` with fields:
    - `level_id: String`
    - `phase: String` (`"intro"`|`"build"`|`"passed"`)
    - `intro_index: int`, `hint_tier: int`
    - `goal_results: Array[Dictionary]`, `test_report: Dictionary`
    - `used_hints: bool`
  - `LevelSession` static functions:
    - `start(level) -> LevelSession`
    - `next_intro(s, level) -> void` (after the last line, the phase becomes `"build"`)
    - `update(s, level, ctx) -> void` (re-evaluates goals; a level **without tests** moves to `"passed"` when every goal passes)
    - `run_tests(s, level, circuit, ctx) -> void` (moves to `"passed"` only if all goals and the report pass)
    - `hint(s, level) -> void` (tier + 1, capped at `level.hints.size()`; sets `used_hints`)
  - `class_name Progress extends RefCounted`:
    - `const VERSION := 1`
    - `completed: Dictionary` (id → `{star: bool, at: int}`)
    - `drafts: Dictionary` (id → circuit dict)
    - `settings: Dictionary` (keys `reduced_motion`, `engineer_view`, `electron_flow`, `large_text`, `patterns`, `night`, all false by default)
    - `stats: Dictionary` (`{parts_burnt: 0}`)
    - `static defaults() -> Progress`, `to_dict() -> Dictionary`, `static from_dict(d) -> Progress` (null on an unknown version or wrong types)
    - `is_unlocked(level_id: String, chapter_level_ids: PackedStringArray) -> bool` (the first level is always unlocked; any other needs the previous one completed)
    - `mark_complete(level_id, star: bool, now: int)` (a star, once earned, stays)
  - `ProgressStorage.load(path := "user://progress.json") -> Dictionary` returns `{progress: Progress, ok: bool, recovered: bool}`. A corrupt file is renamed to `progress.corrupt-<unix>.json` in the same folder.
  - `ProgressStorage.save(p: Progress, path := "user://progress.json") -> bool` writes `<path>.tmp` and then renames it over the real file.

- [ ] **Step 1: Write the failing tests.**
  - `test_intro_then_build`
  - `test_goals_only_level_passes_on_update`
  - `test_tests_level_needs_run_tests`
  - `test_hint_tier_caps`
  - `test_progress_round_trip`
  - `test_unknown_version_rejected`
  - `test_unlock_chain`
  - `test_star_is_sticky`
  - Storage (using `user://test_<random>/` folders):
    - `test_missing_file_gives_defaults_ok`
    - `test_corrupt_file_recovered_and_backed_up` (a backup file exists with the original bytes)
    - `test_save_then_load_round_trip`
    - `test_save_to_missing_dir_returns_false` (`user://no_such_dir/x/progress.json`)
- [ ] **Step 2: Run `tools/test.sh save/` and `tools/test.sh level_session`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: level session flow, progress and crash-safe storage`.

### Task 10: Chapter 1 content, glossary and chapter list

**Files:**
- Create: `game/src/content/{glossary,chapters,levels}.gd`, `game/src/content/ch1/l1_light_it_up.gd` … `l8_inside_the_wire.gd` (each defines `static func build() -> LevelDef` and has **no** `class_name`), `game/tests/content/test_content.gd`

**Interfaces:**
- Consumes: `LevelBuilder`, `Goals`, `LevelTests`, `Simulator`.
- Produces:
  - `Glossary.ENTRIES: Dictionary` (term → `{title, text}`)
  - `Chapters.ALL: Array[Dictionary]` (`{id, title, era, blurb, playable}`)
  - `Levels.all() -> Array[LevelDef]`
  - `Levels.by_id(id) -> LevelDef`
  - `Levels.chapter_ids(chapter: String) -> PackedStringArray`

**Layouts.** These are the positions used below.
- **Compact:** B1 battery at (−6,0); R1 resistor at (−2,−4); L1 LED at (6,0) rot 90.
  - Pins: B1.pos (−6,−2), B1.neg (−6,2), R1.a (−4,−4), R1.b (0,−4), L1.anode (6,−1), L1.cathode (6,1).
- **Wide:** the same, but L1 is at (12,0) rot 90 (anode (12,−1), cathode (12,1)).
- Wire ids: w1 = B1.pos→R1.a, w2 = R1.b→L1.anode, w3 = L1.cathode→B1.neg.

**Levels** (all start parts are locked; hint 3 always has `show_solution: true` unless noted):

| # | id / title | Start | Tray | Goals | Tests | Solution |
|---|---|---|---|---|---|---|
| 1 | `ch1.light-it-up` "Light it up" | compact, R1 220, no wires | — | led_lit L1, no_short | — | w1, w2, w3 |
| 2 | `ch1.pop` "Pop!" | B1, L1 (compact positions) | resistor 47, 220, 1000 (1 each) | led_lit L1, no_damage, uses resistor min 1 | — | resistor (220) at (−2,−4) + w1, w2, w3 equivalents |
| 3 | `ch1.push-and-flow` "Push and flow" | B1; R1 1000 adjustable; M1 ammeter at (6,0) rot 90; V1 voltmeter at (−2,−7); locked wires B1.pos→R1.a, R1.b→M1.a, M1.b→B1.neg, V1.pos→R1.a, V1.neg→R1.b | — | meter_reads M1 target 0.010 tolerance 0.0005, no_damage | — | `solution_props("R1", {ohms: 500.0})` |
| 4 | `ch1.on-and-off` "On and off" | wide, locked w1, w3 | switch `{label:"S"}` | no_damage, no_short, uses switch min 1 | "Switch off: LED off" (S off → led_dark), "Switch on: LED on" (S on → led_lit) | S at (6,−4); R1.b→S.a, S.b→L1.anode |
| 5 | `ch1.both` "Both switches" | wide, locked w1, w3 | switch A, switch B | no_damage, no_short, uses switch min 2 | the 4 combinations; only "A on, B on: LED on" is lit | A at (3,−4), B at (8,−4); R1.b→A.a, A.b→B.a, B.b→L1.anode |
| 6 | `ch1.either` "Either switch" | wide, locked w1, w3 | switch A, switch B | same as L5 | 4 combinations; lit unless both are off | A at (4,−4), B at (4,−7); R1.b→A.a, A.a→B.a, B.b→A.b, A.b→L1.anode |
| 7 | `ch1.short-circuit` "Short circuit!" | compact, w1–w3 locked, plus **unlocked** `w_bad` R1.a→L1.cathode via [(−4,−6),(9,−6),(9,1)] | — | no_short, led_lit L1 | — | `solution_remove_wire("w_bad")` |
| 8 | `ch1.inside-the-wire` "Inside the wire", kind `zoom` | compact, w1–w3 locked | — | zoom_reached `wire.copper` | — | the start circuit (hint 3: no ghost) |

- Star for L2: `{goal: {kind: "led_lit", part: "L1", min_ma: 10.0}, text: "Brightest safe glow (at least 10 mA)"}`.
- In M1, each level's facts double as its "Go deeper" card. Fuller Go-deeper panels start in M3.
- Test case names for L5 and L6 follow `"A on, B off: LED off"`.

**Copy (exact).** Moods are given in parentheses. Hints are listed as tier 1, tier 2 (with what it highlights), tier 3.

- **L1**
  - summary: "Close the loop to light an LED."
  - intro:
    1. "Hi! I'm Pip, a tiny spark of [[electricity]]." (happy)
    2. "Electricity only flows around a full loop: out of the battery's + side, through your parts, and back into −." (curious)
    3. "Drag from one metal dot to another to add a wire. Can you light the [[led|LED]]?" (happy)
  - hints:
    1. "Current leaves the battery's + end. Where should it go first?"
    2. "Connect the battery's + to the resistor, the resistor to the LED, and the LED back to −." (highlights B1.pos, R1.a)
    3. "Here's one way to do it. Tap the ghost wires to place them."
  - outro:
    1. "You made light! About 14 [[milliamp|milliamps]] are flowing around your loop." (wow)
    2. "Every phone and computer works because of loops like this one." (happy)
  - fact: "The first practical LED, made in 1962, could only glow red."
- **L2**
  - summary: "Find out why LEDs need resistors."
  - intro:
    1. "This LED has no [[resistor]]. What could go wrong?" (curious)
    2. "Try connecting it straight to the battery and watch closely." (happy)
  - hints:
    1. "Too much [[current]] burns an LED. A resistor slows the current down."
    2. "Put a resistor between the battery's + and the LED." (highlights B1.pos, L1.anode)
    3. "Here's a safe circuit. Tap the ghosts to place them."
  - outro:
    1. "Safe and glowing! The resistor keeps the current low enough for the LED." (wow)
    2. "Different resistors let different amounts through. Which one is brightest without popping?" (curious)
  - fact: "Stripes on a resistor show its value. Red, red, brown means 220 ohms."
- **L3**
  - summary: "Use Ohm's law to set exactly 10 mA."
  - intro:
    1. "[[voltage|Voltage]] is the push. [[current|Current]] is the flow. [[resistance|Resistance]] makes flowing harder." (curious)
    2. "Tap the resistor and turn its dial until the [[ammeter|current meter]] shows 10 mA." (happy)
  - hints:
    1. "More resistance means less current. Is the meter too high or too low?"
    2. "Try about 500 ohms." (highlights R1)
    3. "Set the resistor to 500 ohms."
  - outro:
    1. "That's [[ohms law|Ohm's law]]: current equals voltage divided by resistance." (wow)
    2. "5 volts ÷ 500 ohms = 0.01 amps, which is 10 milliamps." (happy)
  - fact: "Georg Ohm published his law in 1827."
- **L4**
  - summary: "Control the light with a switch."
  - intro:
    1. "A [[switch]] opens and closes the loop, like a drawbridge." (curious)
    2. "Add the switch so it controls the LED. Tap it to try, then press Test." (happy)
  - hints:
    1. "The loop has a gap. The switch can fill it."
    2. "Connect the resistor to one side of the switch, and the other side to the LED." (highlights R1.b, L1.anode)
    3. "Here's one way. Tap the ghosts to place them."
  - outro:
    1. "On and off, 1 and 0. That's a [[bit]]!" (wow)
    2. "Computers are made of billions of tiny switches doing exactly this." (happy)
  - fact: "'Bit' is short for 'binary digit'. The word was first used in 1947."
- **L5**
  - summary: "Light it only when both switches are on."
  - intro:
    1. "Here are two switches, A and B." (happy)
    2. "Make the LED light only when A and B are both on." (curious)
  - hints:
    1. "Current has to pass through both switches, one after the other."
    2. "Connect the resistor to A, A to B, and B to the LED." (highlights A, B)
    3. "Here's one way. Tap the ghosts to place them."
  - outro:
    1. "Parts in a row are in [[series]]. Every switch must be on." (wow)
    2. "This is the idea behind an AND gate. You'll build real ones soon!" (happy)
- **L6**
  - summary: "Light it when either switch is on."
  - intro:
    1. "Same switches, new rule." (happy)
    2. "Make the LED light when A is on, or B is on, or both." (curious)
  - hints:
    1. "Give the current two paths, one through each switch."
    2. "Connect both switches side by side between the resistor and the LED." (highlights A, B)
    3. "Here's one way. Tap the ghosts to place them."
  - outro:
    1. "Side by side is called [[parallel]]. Either path works." (wow)
    2. "This is the idea behind an OR gate." (happy)
- **L7**
  - summary: "Find the wire that skips everything."
  - intro:
    1. "Uh oh, this battery is getting hot!" (oops)
    2. "A [[short circuit]] is a shortcut that lets current skip your parts. Find it and delete it." (curious)
  - hints:
    1. "One wire connects the + side straight to the − side."
    2. "It's this wire. Hold it and choose Delete." (highlights w_bad)
    3. "Delete the highlighted wire."
  - outro:
    1. "Fixed! The current goes through the LED again." (wow)
    2. "Real short circuits can melt wires. Never connect a real battery's + and − together!" (curious)
  - fact: "Fuses and circuit breakers cut the power when too much current flows."
- **L8**
  - summary: "Zoom into a wire to see electrons."
  - intro:
    1. "Wires look solid, but inside them trillions of [[electron|electrons]] are moving." (curious)
    2. "Pinch or scroll over a wire to zoom in. Keep going until you see atoms!" (happy)
  - hints:
    1. "Put your fingers or mouse right over a wire, then zoom in."
    2. "Keep zooming in. The wire gets bigger and bigger." (highlights w1)
    3. "Keep zooming in through the wire to reach the copper atoms." (`show_solution: false`)
  - outro:
    1. "Those are copper [[atom|atoms]]. Electrons jiggle around them and drift slowly from − to +." (wow)
    2. "Electrons crawl slower than a snail, but the push races down the wire almost as fast as light." (happy)
  - fact: "In this wire, electrons drift about the width of a hair every minute."

**Glossary (exact):**

| Term | Title | Text |
|---|---|---|
| electricity | Electricity | Energy carried by moving electric charges, like electrons flowing through a wire. |
| electron | Electron | A tiny particle with a negative charge. Moving electrons carry electricity through metal. |
| atom | Atom | The tiny building block of everything. Each atom has a nucleus surrounded by electrons. |
| circuit | Circuit | A complete loop that electricity can flow around. |
| current | Current | How much electricity flows past a point each second. Measured in amps. |
| voltage | Voltage | The push that makes current flow. Measured in volts. |
| resistance | Resistance | How hard it is for current to get through something. Measured in ohms. |
| amp | Amp | The unit of current. One amp is a lot for small electronics. |
| milliamp | Milliamp (mA) | One thousandth of an amp. A small LED likes about 20 mA. |
| volt | Volt | The unit of voltage. A AA battery gives about 1.5 volts. |
| ohm | Ohm (Ω) | The unit of resistance. More ohms means less current gets through. |
| ohms law | Ohm's law | Current equals voltage divided by resistance: I = V ÷ R. |
| led | LED | A light-emitting diode: a tiny light that only lets current flow one way. |
| resistor | Resistor | A part that limits current, like a narrow section of pipe. |
| battery | Battery | A store of energy with a + side and a − side. It pushes current around a loop. |
| switch | Switch | A part that opens or closes a gap in the loop. |
| bit | Bit | A single 1 or 0, the smallest piece of information. |
| series | Series | Parts connected one after another, so current must pass through all of them. |
| parallel | Parallel | Parts connected side by side, so current can take either path. |
| short circuit | Short circuit | An accidental shortcut that lets current skip the parts. It can overheat wires and batteries. |
| ammeter | Current meter | A meter that measures current. It must be placed in the loop, in series. |
| voltmeter | Voltage meter | A meter that measures the push between two points. |

**Chapters (exact):**

| id | title | era | blurb | playable |
|---|---|---|---|---|
| ch1 | Spark | 1800s | Electricity: loops, LEDs and switches | yes |
| ch2 | Sand | 1947 | From sand to silicon to the transistor | no |
| ch3 | Logic | 1960s | Logic gates, then your own chips | no |
| ch4 | Numbers | 1960s | Binary, adders and the ALU | no |
| ch5 | Memory | 1970 | Latches, clocks, registers and RAM | no |
| ch6 | The Brain | 1971 | Design a CPU and program it | no |
| ch7 | The Factory | 1970s–today | Make real chips from wafers | no |
| ch8 | The Machine | 1981–2007 | Build a PC or a phone and switch it on | no |
| ch9 | Software | 1970s–2000s | Operating systems, languages and apps | no |
| ch10 | Connect | 1973 | Wires, Wi-Fi and your home network | no |
| ch11 | The Internet | 1969–today | Routers, undersea cables and data centers | no |
| ch12 | White Hat | today | Pretend hacking: test it, then defend it | no |
| ch13 | Thinking Machines | 1958–today | Neurons, AI chips and language models | no |

- [ ] **Step 1: Write the failing `test_content.gd`:**
  - `test_eight_ch1_levels_in_order`
  - `test_ids_unique`
  - `test_every_solution_passes` (goals with ctx from `simulate(solution)`; `zoom_layer` is `"wire.copper"` for zoom levels and `"editor"` otherwise; plus `LevelTests.run`)
  - `test_no_build_level_passes_at_start`
  - `test_solutions_use_only_start_and_tray_parts` (respects counts)
  - `test_glossary_terms_exist` (scans the intro, outro, hint and fact text)
  - `test_hint_highlights_exist`
  - `test_copy_limits` (≤ 2 sentences and ≤ 30 words per line)
  - `test_chapters_list_13_and_ch1_playable`
  - `test_l2_star_only_with_220` (simulate the solution with 47, 220 and 1000 Ω: only 220 lights the LED without burning it and reaches ≥ 10 mA)
- [ ] **Step 2: Run `tools/test.sh content/`.** Expected: FAIL.
- [ ] **Step 3: Implement the eight level files, the glossary, the chapters and the registry.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: Chapter 1 Spark levels, glossary and chapter list`.

### Task 11: Zoom math and scale formatting

**Files:**
- Create: `game/src/zoom/{zoom_camera,zoom_link,layer_info,zoom_math,scale_format}.gd`, `game/tests/zoom/{test_zoom_math,test_scale_format}.gd`

**Interfaces:**
- Produces:
  - `class_name ZoomCamera extends RefCounted`: `layer: String`, `center: Vector2`, `view: float` (the visible height in layer units); `static make(layer, center, view) -> ZoomCamera`
  - `class_name ZoomLink extends RefCounted`: `parent: String`, `child: String`, `anchor: Vector2` (in parent units), `parent_min_view: float`, `child_max_view: float`
  - `class_name LayerInfo extends RefCounted`: `id: String`, `meters_per_unit: float`, `min_view: float`, `max_view: float`
  - `ZoomMath.BAND := 4.0`
  - `ZoomMath` static functions:
    - `zoom_at(cam, factor: float, focus: Vector2) -> ZoomCamera` (view /= factor; center = focus + (center − focus)/factor)
    - `pan(cam, delta: Vector2) -> ZoomCamera`
    - `to_child(cam, link) -> ZoomCamera` (with s = child_max_view/parent_min_view: center = (center − anchor)·s, view·s)
    - `to_parent(cam, link) -> ZoomCamera` (the exact inverse)
    - `child_link(cam, links: Array[ZoomLink], dynamic: Callable) -> ZoomLink` (a static link whose parent is `cam.layer`; otherwise `dynamic.call(cam.layer, cam.center)`; or null)
    - `parent_link(cam, links) -> ZoomLink`
    - `resolve(cam, infos: Dictionary, links, dynamic) -> ZoomCamera` (hands off below `parent_min_view` or above the parent link's `child_max_view`; otherwise clamps to `min_view`/`max_view`; at most 8 hops)
    - `blend(cam, links, dynamic) -> Array[Dictionary]` returns `[{layer, alpha: 1.0, cam}]`, plus `{layer: child, alpha: a, cam: to_child(cam)}` when `cam.view < link.parent_min_view*BAND`. Here a = smoothstep(0, 1, ln(parent_min_view·BAND/view)/ln(BAND)).
    - `magnification(link, infos) -> float` = (parent_min_view·mpu_parent)/(child_max_view·mpu_child)
    - `meters_visible(cam, infos) -> float`
  - `ScaleFormat.meters(m: float) -> String`
    - Units: km if ≥ 1000; m if ≥ 1; cm if ≥ 0.01; mm if ≥ 0.001; µm if ≥ 1e-6; nm if ≥ 1e-9; otherwise pm.
    - The value is an integer with thousands separators when ≥ 10, otherwise 1 decimal with a trailing ".0" dropped.
  - `ScaleFormat.jump(x: float) -> String` gives `"Skipping ahead ×830"` (2 significant digits with a thousands separator: 13,333 → `"×13,000"`).

- [ ] **Step 1: Write the failing tests.**
  - `test_zoom_at_keeps_focus_fixed`
  - `test_child_parent_inverse` (within 1e-9)
  - `test_resolve_hands_off_below_parent_min`
  - `test_resolve_clamps_without_child`
  - `test_resolve_returns_to_parent`
  - `test_dynamic_child_used_when_no_static`
  - `test_blend_child_alpha_0_at_band_edge_1_at_min`
  - `test_blend_mid_band_between`
  - `test_magnification_grain_to_silica` (link 0.5 → 60 with mpu 1e-5 / 1e-10 gives ≈ 833.3)
  - Scale format: 12742000 → "12,742 km"; 300 → "300 m"; 2.5 → "2.5 m"; 0.02 → "2 cm"; 0.0025 → "2.5 mm"; 0.0005 → "500 µm"; 2e-5 → "20 µm"; 5e-9 → "5 nm"; 4e-10 → "400 pm"
  - `test_jump_format` (833.3 → "Skipping ahead ×830", 13333 → "Skipping ahead ×13,000")
- [ ] **Step 2: Run `tools/test.sh zoom/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: zoom math and real-scale formatting`.

### Task 12: ZoomStage and ZoomLayer

**Files:**
- Create: `game/src/zoom/{zoom_layer,zoom_stage}.gd`, `game/src/zoom/zoom_demo.tscn`, `game/src/zoom/zoom_demo.gd`, `game/tests/zoom/test_zoom_stage.gd`

**Interfaces:**
- Consumes: Task 11.
- Produces:
  - `class_name ZoomLayer extends SubViewportContainer` (with `stretch = true` and a child `SubViewport` created in `_ready` if missing):
    - `@export var layer_id: String`, `meters_per_unit: float`, `min_view: float`, `max_view: float`, `home_view: float`
    - `var viewport: SubViewport`
    - `func info() -> LayerInfo`
    - `func apply_view(center: Vector2, view: float) -> void` (virtual)
    - `func set_live(live: bool, interactive: bool) -> void` (update mode `UPDATE_ALWAYS`/`UPDATE_DISABLED`; `mouse_filter` `STOP`/`IGNORE`)
    - `func dynamic_child(center: Vector2) -> ZoomLink` (virtual; null by default)
    - `func screen_to_layer(p: Vector2, view: float, center: Vector2) -> Vector2` and `func layer_to_screen(...)`, using units_per_px = view / size.y with the view centered on the container
  - `class_name ZoomStage extends Control`:
    - `signal layer_changed(id: String)`
    - `signal view_changed(meters: float, jump_text: String)` (jump text is empty unless the active blend uses a link with magnification > 1.5)
    - `add_layer(l: ZoomLayer)`, `add_link(link: ZoomLink)`, `set_camera(cam: ZoomCamera)` (resolve → blend → visibility, modulate, live state, `apply_view`)
    - `camera() -> ZoomCamera`
    - `zoom_at_screen(factor: float, screen_pos: Vector2)`, `pan_screen(delta_px: Vector2)`
    - `go_home(layer_id: String)`
    - `screen_to_active(p: Vector2) -> Vector2`, `active_to_screen(p: Vector2) -> Vector2`
  - Children are drawn parent-first; only the child layer's `modulate.a` changes.

- [ ] **Step 1: Write the failing tests.** Headless, with two dummy layers (`ColorRect` content) and a link parent→child (`parent_min_view` 10, `child_max_view` 100):
  - `test_only_parent_visible_far_out`
  - `test_child_fades_in_band` (view 20 gives child alpha strictly between 0 and 1)
  - `test_handoff_emits_layer_changed_once`
  - `test_inactive_layers_not_live`
  - `test_screen_layer_round_trip`
  - `test_view_changed_reports_jump_text_for_magnified_link`
- [ ] **Step 2: Run `tools/test.sh test_zoom_stage`.** Expected: FAIL.
- [ ] **Step 3: Implement.** Also build the demo scene: two pastel layers with a label; mouse wheel zooms.
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Visual check.** Capture `res://src/zoom/zoom_demo.tscn` at a mid-band view (the demo reads `--view=` from user args). It passes if both layers are visible, with the child partially transparent over the parent.
- [ ] **Step 6: Commit** with `feat: ZoomStage with cross-faded SubViewport layers`.

### Task 13: Gestures (pure) and pointer input

**Files:**
- Create: `game/src/input/{gesture_recognizer,pointer_input}.gd`, `game/tests/input/{test_gestures,test_pointer_input}.gd`

**Interfaces:**
- Produces:
  - `class_name GestureRecognizer extends RefCounted`:
    - `const DRAG_PX := 8.0`, `const LONG_PRESS_S := 0.45`, `const WHEEL_STEP := 1.15`
    - `down(id: int, pos: Vector2, t: float, button := MOUSE_BUTTON_LEFT) -> Array[Dictionary]`
    - `move(id, pos, t) -> Array[Dictionary]`, `up(id, pos, t) -> Array[Dictionary]`
    - `tick(t: float) -> Array[Dictionary]`
    - `wheel(pos, steps: float) -> Array[Dictionary]` (`{type:"zoom", at, factor: WHEEL_STEP^steps}`)
    - `magnify(pos, factor)`, `pan_gesture(delta)`
  - Gesture dictionaries: `tap{at}`, `long_press{at}`, `secondary_tap{at}`, `drag_start{at}`, `drag_move{at}`, `drag_end{at}`, `drag_cancel{}`, `zoom{at, factor}`, `pan{delta}`.
  - Pinch: when a second pointer goes down during a drag, it emits `drag_cancel`. Then every move emits a `zoom` (midpoint, distance ratio) and a `pan` (midpoint delta). After a pointer lifts, the remaining pointer is ignored until everything is up.
  - `class_name PointerInput extends Node`:
    - `signal gesture(g: Dictionary)`
    - `func feed(e: InputEvent, now: float) -> void` handles `ScreenTouch`/`ScreenDrag` (id = index), `MouseButton`/`MouseMotion` with `device != InputEvent.DEVICE_ID_EMULATION` (id 1000), the wheel, `MagnifyGesture` and `PanGesture`. It calls the recognizer's `tick` from `_process`.

- [ ] **Step 1: Write the failing tests.**
  - `test_tap`
  - `test_small_move_is_still_tap` (6 px)
  - `test_drag_after_9px`
  - `test_long_press_at_0_5s`
  - `test_no_tap_after_long_press`
  - `test_second_pointer_cancels_drag` (drag_cancel first, then zoom with factor 2.0 within 1e-6 when the distance doubles)
  - `test_right_button_secondary_tap`
  - `test_wheel_factor`
  - `test_emulated_mouse_ignored` (`PointerInput` fed an `InputEventMouseButton` with `device = InputEvent.DEVICE_ID_EMULATION` emits nothing)
- [ ] **Step 2: Run `tools/test.sh input/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: gesture recognizer with pinch, long-press and drag`.

### Task 14: Editor art (pure) and the art gallery

**Files:**
- Create: `game/src/editor/{draw_kit,resistor_bands,visual_state,part_art,wire_art}.gd`, `game/src/editor/art_gallery.tscn`, `game/src/editor/art_gallery.gd`, `game/tests/editor/{test_resistor_bands,test_visual_state,test_part_art,test_wire_art}.gd`

**Interfaces:**
- Consumes: circuit types, `SimResult`, `Palette`.
- Produces:
  - `ResistorBands.digits(ohms: float) -> Array[int]` (`[d1, d2, multiplier exponent]`, rounded to 2 significant digits)
  - `ResistorBands.colors(ohms) -> Array[Color]` (3 bands plus a gold tolerance band `#E8C66A`)
  - Band colors 0–9: `#2B2B2B #8B5A2B #E0605E #F29D52 #F2D35B #6CBF84 #5C9BD6 #A77BD9 #9A9AA6 #F5F5F5`
  - `VisualState.for_part(p: Part, sim: SimResult, settings: Dictionary) -> Dictionary` with keys:
    - `brightness` (0..1, = clamp(I/0.020) when not burnt)
    - `burnt`
    - `hot` (battery in `shorts`)
    - `reading` (ammeter `"%.1f mA"` of |I|·1000; voltmeter `"%.2f V"`; `"—"` if NAN)
    - `closed`, `color`, `label`
  - `PartArt.ops(p: Part, vis: Dictionary, selected: bool, highlighted: bool) -> Array[Dictionary]`
    - Ops are in **part-local** grid units (before rotation).
    - Op types:
      - `rrect{rect, radius, fill, stroke, stroke_w}`
      - `circle{c, r, fill, stroke, stroke_w}`
      - `capsule{a, b, r, fill}`
      - `glow{c, r, color}`
      - `text{at, text, size, color, bold}` (drawn upright)
  - `WireArt.color_for_volts(v: float, floating: bool, night := false) -> Color` (lerp `signal_low`→`signal_high` by clamp(v/5); floating → `line`)
  - `WireArt.dot_speed(amps: float) -> float` (0 if |I| < 1e-5, otherwise clamp(0.8·log10(|I|/1e-5), 0.3, 4.0) units per second)
  - `WireArt.dots(path: PackedVector2Array, amps: float, t: float) -> PackedVector2Array` (spacing 0.6 units, moving along the path for positive amps and against it for negative)
  - `WireArt.display_amps(amps: float, settings: Dictionary) -> float` (−amps when `electron_flow` is on)
  - `WireArt.pattern_dashes(path: PackedVector2Array, volts: float, enabled: bool) -> Array[PackedVector2Array]` (only when enabled and volts > 2.5: 0.3-unit dashes every 0.6 units; otherwise empty)
  - `VisualState.engineer_labels(c: Circuit, sim: SimResult) -> Array[Dictionary]` (`{at: Vector2, text: String}`): one `"%.2f V"` label per non-floating net at its first pin, offset (0.4, −0.4), and one `"%.1f mA"` label per resistor and LED at the part center, offset (0, 0.9)
  - `DrawKit` static drawing helpers (`rrect`, `circle`, `capsule`, `glow`, `text`) taking a `CanvasItem` and `px_per_unit` (the circle segment count is clamp(r·px_per_unit/2, 12, 96)).
- **Visual requirements** (the implementer chooses coordinates; the gallery capture checks them):
  - battery: mint pack with + and − labels and "5V"; coral body and glow when hot
  - resistor: butter body with color bands; small dial icon when adjustable
  - LED: domed body in its tint, a flat cathode-side line, a "+" by the anode, and a glow scaled by brightness
  - switch: two metal contacts with a lever lying flat when closed and raised 30° when open, and its label below
  - meters: round dial (sky for current, lilac for voltage) with a paper display showing the reading
  - burnt parts: dimmed, with a scorch mark
  - pins: metal dots

- [ ] **Step 1: Write the failing tests.**
  - `test_digits` (220 → [2,2,1]; 1000 → [1,0,2]; 47 → [4,7,0]; 500 → [5,0,1]; 150 → [1,5,1]; 1234 → [1,2,2])
  - `test_band_colors_220_red_red_brown`
  - `test_reading_formats`
  - `test_brightness_clamped`
  - `test_lit_led_has_glow_op`
  - `test_burnt_part_has_scorch_and_no_glow`
  - `test_switch_lever_differs_open_closed`
  - `test_meter_has_reading_text_op`
  - `test_selected_adds_outline`
  - `test_color_for_volts_endpoints_and_floating`
  - `test_no_dots_without_current`
  - `test_dot_spacing_0_6`
  - `test_dot_speed_monotonic`
  - `test_dots_reverse_for_negative_amps`
  - `test_display_amps_electron_flow`
  - `test_pattern_dashes_only_high_and_enabled`
  - `test_engineer_labels_volts_and_amps` (`compact_loop(220)` gives `"4.99 V"` on the + net and `"13.8 mA"` on R1 and on L1)
- [ ] **Step 2: Run `tools/test.sh editor/`.** Expected: FAIL.
- [ ] **Step 3: Implement.** The art gallery shows every part kind in each state on a cream board.
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Visual check.** Capture `res://src/editor/art_gallery.tscn`. It passes if each part matches the visual requirements, edges stay crisp at 1× and at 4× zoom (the gallery reads `--zoom=`), and nothing clips.
- [ ] **Step 6: Commit** with `feat: pastel part and wire art`.

### Task 15: Editor — hit testing, controller and editor layer

**Files:**
- Create: `game/src/editor/{hit_test,editor_controller,circuit_view,flow_view,editor_layer}.gd`, `game/src/editor/editor_layer.tscn`, `game/src/editor/editor_preview.tscn` + `editor_preview.gd` (dev only: reads `--level=<id>` and `--solution`, shows that circuit with live sim), `game/tests/editor/{test_hit_test,test_editor_controller,test_editor_layer}.gd`

**Interfaces:**
- Consumes: Tasks 3, 4, 7, 8 (`SolutionDiff`), 12, 13, 14.
- Produces:
  - `HitTest.at(c: Circuit, p: Vector2, pin_r: float, wire_r: float) -> Dictionary` returns `{kind: "pin"|"part"|"wire"|"empty", part, pin, wire, at}`.
    - Priority: nearest pin within `pin_r`, then the topmost part whose rotated rect contains `p`, then a wire within `wire_r` of its path, then empty.
  - `class_name EditorController extends RefCounted`:
    - `var mode: Dictionary`, one of:
      - `idle`
      - `placing{tray, ghost, has_ghost}`
      - `pin_selected{part, pin}`
      - `wiring{from_part, from_pin, to, snap_part, snap_pin}`
      - `moving{part, grab, at}`
      - `panning`
    - `var selection: String`
    - `begin_placing(tray_index: int)`, `cancel()`
    - `handle(g: Dictionary, ctx: Dictionary) -> Array[Dictionary]`
      - `ctx = {circuit, tray, tray_used: Array[int], pin_r, wire_r}` (gesture positions already in grid units; pan deltas in px)
      - Effects: `commit{circuit}`, `menu{part?, wire?, at}`, `value{part}`, `camera_zoom{factor, at}`, `camera_pan{delta}`, `toast{text}`
  - Controller rules:
    - **Tap**
      - Tap on a pin: either selects it (`pin_selected`) or, if a pin is already selected, wires the two pins.
      - Tap on a switch: toggles `closed` and commits.
      - Tap on an adjustable resistor: emits `value`.
      - Tap on a burnt part: emits `menu`.
      - Tap on any other part or a wire: selects it.
      - Tap on empty space while placing: adds the tray part at the rounded position (tray index and props from the tray item, a new id from `next_id`) and commits.
    - **Drag**
      - Starting on a pin: enters `wiring`. The snap is the nearest other pin within `1.5·pin_r`. On release over a valid snap the wire is committed; otherwise it emits `toast "Drop the wire on a metal dot."`, or `"Those are already connected."` for a duplicate.
      - Starting on an unlocked part: `moving`, snapped to the grid on release.
      - Starting on a locked part or empty space: `panning`.
    - `drag_cancel` → back to `idle` with no commit.
    - `long_press` or `secondary_tap` on a part or wire → `menu`.
    - `zoom` and `pan` → camera effects.
    - Keys: `rotate`, `delete`, `cancel`.
  - `class_name EditorLayer extends ZoomLayer` (scene `editor_layer.tscn`: SubViewport → Node2D world → `Camera2D`, `CircuitView`, `FlowView`, `PointerInput`):
    - `signal commit_requested(c: Circuit)`, `signal menu_requested(target: Dictionary, screen_pos: Vector2)`, `signal value_requested(part_id: String)`, `signal toast_requested(text: String)`, `signal ghost_tapped(kind: String, data: Dictionary)`
    - `set_state(c: Circuit, sim: SimResult, settings: Dictionary, ghosts: Dictionary, highlights: Array)`
    - `set_tray(tray: Array, used: Array[int])`, `begin_placing(i: int)`
    - `fit_view() -> float` (circuit bounds plus 3 units of margin; the result is at least 12)
    - `pin_screen_pos(part_id, pin) -> Vector2` (for tests)
    - `apply_view`: `Camera2D.position = center*32` and `zoom = size.y/(view*32)`
    - `dynamic_child` returns null in this task (Task 19 adds it)
    - The pin radius in grid units is max(0.35, 22/px_per_unit). `FlowView` animates dots each frame when any |I| ≥ 1e-5, unless `reduced_motion` is on (then it draws static arrows).
    - Dot directions use `WireArt.display_amps`.
    - `CircuitView` takes every color from `Palette.color(name, settings.night)`. It draws `VisualState.engineer_labels` when `engineer_view` is on, and `WireArt.pattern_dashes` when `patterns` is on.
    - Newly placed parts pop in with a 0.18 s scale overshoot. This is skipped when `reduced_motion` is on.

- [ ] **Step 1: Write the failing tests.**
  - Hit test:
    - `test_pin_beats_part_body`
    - `test_part_rect_hit_rotated`
    - `test_wire_hit_within_radius`
    - `test_empty`
  - Controller:
    - `test_tap_place_from_tray_commits_part_with_tray_index`
    - `test_tap_tap_wiring`
    - `test_drag_wiring_snaps_and_commits`
    - `test_drop_on_nothing_toasts`
    - `test_duplicate_wire_toasts`
    - `test_move_snaps_to_grid`
    - `test_locked_part_drag_pans`
    - `test_tap_switch_toggles`
    - `test_tap_adjustable_resistor_opens_value`
    - `test_long_press_opens_menu`
    - `test_drag_cancel_while_wiring_commits_nothing`
    - `test_rotate_and_delete_keys_on_selection`
  - Editor layer (scene test): load L1, push mouse press/motion/release events at `pin_screen_pos` for the three solution wires, and assert three `commit_requested` emissions whose last circuit lights L1 (via `Simulator`).
- [ ] **Step 2: Run `tools/test.sh editor/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Visual check.** Capture `res://src/editor/editor_preview.tscn -- --level=ch1.light-it-up --solution`, once as is and once with `--engineer`. It passes if:
  - wires are tinted by voltage
  - sparks sit on the wires
  - the LED glows
  - the grid dots are subtle
  - the engineer labels don't overlap the parts
- [ ] **Step 6: Commit** with `feat: circuit editor with wiring, placing, moving and live visuals`.

### Task 16: Game state, game node, main scene and navigation

**Files:**
- Create: `game/src/app/{game_state,game}.gd`, `game/src/screens/{map_screen,level_screen,title_screen}.{gd,tscn}` (the title screen is a placeholder until Task 18)
- Modify: `game/src/app/main.{gd,tscn}`
- Test: `game/tests/app/{test_game_state,test_navigation}.gd`

**Interfaces:**
- Consumes: Tasks 7–10, 12, 15.
- Produces:
  - `class_name GameState extends RefCounted` (pure):
    - Fields: `progress: Progress`, `level: LevelDef`, `history: CircuitHistory`, `outcome: SimOutcome`, `session: LevelSession`, `zoom_layer := "editor"`, `preview_circuit: Circuit`, `events: Array[Dictionary]`
    - `start_level(l: LevelDef)` (uses a valid draft if present, otherwise copies the start circuit)
    - `commit(c: Circuit)` (simulate; store `outcome.circuit` in history; update the session; save the draft; add `stats.parts_burnt`; queue `{type:"burnt", part, reason}` events)
    - `preview(c)` (simulate without touching history)
    - `undo() -> bool`, `redo() -> bool` (re-simulate)
    - `run_tests()`, `next_intro()`, `use_hint()`
    - `set_zoom_layer(id)` (re-evaluates goals)
    - `complete(now: int)` (when the phase is `passed`: `mark_complete` with the star result; queue `{type:"passed"}`)
    - `tray_used() -> Array[int]`
    - `take_events() -> Array[Dictionary]`
  - `class_name Game extends Node`:
    - `signal changed`, `signal toast(text: String)`, `signal navigate(screen: String, arg: String)`
    - `var state: GameState`
    - `boot(path := "user://progress.json")`
    - `open_level(id)`, `open_map()`, `open_title()`
    - Actions forwarding to `state` that then emit `changed`: `commit`, `preview`, `undo`, `redo`, `run_tests`, `next_intro`, `use_hint`, `set_zoom_layer`, `set_setting(key, value)`
    - `save_soon()` (a 0.5 s debounce timer) and `save_now()` (also called on `NOTIFICATION_WM_CLOSE_REQUEST` and `NOTIFICATION_APPLICATION_PAUSED`)
  - `Main` owns one `Game`, listens to `navigate`, swaps the screen scene and sets `screen.game = game`.
  - `MapScreen` shows Chapter 1's 8 level buttons on a winding path (✓ completed, ★ star, disabled if locked) and 12 locked chapter cards with their era and blurb.
  - `LevelScreen` holds a `ZoomStage` with an `EditorLayer`, plus `HUD` placeholders (filled in Task 17). It connects the editor signals to `game`.

- [ ] **Step 1: Write the failing tests.**
  - `test_start_level_uses_draft`
  - `test_commit_burn_stores_burnt_circuit_and_event`
  - `test_undo_after_burn_restores_part` (undo leaves L1 unburnt, `outcome` re-simulated, no burnt state in the result)
  - `test_l1_solution_passes_and_unlocks_l2`
  - `test_l2_star_with_220`
  - `test_zoom_goal_passes_on_layer` (L8, `set_zoom_layer("wire.copper")`)
  - `test_drafts_saved_per_level`
  - Navigation (scene): `test_map_only_l1_enabled_on_fresh_progress`, `test_map_l2_enabled_after_l1`, `test_open_level_shows_level_screen`
- [ ] **Step 2: Run `tools/test.sh app/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: game state, autosave and screen navigation`.

### Task 17: Level HUD — tray, goals, tests, hints, menus, guide, glossary, settings

**Files:**
- Create: `game/src/hud/*.gd` (see the file map), `game/src/ui/glossary_text.gd`
- Modify: `game/src/screens/level_screen.{gd,tscn}`, `game/src/editor/editor_layer.gd` (add `_can_drop_data` and `_drop_data` for tray drags, with data `{tray: int}`; a drop places the part at the rounded grid point under the cursor)
- Test: `game/tests/ui/test_glossary_text.gd`, `game/tests/hud/test_hud.gd`

**Interfaces:**
- Consumes: `Game`, `GameState`, `EditorLayer`, `SolutionDiff`, `Glossary`, `PastelTheme`.
- Produces:
  - `GlossaryText.to_bbcode(text: String) -> String`
    - `[[term]]` becomes `[url=term][color=#7C5CC4]term[/color][/url]`
    - `[[term|shown]]` keeps the term and displays `shown`
    - Unknown terms are left as plain text.
  - HUD nodes (all read from `game.state` on `changed`):
    - **TopBar:** back to the map, level title, undo, redo, settings.
    - **PartsTray:** shows remaining counts. A tap calls `editor.begin_placing`, a drag uses Godot drag-and-drop onto the `EditorLayer`, and items with 0 left are disabled.
    - **GoalsPanel:** ✓/○ rows plus the first failing message.
    - **TestSheet:** shown only for levels with tests. Lists the cases ✓/✗ with messages.
    - **HintButton:** tier 1 shows text; tier 2 shows text and highlights; tier 3 shows ghosts from `SolutionDiff` (tap a ghost to place it), plus chips for prop changes ("Set Resistor to 500 Ω") and removals ("Delete the highlighted wire").
    - **ContextMenu:** Rotate, Delete, and Replace (shown only when the part is burnt).
    - **ValuePopover:** `HSlider` 100–2000, step 10. Calls `game.preview` while dragging and `game.commit` on release; shows "{ohms} Ω".
    - **Toasts:** stacked, 2.5 s each. A burn shows "Pop! {title} burned out."
    - **Pip:** drawn with `_draw()`: a round butter-to-peach body, eyes, cheeks, and a mood expression.
    - **GuideBubble:** Pip plus a `RichTextLabel` with BBCode. Shows the intro with Next; after passing, the outro, facts, and buttons "Next level" and "Map".
    - **GlossaryPopup:** opened by `meta_clicked`.
    - **SettingsSheet:** toggles for reduced motion, engineer view, electron flow, large text, patterns and night. They apply immediately; the theme rebuilds for night and large text.
    - **ScaleBar:** from `view_changed`, with the jump badge.
    - **BackToBuilding:** a button shown when `zoom_layer != "editor"`.
  - Layout: if width < height (portrait), the tray is a horizontal strip at the bottom and the goals collapse into a top pill; otherwise the tray is a left column and the goals sit top-right. Re-layout runs on `NOTIFICATION_RESIZED`.

- [ ] **Step 1: Write the failing tests.**
  - `test_bbcode_simple_term`
  - `test_bbcode_shown_text`
  - `test_bbcode_unknown_term_plain`
  - HUD (scene):
    - `test_tray_tap_then_board_tap_places_part`
    - `test_tray_item_disabled_at_zero`
    - `test_hint_tiers_progress_and_tier3_shows_ghosts`
    - `test_ghost_tap_places_wire`
    - `test_replace_resets_burnt`
    - `test_value_slider_commits_on_release`
    - `test_settings_toggle_persists_in_progress`
    - `test_portrait_layout_moves_tray_to_bottom`
- [ ] **Step 2: Run `tools/test.sh hud/` and `tools/test.sh glossary_text`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Visual check.** Capture the level screen for L2 at 1280×720 and at 390×844. It passes if there is no overlap, the tray placement matches the orientation, the text is readable, and Pip's bubble is pastel and rounded.
- [ ] **Step 6: Commit** with `feat: level HUD with guide, hints, tests, glossary and settings`.

### Task 18: Title zoom from Earth to a silicon atom

**Files:**
- Create: `tools/make_land.mjs`, `game/data/land_110m.json`, `game/src/scenes/title/*.gd` (see the file map), `game/tests/title/{test_geo,test_lattice,test_land_data,test_title_director}.gd`
- Modify: `game/src/screens/title_screen.{gd,tscn}`

**Interfaces:**
- Consumes: Tasks 11–12, 16.
- Produces:
  - `Geo.to_vec3(lat: float, lon: float, r: float) -> Vector3` (y up; lon 0 on +z)
  - `Geo.great_circle(a_latlon: Vector2, b_latlon: Vector2, r: float, steps: int) -> PackedVector3Array`
  - `Lattice.silica(cells: Vector3i, a := 7.16) -> Dictionary` returns `{si: PackedVector3Array, o: PackedVector3Array}`. This is idealized cristobalite: Si sits on diamond sites (FCC plus a (¼,¼,¼) basis) and O sits at the Si–Si bond midpoints.
  - `Lattice.fcc(cells: Vector3i, a := 3.615) -> PackedVector3Array`
  - `LandTexture.build(polygons: Array, size := Vector2i(2048, 1024)) -> ViewportTexture` (Polygon2D nodes in a SubViewport: sky ocean, mint land, lavender coastline)
  - `TitleChain.infos() -> Dictionary` and `TitleChain.links() -> Array[ZoomLink]` (pure, in `title_chain.gd`). These hold the layer and link tables below and are shared by the title screen, the director and the tests.
  - `class_name TitleDirector extends RefCounted`:
    - `_init(infos: Dictionary, links: Array[ZoomLink])`
    - `const RATES := {"title.globe": 0.9, "title.coast": 1.8, "title.beach": 2.4, "title.grain": 2.4, "title.silica": 0.9, "title.atom": 0.5}` (natural-log zoom per second, ramping in over the first 1.0 s; each `step` applies `ZoomMath.zoom_at` and then `ZoomMath.resolve`)
    - `var finished := false`
    - `step(cam: ZoomCamera, dt: float) -> ZoomCamera`
    - `skip_to_end() -> ZoomCamera` (the atom at view 400)
    - `slideshow_order() -> PackedStringArray` (for reduced motion)
  - Layers (id, meters per unit, home view):

    | Layer | Meters per unit | Home view |
    |---|---|---|
    | `title.globe` | 1000 (km) | 30000 |
    | `title.coast` | 10 | 4000 |
    | `title.beach` | 0.01 | 3000 |
    | `title.grain` | 1e-5 | 150 |
    | `title.silica` | 1e-10 (Å) | 30 |
    | `title.atom` | 1e-12 (pm) | 400 (min view 200) |

  - Links (parent_min_view → child_max_view; all anchors at (0,0) unless noted):

    | Link | Values | Kind |
    |---|---|---|
    | globe → coast | 400 → 40000 | physical |
    | coast → beach | 30 → 30000 | physical |
    | beach → grain | 2 → 2000 | physical |
    | grain → silica | 0.5 → 60 | jump, ≈ ×833 |
    | silica → atom | 4 → 400 | physical; anchor at the Si atom nearest the patch center |

  - Globe:
    - Focus at Bude, UK (50.83, −4.55).
    - `SphereMesh` with a radius of 6371 units and the land texture.
    - A soft lilac rim (Fresnel).
    - Seven stylized cable arcs at 20 km altitude, as tubes with emissive peach color and moving light pulses (`MultiMesh`). The pairs are:
      - New York (40.71,−74.01) ↔ Bude (50.83,−4.55)
      - Virginia Beach (36.85,−75.98) ↔ Bilbao (43.26,−2.93)
      - Fortaleza (−3.73,−38.52) ↔ Sines (37.96,−8.87)
      - Los Angeles (34.05,−118.24) ↔ Chikura (34.95,139.95)
      - Marseille (43.30,5.37) ↔ Alexandria (31.20,29.92)
      - Singapore (1.35,103.82) ↔ Perth (−31.95,115.86)
      - Mumbai (19.08,72.88) ↔ Muscat (23.59,58.41)
    - Glow is enabled in a `WorldEnvironment`.
  - Coast: a sea plane with gentle wave shading, a noise-generated mint coastline, a butter beach strip, a few houses, a small cable landing building, and a peach cable line into the sea.
  - Beach: a sand plane, animated foam lines, the player's future workshop shack, shells.
  - Grain: low-poly noise-displaced grains in pastel quartz tones. Below a view of 5 the micro-surface fades in.
  - Silica: `MultiMesh` spheres (Si lavender, radius 0.9; O rose, radius 0.6) and thin bond cylinders.
  - Atom: a nucleus of 14 rose protons and 14 lilac neutrons, plus shells at display radii 50/100/150 holding 2, 8 and 4 butter electrons orbiting on tilted rings.
  - Captions (exact), one per layer:
    - globe: "This is Earth. The glowing lines are undersea cables that carry the internet."
    - coast: "Some of those cables come ashore on beaches like this one."
    - beach: "A quiet beach. This is where your journey starts."
    - grain: "One grain of sand."
    - silica: "Sand is mostly silica: silicon and oxygen atoms locked together."
    - atom: "A silicon atom. Everything you'll build starts here."
  - Atom Go-deeper text (exact): "Real electrons are fuzzy clouds, not tiny planets. And the nucleus is drawn far too big: if this atom were a stadium, its nucleus would be a pea."
  - Title UI: the "Circuit" heading, caption label, scale bar with jump badge, Skip, Settings, and Start/Continue (shown when the zoom finishes or is skipped). Any user zoom input stops autoplay. With reduced motion, the title shows a slideshow: each layer's home view for 4 s, fading through cream over 0.6 s.

- [ ] **Step 1: Write `tools/make_land.mjs` and run it once.**
  - In a fresh temp folder, `npm pack world-atlas@2.0.2 topojson-client@3.1.0`, extract them, and convert `land-110m.json` to `{"polygons": [[[lon,lat],…],…]}`. Keep outer rings only, round to 2 decimals.
  - Write `game/data/land_110m.json`. Expected: under 300 KB.
- [ ] **Step 2: Write the failing tests.**
  - `test_to_vec3_poles_and_prime_meridian`
  - `test_great_circle_on_sphere` (every point's length is R + altitude within 1e-3)
  - `test_silica_bonds` (every interior Si has 4 O within 1.7 Å, every interior O has exactly 2 Si within 1.7 Å, and the Si–O distance is ≈ 1.550 Å)
  - `test_fcc_neighbors` (12 neighbors at 2.556 Å within 1e-3 for interior atoms)
  - `test_land_data_sane` (at least 50 polygons, all coordinates in range)
  - `test_director_reaches_atom` (simulate 60 s of dt = 1/60 frames with `TitleDirector.new(TitleChain.infos(), TitleChain.links())`; it finishes in the atom layer in under 30 s of simulated time)
  - `test_skip_goes_to_atom`
  - `test_slideshow_order`
- [ ] **Step 3: Run `tools/test.sh title/`.** Expected: FAIL.
- [ ] **Step 4: Implement the layers, director and title screen.**
- [ ] **Step 5: Run the tests.** Expected: PASS.
- [ ] **Step 6: Visual check.** Capture each title layer at its home view (the title screen reads `--layer=`), in `gl_compatibility` and in `forward_plus` (lavapipe). It passes if:
  - continents are recognizable and Europe faces the camera
  - cables glow peach
  - the beach reads as a beach
  - the silica network shows tetrahedra
  - the atom shows 2-8-4 shells
  - the pastel palette is used throughout
  - Compatibility shows no missing effects, only fewer of them
- [ ] **Step 7: Commit** with `feat: title zoom from Earth to a silicon atom`.

### Task 19: Wire zoom and the "Inside the wire" level

**Files:**
- Create: `game/src/scenes/wire/{wire_closeup_layer,copper_layer}.gd`, `game/tests/wire/test_wire_zoom.gd`
- Modify: `game/src/editor/editor_layer.gd` (`dynamic_child`), `game/src/screens/level_screen.gd` (add the layers and links)

**Interfaces:**
- Consumes: Tasks 12, 15, 16.
- Produces:
  - `EditorLayer.dynamic_child(center)` returns a `ZoomLink("editor", "wire.closeup", anchor = closest point on the nearest wire path within 0.4 units, parent_min_view 3.0, child_max_view 762.0)`. It also calls `closeup.set_wire(amps, direction)`, where direction is the unit vector of the nearest segment and `closeup` is a `var closeup: WireCloseupLayer` that `LevelScreen` assigns. It returns null when there is no wire nearby.
  - `class_name WireCloseupLayer extends ZoomLayer`:
    - id `wire.closeup`, 1e-5 meters per unit, home 200
    - `set_wire(amps: float, dir: Vector2)`
    - Content: a 3D wire along `dir` with a copper core of radius 30, a translucent insulation of radius 70 and a cutaway, plus current arrows moving at `WireArt.dot_speed(amps)` scaled ×40.
    - Static link to copper: 8 → 60 (a jump of ≈ ×13,333).
  - `class_name CopperLayer extends ZoomLayer`:
    - id `wire.copper`, 1e-10 meters per unit, min view 15 (clamp)
    - An FCC patch of 6×6×2 cells: copper-peach spheres of radius 1.28 Å.
    - 60 butter electrons with random thermal jitter, plus a net drift **opposite** to conventional current. The visual drift speed is clamp(0.5·log10(|I|/1e-5), 0, 3) Å per second.
    - Caption (exact): "Copper atoms sit in a neat grid. Electrons zip around them and drift slowly from − to +."
  - `LevelScreen` reports the active layer to `game.set_zoom_layer(id)` on `layer_changed`.

- [ ] **Step 1: Write the failing tests.**
  - `test_dynamic_child_near_wire`
  - `test_dynamic_child_null_away_from_wires`
  - `test_closeup_receives_amps_and_direction`
  - `test_l8_zoom_to_copper_passes` (scene: open L8, repeatedly `zoom_at_screen(1.25, pin-free point on w1)` until the active layer is `wire.copper`; the session phase becomes `passed`)
- [ ] **Step 2: Run `tools/test.sh wire/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Visual check.** Capture the close-up and the copper layers. It passes if the cutaway shows the copper core, the arrows point the conventional way, the electrons drift the opposite way, and the "×13,000" badge is visible during the jump.
- [ ] **Step 6: Commit** with `feat: zoom into a wire down to copper atoms`.

### Task 20: Playthrough and robustness tests

**Files:**
- Create: `game/tests/e2e/{test_playthrough,test_touch,test_layout,test_motion,test_performance}.gd`

**Interfaces:**
- Consumes: everything above; drives `Main` through real input events with `get_viewport().push_input`.

- [ ] **Step 1: Write the tests.**
  - `test_play_l1_by_mouse`: from Main, go to the map, open L1, step through the intro, drag the three wires with mouse events, and expect the outro to appear. Back on the map, L2 is enabled.
  - `test_play_l2_burn_and_replace`: wire the LED straight to the battery and expect the toast "Pop! LED burned out.". Long-press the LED, choose Replace, place the 220 Ω resistor from the tray, wire it, and expect the level to pass with the star.
  - `test_touch_pinch_zoom`: two `ScreenTouch`/`ScreenDrag` fingers whose distance doubles halve `camera().view` within 2%, and the circuit is unchanged.
  - `test_touch_second_finger_cancels_wire`: finger 0 starts dragging from B1.pos, finger 1 lands, then both lift. The circuit is unchanged.
  - `test_resize_keeps_circuit_visible`: in L5, set the window to 1280×720, then 390×844, then 844×390. After each resize, every start-part pin's screen position is inside the board area (the viewport minus the HUD tray and top bar rects).
  - `test_reduced_motion`: with the setting on, `FlowView` isn't animating and the title uses the slideshow.
  - `test_solver_speed`: a 100-resistor ladder (battery plus 50 rungs, each a series 220 Ω and a shunt 1 kΩ) simulates in under 100 ms, measured with `Time.get_ticks_usec()`.
- [ ] **Step 2: Run `tools/test.sh e2e/`.** Expected: PASS. If anything fails, fix the owning task's code and rerun the full `tools/test.sh`.
- [ ] **Step 3: Commit** with `test: end-to-end playthrough, touch, layout, motion and speed`.

### Task 21: Downloadable builds

**Files:**
- Create: `game/export_presets.cfg`, `tools/export.sh`, `.github/workflows/build.yml`
- Modify: `README.md`

**Interfaces:**
- Produces:
  - Export presets:
    - "Linux": x86_64, `build/linux/Circuit.x86_64`
    - "Windows Desktop": x86_64, `build/windows/Circuit.exe`
    - "macOS": universal, `build/macos/Circuit.zip`
    - "Web": `variant/thread_support=false`, `build/web/index.html`
    - All presets use `exclude_filter="tests/*,tools/*,src/ui/gallery.*,src/zoom/zoom_demo.*,src/editor/art_gallery.*"`.
  - `tools/export.sh [linux|windows|macos|web|all]`:
    - If they are missing, downloads `Godot_v4.7.2-stable_export_templates.tpz` and verifies its SHA-512 the same way `godot.sh` does.
    - Unpacks it into `~/.local/share/godot/export_templates/4.7.2.stable/`.
    - Runs `--headless --path game --export-release "<preset>" <path>`.
    - Zips each output to `build/dist/Circuit-<platform>.zip`.
  - The CI workflow:
    - `test` job: `tools/test.sh`.
    - `export` job: caches the templates keyed on `4.7.2`, runs `tools/export.sh all`, and uploads one artifact per platform.
    - `release` job: on tags `v*`, runs `gh release create "$GITHUB_REF_NAME" build/dist/*.zip --title "Circuit $GITHUB_REF_NAME" --notes-file docs/release-notes.md`.
    - `pages` job: on `main`, only when the repo variable `PAGES_ENABLED == 'true'`; uses `actions/upload-pages-artifact@v3` and `actions/deploy-pages@v4`.
    - Only official `actions/*` actions are used.
    - Permissions are the minimum per job: `contents: read` for test and export, `contents: write` for release, and `pages: write` plus `id-token: write` for pages.
    - Godot and the templates are downloaded with the same SHA-512 check as `tools/godot.sh`.

- [ ] **Step 1: Write the presets, the export script and the workflow.**
- [ ] **Step 2: Run `tools/export.sh linux`, then `build/linux/Circuit.x86_64 --headless --quit-after 120`.** Expected: exit 0 and no script errors in the output.
- [ ] **Step 3: Run `tools/export.sh web`, serve `build/web` with `npx serve@14.2.6 build/web`, and open it with Playwright (preinstalled Chromium).** Expected: a canvas appears and the title caption "This is Earth…" renders. Take a screenshot to `build/captures/web.png` and review it.
- [ ] **Step 4: Update the README** with a "Play it" section:
  - **Windows:** unzip and run `Circuit.exe`. At the "Windows protected your PC" message, choose More info → Run anyway.
  - **Mac:** unzip, then right-click Circuit → Open.
  - **Linux:** `chmod +x Circuit.x86_64`.
  - **Browser:** the Pages link, once Pages is enabled.
  - Also add `docs/release-notes.md` for v0.1.0.
- [ ] **Step 5: Commit** with `chore: export presets, export script and CI release workflow`. Push the branch. **Ask the owner before tagging `v0.1.0`**, because tagging publishes a public release.
