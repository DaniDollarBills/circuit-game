# M1 "First Light" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A playable, downloadable first slice of *Circuit*. It has a title zoom from Earth down to a silicon atom, the pastel circuit editor with a real DC simulator, Chapter 1 "Spark" (9 levels using real-life parts, datasheets and formulas, with heavy help on by default), and a zoom into a wire down to copper atoms. Windows, macOS, Linux and web builds are produced by CI.

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
| LED thresholds | lit ≥ 0.0005 A; full brightness and recommended maximum 0.020 A; burns above the absolute maximum 0.030 A |
| Resistor | burns above its `watts` rating (default 0.25 W); adjustable range 100–2000 Ω, step 10 |
| Ammeter | a real 0.1 Ω device in the netlist (its burden, as on its datasheet); fuse 0.5 A |
| Voltmeter | 10 MΩ input resistance, like a real multimeter (a real device in the netlist) |
| Wire and closed-switch flow conductance | 1000 S |
| Battery "short" flag | > 1.0 A |
| gmin | 1e-12 S |

**Look**
- Light palette (exact hex): `cream #FFF8EF`, `paper #FFFFFF`, `ink #3D3A4B`, `ink_soft #6E6A80`, `line #E7E1F0`, `lavender #CDB8F0`, `lilac #E6DAFB`, `mint #BDEBD7`, `sky #BFDDF8`, `peach #FFD3B8`, `butter #FFF0A6`, `rose #F8C3D6`, `coral #FF9F8A`, `signal_low #B9B3D1`, `signal_high #FF8FAB`, `spark #FFE58A`, `metal #D9D6E6`.
- Night palette overrides: `cream #24212F`, `paper #2F2B3D`, `ink #F3EEFF`, `ink_soft #BDB6D6`, `line #3B3650`.
- LED tints: red `#FF8F9A`, yellow `#FFE27A`, green `#8FE3B0`, blue `#8FC2FF`.
- Font: Nunito 400/700/800 (`@fontsource/nunito@5.3.0` woff2 files), imported with MSDF enabled.

**Real-life look (3D)**
- In workbench scenes, 1 world unit = 1 cm. The board's grid pitch is 0.254 units (2.54 mm), and the board top is at y = 0.
- True-to-size dimensions in mm (exact):

  | Item | Dimensions |
  |---|---|
  | LED, 5 mm | dome Ø5.0, flange Ø5.8, height 8.6; leads 0.5 mm square, 2.54 apart; flat on the cathode side |
  | ¼ W carbon-film resistor | body 6.3 × Ø2.4, beige; leads Ø0.6; pin span 10.16 |
  | 1 W metal-film resistor | body 11.0 × Ø4.5, blue; pin span 15.24 |
  | Mini toggle switch | body 13 × 8 × 10; lever 10 |
  | AA cell | 50.5 × Ø14.5 |
  | 4 × AA holder | 63 × 58 × 15 |
  | Jumper wire, 22 AWG | copper Ø0.64; insulation Ø1.4 |
  | Perfboard | 1.6 thick FR-4; holes Ø1.0; tinned pads Ø1.8 at every grid point |
  | Handheld multimeter | 150 × 75 × 35 |

- The battery holder and the multimeters sit on the desk beside the board, joined to their pins by leads (battery) or clip leads (meters).
- Assets are listed in `game/assets/third_party/manifest.json` with URL, license, credit and checksum. `tools/fetch_assets.mjs` downloads and verifies them, the files are committed, and `CREDITS.md` lists them.
- M1 Poly Haven assets (CC0, 2K): `studio_small_09` (HDRI), `kloofendal_48d_partly_cloudy_puresky` (HDRI), `wood_table_001`, `aerial_beach_01` and `sand_01` (textures). NASA Earth imagery is added in Task 18.

**Real life by default, heavy help**
- Settings defaults:
  - `help_level = "heavy"` (`"heavy"`|`"light"`|`"off"`)
  - `view_style = "physical"` (`"physical"` is the real-looking 3D workbench; `"schematic"` shows circuit symbols)
  - `show_values = true`
  - `show_current = true` (the glowing current-flow overlay)
  - `quality = "auto"` (`"auto"`|`"low"`|`"medium"`|`"high"`|`"ultra"`)
- Every part has a datasheet (`Catalog.datasheet`) with real-world values, and every value shown on screen can be explained (`Explain.part`).
- The help level only changes how much guidance is shown, never the parts, values or physics.
- UI flags record help actions so steps can tick:
  - `"datasheet:<part id>"` and `"datasheet:tray"`
  - `"formula:<name>"`
  - `"value:<part id>"`
  - `"selected:<wire id>"`
  - `"tested"`

**Copy and interaction**
- Player-facing guide lines: at most 2 sentences and 30 words each. Glossary markup is `[[term]]` or `[[term|shown text]]`.
- Touch targets ≥ 44 px. The pin hit radius is at least 22 screen px and at least 0.35 grid units.
- **Defined on the spot:** every on-screen string goes through `GlossaryText.render`. It auto-links each glossary term or alias and reports the terms the player hasn't met yet. An unseen term gets a New word card at **every** help level.
- Each glossary entry has a `simple` definition (≤ 30 words, everyday language) and a `precise` one (≤ 40 words, expert-accurate). Both may only use everyday words or other glossary terms.
- **Accuracy:** every number shown comes from the simulation or from the constants in this plan. Every content fact has a `source`.

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
game/src/lessons/    level_def.gd level_builder.gd goals.gd level_tests.gd solution_diff.gd level_session.gd formulas.gd e12.gd
game/src/save/       progress.gd progress_storage.gd achievements.gd
game/src/content/    glossary.gd chapters.gd levels.gd ch1/l1_light_it_up.gd … ch1/l9_inside_the_wire.gd
game/src/ui/         palette.gd pastel_theme.gd glossary_text.gd gallery.tscn gallery.gd
game/src/zoom/       zoom_camera.gd zoom_link.gd layer_info.gd zoom_math.gd scale_format.gd zoom_layer.gd zoom_stage.gd zoom_demo.tscn zoom_demo.gd
game/src/input/      gesture_recognizer.gd pointer_input.gd
game/src/render/     quality.gd studio_environment.gd materials.gd materials_gallery.tscn materials_gallery.gd
game/src/workbench/  part_dims.gd part_models.gd wire_mesh.gd meter_rig.gd workbench_3d.gd workbench_gallery.tscn workbench_gallery.gd
game/assets/third_party/ manifest.json CREDITS.md polyhaven/… nasa/…
tools/fetch_assets.mjs
game/src/editor/     draw_kit.gd resistor_bands.gd visual_state.gd explain.gd part_art.gd wire_art.gd hit_test.gd editor_controller.gd circuit_view.gd flow_view.gd editor_layer.gd editor_layer.tscn art_gallery.tscn art_gallery.gd
game/src/screens/    title_screen.* map_screen.* level_screen.*
game/src/hud/        top_bar.gd parts_tray.gd goals_panel.gd test_sheet.gd hint_button.gd context_menu.gd value_popover.gd toasts.gd pip.gd guide_bubble.gd glossary_popup.gd settings_sheet.gd scale_bar.gd steps_checklist.gd datasheet_card.gd formula_card.gd explain_popover.gd new_word_card.gd notebook_sheet.gd
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
    | `battery` | Battery pack (4 × AA) | (2,4) | `pos` (0,−2), `neg` (0,2) | `{volts: 5.0}` |
    | `resistor` | Resistor | (4,1); (6,1) when `watts ≥ 1.0` | `a` (−2,0), `b` (2,0); (−3,0) and (3,0) when `watts ≥ 1.0` | `{ohms: 220.0, adjustable: false, watts: 0.25}` |
    | `led` | LED | (2,1) | `anode` (−1,0), `cathode` (1,0) | `{color: "red"}` |
    | `switch` | Switch | (4,1) | `a` (−2,0), `b` (2,0) | `{closed: false}` |
    | `ammeter` | Current meter | (2,2) | `a` (−1,0), `b` (1,0) | `{}` |
    | `voltmeter` | Voltage meter | (2,2) | `pos` (−1,0), `neg` (1,0) | `{}` |

  - `Catalog.pin_names(kind) -> PackedStringArray` and `Catalog.title(kind) -> String`
  - `Catalog.pins(kind, props := {}) -> Array` and `Catalog.size(kind, props := {}) -> Vector2i`. These are props-aware (1 W resistors are wider), and `CircuitGeometry` always uses them.
  - `Catalog.datasheet(p: Part) -> Array[Dictionary]`: rows `{label, value, term}`, where `term` is a glossary key or `""`. The copy is exact:
    - **battery:** Voltage "5.0 V" (voltage); Cells "4 × AA, partly used"; Internal resistance "1 Ω" (resistance); Short-circuit current "5 A, gets hot!" (short circuit)
    - **resistor:** Resistance "{ohms} Ω" (resistance); Tolerance "±5%"; Power rating "0.25 W (¼ W)" or "1 W" (power); Type "Carbon film"
    - **led:** Color "Red, 625 nm" / "Yellow, 590 nm" / "Green, 570 nm" / "Blue, 470 nm"; Forward voltage "2.0 / 2.1 / 2.2 / 3.0 V at 20 mA" (forward voltage); Recommended current "20 mA" (current); Absolute maximum "30 mA"; Polarity "+ anode (long leg), − cathode (flat side)" (anode)
    - **switch:** Type "SPST toggle (single-pole, single-throw)"; State "Open" or "Closed"
    - **ammeter:** Measures "Current, placed in series" (ammeter); Burden "0.1 Ω"; Fuse "500 mA"
    - **voltmeter:** Measures "Voltage, placed in parallel" (voltmeter); Input resistance "10 MΩ"
    - These forward voltages are the terminal voltages, and they match the model: junction voltage plus 5 Ω × 20 mA.
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
  - `test_resistor_default_watts_quarter()`
  - `test_one_watt_resistor_pins_wider()` (`watts: 1.0` at (0,0) rot 0 puts pins at (−3,0) and (3,0))
  - `test_datasheet_red_led()` (has rows "Forward voltage" = "2.0 V at 20 mA" and "Absolute maximum" = "30 mA")
  - `test_datasheet_one_watt_resistor()` ("Power rating" = "1 W")
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
    - `var devices: Array[Dictionary]` (`{part: Part, kind: String, nets: PackedInt32Array}` in catalog pin order, for unburnt batteries, resistors and LEDs, for voltmeters as a 10 MΩ resistor between `pos` and `neg`, and for unburnt ammeters as a 0.1 Ω resistor between `a` and `b`)
    - `var connectors: Array[Dictionary]` (`{id: String, kind: "wire"|"switch", a: String, b: String, g: float}`, where `a` and `b` are pin keys)
    - `var voltmeters: Array[Part]`
    - `static func build(c: Circuit) -> Netlist`
  - Merge rules:
    - Wires and closed switches merge their two pin keys (union-find).
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
  - `test_ammeter_is_a_0_1_ohm_device`
  - `test_burnt_resistor_not_a_device`, `test_burnt_ammeter_is_open`
  - `test_isolated_resistor_nets_floating`
  - `test_two_battery_loops_two_references`
  - `test_voltmeter_is_10m_device` (it joins the components of its two nets)
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
  - `test_voltmeter_draws_half_microamp` (a voltmeter alone across the battery: `device_amps["V1"]` is 5e-7 within 1e-9)
- [ ] **Step 2: Run `tools/test.sh dc_solver`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
  - **Unknowns:** the nets of each powered component except its reference, plus one internal node per LED (between `Rs` and the junction).
  - **Stamps:**
    - resistor: conductance G = 1/R
    - battery: Norton equivalent, G = 1/R_int between `pos` and `neg`, with source V/R_int into `pos` and out of `neg`
    - LED: `Rs` from the anode to the internal node, and the junction from the internal node to the cathode
    - voltmeter: conductance 1e-7 S between `pos` and `neg`; `device_amps` is pos→neg
    - ammeter: conductance 10 S between `a` and `b`; `device_amps` is a→b
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
  - `test_burn_order_highest_ratio_first`: a battery, a 10 Ω resistor and a red LED in series. The LED ratio is ≈ 6.2 (186.5 mA ÷ 30 mA) and the resistor's ≈ 1.4; only L1 burns.
  - `test_quarter_watt_resistor_burns_at_half_watt`: 47 Ω (¼ W) straight across the battery dissipates 0.51 W and burns with `"overheat"`.
  - `test_one_watt_resistor_survives_half_watt`: the same circuit with `watts: 1.0` has no damage and 0.510 W within 1e-3.
  - `test_led_over_recommended_but_under_max_not_burnt`: a 100 Ω resistor gives ≈ 29.1 mA and no damage.
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
      - voltmeter: `pos` −I, `neg` +I (its tiny 10 MΩ current)
      - ammeter: `a` −I, `b` +I (its reading is its own device current)
    - Pin the first vertex at 0, solve the Laplacian with `DenseSolver`, then each edge current = g·(φa − φb).
  - **Damage rules:**
    - LED forward current > 0.030 A, ratio I/0.030, `"overcurrent"`
    - resistor watts > `props.watts`, ratio P/watts, `"overheat"`
    - ammeter |I| > 0.5 A, ratio |I|/0.5, `"fuse"`
  - **Simulate:** loop up to 10 times: build → solve → flow → detect. When something is detected, burn only `damage[0]` (via `set_props` with `burnt: true`) and repeat.
  - **Voltmeter readable** = both pins non-floating and in the same component.
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: current flow, damage rules and simulate()`.

### Task 8: Level definitions, goals, level tests and solution diff

**Files:**
- Create: `game/src/lessons/{level_def,level_builder,goals,level_tests,solution_diff,formulas,e12}.gd`, `game/tests/lessons/{test_goals,test_level_tests,test_solution_diff,test_formulas}.gd`

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
    - `outro: Array[Dictionary]`, `facts: Array[Dictionary]` (`{text, source}`)
    - `star: Dictionary` (`{goal, text}` or `{}`)
    - `steps: Array[Dictionary]` (`{text, check: goal}`): the heavy-help checklist
    - `formula: String` (`""`, `"led_resistor"`, `"ohms_law"` or `"power"`): the calculator that heavy help suggests
  - `LevelBuilder` (fluent; every method returns `self`):
    - `_init(id, chapter, title)`, `summary(t)`, `kind(k)`
    - `part(id, kind, x, y, rot := 0, props := {}, locked := true)`
    - `wire(id, a_part, a_pin, b_part, b_pin, locked := true, via: Array[Vector2i] = [])`
    - `tray(kind, props := {}, count := 1)`, `goal(g)`, `test(name, set, expect)`
    - `hint(text, highlight := [], show_solution := false)`
    - `solution_part(id, kind, x, y, rot, props)` (gets the tray index of the first tray item with the same kind and matching props)
    - `solution_wire(a_part, a_pin, b_part, b_pin)`, `solution_props(id, patch)`, `solution_remove_wire(id)`
    - `intro(text, mood := "happy")`, `outro(text, mood := "wow")`, `fact(text, source)`, `star(goal, text)`, `step(text, check)`, `formula(name)`
    - `done() -> LevelDef` (the solution is the start circuit plus the solution edits)
  - `Goals.evaluate(goal: Dictionary, ctx: Dictionary) -> Dictionary` and `Goals.evaluate_all(goals, ctx) -> Array[Dictionary]`
    - `ctx = {circuit, sim: SimResult, zoom_layer: String, zoom_seen: Dictionary, ui_flags: Dictionary}`
    - Result = `{pass: bool, message: String}`
  - Goal kinds:
    - `led_lit {part, min_ma?, max_ma?}`
    - `led_dark {part}`
    - `no_damage`
    - `no_short`
    - `meter_reads {part, target, tolerance}`
    - `uses {part_kind, min?, max?}`
    - `zoom_reached {layer}`: passes when `layer` is the current layer or is in `zoom_seen`
    - `connected {a, b}`: pin specs are `"<part>:<pin>"` or `"<part>:*"` (any pin of that part); passes when both share a net
    - `all {goals}`: passes when every inner goal passes
    - `ui_flag {flag}`: passes when `ctx.ui_flags` has the flag
    - `resistor_watts {min, max}`: passes when some unburnt resistor dissipates within [min, max] W
    - The `part` field matches a part id or a label.
  - `E12.values(lo := 10.0, hi := 10000.0) -> PackedFloat64Array`: 10, 12, 15, 18, 22, 27, 33, 39, 47, 56, 68, 82 times powers of ten, within [lo, hi]
  - `E12.at_or_above(r: float) -> float`: the smallest standard value ≥ r
  - `Formulas.led_resistor(supply_v: float, led_v: float, led_a: float) -> Dictionary` returns `{exact, standard, steps: PackedStringArray}`. For (5, 2.0, 0.020) the steps are exactly: `"R = (supply − LED voltage) ÷ current"`, `"R = (5.0 V − 2.0 V) ÷ 0.020 A"`, `"R = 150 Ω"`, `"Nearest standard value at or above: 150 Ω"`.
  - `Formulas.ohms_law(v: float, i: float, r: float) -> Dictionary`: exactly one argument is NAN and gets solved; returns `{value, unit, steps}`. For (5, NAN, 500): value 0.010, unit `"A"`, last step `"I = 5.0 V ÷ 500 Ω = 0.010 A (10 mA)"`.
  - `Formulas.power_from_r(v: float, r: float) -> Dictionary`. For (5, 47): value ≈ 0.532, last step `"P = (5.0 V)² ÷ 47 Ω = 0.53 W"`.
  - Number formats in steps: volts 1 decimal, amps 3 decimals (mA in parentheses where shown), ohms as integers, watts 2 decimals.
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
    6. above `max_ma` → `"Careful: {ma} mA is more than this LED's recommended {max} mA. It glows, but it won't last."`
    7. below `min_ma` → `"It's glowing, but dimly ({ma} mA). Can you make it brighter?"`
    8. pass → `"Lit! {ma} mA flowing."`
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
  - `connected`: pass `"Connected."`, fail `"Not connected yet."`
  - `all`: its message is the first failing inner message, or `""` when all pass
  - `ui_flag`: pass `"Done."`, fail `"Not yet."`
  - `resistor_watts`: pass `"{w} W of heat. Toasty!"` (2 decimals), fail `"Aim for {min}–{max} W of heat from a resistor."`
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
    - `test_led_over_max_message` (100 Ω gives ≈ 29.1 mA, over a `max_ma` of 20)
    - `test_connected_any_pin_wildcard`
    - `test_all_requires_every_goal`
    - `test_ui_flag_and_zoom_seen`
    - `test_resistor_watts_range`
    - `test_e12_values_and_at_or_above` (350 → 390; 150 → 150; 500 → 560)
    - `test_led_resistor_formula_150`
    - `test_ohms_law_solves_missing`
    - `test_power_from_r_47`
- [ ] **Step 2: Run `tools/test.sh lessons/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: level definitions, goal diagnosis, level tests and solution diff`.

### Task 9: Level session, progress and safe storage

**Files:**
- Create: `game/src/lessons/level_session.gd`, `game/src/save/{progress,progress_storage,achievements}.gd`, `game/tests/lessons/test_level_session.gd`, `game/tests/save/test_progress.gd`, `game/tests/save/test_storage.gd`, `game/tests/save/test_achievements.gd`

**Interfaces:**
- Consumes: Task 8.
- Produces:
  - `class_name LevelSession extends RefCounted` with fields:
    - `level_id: String`
    - `phase: String` (`"intro"`|`"build"`|`"passed"`)
    - `intro_index: int`, `hint_tier: int`
    - `goal_results: Array[Dictionary]`, `test_report: Dictionary`
    - `used_hints: bool`
    - `step_results: Array[Dictionary]` (one per level step)
  - `LevelSession` static functions:
    - `start(level) -> LevelSession`
    - `next_intro(s, level) -> void` (after the last line, the phase becomes `"build"`)
    - `update(s, level, ctx) -> void` (re-evaluates goals and steps; a level **without tests** moves to `"passed"` when every goal passes; steps are guidance and never block passing)
    - `run_tests(s, level, circuit, ctx) -> void` (moves to `"passed"` only if all goals and the report pass)
    - `hint(s, level) -> void` (tier + 1, capped at `level.hints.size()`; sets `used_hints`)
  - `class_name Progress extends RefCounted`:
    - `const VERSION := 1`
    - `completed: Dictionary` (id → `{star: bool, at: int}`)
    - `drafts: Dictionary` (id → circuit dict)
    - `settings: Dictionary` with defaults `help_level: "heavy"`, `view_style: "schematic"`, `show_values: true`, and `reduced_motion`, `electron_flow`, `large_text`, `patterns`, `night` all false
    - `stats: Dictionary` (`{parts_burnt: 0}`)
    - `seen_terms: Dictionary` (term → unix time first seen; this is the Notebook) and `achievements: Dictionary` (id → unix time earned)
    - `mark_terms_seen(terms: PackedStringArray, now: int) -> PackedStringArray` (records them and returns only the terms that were new)
    - `static defaults() -> Progress`, `to_dict() -> Dictionary`, `static from_dict(d) -> Progress` (null on an unknown version or wrong types)
    - `is_unlocked(level_id: String, chapter_level_ids: PackedStringArray) -> bool` (the first level is always unlocked; any other needs the previous one completed)
    - `mark_complete(level_id, star: bool, now: int)` (a star, once earned, stays)
  - `ProgressStorage.load(path := "user://progress.json") -> Dictionary` returns `{progress: Progress, ok: bool, recovered: bool}`. A corrupt file is renamed to `progress.corrupt-<unix>.json` in the same folder.
  - `ProgressStorage.save(p: Progress, path := "user://progress.json") -> bool` writes `<path>.tmp` and then renames it over the real file.
  - `Achievements.ALL: Array[Dictionary]` (`{id, name, description}`, exact copy):

    | id | Name | Description | Earned when |
    |---|---|---|---|
    | `first_light` | First Light | Light your first LED. | `ch1.light-it-up` complete |
    | `magic_smoke` | Magic Smoke | Burn out a part. Every engineer does it! | `stats.parts_burnt ≥ 1` |
    | `on_spec` | Right on Spec | Earn the 18–20 mA star. | star on `ch1.pop` |
    | `ohms_apprentice` | Ohm's Apprentice | Use Ohm's law to hit 10 mA. | `ch1.push-and-flow` complete |
    | `logic_begins` | Logic Begins | Build the both-switches and either-switch circuits. | `ch1.both` and `ch1.either` complete |
    | `deep_diver` | Deep Diver | Zoom all the way into a wire. | `ch1.inside-the-wire` complete |
    | `word_collector` | Word Collector | Learn 20 new words. | `seen_terms.size() ≥ 20` |
    | `spark_graduate` | Spark Graduate | Finish every Chapter 1 level. | all nine `ch1` levels complete |

  - `Achievements.newly_earned(p: Progress, ch1_ids: PackedStringArray) -> PackedStringArray` returns the ids whose condition now holds and that aren't in `p.achievements` yet. The caller records them.

- [ ] **Step 1: Write the failing tests.**
  - `test_intro_then_build`
  - `test_goals_only_level_passes_on_update`
  - `test_tests_level_needs_run_tests`
  - `test_hint_tier_caps`
  - `test_steps_tick_live`
  - `test_defaults_are_real_life_heavy_help` (`help_level` "heavy", `view_style` "schematic", `show_values` true)
  - `test_mark_terms_seen_returns_only_new`
  - `test_first_light_earned_once`
  - `test_magic_smoke_after_first_burn`
  - `test_word_collector_at_20_terms`
  - `test_spark_graduate_needs_all_nine`
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

### Task 10: Chapter 1 content, two-layer glossary, automatic definitions and chapter list

**Files:**
- Create: `game/src/content/{glossary,chapters,levels}.gd`, `game/src/content/ch1/l1_light_it_up.gd` … `l7_short_circuit.gd`, `l8_too_hot.gd`, `l9_inside_the_wire.gd` (each defines `static func build() -> LevelDef` and has **no** `class_name`), `game/src/ui/glossary_text.gd`, `game/tests/content/test_content.gd`, `game/tests/ui/test_glossary_text.gd`

**Interfaces:**
- Consumes: `LevelBuilder`, `Goals`, `LevelTests`, `Simulator`.
- Produces:
  - `Glossary.ENTRIES: Dictionary` (term → `{title, simple, precise, aliases: PackedStringArray, explicit_only: bool}`)
  - `GlossaryText.render(text: String, seen: Dictionary, autolink := true) -> Dictionary` (pure) returns `{bbcode: String, terms: PackedStringArray, new_terms: PackedStringArray}`.
    - **Explicit markup:**
      - `[[term]]` and `[[term|shown]]` link that term; unknown terms stay plain text.
      - `[[=text]]` shows `text` and never auto-links it.
    - **Auto-linking** (when `autolink` is true): the first occurrence in the string of every glossary term or alias is linked.
      - The longest match wins, so "forward voltage" beats "voltage".
      - Matching is case-insensitive, on whole words, allowing a trailing "s", "es" or "'s".
      - `explicit_only` terms are linked only through markup.
    - A link renders as `[url=<term>][color=#7C5CC4]<shown>[/color][/url]`.
    - `new_terms` lists the linked terms that aren't in `seen`.
    - Badge names are rendered with `autolink = false`.
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
| 2 | `ch1.pop` "Pop!" | B1, L1 (compact positions) | resistors 47, 100, 150, 220, 330 and 1000 Ω (1 each, ¼ W) | led_lit L1 `max_ma` 20, no_damage, uses resistor min 1 | — | resistor (150) at (−2,−4) + w1, w2, w3 equivalents |
| 3 | `ch1.push-and-flow` "Push and flow" | B1; R1 1000 adjustable; M1 ammeter at (6,0) rot 90; V1 voltmeter at (−2,−7); locked wires B1.pos→R1.a, R1.b→M1.a, M1.b→B1.neg, V1.pos→R1.a, V1.neg→R1.b | — | meter_reads M1 target 0.010 tolerance 0.0005, no_damage | — | `solution_props("R1", {ohms: 500.0})` |
| 4 | `ch1.on-and-off` "On and off" | wide, locked w1, w3 | switch `{label:"S"}` | no_damage, no_short, uses switch min 1 | "Switch off: LED off" (S off → led_dark), "Switch on: LED on" (S on → led_lit) | S at (6,−4); R1.b→S.a, S.b→L1.anode |
| 5 | `ch1.both` "Both switches" | wide, locked w1, w3 | switch A, switch B | no_damage, no_short, uses switch min 2 | the 4 combinations; only "A on, B on: LED on" is lit | A at (3,−4), B at (8,−4); R1.b→A.a, A.b→B.a, B.b→L1.anode |
| 6 | `ch1.either` "Either switch" | wide, locked w1, w3 | switch A, switch B | same as L5 | 4 combinations; lit unless both are off | A at (4,−4), B at (4,−7); R1.b→A.a, A.a→B.a, B.b→A.b, A.b→L1.anode |
| 7 | `ch1.short-circuit` "Short circuit!" | compact, w1–w3 locked, plus **unlocked** `w_bad` R1.a→L1.cathode via [(−4,−6),(9,−6),(9,1)] | — | no_short, led_lit L1 | — | `solution_remove_wire("w_bad")` |
| 8 | `ch1.too-hot` "Too hot to handle" | B1 only | resistor `{ohms: 47.0, watts: 0.25}` and resistor `{ohms: 47.0, watts: 1.0}` (1 each) | resistor_watts min 0.4 max 0.6, no_damage | — | the 1 W resistor at (−2,0) rot 90; B1.pos→R.a, R.b→B1.neg |
| 9 | `ch1.inside-the-wire` "Inside the wire", kind `zoom` | compact, w1–w3 locked | — | zoom_reached `wire.copper` | — | the start circuit (hint 3: no ghost) |

Formulas (the calculator heavy help suggests): L2 `led_resistor`, L3 `ohms_law`, L8 `power`.

- Star for L2: `{goal: {kind: "led_lit", part: "L1", min_ma: 18.0, max_ma: 20.0}, text: "Brightest glow within spec (18–20 mA)"}`. Only 150 Ω earns it (19.9 mA).
- Every level has 2–5 **steps** for the heavy-help checklist. They're listed with each level's copy below, with their checks in parentheses.
- In M1, each level's facts double as its "Go deeper" card. Fuller Go-deeper panels start in M3.
- Test case names for L5 and L6 follow `"A on, B off: LED off"`.

**Copy (exact).** Moods are given in parentheses. Hints are listed as tier 1, tier 2 (with what it highlights), tier 3.

- **L1**
  - summary: "Close the loop to light an LED."
  - intro:
    1. "Hi! I'm Pip, a tiny spark of [[electricity]]." (happy)
    2. "Electricity only flows around a full loop: out of the battery's + side, through your parts, and back into −." (curious)
    3. "Drag from one metal dot to another to add a wire. Can you light the [[led|LED]]?" (happy)
  - steps:
    1. "Connect the battery's + to the resistor's left end." (`connected B1:pos R1:a`)
    2. "Connect the resistor's right end to the LED's + side." (`connected R1:b L1:anode`)
    3. "Connect the LED's − side back to the battery's −." (`connected L1:cathode B1:neg`)
  - hints:
    1. "Current leaves the battery's + end. Where should it go first?"
    2. "Connect the battery's + to the resistor, the resistor to the LED, and the LED back to −." (highlights B1.pos, R1.a)
    3. "Here's one way to do it. Tap the ghost wires to place them."
  - outro:
    1. "You made light! About 14 [[milliamp|milliamps]] are flowing around your loop." (wow)
    2. "Every phone and computer works because of loops like this one." (happy)
  - fact: "The first practical LED, made in 1962, could only glow red." (source: "Nick Holonyak Jr., General Electric, 1962")
- **L2**
  - summary: "Work out the right resistor from the LED's datasheet."
  - intro:
    1. "This LED has no [[resistor]]. What could go wrong?" (curious)
    2. "Try connecting it straight to the battery and watch closely." (happy)
  - steps:
    1. "Tap the LED to read its [[datasheet]]." (`ui_flag "datasheet:L1"`)
    2. "Work out the resistor with the calculator." (`ui_flag "formula:led_resistor"`)
    3. "Place the resistor you picked." (`uses resistor min 1`)
    4. "Wire it in and close the loop. Keep it at 20 mA or less." (`led_lit L1 max_ma 20`)
  - hints:
    1. "Too much [[current]] burns an LED. A resistor limits the current."
    2. "The datasheet says 2.0 V at 20 mA. Resistor = (5 V − 2.0 V) ÷ 0.020 A." (highlights L1)
    3. "Here's a safe circuit. Tap the ghosts to place them."
  - outro:
    1. "Safe and glowing! That's the exact formula engineers use for every LED." (wow)
    2. "Resistors come in [[standard values]]. 150 Ω is exactly right here." (happy)
  - fact: "Stripes on a resistor show its value. Brown, green, brown means 150 ohms." (source: "IEC 60062 resistor color code")
- **L3**
  - summary: "Use Ohm's law to set exactly 10 mA."
  - intro:
    1. "[[voltage|Voltage]] is the push. [[current|Current]] is the flow. [[resistance|Resistance]] makes flowing harder." (curious)
    2. "Tap the resistor and turn its dial until the [[ammeter|current meter]] shows 10 mA." (happy)
  - steps:
    1. "Tap the resistor to open its dial." (`ui_flag "value:R1"`)
    2. "Use Ohm's law: R = 5 V ÷ 0.010 A." (`ui_flag "formula:ohms_law"`)
    3. "Turn the dial until the meter reads 10 mA." (`meter_reads M1 0.010 ±0.0005`)
  - hints:
    1. "More resistance means less current. Is the meter too high or too low?"
    2. "Try about 500 ohms." (highlights R1)
    3. "Set the resistor to 500 ohms."
  - outro:
    1. "That's [[ohms law|Ohm's law]]: current equals voltage divided by resistance." (wow)
    2. "5 volts ÷ 500 ohms = 0.01 amps, which is 10 milliamps." (happy)
  - fact: "Georg [[=Ohm]] published his law in 1827." (source: "G. S. Ohm, Die galvanische Kette, mathematisch bearbeitet, 1827")
- **L4**
  - summary: "Control the light with a switch."
  - intro:
    1. "A [[switch]] opens and closes the loop, like a drawbridge." (curious)
    2. "Add the switch so it controls the LED. Tap it to try, then press Test." (happy)
  - steps:
    1. "Place the switch from the tray." (`uses switch min 1`)
    2. "Connect the resistor to one side of the switch." (`connected R1:b S:*`)
    3. "Connect the other side to the LED's + side." (`connected L1:anode S:*`)
    4. "Try the switch, then press Test." (`ui_flag "tested"`)
  - hints:
    1. "The loop has a gap. The switch can fill it."
    2. "Connect the resistor to one side of the switch, and the other side to the LED." (highlights R1.b, L1.anode)
    3. "Here's one way. Tap the ghosts to place them."
  - outro:
    1. "On and off, 1 and 0. That's a [[bit]]!" (wow)
    2. "Computers are made of billions of tiny switches doing exactly this." (happy)
  - fact: "'[[bit|Bit]]' is short for 'binary digit'. The word was first used in 1947." (source: "J. W. Tukey, Bell Labs memo, January 1947; popularized by C. E. Shannon, 1948")
- **L5**
  - summary: "Light it only when both switches are on."
  - intro:
    1. "Here are two switches, A and B." (happy)
    2. "Make the LED light only when A and B are both on." (curious)
  - steps:
    1. "Place switches A and B." (`uses switch min 2`)
    2. "Connect the resistor to A." (`connected R1:b A:*`)
    3. "Connect A to B." (`connected A:* B:*`)
    4. "Connect B to the LED's + side." (`connected B:* L1:anode`)
    5. "Press Test." (`ui_flag "tested"`)
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
  - steps:
    1. "Place switches A and B." (`uses switch min 2`)
    2. "Connect one side of each switch to the resistor." (`all [connected R1:b A:*, connected R1:b B:*]`)
    3. "Connect the other sides to the LED's + side." (`all [connected L1:anode A:*, connected L1:anode B:*]`)
    4. "Press Test." (`ui_flag "tested"`)
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
  - steps:
    1. "Tap the wires to find the one going from + straight to −." (`ui_flag "selected:w_bad"`)
    2. "Hold it and choose Delete." (`no_short`)
  - hints:
    1. "One wire connects the + side straight to the − side."
    2. "It's this wire. Hold it and choose Delete." (highlights w_bad)
    3. "Delete the highlighted wire."
  - outro:
    1. "Fixed! The current goes through the LED again." (wow)
    2. "Real short circuits can melt wires. Never connect a real battery's + and − together!" (curious)
  - fact: "Fuses and circuit breakers cut the power when too much current flows." (source: "Standard overcurrent protection, e.g. IEC 60269 fuses")
- **L8**
  - summary: "Pick a resistor that can handle the heat."
  - intro:
    1. "Resistors turn electricity into heat. That's how toasters work!" (happy)
    2. "Make about half a [[watt]] of heat without burning anything. Check each resistor's [[datasheet]] first." (curious)
  - steps:
    1. "Read both resistors' datasheets in the tray." (`ui_flag "datasheet:tray"`)
    2. "Work out the heat with the calculator." (`ui_flag "formula:power"`)
    3. "Place the resistor that can handle it." (`uses resistor min 1`)
    4. "Connect it across the battery." (`resistor_watts 0.4–0.6`)
  - hints:
    1. "[[power|Power]] = voltage × current. Both resistors are 47 Ω, but they're not the same."
    2. "One is rated ¼ W and the other 1 W. Which one can handle half a watt?"
    3. "Here's the circuit. Tap the ghosts to place them."
  - outro:
    1. "Toasty! That's 0.51 watts of heat, and the 1 W resistor handles it easily." (wow)
    2. "Engineers always check the power rating. A ¼ W resistor here would burn." (curious)
  - fact: "A hair dryer turns about 1,500 watts into heat, 3,000 times more than your resistor." (source: "Typical hair dryer rating 1,200–1,875 W; 1,500 ÷ 0.51 ≈ 2,940")
- **L9**
  - summary: "Zoom into a wire to see electrons."
  - intro:
    1. "Wires look solid, but a short piece holds billions of trillions of free [[electron|electrons]] that can move." (curious)
    2. "Pinch or scroll over a wire to zoom in. Keep going until you see atoms!" (happy)
  - steps:
    1. "Zoom in over a wire." (`zoom_reached wire.closeup`)
    2. "Keep going until you see atoms." (`zoom_reached wire.copper`)
  - hints:
    1. "Put your fingers or mouse right over a wire, then zoom in."
    2. "Keep zooming in. The wire gets bigger and bigger." (highlights w1)
    3. "Keep zooming in through the wire to reach the copper atoms." (`show_solution: false`)
  - outro:
    1. "Those are copper [[atom|atoms]] in a [[crystal lattice]]. Electrons drift from − to +, against the [[conventional current]] arrows." (wow)
    2. "Electrons crawl slower than a snail, but the push travels down the wire at a large fraction of the speed of light." (happy)
  - fact: "In this wire, electrons drift only about 0.2 millimeters per minute." (source: "v = I ÷ (n·A·e): 13.8 mA, n = 8.47 × 10²⁸ m⁻³ for copper, 0.64 mm wire gives ≈ 3.1 µm/s")

**Glossary (exact).**
- The `simple` definition is shown first, and the `precise` one under "More precisely".
- Aliases are auto-linked too.
- *explicit* terms are linked only through `[[ ]]` markup.
- `[[=text]]` shows text that is never auto-linked, for example "Georg [[=Ohm]]".

| Term | Title | Simple | More precisely | Aliases |
|---|---|---|---|---|
| electricity | Electricity | Energy carried by moving electric charges, like electrons flowing through a wire. | Everything to do with electric charge: charges at rest make electric fields, and moving charges are an electric current. | |
| charge | Electric charge | A property of tiny particles that makes them push or pull on each other. Electrons are negative, protons positive. | Measured in coulombs. Like charges repel, and opposite charges attract. | electric charge |
| electron | Electron | A tiny particle with a negative charge. Moving electrons carry electricity through metal. | A fundamental particle with a charge of −1.602 × 10⁻¹⁹ coulombs and a mass of 9.109 × 10⁻³¹ kg. | |
| atom | Atom | The tiny building block of everything. Each atom has a nucleus surrounded by electrons. | The smallest unit of an element, about 10⁻¹⁰ m across. Its nucleus is tens of thousands of times narrower. | |
| nucleus | Nucleus | The tiny, heavy center of an atom, made of protons and neutrons. | It holds over 99.9% of the atom's mass in a space tens of thousands of times narrower than the atom. | |
| proton | Proton | A particle in the nucleus with a positive charge. | Charge +1.602 × 10⁻¹⁹ C and mass 1.673 × 10⁻²⁷ kg, about 1,836 times an electron's. The number of protons decides the element. | |
| neutron | Neutron | A particle in the nucleus with no charge. | Mass 1.675 × 10⁻²⁷ kg, slightly more than a proton. Atoms of one element can have different numbers of neutrons. | |
| element | Element | A basic substance made of only one kind of atom, like oxygen, iron or silicon. | Each element is set by the number of protons in its atoms' nuclei: silicon has 14. | chemical element |
| coulomb | Coulomb (C) | The unit of electric charge: the charge of about 6.24 billion billion electrons. | The standard unit of charge: the charge carried past a point by one amp in one second. | |
| joule | Joule (J) | The unit of energy. Lifting an apple 1 meter takes about 1 joule. | The standard unit of energy: a force of one newton (about an apple's weight) acting over one meter. | |
| silicon | Silicon | A chemical element found in sand and rocks. Computer chips are made from it. | Element 14. Pure silicon crystals, where each atom bonds to 4 neighbors, are semiconductors. | |
| silica | Silica | A hard mineral made of silicon and oxygen. Most sand is silica. | Silicon dioxide, SiO₂: each silicon atom bonds to 4 oxygen atoms, and each oxygen to 2 silicon atoms. Quartz is its most common form. | |
| crystal lattice | Crystal lattice | A neat, repeating 3D pattern of atoms, like oranges stacked in a shop. | Copper's pattern is a cube with an atom at each corner and in the middle of each face. Neighbors are 0.256 nanometers apart. | lattice |
| internet | Internet | A worldwide network of networks that lets computers send each other data. | Billions of devices on millions of networks, linked so that data, split into small packets, can travel between any two of them. | |
| undersea cable | Undersea cable | A cable on the ocean floor that carries internet data between continents as flashes of light. | Glass fibers inside carry about 99% of the data between continents. In deep water the cable is often thinner than a garden hose. | |
| circuit | Circuit | A complete loop that electricity can flow around. | A closed path through conductors and parts, so current can flow from a source and back to it. | |
| conductor | Conductor | A material that lets electricity flow easily, like copper. | A material with many free charges that can move, so its resistance is very low. | |
| insulator | Insulator | A material that blocks electricity, like plastic or rubber. | A material with almost no free charges, so its resistance is enormous. | |
| current | Current | How much electricity flows past a point each second. Measured in amps. | The rate of flow of electric charge: 1 amp = 1 coulomb per second. Drawn flowing from + to −. | |
| conventional current | Conventional current | The direction we draw current: from + to −. In wires, electrons actually move the other way! | The rule was chosen before electrons were discovered in 1897. Electrons are negative, so in metals they drift from − to +. | |
| voltage | Voltage | The push that makes current flow. Measured in volts. | The difference in electric potential energy per unit of charge between two points: 1 volt = 1 joule per coulomb. | |
| resistance | Resistance | How hard it is for current to get through something. Measured in ohms. | The ratio of voltage to current for a part: R = V ÷ I. | |
| amp | Amp (A) | The unit of current. One amp is a lot for small electronics. | The ampere, the standard unit of current: one coulomb of charge passing each second. | ampere |
| milliamp | Milliamp (mA) | One thousandth of an amp. A small LED likes about 20 mA. | 1 mA = 0.001 A. | mA |
| volt | Volt (V) | The unit of voltage. A AA battery gives about 1.5 volts. | The standard unit of voltage: one joule of energy per coulomb of charge. | |
| ohm | Ohm (Ω) | The unit of resistance. More ohms means less current gets through. | The standard unit of resistance: one volt per amp. | |
| ohms law | Ohm's law | Current equals voltage divided by resistance: I = V ÷ R. | For a resistor, V = I × R at any current. Many parts, like LEDs, don't follow it: their current rises much faster than their voltage. | Ohm's law |
| led | LED | A light-emitting diode: a tiny light that only lets current flow one way. | A semiconductor diode that gives off light when current flows forward through it. The material it's made of sets its color. | light-emitting diode |
| diode | Diode | A part that lets current flow only one way. | A semiconductor part with two leads that conducts easily one way (forward) and blocks the other way (reverse), up to a limit. | |
| semiconductor | Semiconductor | A material, like silicon, that can be made to conduct electricity or not. | Its ability to conduct is between a conductor's and an insulator's, and can be controlled by adding tiny amounts of other elements, by light, or by voltage. | |
| resistor | Resistor | A part that limits current, like a narrow section of pipe. | A part made to have a specific resistance, so V = I × R across it. Its power rating limits how much heat it can safely make. | |
| carbon film | Carbon film | A resistor made from a thin layer of carbon on a tiny ceramic tube. | A spiral groove cut into the carbon layer sets the resistance. | |
| tolerance | Tolerance | How far a part's real value may be from its label. A 220 Ω, ±5% resistor is between 209 and 231 Ω. | The allowed difference from the value printed on the part, given as a percentage. | |
| battery | Battery | A store of energy with a + side and a − side. It pushes current around a loop. | Cells that turn chemical energy into electrical energy. Real batteries have internal resistance, so their voltage dips as current rises. | |
| internal resistance | Internal resistance | Resistance inside the battery itself. It makes the voltage drop a little when current flows. | Terminal voltage = open-circuit voltage − current × internal resistance. Here that's 5.0 V − I × 1 Ω. | |
| switch | Switch | A part that opens or closes a gap in the loop. | A part that connects (closed) or disconnects (open) a path. This one is SPST: single-pole, single-throw. | |
| bit | Bit | A single 1 or 0, the smallest piece of information. | A binary digit: the basic unit of information, with exactly two possible values. | *explicit* |
| series | Series | Parts connected one after another, so current must pass through all of them. | Parts in series carry the same current, and their voltages add up. | |
| parallel | Parallel | Parts connected side by side, so current can take either path. | Parts in parallel share the same voltage, and their currents add up. | |
| short circuit | Short circuit | An accidental shortcut that lets current skip the parts. It can overheat wires and batteries. | A very low-resistance path between points at different voltages, which lets a large current flow. | |
| fuse | Fuse | A thin wire that melts to cut off the current when it gets too high. | A safety part that opens the circuit when the current stays above its rating for long enough. | |
| ammeter | Current meter | A meter that measures current. It must be placed in the loop, in series. | An instrument with very low resistance (here 0.1 Ω), connected in series so all the current passes through it. | current meter |
| voltmeter | Voltage meter | A meter that measures the push between two points. | An instrument with very high input resistance (here 10 MΩ), connected in parallel so it barely disturbs the circuit. | voltage meter |
| burden | Burden | A current meter's own small resistance, which slightly reduces the current it measures. | The resistance an ammeter adds to the circuit. Here it's 0.1 Ω. | |
| input resistance | Input resistance | The resistance between a meter's probes. The higher it is, the less the meter affects the circuit. | For this voltage meter, 10 MΩ: at 5 V it draws only 0.5 microamps (millionths of an amp). | |
| power | Power | How fast energy is used or turned into heat. Watts = volts × amps. | The rate of energy transfer: P = V × I. In a resistor, P = I² × R = V² ÷ R. | |
| watt | Watt (W) | The unit of power. One watt is one volt pushing one amp. | The standard unit of power: one joule per second. | |
| datasheet | Datasheet | A part's official fact sheet: its values, limits and how to use it safely. | The maker's specification: typical values, guaranteed ranges, and absolute maximum ratings that must never be exceeded. | |
| forward voltage | Forward voltage | The voltage an LED needs across it before current flows through it. | The voltage across a diode at a stated forward current, such as 2.0 V at 20 mA. It rises only slowly as current rises. | |
| absolute maximum | Absolute maximum | A limit you must never go past, or the part can be damaged. | A limit beyond which permanent damage may happen. Parts aren't guaranteed to work properly near it. | |
| standard values | Standard values | Resistors come in standard steps, like 100, 150, 220, 330 and 470 ohms. | The E12 values: 12 steps per factor of ten (10, 12, 15, 18, 22, 27, 33, 39, 47, 56, 68, 82), designed for ±10% parts. | E12 |
| wavelength | Wavelength | The size of a light wave, which sets its color. Red light is about 625 nanometers (billionths of a meter). | The distance between wave peaks. Visible light runs from about 380 nm (violet) to 750 nm (red). | |
| polarity | Polarity | Which side is + and which is −. Some parts only work one way round. | LEDs and other diodes conduct forward only when the anode is higher in voltage than the cathode, by about their forward voltage. | |
| anode | Anode | The + side of an LED, where current goes in. | The lead where conventional current enters. On an LED it's usually the longer leg. | |
| cathode | Cathode | The − side of an LED, where current comes out. | The lead where conventional current leaves. On an LED it's marked by a flat edge on the rim. | |

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
  - `test_nine_ch1_levels_in_order`
  - `test_ids_unique`
  - `test_every_solution_passes`:
    - goals use a ctx from `simulate(solution)`
    - `zoom_layer` is `"wire.copper"` for zoom levels and `"editor"` otherwise
    - `ui_flags` and `zoom_seen` contain every flag and layer the level's steps mention
    - `LevelTests.run` passes, and every step's check passes too
  - `test_every_level_has_valid_steps` (2–5 steps; every check is a known goal kind and only references parts, labels, flags or layers that exist)
  - `test_no_build_level_passes_at_start`
  - `test_solutions_use_only_start_and_tray_parts` (respects counts)
  - `test_glossary_terms_exist` (scans the intro, outro, hint and fact text)
  - `test_hint_highlights_exist`
  - `test_copy_limits` (≤ 2 sentences and ≤ 30 words per line)
  - `test_chapters_list_13_and_ch1_playable`
  - `test_l2_star_only_with_150` (simulate the solution with each tray resistor: 47 burns; 100 fails `max_ma` 20 at ≈ 29.1 mA; 150 passes and earns the star at ≈ 19.9 mA; 220, 330 and 1000 pass without the star)
  - `test_l8_quarter_watt_burns_one_watt_passes`
  - `test_every_fact_has_source`
  - In `test_glossary_text.gd`:
    - `test_render_explicit_markup`
    - `test_render_no_link_escape` (`"Georg [[=Ohm]]"` links nothing)
    - `test_render_autolinks_first_occurrence_only`
    - `test_render_plural_and_possessive` ("resistors", "battery's")
    - `test_render_longest_match_first` ("forward voltage")
    - `test_render_alias` ("current meter" → `ammeter`, "mA" → `milliamp`)
    - `test_render_explicit_only_not_autolinked` ("a bit dim" stays plain)
    - `test_render_new_terms_excludes_seen`
  - `test_glossary_definition_lengths` (simple ≤ 30 words, precise ≤ 40)
  - `test_jargon_list_in_glossary`: each of these resolves through `GlossaryText.render` to a glossary term: electricity, charge, electron, atom, nucleus, proton, neutron, element, coulomb, joule, silicon, silica, crystal lattice, internet, undersea cable, circuit, conductor, insulator, current, conventional current, voltage, resistance, amp, milliamp, mA, volt, ohm, Ohm's law, LED, diode, semiconductor, resistor, carbon film, tolerance, battery, internal resistance, switch, series, parallel, short circuit, fuse, current meter, voltage meter, burden, input resistance, power, watt, datasheet, forward voltage, absolute maximum, standard values, wavelength, polarity, anode, cathode
- [ ] **Step 2: Run `tools/test.sh content/` and `tools/test.sh glossary_text`.** Expected: FAIL.
- [ ] **Step 3: Implement the nine level files, the glossary, the chapters and the registry.**
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

### Task 14: Schematic art, values and explanations (pure)

**Files:**
- Create: `game/src/editor/{draw_kit,resistor_bands,visual_state,explain,part_art,wire_art}.gd`, `game/src/editor/art_gallery.tscn`, `game/src/editor/art_gallery.gd`, `game/tests/editor/{test_resistor_bands,test_visual_state,test_explain,test_part_art,test_wire_art}.gd`

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
  - `PartArt.ops(p: Part, vis: Dictionary, selected: bool, highlighted: bool) -> Array[Dictionary]`: the Schematic view's real circuit symbols. The real-looking 3D view is Task 14c.
    - Ops are in **part-local** grid units (before rotation).
    - Op types:
      - `rrect{rect, radius, fill, stroke, stroke_w}`
      - `circle{c, r, fill, stroke, stroke_w}`
      - `capsule{a, b, r, fill}`
      - `poly{points, fill, stroke, stroke_w}`
      - `polyline{points, color, width}`
      - `glow{c, r, color}`
      - `text{at, text, size, color, bold}` (drawn upright)
  - `WireArt.color_for_volts(v: float, floating: bool, night := false) -> Color` (lerp `signal_low`→`signal_high` by clamp(v/5); floating → `line`)
  - `WireArt.dot_speed(amps: float) -> float` (0 if |I| < 1e-5, otherwise clamp(0.8·log10(|I|/1e-5), 0.3, 4.0) units per second)
  - `WireArt.dots(path: PackedVector2Array, amps: float, t: float) -> PackedVector2Array` (spacing 0.6 units, moving along the path for positive amps and against it for negative)
  - `WireArt.display_amps(amps: float, settings: Dictionary) -> float` (−amps when `electron_flow` is on)
  - `WireArt.pattern_dashes(path: PackedVector2Array, volts: float, enabled: bool) -> Array[PackedVector2Array]` (only when enabled and volts > 2.5: 0.3-unit dashes every 0.6 units; otherwise empty)
  - `VisualState.engineer_labels(c: Circuit, sim: SimResult) -> Array[Dictionary]` (`{at: Vector2, text: String}`): one `"%.2f V"` label per non-floating net at its first pin, offset (0.4, −0.4), and one `"%.1f mA"` label per resistor and LED at the part center, offset (0, 0.9). These are shown by default (`show_values`).
  - `Explain.part(p: Part, sim: SimResult) -> PackedStringArray`: explanation lines with the real numbers. Exact for `compact_loop(220)`:
    - R1: `"Voltage across R1: 3.04 V"`, `"Current = 3.04 V ÷ 220 Ω = 13.8 mA"`, `"Heat = 3.04 V × 13.8 mA = 0.042 W (rated 0.25 W)"`
    - L1: `"Voltage across L1: 1.95 V"`, `"Current: 13.8 mA (recommended up to 20 mA)"`, `"Brightness: 69%"`
    - B1: `"Voltage at the terminals: 5.0 V − 13.8 mA × 1 Ω = 4.99 V"`, `"Power delivered: 4.99 V × 13.8 mA = 0.069 W"`
    - Ammeter: `"Current through M1: {x} mA"`, `"A current meter goes in series, so all the current flows through it."`
    - Voltmeter: `"Voltage between the probes: {v} V"`, `"A voltage meter has 10 MΩ inside, so it barely changes the circuit."`
    - Switch: `"S is closed, so current can flow."` or `"S is open, so the loop is broken."`
    - Burnt: `"{title} burned out: {why}."`, where why is `"more than its 30 mA maximum"`, `"more heat than its {watts} W rating"` or `"its 500 mA fuse blew"`
    - Floating: `"Not connected to the battery yet."`
  - `DrawKit` static drawing helpers (`rrect`, `circle`, `capsule`, `glow`, `text`) taking a `CanvasItem` and `px_per_unit` (the circle segment count is clamp(r·px_per_unit/2, 12, 96)).
- **Visual requirements** (the implementer chooses coordinates; the gallery capture checks them):
  - Real circuit symbols drawn with rounded ink strokes on soft pastel tiles:
    - battery: long and short plates with "+" by the long plate and "5V", on a mint tile; a coral tile and glow when hot
    - resistor: a zigzag polyline with 6 peaks on a butter tile, with the value below ("220 Ω", plus "1 W" when rated 1 W); an arrow across it when adjustable
    - LED: a triangle pointing anode → cathode with a bar at the cathode, filled in its tint, with two small light arrows that glow with brightness
    - switch: two contact dots and a lever line, flat when closed and raised 30° when open, with its label
    - meters: a circle with "A" or "V" (sky for current, lilac for voltage) and the reading below
  - Burnt parts are dimmed with a scorch mark, and pins are metal dots.

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
  - `test_schematic_resistor_is_zigzag_polyline`
  - `test_schematic_led_has_triangle_poly`
  - `test_explain_resistor_led_battery_220` (the exact lines above)
  - `test_explain_floating_and_burnt`
- [ ] **Step 2: Run `tools/test.sh editor/`.** Expected: FAIL.
- [ ] **Step 3: Implement.** The art gallery shows every part kind in each state on a cream board.
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Visual check.** Capture `res://src/editor/art_gallery.tscn`. It passes if each part matches the visual requirements, edges stay crisp at 1× and at 4× zoom (the gallery reads `--zoom=`), and nothing clips.
- [ ] **Step 6: Commit** with `feat: pastel part and wire art`.

### Task 14b: Realistic rendering foundation — assets, studio lighting, materials, quality

**Files:**
- Create: `tools/fetch_assets.mjs`, `game/assets/third_party/manifest.json`, `game/assets/third_party/CREDITS.md`, the downloaded files under `game/assets/third_party/polyhaven/…`, `game/src/render/{quality,studio_environment,materials}.gd`, `game/src/render/materials_gallery.tscn` + `.gd`, `game/tests/render/{test_quality,test_materials,test_manifest}.gd`

**Interfaces:**
- Produces:
  - `tools/fetch_assets.mjs` (Node 22, no dependencies):
    - Reads the manifest.
    - For Poly Haven entries, it resolves each file's URL and md5 from `https://api.polyhaven.com/files/<id>`: 2K resolution; HDRIs as `.hdr`; textures as `diff`, `nor_gl` and `rough` JPGs.
    - It downloads to the listed path and verifies the md5 (Poly Haven) or the pinned `sha256` (any other source).
    - It exits non-zero on any mismatch, and files that already verify are skipped.
  - `manifest.json` entries: `{id, source: "polyhaven"|"nasa", kind: "hdri"|"texture"|"image", files: [{path, url?, md5?, sha256?}], license: "CC0"|"Public domain", credit}`.
    - M1 entries: `studio_small_09` and `kloofendal_48d_partly_cloudy_puresky` (HDRIs); `wood_table_001`, `aerial_beach_01` and `sand_01` (textures).
    - `CREDITS.md` lists each one with its license and a link.
  - `Quality.PRESETS` (exact):

    | preset | sdfgi | ssao | ssil | ssr | glow | dof | shadow_size | msaa_3d |
    |---|---|---|---|---|---|---|---|---|
    | low | no | no | no | no | yes | no | 1024 | 2x |
    | medium | no | no | no | no | yes | yes | 2048 | 2x |
    | high | no | yes | yes | yes | yes | yes | 2048 | 4x |
    | ultra | yes | yes | yes | yes | yes | yes | 4096 | 4x |

  - `Quality.auto(rendering_method: String) -> String`: `forward_plus` → `"high"`, `mobile` → `"medium"`, `gl_compatibility` → `"low"`. `Quality.resolve(setting: String, rendering_method: String) -> String` returns `auto` resolved, or the explicit preset.
  - `StudioEnvironment.build(hdri_path: String, quality: String) -> Environment`:
    - a panorama sky from the HDRI, which also provides the ambient light and reflections
    - `tonemap_mode = TONE_MAPPER_ACES`, exposure 1.0
    - glow with `glow_hdr_threshold = 1.0`, so only emissive parts bloom
    - SSAO, SSIL, SSR and SDFGI as the preset says
  - `StudioEnvironment.camera_attributes(quality: String, focus_distance: float) -> CameraAttributesPractical` (far and near DOF blur when the preset has `dof`).
  - `Materials` static factory (all `StandardMaterial3D`, cached by name and arguments):

    | name | albedo | metallic | roughness | notes |
    |---|---|---|---|---|
    | `plastic_matte(c)` | c | 0.0 | 0.6 | |
    | `plastic_gloss(c)` | c | 0.0 | 0.25 | clearcoat 0.3 |
    | `epoxy_clear(tint)` | tint, alpha 0.35 | 0.0 | 0.05 | transparent; refraction 0.05 where supported; rim 0.2 |
    | `copper()` | `#B87333` | 1.0 | 0.35 | |
    | `tin()` | `#C8CDD2` | 1.0 | 0.4 | leads, pads |
    | `steel()` | `#9EA4AA` | 1.0 | 0.45 | |
    | `fr4()` | `#C9B48A` | 0.0 | 0.7 | perfboard |
    | `resistor_paint(c)` | c | 0.0 | 0.55 | carbon film `#D8C39A`, 1 W metal film `#6E9FCB` |
    | `pvc(c)` | c | 0.0 | 0.45 | wire insulation |
    | `rubber()` | `#2A2A2E` | 0.0 | 0.85 | |
    | `lcd()` | `#9FB3A6` | 0.0 | 0.1 | meter display |
    | `wood_desk()` | `wood_table_001` maps | 0.0 | from map | with normal map |
    | `cutting_mat()` | mint `#BDEBD7` | 0.0 | 0.8 | 1 cm and 1 mm grid lines in a generated texture |

- [ ] **Step 1: Write the failing tests.**
  - `test_quality_auto_per_renderer`
  - `test_quality_resolve_explicit_wins`
  - `test_presets_monotonic` (every effect on in a lower preset is also on in every higher one)
  - `test_materials_pbr_values` (copper metallic 1.0 and roughness 0.35; `epoxy_clear` transparent)
  - `test_manifest_entries_have_license_and_credit`
  - `test_manifest_files_verify` (`FileAccess.get_md5` / `get_sha256` of every listed file matches the manifest)
- [ ] **Step 2: Run `tools/test.sh render/`.** Expected: FAIL.
- [ ] **Step 3: Write the manifest and the fetch script, run `node tools/fetch_assets.mjs`, then implement `Quality`, `StudioEnvironment` and `Materials`.** Expected from the fetch: every file reported as verified.
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Visual check.** Capture `res://src/render/materials_gallery.tscn` (a sphere and a cube of each material, plus a glowing LED die, under `studio_small_09`) with `forward_plus` (lavapipe) at High, and with `gl_compatibility`. It passes if:
  - the metals reflect the studio
  - the plastics look molded, not shiny
  - the epoxy is see-through
  - only the LED die blooms
  - no highlights are blown out
  - Compatibility still looks clean, just flatter
- [ ] **Step 6: Commit** with `feat: realistic rendering foundation with CC0 studio lighting and PBR materials`.

### Task 14c: True-to-size 3D parts, wires and the workbench

**Files:**
- Create: `game/src/workbench/{part_dims,part_models,wire_mesh,meter_rig,workbench_3d}.gd`, `game/src/workbench/workbench_gallery.tscn` + `.gd`, `game/tests/workbench/{test_part_dims,test_wire_mesh,test_part_models,test_workbench}.gd`

**Interfaces:**
- Consumes: Task 3 (catalog, geometry), Task 7 (`SimResult`), Task 14 (`VisualState`, `ResistorBands`, `WireArt.dots`), Task 14b (`Materials`, `StudioEnvironment`, `Quality`).
- Produces:
  - `PartDims`: the Global Constraints dimensions as constants (mm), plus `grid_to_world(p: Vector2) -> Vector3` (x·0.254, 0, y·0.254) and `world_to_grid(v: Vector3) -> Vector2`.
  - `PartModels.build(p: Part) -> Node3D`: a true-to-size model whose lead tips end exactly in the holes at `CircuitGeometry.pin_position`.
    - **resistor:** a body with 4 painted bands from `ResistorBands` (the 4th is gold tolerance) and tinned leads bent down into the holes.
    - **led:** an epoxy dome and cylinder with its flange, a flat on the cathode side, and inside it an emissive die on a reflector cup with anvil and post; two tinned leads.
    - **switch:** a mini toggle with a steel bushing and lever, tilted +15° when closed and −15° when open.
    - **battery:** two header posts with red (`pos`) and black (`neg`) leads running off the board to a 4 × AA holder on the desk, with four AA cells.
    - **ammeter / voltmeter:** two clip leads (red on `a`/`pos`, black on `b`/`neg`) running to a handheld multimeter on the desk. Its LCD shows `VisualState.reading`, and its dial points at mA or V.
  - `PartModels.apply_state(node: Node3D, vis: Dictionary) -> void`:
    - **LED:** die emission and an `OmniLight3D` (range 3 cm, energy proportional to brightness, colored by wavelength: red `#FF2A1A`, yellow `#FFC21A`, green `#9CFF3A`, blue `#2A6BFF`).
    - **Burnt:** darkened epoxy or body, plus `GPUParticles3D` smoke for 3 s.
    - **Overheated resistor:** a scorched body color.
    - **Hot battery:** a red emissive tint on the holder.
    - **Blown meter fuse:** the LCD shows "FUSE".
  - `WireMesh.points(path: PackedVector2Array, lift_mm := 1.2) -> PackedVector3Array` (pure): a vertical drop into each end hole, then the path `lift_mm` above the board, with rounded corners of radius 1.5 mm and at least 6 segments per 90°.
  - `WireMesh.tube(points: PackedVector3Array, radius_mm := 0.7, sides := 12) -> ArrayMesh`.
  - `WireMesh.color_for(c: Circuit, w: Wire, index: int) -> Color`:
    - red `#D2342B` when either end is on a battery `pos` net, black `#1E1E22` when on a `neg` net
    - otherwise cycling yellow `#E8C547`, green `#4FA36B`, blue `#3D7CC9`, white `#EDEDED`, orange `#E8833A`
  - `MeterRig.place(c: Circuit) -> Dictionary` maps each meter and battery part id to a desk position beside the board: batteries on the left, meters on the right, spaced so nothing overlaps.
  - `class_name Workbench3D extends Node3D`:
    - **The scene:**
      - a desk (`wood_desk`), with a 30 × 20 cm cutting mat (`cutting_mat`)
      - a perfboard (`fr4`) sized to the circuit bounds plus 4 holes of margin, with a pad `MultiMesh` at every grid point
      - the parts, wires and off-board rigs
      - a current overlay: emissive dots along the wire centerlines, using `WireArt.dots` spacing and speed, hidden when `show_current` is off
      - a `Camera3D` (FOV 30°, pitched 25° from vertical), and a `WorldEnvironment` from `StudioEnvironment.build(studio_small_09, quality)`
    - `set_state(c: Circuit, sim: SimResult, settings: Dictionary, ghosts: Dictionary, highlights: Array)`
    - `apply_view(center: Vector2, view: float)` (the camera frames `view` grid units of board height)
    - `screen_to_grid(screen_pos: Vector2) -> Vector2` (the ray meets the plane y = 0) and `grid_to_screen(p: Vector2) -> Vector2`
    - Value labels are `Label3D` billboards when `show_values` is on.

- [ ] **Step 1: Write the failing tests.**
  - `test_grid_world_round_trip`
  - `test_resistor_body_dims` (the body AABB is 6.3 × 2.4 × 2.4 mm within 0.05; the 1 W body is 11.0 × 4.5 × 4.5)
  - `test_led_dims` (dome Ø5.0, flange Ø5.8, height 8.6, within 0.05)
  - `test_leads_end_at_pin_holes` (for every kind and every rotation, each lead tip's grid position equals `pin_position` within 0.01)
  - `test_wire_points_drop_into_holes_and_round_corners`
  - `test_wire_colors_red_black_by_battery_net`
  - `test_meter_rig_places_off_board_without_overlap`
  - `test_screen_to_grid_round_trip` (scene test, headless: camera math works without rendering)
- [ ] **Step 2: Run `tools/test.sh workbench/`.** Expected: FAIL.
- [ ] **Step 3: Implement.** Build `workbench_gallery.tscn`: every part unlit, lit and burnt, plus the L1 solution with live current.
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Visual check.** Capture the gallery at 1280×720 with `forward_plus` (High) and with `gl_compatibility`. It passes if:
  - the parts read as real components at true size
  - the resistor bands are readable when zoomed in
  - the LED's light falls on the board around it
  - wires sit just above the board with rounded bends
  - the multimeter's display is readable
  - nothing floats or intersects
  - Compatibility stays clean
- [ ] **Step 6: Commit** with `feat: true-to-size 3D parts, wires and the real-looking workbench`.

### Task 15: Editor — hit testing, controller and editor layer

**Files:**
- Create: `game/src/editor/{hit_test,editor_controller,circuit_view,flow_view,editor_layer}.gd`, `game/src/editor/editor_layer.tscn`, `game/src/editor/editor_preview.tscn` + `editor_preview.gd` (dev only: reads `--level=<id>` and `--solution`, shows that circuit with live sim), `game/tests/editor/{test_hit_test,test_editor_controller,test_editor_layer}.gd`

**Interfaces:**
- Consumes: Tasks 3, 4, 7, 8 (`SolutionDiff`), 12, 13, 14, 14b, 14c.
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
      - Effects: `commit{circuit}`, `menu{part?, wire?, at}`, `value{part}`, `datasheet{part}`, `selected{id}`, `camera_zoom{factor, at}`, `camera_pan{delta}`, `toast{text}`
  - Controller rules:
    - **Tap**
      - Tap on a pin: either selects it (`pin_selected`) or, if a pin is already selected, wires the two pins.
      - Tap on a switch: toggles `closed` and commits.
      - Tap on an adjustable resistor: emits `value`.
      - Tap on a burnt part: emits `menu`.
      - Tap on any other part: selects it and emits `datasheet{part}`.
      - Tap on a wire: selects it and emits `selected{id}`.
      - Tap on empty space while placing: adds the tray part at the rounded position (tray index and props from the tray item, a new id from `next_id`) and commits.
    - **Drag**
      - Starting on a pin: enters `wiring`. The snap is the nearest other pin within `1.5·pin_r`. On release over a valid snap the wire is committed; otherwise it emits `toast "Drop the wire on a metal dot."`, or `"Those are already connected."` for a duplicate.
      - Starting on an unlocked part: `moving`, snapped to the grid on release.
      - Starting on a locked part or empty space: `panning`.
    - `drag_cancel` → back to `idle` with no commit.
    - `long_press` or `secondary_tap` on a part or wire → `menu`.
    - `zoom` and `pan` → camera effects.
    - Keys: `rotate`, `delete`, `cancel`.
  - `class_name EditorLayer extends ZoomLayer` (scene `editor_layer.tscn`):
    - Its SubViewport holds two views of the same circuit, and `settings.view_style` picks which one renders: `Workbench3D` (Task 14c, the default real-looking view) or `Schematic2D` (a Node2D world with `Camera2D`, `CircuitView` and `FlowView`).
    - One `PointerInput` feeds one `EditorController`. Screen-to-grid conversion goes through the active view (`Workbench3D.screen_to_grid` or the `Camera2D` transform).
    - `signal commit_requested(c: Circuit)`, `signal menu_requested(target: Dictionary, screen_pos: Vector2)`, `signal value_requested(part_id: String)`, `signal datasheet_requested(part_id: String)`, `signal selected(id: String)`, `signal toast_requested(text: String)`, `signal ghost_tapped(kind: String, data: Dictionary)`
    - `set_state(c: Circuit, sim: SimResult, settings: Dictionary, ghosts: Dictionary, highlights: Array)`
    - `set_tray(tray: Array, used: Array[int])`, `begin_placing(i: int)`
    - `fit_view() -> float` (circuit bounds plus 3 units of margin; the result is at least 12)
    - `pin_screen_pos(part_id, pin) -> Vector2` (for tests)
    - `apply_view` forwards to the active view. Schematic: `Camera2D.position = center*32` and `zoom = size.y/(view*32)`. Workbench: `Workbench3D.apply_view(center, view)`.
    - `dynamic_child` returns null in this task (Task 19 adds it)
    - The pin radius in grid units is max(0.35, 22/px_per_unit). `FlowView` animates dots each frame when any |I| ≥ 1e-5, unless `reduced_motion` is on (then it draws static arrows).
    - Dot directions use `WireArt.display_amps`.
    - `CircuitView` (the Schematic view) takes every color from `Palette.color(name, settings.night)`. It draws `VisualState.engineer_labels` when `show_values` is on (the default), and `WireArt.pattern_dashes` when `patterns` is on. The workbench shows the same values as floating labels.
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
    - `test_tap_plain_part_opens_datasheet`
    - `test_tap_wire_emits_selected`
    - `test_long_press_opens_menu`
    - `test_drag_cancel_while_wiring_commits_nothing`
    - `test_rotate_and_delete_keys_on_selection`
  - Editor layer (scene test), once per view (`physical` and `schematic`): load L1, push mouse press/motion/release events at `pin_screen_pos` for the three solution wires, and assert three `commit_requested` emissions whose last circuit lights L1 (via `Simulator`).
- [ ] **Step 2: Run `tools/test.sh editor/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Visual check.** Capture `res://src/editor/editor_preview.tscn -- --level=ch1.light-it-up --solution`, once as is (the real-looking workbench, with `forward_plus`) and once with `--schematic`. It passes if:
  - wires are tinted by voltage
  - sparks sit on the wires
  - the LED glows
  - the grid dots are subtle
  - the value labels don't overlap the parts
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
    - Fields: `progress: Progress`, `level: LevelDef`, `history: CircuitHistory`, `outcome: SimOutcome`, `session: LevelSession`, `zoom_layer := "editor"`, `zoom_seen: Dictionary`, `ui_flags: Dictionary`, `preview_circuit: Circuit`, `events: Array[Dictionary]`
    - `start_level(l: LevelDef)` (uses a valid draft if present, otherwise copies the start circuit)
    - `commit(c: Circuit)` (simulate; store `outcome.circuit` in history; update the session; save the draft; add `stats.parts_burnt`; queue `{type:"burnt", part, reason}` events)
    - `preview(c)` (simulate without touching history)
    - `undo() -> bool`, `redo() -> bool` (re-simulate)
    - `run_tests()`, `next_intro()`, `use_hint()`
    - `set_zoom_layer(id)` (adds the layer to `zoom_seen`, then re-evaluates goals and steps)
    - `set_ui_flag(flag: String)` (re-evaluates steps)
    - `complete(now: int)` (when the phase is `passed`: `mark_complete` with the star result; queue `{type:"passed"}`)
    - `mark_terms_seen(terms: PackedStringArray, now: int) -> PackedStringArray` (records them in `progress.seen_terms` and returns the new ones)
    - `check_achievements(now: int)`: records `Achievements.newly_earned` and queues `{type:"badge", id}` for each. It runs after `complete`, after any commit that burns something, and after `mark_terms_seen`.
    - `tray_used() -> Array[int]`
    - `take_events() -> Array[Dictionary]`
  - `class_name Game extends Node`:
    - `signal changed`, `signal toast(text: String)`, `signal navigate(screen: String, arg: String)`
    - `var state: GameState`
    - `boot(path := "user://progress.json")`
    - `open_level(id)`, `open_map()`, `open_title()`
    - Actions forwarding to `state` that then emit `changed`: `commit`, `preview`, `undo`, `redo`, `run_tests`, `next_intro`, `use_hint`, `set_zoom_layer`, `set_ui_flag`, `mark_terms_seen`, `set_setting(key, value)`
    - `save_soon()` (a 0.5 s debounce timer) and `save_now()` (also called on `NOTIFICATION_WM_CLOSE_REQUEST` and `NOTIFICATION_APPLICATION_PAUSED`)
  - `Main` owns one `Game`, listens to `navigate`, swaps the screen scene and sets `screen.game = game`.
  - `MapScreen` shows Chapter 1's 9 level buttons on a winding path (✓ completed, ★ star, disabled if locked) and 12 locked chapter cards with their era and blurb.
  - `LevelScreen` holds a `ZoomStage` with an `EditorLayer`, plus `HUD` placeholders (filled in Task 17). It connects the editor signals to `game`.

- [ ] **Step 1: Write the failing tests.**
  - `test_start_level_uses_draft`
  - `test_commit_burn_stores_burnt_circuit_and_event`
  - `test_undo_after_burn_restores_part` (undo leaves L1 unburnt, `outcome` re-simulated, no burnt state in the result)
  - `test_l1_solution_passes_and_unlocks_l2`
  - `test_l2_star_with_150`
  - `test_zoom_goal_passes_on_layer` (L9, `set_zoom_layer("wire.copper")`)
  - `test_ui_flag_ticks_step` (L2: `set_ui_flag("datasheet:L1")` ticks step 1)
  - `test_zoom_seen_keeps_closeup_step` (L9: after `wire.closeup` and then `wire.copper`, both steps are ticked)
  - `test_badge_event_on_first_light`
  - `test_magic_smoke_badge_on_first_burn`
  - `test_terms_seen_saved_in_progress`
  - `test_drafts_saved_per_level`
  - Navigation (scene): `test_map_only_l1_enabled_on_fresh_progress`, `test_map_l2_enabled_after_l1`, `test_open_level_shows_level_screen`
- [ ] **Step 2: Run `tools/test.sh app/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Commit** with `feat: game state, autosave and screen navigation`.

### Task 17: Level HUD — heavy help, tray, goals, tests, hints, menus, guide, glossary, settings

**Files:**
- Create: `game/src/hud/*.gd` (see the file map)
- Modify: `game/src/screens/level_screen.{gd,tscn}`, `game/src/editor/editor_layer.gd` (add `_can_drop_data` and `_drop_data` for tray drags, with data `{tray: int}`; a drop places the part at the rounded grid point under the cursor)
- Test: `game/tests/hud/test_hud.gd`

**Interfaces:**
- Consumes: `Game`, `GameState`, `EditorLayer`, `SolutionDiff`, `Glossary`, `PastelTheme`, `Catalog.datasheet`, `ResistorBands`, `Formulas`, `Explain`, `PartArt`.
- Produces:
  - **Every on-screen string goes through `GlossaryText.render`** (from Task 10): guide lines, steps, hints, goal messages, toasts, datasheet rows, Explain lines, calculator steps, captions and the Notebook. Whatever `new_terms` it returns is passed to `game.mark_terms_seen` and shown as New word cards.
  - HUD nodes (all read from `game.state` on `changed`):
    - **TopBar:** back to the map, level title, undo, redo, calculator, settings.
    - **PartsTray:** shows remaining counts. A tap calls `editor.begin_placing`, a drag uses Godot drag-and-drop onto the `EditorLayer`, and items with 0 left are disabled.
    - **GoalsPanel:** ✓/○ rows plus the first failing message.
    - **TestSheet:** shown only for levels with tests. Lists the cases ✓/✗ with messages.
    - **HintButton:** tier 1 shows text; tier 2 shows text and highlights; tier 3 shows ghosts from `SolutionDiff` (tap a ghost to place it), plus chips for prop changes ("Set Resistor to 500 Ω") and removals ("Delete the highlighted wire").
    - **ContextMenu:** Rotate, Delete, Datasheet, Explain, and Replace (shown only when the part is burnt).
    - **ValuePopover:** `HSlider` 100–2000, step 10. Calls `game.preview` while dragging and `game.commit` on release; shows "{ohms} Ω".
    - **Toasts:** stacked, 2.5 s each. A burn shows "Pop! {title} burned out."
    - **Pip:** drawn with `_draw()`: a round butter-to-peach body, eyes, cheeks, and a mood expression.
    - **GuideBubble:** Pip plus a `RichTextLabel` with BBCode. Shows the intro with Next; after passing, the outro, facts, and buttons "Next level" and "Map".
    - **GlossaryPopup:** opened by `meta_clicked`.
    - **StepsChecklist** (Heavy only): the level's steps, ticked from `session.step_results`. The first unticked step is highlighted.
    - **DatasheetCard:** opened by `datasheet_requested`, by the menu's Datasheet item, or by a tray item's ⓘ button.
      - It shows the `Catalog.datasheet` rows with glossary links, the resistor color code from `ResistorBands`, and a small turntable preview of the real 3D part (`PartModels`) next to its schematic symbol.
      - It sets the flag `"datasheet:<id>"`, or `"datasheet:tray"` when opened from the tray.
    - **FormulaCard** (the calculator, opened from the TopBar):
      - Tabs: LED resistor, Ohm's law, Power. Fields are prefilled from the level (supply 5.0 V; in L2, the LED's 2.0 V at 20 mA).
      - Calculate shows the `Formulas` steps and sets `"formula:<name>"`.
      - In Heavy, when `level.formula` is set, Pip suggests it once with an "Open calculator" button.
    - **ExplainPopover:** tap a value label, or choose Explain in the part menu, to see the `Explain.part` lines.
    - **Pip helping (Heavy):**
      - On a `burnt` event, or when the first failing goal message becomes a mistake message (burnt, short, backwards, over the recommended current), Pip says that message with mood `oops`.
      - After 30 s with no new step ticked, Pip says exactly: "Stuck? Tap the lightbulb and I'll help."
    - **Help levels:**
      - Heavy shows the checklist, Pip's help and the idle offer.
      - Light hides all three.
      - Off also hides the HintButton.
    - **Flags:** the ValuePopover sets `"value:<id>"`, Test sets `"tested"`, and selecting a wire sets `"selected:<id>"`.
    - **SettingsSheet:** Help (Heavy / Light / Off), Look (Real 3D / Schematic), Show values, Show current flow, Graphics quality (Auto / Low / Medium / High / Ultra), and toggles for reduced motion, electron flow, large text, patterns and night. They apply immediately; the theme rebuilds for night and large text.
    - **NewWordCard** (at every help level):
      - A non-blocking card that slides in from the side, with a "New word" tag, the title, the `simple` definition, and the `precise` one under "More precisely".
      - It stays 8 s or until tapped (tapping opens the full GlossaryPopup).
      - At most 2 cards are visible; the rest queue.
      - It is shown only for terms the player has never seen before.
    - **NotebookSheet** (from the TopBar and the map):
      - "Words" tab: every seen term in the order it was learned, with both definitions.
      - "Badges" tab: all 8 badges, earned ones in color and locked ones greyed out with their description.
    - **Badge toasts:** for `{type:"badge"}` events, "Badge earned: {name}" with a small sparkle (no sparkle when `reduced_motion` is on).
    - **ScaleBar:** from `view_changed`, with the jump badge.
    - **BackToBuilding:** a button shown when `zoom_layer != "editor"`.
  - Layout: if width < height (portrait), the tray is a horizontal strip at the bottom and the goals collapse into a top pill; otherwise the tray is a left column and the goals sit top-right. Re-layout runs on `NOTIFICATION_RESIZED`.

- [ ] **Step 1: Write the failing tests.**
  - HUD (scene):
    - `test_tray_tap_then_board_tap_places_part`
    - `test_tray_item_disabled_at_zero`
    - `test_hint_tiers_progress_and_tier3_shows_ghosts`
    - `test_ghost_tap_places_wire`
    - `test_replace_resets_burnt`
    - `test_value_slider_commits_on_release`
    - `test_settings_toggle_persists_in_progress`
    - `test_portrait_layout_moves_tray_to_bottom`
    - `test_checklist_visible_only_on_heavy`
    - `test_datasheet_card_rows_and_flag`
    - `test_formula_card_led_resistor_gives_150_and_sets_flag`
    - `test_pip_explains_burn_on_heavy`
    - `test_idle_offer_after_30s_on_heavy_only`
    - `test_help_off_hides_hint_button`
    - `test_explain_popover_lines`
    - `test_new_word_card_on_first_sight_only` (L1 intro: "electricity" shows a card once; opening L1 again shows none)
    - `test_new_word_cards_shown_with_help_off`
    - `test_notebook_lists_seen_words_in_order`
    - `test_badge_toast_on_first_light`
- [ ] **Step 2: Run `tools/test.sh hud/`.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Visual check.** Capture the level screen for L2 at 1280×720 and at 390×844, with the checklist showing, and once more with the datasheet card and calculator open. It passes if:
  - nothing overlaps
  - the tray placement matches the orientation
  - the text is readable
  - Pip's bubble is pastel and rounded
  - the datasheet and calculator cards fit on the phone-sized screen
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
    - `SphereMesh` with a radius of 6371 units, textured with NASA Blue Marble (day) and Black Marble city lights on the night side, plus a separate cloud shell, specular oceans and an atmosphere rim.
    - Add the three NASA images to the manifest (public domain; sha256 pinned on first fetch).
    - If `eoimages.gsfc.nasa.gov` is still unreachable, ledger a ruling and use `LandTexture` (Natural Earth land on a realistic ocean color) until it opens.
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
  - Coast: the `aerial_beach_01` photo texture for sand and shallows, an ocean shader with moving waves and foam, the `kloofendal_48d_partly_cloudy_puresky` sky, a few houses, a small cable landing building, and the undersea cable running into the sea (drawn glowing and labeled as a visualization).
  - Beach: `sand_01` PBR sand, breaking waves with foam, the player's future workshop shack and shells, under the same sky.
  - Grain: realistic quartz grains (translucent, slightly frosted, rounded by the sea) under studio light, with macro depth of field. Below a view of 5, a pitted micro-surface fades in.
  - Silica: a ball-and-stick model the way chemists render it, under studio light. Si spheres of radius 0.9 in `#F0C8A0` and O spheres of radius 0.6 in `#FF0D0D` (the standard element colors), with thin bond cylinders.
  - Atom: a nucleus of 14 protons and 14 neutrons, surrounded by a soft electron cloud whose density follows silicon's shells (2, 8 and 4 electrons). A "Simple picture" toggle shows the classic shells instead: display radii 50, 100 and 150, with 2, 8 and 4 electrons on tilted rings.
  - Captions (exact), one per layer:
    - globe: "This is Earth. The glowing lines are undersea cables that carry the internet."
    - coast: "Some of those cables come ashore on beaches like this one."
    - beach: "A quiet beach. This is where your journey starts."
    - grain: "One grain of sand."
    - silica: "Sand is mostly silica: silicon and oxygen atoms locked together."
    - atom: "A silicon atom. Everything you'll build starts here."
  - Atom Go-deeper text (exact): "Electrons don't orbit like tiny planets. This cloud shows where they're likely to be. The nucleus is drawn far too big: if this atom were a stadium, its nucleus would be a pea."
  - Title UI: the "Circuit" heading, caption label, scale bar with jump badge, Skip, Settings, and Start/Continue (shown when the zoom finishes or is skipped).
  - Captions go through `GlossaryText.render`. Their new words (for example undersea cable, internet, silica, silicon, atom) appear as small subtitles under the caption with the `simple` definition only. They don't block anything, and they are marked seen. Any user zoom input stops autoplay. With reduced motion, the title shows a slideshow: each layer's home view for 4 s, fading through cream over 0.6 s.

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
  - the Earth looks like a satellite photo with clouds, and Europe faces the camera
  - the cables glow
  - the coast and the beach look photographic
  - the grains look like real quartz
  - the silica network shows tetrahedra
  - the atom's cloud is soft, and the simple picture shows the 2-8-4 shells
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
    - Content: a 3D wire along `dir` with a copper core of radius 30 (`Materials.copper`), PVC insulation of radius 70 (`Materials.pvc`) and a cutaway, lit by `studio_small_09` with macro depth of field. Current arrows move at `WireArt.dot_speed(amps)` scaled ×40, as a teaching overlay.
    - Static link to copper: 8 → 60 (a jump of ≈ ×13,333).
  - `class_name CopperLayer extends ZoomLayer`:
    - id `wire.copper`, 1e-10 meters per unit, min view 15 (clamp)
    - An FCC patch of 6×6×2 cells: copper atoms as spheres of radius 1.28 Å with a polished copper material.
    - 60 butter electrons with random thermal jitter, plus a net drift **opposite** to conventional current. The visual drift speed is clamp(0.5·log10(|I|/1e-5), 0, 3) Å per second.
    - Caption (exact): "Copper atoms sit in a neat grid called a crystal lattice. Electrons zip around them and drift slowly from − to +."
  - `LevelScreen` reports the active layer to `game.set_zoom_layer(id)` on `layer_changed`.

- [ ] **Step 1: Write the failing tests.**
  - `test_dynamic_child_near_wire`
  - `test_dynamic_child_null_away_from_wires`
  - `test_closeup_receives_amps_and_direction`
  - `test_l9_zoom_to_copper_passes` (scene: open L9, repeatedly `zoom_at_screen(1.25, pin-free point on w1)` until the active layer is `wire.copper`; the session phase becomes `passed`)
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
  - `test_play_l2_burn_and_replace`: wire the LED straight to the battery and expect the toast "Pop! LED burned out." along with Pip's explanation. Long-press the LED and choose Replace. Open the LED's datasheet and the calculator (steps 1 and 2 tick). Place the 150 Ω resistor from the tray, wire it, and expect the level to pass with the star.
  - `test_play_l8_power_rating`: place the ¼ W 47 Ω resistor across the battery and watch it burn. Replace it with the 1 W one and expect the level to pass.
  - `test_every_word_defined_on_first_sight`: on fresh progress, play from the title through L1. Every term in every string shown gets a New word card or caption subtitle the first time it appears, and appears in the Notebook afterwards. None is shown twice.
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
