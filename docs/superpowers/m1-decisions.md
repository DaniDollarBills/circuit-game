# Milestone 1 decisions

Every decision taken on the owner's behalf while building Milestone 1 ("First Light"), in the order it was taken, each with what it costs if it turns out wrong. Below them are the review findings left for later. Both lists are copied from the build ledger, which was scratch space and is gone now.

- Plan: [plans/2026-11-26-m1-first-light.md](plans/2026-11-26-m1-first-light.md)
- Design: [specs/2026-11-26-circuit-game-design.md](specs/2026-11-26-circuit-game-design.md)

Each ruling reads: what was decided — why — what it costs if wrong. "Checkpoint" rulings were taken while acting on the four mid-build reviews, and "Final" ones on the whole-branch review.

## Rulings (164)

### Setup

- work in this session's own checkout on branch claude/zealous-goldberg-sqjca5 (not main) instead of a separate git worktree — the cloud container is already an isolated, single-purpose workspace — cost if wrong: none (no shared checkout to collide with).
- execution mode is a blend chosen by the owner — inline execution (executing-plans) plus fresh-reviewer checkpoints after Task 7 (simulator), Task 10 (lessons/content accuracy), Task 15 (editor) and Task 19 (screens), then the final whole-branch review — owner asked for "a blend of fast and careful" — cost if wrong: more review spend than pure inline, less than per-task review.
- owner asked for the game to look as real-life as possible — added Task 14b (CC0 studio lighting, PBR materials, quality presets) and Task 14c (true-to-size 3D parts, wires, workbench), made the real-looking 3D workbench the default view with Schematic as a toggle, and made the title and wire zooms photographic. The pastel palette stays in the UI and backdrops — cost if wrong: more rendering work than the 2D plan; the schematic 2D view still exists as a fallback.
- created the personal cloud environment "circuit-game" (owner-approved) allowing dl.polyhaven.org, api.polyhaven.com and eoimages.gsfc.nasa.gov. Poly Haven works; NASA's host currently resets the connection, so the Earth texture decision is deferred to Task 18 with a Natural Earth fallback — cost if wrong: a less photographic globe until NASA opens.

### Task 1

- the runner self-test waits 3 frames and expects ≥ 2 to have advanced (the plan said 2 and ≥ 2) — when the runner starts from call_deferred, Godot resumes the first frame-wait in the same frame — cost if wrong: none; the probe confirmed `await Callable(...).call()` waits for coroutines.
- the runner registers an OS Logger and fails any test that causes engine or script errors beyond those it declares with allow_errors() — without this, a test that crashes mid-way would print PASS — cost if wrong: a test that triggers an expected engine error must call allow_errors(n).
- tools/test.sh discards the output of the import step and ignores its exit status — the import prints noise, and real problems surface as test load failures — cost if wrong: an import problem shows up one step later, as a FAIL.

### Task 2

- interface fonts are imported without MSDF (the plan said MSDF on) — the capture showed rough, ghosted glyph edges at normal interface sizes, while plain rasterization is crisp — cost if wrong: none for the UI; text placed in the 3D world gets its own MSDF font copy in Task 14c.
- button text always uses the light theme's dark ink, because the pastel fills keep their light values at night; added test_button_text_is_readable_in_both_themes, which failed first at a night contrast of 1.17 — cost if wrong: none.
- tools/capture.sh passes --audio-driver Dummy — this machine has no sound card, and the audio errors buried real ones — cost if wrong: none.

### Task 3

- datasheet rows link the more specific glossary terms that now exist (internal resistance, tolerance, carbon film, wavelength, absolute maximum, polarity, burden, fuse, input resistance), and 1 W resistors are listed as "Metal film" — the plan's datasheet copy predates the expanded glossary and the blue metal-film 1 W model in Task 14c — cost if wrong: none; the values are unchanged.
- resistances of 1 kΩ and up are formatted the engineering way ("1 kΩ", "4.7 kΩ") — that's how real datasheets and resistor kits label them — cost if wrong: none.

### Task 4

- a refused edit (locked part or wire, unknown id) returns the input circuit itself instead of a new copy, and CircuitHistory ignores committing the present instance — otherwise every refused drag or delete would leave an empty undo step — cost if wrong: none; callers never mutate circuits.
- next_id returns the prefix plus one more than the largest number already used, so ids are never reused — ui flags like "selected:<id>" and undo snapshots stay unambiguous — cost if wrong: none.

### Task 6

- Netlist now takes CONNECTOR_G from Devices instead of keeping its own copies of the meter and connector constants — one source of truth for the electrical constants — cost if wrong: none.

### Task 7

- the DC solver's convergence test is SPICE-style, |Δ| ≤ 1 µV + 1e-6·|value|, instead of the plan's absolute 1 nV — the fuzz test (trial 155) found LEDs leading to a dead end whose leakage-held node voltages carry ~1e-7 V of rounding noise between iterations, so 1 nV could never be met. Regression test test_dead_end_leds_converge went RED→GREEN, and the suite is 46/46 for sim — cost if wrong: answers are accurate to about 1 µV instead of 1 nV, far below anything a meter shows.
- test_voltmeter_reads_resistor_drop expects 4.98902 V (the plan said ≈ 4.990) and the ammeter is also checked at 9.97854 mA — the 0.1 Ω ammeter burden is now part of the model, so the true readings shift slightly — cost if wrong: none; the plan's tolerance would also pass.
- SimResult also carries component_of_net (needed to decide whether a voltmeter is readable), and part_amps includes closed switches (taken from their connector currents) — the HUD and Explain need a current for every part — cost if wrong: none.

### Task 8

- the `uses` message puts the part's title mid-sentence with the right article ("Add an LED from the tray.", "Add a switch from the tray.") — the plan's literal "Add a {title}" would print "Add a LED" and "Add a Switch" — cost if wrong: none; same words otherwise.
- a passing `uses` goal says "" (the plan gives no pass copy), matching `all` — the GoalsPanel shows ✓ rows and only the first failing message — cost if wrong: T17 adds a pass line.
- LevelTests.run passes a level that has no tests (vacuous truth) — Task 10's test_every_solution_passes runs LevelTests on every level, and Task 9's session already passes tests-free levels on goals alone — cost if wrong: none.
- SolutionDiff keeps the brief's (current, solution) signature; `remove_wires` lists every player wire the solution doesn't have, and `props` compares every solution prop except a switch's `closed` (flipping switches is testing, not building) — tier-3 hints show "one way to do it", so stray or bypass wires are worth flagging; covered by test_solution_diff_empty_when_solved_with_switch_closed and test_solution_diff_lists_extra_player_wire_for_removal — cost if wrong: a valid but different wiring gets "remove" ghosts at hint tier 3.
- the calculator refuses impossible inputs with a plain explanation step instead of showing inf/nan (supply not above the LED voltage, zero resistance, zero current), with new copy kept under 30 words; test_formulas_refuse_impossible_inputs — cost if wrong: none.
- `led_lit` treats under 1 nA (Goals.NO_CURRENT_AMPS) as "no current", which separates an open loop (picoamp solver leakage) from a merely dim LED; a goal naming a missing part says "Missing part: <name>", like LevelTests — cost if wrong: a circuit leaking between 1 nA and 0.5 mA reads as "too dim" rather than "open".
- LevelBuilder resolves each solution part's tray index in done(), comparing against the tray item's props filled with catalog defaults — so a ¼ W 47 Ω tray item never matches a 1 W solution resistor, and tray order in the level file doesn't matter — cost if wrong: none.

### Task 9

- Progress defaults to view_style "physical" and adds show_current true and quality "auto" (the brief said "schematic" and had neither) — the Global Constraints, updated when the owner asked for the most real-life look, make the 3D workbench the default view and list both settings; test_defaults_are_real_life_heavy_help asserts them — cost if wrong: one default to flip.
- ProgressStorage.load uses a leftover "<path>.tmp" when the real file is missing — Godot's Windows rename deletes the destination before renaming, so a crash in between would otherwise drop the finished save; test_leftover_tmp_used_when_main_missing — cost if wrong: none; a valid tmp only exists after a completed write.
- a file from an unknown version is backed up like a corrupt one (Review Focus 3: never lost silently), and load reports ok false / recovered true for both; test_unknown_version_file_backed_up — cost if wrong: none.
- Progress.from_dict also rejects out-of-range setting choices (help_level, view_style, quality), drops setting keys this build doesn't know, fills missing keys from defaults, and keeps drafts as raw dictionaries (Task 16 validates a draft when its level opens); test_wrong_types_rejected and test_missing_keys_take_defaults — cost if wrong: a file with a bad setting starts fresh, but is backed up first.
- a level without intro lines starts in "build", and mark_complete keeps the first completion time when a level is replayed (only the star can upgrade) — neither case is covered by the brief — cost if wrong: none.

### Task 10

- accuracy fixes to the plan's exact copy — L1 fact says "The first LED that gave visible light, made in 1962, could only glow red." (infrared LEDs came first, Biard and Pittman at TI in 1961; added to the source); L2 outro says "for LEDs like this one" (high-power LEDs use current drivers, not a resistor); L9 intro says "a 10 cm piece" holds billions of trillions of free electrons (1 cm of 22 AWG copper holds about 2.7 × 10²⁰); the L9 drift source names 22 AWG (0.644 mm), which is what gives ≈ 3.1 µm/s (0.64 mm exactly gives 3.16) — cost if wrong: none; the reviewer at checkpoint B re-checks every fact.
- L3 intro line 1 reads "Voltage is the push and current is the flow. Resistance makes flowing harder." — the plan's three-sentence version breaks its own two-sentence rule (test_copy_limits) — cost if wrong: none.
- glossary precision fixes — carbon film is on a ceramic rod (not a tube), a deep-water undersea cable is "about as thick as" a garden hose (TeleGeography), forward voltage is where "much" current starts to flow, and burden's precise line names the burden voltage — cost if wrong: none; still within the word limits.
- L7 hint 3 ("Delete the highlighted wire.") also highlights w_bad, since its text points at a highlight — cost if wrong: none.
- GlossaryText matches acronyms and unit symbols with their capitals ("LED", "mA") and everything else in any case — fully case-insensitive matching would link the verb "led" and "Ma"; test_render_acronyms_match_case — cost if wrong: an all-lowercase "led" in copy stays unlinked.
- GlossaryText also escapes "[" as [lb] in copy, never auto-links a term the line already links with markup, and exposes plain() and resolve() for the copy and content tests — cost if wrong: none.
- added content/ch1/layout.gd (the compact and wide layouts, the loop wires and the four switch-combination tests), preloaded by the level files, so positions are written once — cost if wrong: none.
- added content tests beyond the brief — test_start_parts_are_locked, test_three_hint_tiers, test_moods_are_known, test_datasheet_terms_exist — cost if wrong: none.

### Checkpoint A

- Task 7 folded the plan's test_current_flow.gd and test_damage.gd into test_simulator.gd (missing from the ledger until the review noticed) — the flows and burns are only observable through simulate(), so one file tests them together — cost if wrong: none; the named tests exist.
- ideal wires stand (a meter bypassed by a wire reads exactly 0, where a real 10–20 mΩ jumper would let it read a few percent) — the plan merges wired pins into one net, and the lesson (never bypass the meter) holds — cost if wrong: a bench comparison shows 0 where reality shows a small reading.
- LED reverse breakdown stays unmodeled — M1 has one 5 V battery and indicator LEDs are rated for about 5 V reverse — cost if wrong: higher-voltage chapters must add it.
- CircuitIO's acceptance of nonsense props is now partly a finding (non-finite numbers are rejected, above); negative or zero ohms stay clamped to a 1 mΩ near-short — a reasonable player only meets them through a hand-edited save, and the result is finite — cost if wrong: such a save shows a short instead of starting clean.
- duplicate part ids stand — CircuitIO already rejects them in saves, and the editor's next_id never reuses one — cost if wrong: a programmatic caller could collide pin keys.
- the dense O(n³) GDScript solve stands for M1 (under 1 ms at M1 sizes once convergence is fixed) — cost if wrong: free-build chapters need the planned sparse or Rust solver.
- battery watts stay terminal power (0 W in a dead short, while 25 W heats the battery inside) — it matches the Explain copy, and the "hot" state comes from shorts — cost if wrong: an Explain card could say "0 W delivered" beside a hot battery; Task 14 can add the internal heat.
- each component keeps its own 0 V reference, and instant burnout with no thermal time stays — both are the spec's and plan's design — cost if wrong: none for M1.

### Task 11

- test_child_parent_inverse checks the round trip to 1e-6, not 1e-9 — Vector2 is single precision in standard Godot builds (7.3 comes back as 7.30000019) — cost if wrong: none; the layer design keeps each layer's coordinates small enough that float32 stays sub-pixel.
- resolve() keeps the dynamic link it hands off through in `links` (marked ZoomLink.dynamic, replacing an older one to the same child), and child_link() ignores kept dynamic links when looking down — otherwise zooming back out of a wire close-up would have no parent link, or would use a stale wire's anchor; test_resolve_remembers_dynamic_link_for_the_way_back — cost if wrong: none.
- added test_pan_moves_center and test_meters_visible, and ScaleFormat.jump keeps one decimal below 10 ("×1.6") — the brief only shows ×830 and ×13,000 — cost if wrong: none.

### Task 12

- ZoomStage re-applies its camera (deferred) after every resize, including the first layout — a camera set before layout used a zero-height layer, and Review Focus 4 needs a resize to keep everything in view; test_resize_reapplies_camera RED→GREEN — cost if wrong: one extra set_camera per resize.
- added test_zoom_at_screen_keeps_point_under_cursor, test_pan_screen_follows_the_drag (dragging the content right moves the camera left) and test_go_home_uses_home_view; go_home centers the layer's origin — cost if wrong: none.

### Task 13

- taps, long presses and drag starts report where the finger went down (a tap that wobbled 6 px still lands on the part it touched; a wire drag starts at the pin pressed) — the brief only says {at} — cost if wrong: none.
- a right-button press that moves past 8 px is dropped (no secondary tap, no drag), and only the left button long-presses — the brief doesn't cover right-button drags — cost if wrong: a right-drag does nothing.
- PointerInput.now() is the one clock for feed() and the _process tick, and a wheel event reporting factor 0 counts as one step — cost if wrong: none.
- added test_pinch_before_drag_gives_no_tap, test_trackpad_gestures, test_third_finger_does_not_end_pinch (RED→GREEN: a stray third finger lifting used to end the pinch) and pointer tests for touch, mouse drag, wheel and trackpad events — cost if wrong: none.

### Task 14

- DrawKit scales world units to pixels itself and the CanvasItem is never scaled — Godot's antialiasing feather and glyph rasterizing are in canvas units, so a scaled canvas blurs edges and text when zoomed in; DrawKit also gains polyline (round joins and caps), poly, draw_ops and turn so the editor can draw a whole part — cost if wrong: the editor redraws on zoom instead of leaning on a Camera2D zoom.
- every PartArt op may carry a "tag" (tile, zigzag, body, lever, reading, value, scorch, pin, selected, highlight, light, adjust…) — the tests and later renderers find shapes by name instead of by position in the list — cost if wrong: none; additive.
- a text op below a part's tile stays below the turned tile at the same gap (values, readings and labels never sit on a sideways symbol); other text turns with the part and is drawn upright — cost if wrong: none.
- a 1 W resistor's value reads "47 Ω · 1 W" in one label, the LED tile is a little taller than its 2×1 footprint to fit the light arrows, and the switch tile is peach (the brief names no switch color) — cost if wrong: cosmetic.
- WireArt places dots and dashes by index, strictly before the wire's end — adding 0.6 ten times gave 5.9999…, which put an 11th dot on the end pin where the next wire's first dot also sits — cost if wrong: none.
- engineer labels follow the plan's rule (one volt label per powered net, including nets held only by leakage) and skip the current label of a floating resistor or LED; checkpoint A's leakage minor stays deferred — cost if wrong: a dangling LED pin can show a leakage-set voltage such as 4.25 V.

### Task 14b

- installed mesa-vulkan-drivers (lavapipe) in this container, as the plan's execution notes list, and Forward+ captures set VK_ICD_FILENAMES to lavapipe — without a Vulkan driver Godot silently fell back to OpenGL, so the "Forward+" capture wasn't one — cost if wrong: none; captures only.
- fetch_assets.mjs has a --pin mode that writes the urls and md5s it resolves from Poly Haven into the manifest; the pinned md5s let test_manifest_files_verify run offline, and a later run reports any file Poly Haven has changed — cost if wrong: none.
- wood_desk and cutting_mat use world-space triplanar mapping (1 unit = 1 cm), so the mat's 1 mm / 1 cm grid (a generated 10 cm tile) and the wood grain are true to size on any mesh; the wood's roughness comes from the rough map's green channel; epoxy refraction is turned on only off Compatibility — cost if wrong: none.
- StudioEnvironment sets glow intensity 0.8 and bloom 0.05, and camera_attributes places DOF relative to the focus distance (far blur from 1.6×, near blur inside 0.5×, amount 0.06); Quality gains current_method() and msaa() helpers — the brief leaves these values open — cost if wrong: cosmetic.
- added test_presets_exact, test_studio_environment_follows_preset, test_camera_attributes_dof_by_preset, test_materials_cached_by_name_and_args and test_textured_materials; CREDITS.md names every artist as Poly Haven's info API lists them — cost if wrong: none.

### Checkpoint B

- I6's chapter-blurb terms (CPU, ALU, RAM, transistor, binary, adders, latches, registers, wafers, routers, neurons) re-graded Minor and deferred — they sit on locked chapter cards a player can't open in M1, so an untappable word misleads no one; they get entries when their chapters are written — cost if wrong: a curious beginner can't tap them on the map.
- the simulator's game rules stand (0.1 Ω meter burden with a 500 mA fuse, instant burnout at the rating, an LED popping rather than wearing out) — spec §6 requires them; Task 17's Go-deeper text should say they are simplified — cost if wrong: a beginner may believe parts fail instantly at their exact rating.
- the adjustable resistor keeps its carbon-film datasheet row — potentiometer tracks are commonly carbon film — cost if wrong: none.
- L8's calculator gives 0.53 W from the ideal 5 V while the outro says the real 0.51 W — Task 17 should show both when they differ and name the battery's 1 Ω internal resistance as the reason — cost if wrong: a beginner sees two numbers with no explanation.
- intro and outro claims stay unsourced (the plan requires sources on facts), Godot's lack of fsync is an engine limit, the chapter eras follow the plan's exact table, and hints during the intro, a stale test report after edits, internal ids in "Missing part" messages and web save persistence are left to Tasks 16, 17 and 21 — cost if wrong: none for M1's content.

### Task 14c

- the LED's leads leave the epoxy 2.54 mm apart (the real lead pitch) and splay out to the catalog's pins two holes apart (5.08 mm), the way LEDs are bent to fit a board — every lead still ends in the hole at its pin (test_leads_end_at_pin_holes) — cost if wrong: none.
- the equipment sits in rows level with the middle of the board, stepping outward (holders left, meters right) instead of stacked front to back — stacked 15 cm multimeters ran off screen and stretched every lead — cost if wrong: none; test_meter_rig_places_off_board_without_overlap still holds.
- rig leads rise out of their posts, cross the board's edge, fly over that side's tallest equipment and drop into their sockets from above, so no lead passes through anything; the holder's terminals sit on top of its +x wall, and multimeter leads plug into mA or V plus COM by meter kind — cost if wrong: leads crossing a crowded board may pass over tall parts.
- the cutting mat is the smallest standard size (A4 30 × 22 up to A1 90 × 60 cm) that holds the board and the equipment, not a fixed 30 × 20 cm — with the brief's mat, multimeters hung off its edge 3 mm above the desk; test_mat_holds_board_and_equipment RED→GREEN — cost if wrong: a bigger mat than the brief pictured.
- depth of field focuses at the camera's distance to its target on every apply_view (a fixed 30 cm focus blurred every close-up), the current dots are 0.45 mm glowing beads riding on top of each wire (bigger ones hid the wires), and value labels float 3 mm up and 3.5 mm forward of their spot so they don't cover their parts — cost if wrong: cosmetic.
- Workbench3D adds part_node(), wire_count(), label_texts() and mat_rect() for tests, and PartModels adds build_holder(), build_multimeter(), apply_holder() (red glow on a shorted battery) and apply_meter() (reading or FUSE), since the off-board rigs aren't part models — cost if wrong: none; additive.

### Task 15

- the Schematic view draws at screen resolution (CircuitView and FlowView take center, px-per-unit and size and redraw on zoom) instead of the brief's Camera2D zoom — a scaled canvas blurs edges and text, which the Task 14 ruling set out to avoid — cost if wrong: one redraw per zoom step.
- gestures reach the controller with both the grid position ("at") and the screen position ("screen"); drag-panning uses screen deltas in pixels, since grid positions shift under a moving camera — cost if wrong: none.
- placing ends after one part; a tap on a part, pin or wire while placing cancels placing and acts as a normal tap; a tray item with none left places nothing; placed parts get kind prefixes (B, R, L, SW, M, V) with next_id — cost if wrong: placing several of one item takes several taps on the tray.
- camera effects go through the parent ZoomStage when there is one (zoom_at_screen, pan_screen); with no stage (preview, tests) the layer moves its own view — cost if wrong: none.
- taps hit the hint's ghosts before the controller sees them — a ghost part by its footprint, a ghost wire within the pin radius — and emit ghost_tapped("part", {part}) or ("wire", {a_part, a_pin, b_part, b_pin}) — cost if wrong: none.
- Schematic value labels move to the first clear spot near their anchor (clear of parts, the text under them, wires and earlier labels) — the plan's fixed offsets put "13.8 mA" on "220 Ω" and "0.00 V" on the battery's "5V"; test_schematic_labels_stay_clear RED→GREEN — cost if wrong: a label can sit a little away from its pin.
- in the workbench, wires keep their real jumper colors (red to +, black to −, then the cycle) and voltages show as labels; tinting by voltage is the Schematic view's job — real jumper wires don't change color, and the owner asked for the most real-life look — cost if wrong: the visual check's "tinted by voltage" applies to the schematic capture only.
- the layer also handles mouse hover (a placing ghost under the cursor) and keys R, Delete/Backspace and Esc while interactive; Workbench3D gains set_preview() for the wiring rubber band and the placing ghost in 3D; EditorLayer adds fit_center() beside fit_view(), and public screen_to_grid(), grid_to_screen() and pin_radius() — cost if wrong: none; additive.

### Task 16

- GameState gets a `now_fn` clock (and public `now()`), because commit, set_zoom_layer, set_ui_flag, run_tests and next_intro call complete() and check_achievements() themselves when the level passes or something burns; complete/mark_terms_seen/check_achievements still take `now` as the brief says — cost if wrong: none for callers; tests inject the clock.
- preview(c) simulates into a separate `preview_outcome` and `shown()` returns what to draw; `outcome` stays the committed simulation so goals, steps, tests and passing never run on a preview (a flag set mid-drag could otherwise pass a level on an uncommitted circuit); any commit/undo/redo/start ends the preview — cost if wrong: Task 17's ValuePopover must draw `shown()`, not `outcome`.
- the `passed` event also carries `star: bool`, and a star reached after the level already passed is still recorded (mark_complete + a `{type:"star"}` event + badge check) — a player who passes L2 with 220 Ω and then tunes to 150 Ω would otherwise never get the star or "Right on Spec" — cost if wrong: one extra event type for Task 17 to toast.
- a saved draft is used only if it parses and still holds every locked part of the level (same id, kind, position, rotation) and every locked wire (same endpoints); otherwise the start circuit is used — protects players from a draft made for an older version of a level — cost if wrong: an in-progress draft is dropped after a level's locked layout changes in an update.
- Game adds copy and guards the brief doesn't spell out: a damaged save toasts "Your saved progress couldn't be read, so a fresh save was started. The old file was kept as a backup." (or without the last sentence when no backup could be made); a failed save toasts "Couldn't save your progress. Check that the disk isn't full." once per failure streak; open_level refuses a locked level with "Finish the level before this one to unlock it." (`ignore_lock` param for dev captures only); leaving a level flushes a pending save; Main shows these app-level toasts until Task 17's HUD toasts exist; Main accepts `--open=map` / `--open=level:<id>` for development and screenshots — cost if wrong: copy edits only.
- Main sets the window's content scale with ScreenScale (factor = max(screen points, shorter side ÷ 720)) instead of the fixed 1280×720 canvas_items base — that base rendered a 390×844 phone window at 0.3×, unreadable, which Task 17's 390×844 visual check and Task 20's resize test could not pass; desktops at 1280×720 and up look exactly as before — cost if wrong: small desktop windows show less of the layout instead of shrinking it.
- fixed two Task 15 EditorLayer framing bugs found by the level-screen capture: fit_center() returned a value cached by fit_view(), so `make(fit_center(), fit_view())` (argument order) framed the wrong spot — it now computes its own bounds; and in the real 3D view the starting frame now includes the battery holders and meters beside the board, widened exactly for the tilted camera's near edge and for equipment height (tests test_fit_center_does_not_depend_on_fit_view_first, test_fit_view_shows_equipment_in_real_view RED→GREEN) — cost if wrong: meter levels open further out, with the small board needing a zoom.

### Checkpoint C

- GPU frame times against 60 fps (declined: lavapipe isn't representative) — Task 21's builds get a frame-time check on the capture machine's CPU renderer only; real-GPU timing is for the owner's hardware — cost if wrong: a low-end device may run below 60 fps at the auto preset.
- web specifics (touchcancel mapping, WASM GDScript speed, WebGL MSAA) (declined: no web export) — the spec ships desktop downloads first; the web build is not in M1's Task 21 scope — cost if wrong: none for M1.
- trackpad pan/magnify deltas on macOS and Windows (declined: no hardware) — PointerInput already maps InputEventPanGesture/MagnifyGesture; tuning waits for owner feedback — cost if wrong: trackpad zoom may feel too fast or slow.
- touch focus routing when mouse_filter flips mid-gesture (declined: engine behavior) — the I2 fix resets the recognizer whenever a layer stops being interactive, which covers Task 19's hand-off whatever Godot does with focus — cost if wrong: a stuck gesture during a layer hand-off, cleared on the next press.
- Task 18/19 consumers, out-of-scope folders, texture bytes, pastel band hues (declined: not written yet / reviewed elsewhere / checksums only / taste) — no action; band hues stay the pastel-tinted IEC colors already approved — cost if wrong: none.
- leakage-held voltage labels (flagged Task 14 ruling 6) — decide in the fix pass alongside I-items, since Task 17 ships labels on by default — cost if wrong: a beginner reads a leakage voltage as meaningful.

### Task 17

- the HUD floats over a full-screen board, and EditorLayer frames the circuit inside `safe_rect` (the area no panel covers); the layer's max_view follows the framing (1.5×) because on a phone the board area is small enough that the needed zoom-out passed the fixed 120 — cost if wrong: players can zoom out further than before.
- New word cards print their definitions as plain text, not through GlossaryText, so a card never spawns more cards (definitions mention other glossary words, which would cascade through the glossary); words in them stay tappable in the GlossaryPopup and Notebook, which do render links — cost if wrong: a word first met inside a card's definition gets its card later, when it appears in other copy.
- at most 2 New word cards in landscape and 1 in portrait (the brief's "at most 2"; two cards would cover a phone's whole board area); cards sit top-left of the board area and toasts at its bottom, above Pip, so the transient pieces don't overlap — cost if wrong: words queue twice as long on phones.
- GameState announces each first-seen term as a `new_word` event and Game gains `term_requested(term)` for tapped links, so every screen shares one path for cards and definitions — cost if wrong: none.
- tapping a value label explains its part through a new EditorLayer signal `explain_requested(part_id)`; labels now carry their part id; a tap counts as a label tap only on empty board in idle mode, so pins and parts under a label keep working — cost if wrong: a label drawn over a part body can't be tapped there.
- Go deeper notes (new GoDeeper) appear on every part's datasheet and in Explain for burnt parts, saying the game pops LEDs at the limit, burns resistors at the rating, gives the meter a 0.1 Ω burden and an instant 500 mA fuse, and holds the battery at 5 V behind 1 Ω (Checkpoint B ruling) — cost if wrong: copy edits only.
- the calculator shows the simulated value for the same resistor when it differs from the ideal by 1–10% (power, and Ohm's-law current), "In your circuit it's 0.51 W: a little less, because the battery's 1 Ω internal resistance uses up part of its voltage." (Checkpoint B ruling) — cost if wrong: no real-vs-ideal note for other formulas or bigger differences.
- Pip's calculator offer comes once, when the step that names that calculator becomes the current step (L2: after the datasheet step), or at the start of building when no step names it; the Stuck offer comes once per stuck stretch (reset when a step ticks), only while building, on Heavy, in levels with hints — cost if wrong: the offers come at slightly different moments.
- hint tier n shows hint n from the level's list (its text, its highlights, and the solution's ghosts when it says show_solution); ghosts and highlights stay until the board matches; chips also cover removing extra parts ("Remove the highlighted part") alongside wires — cost if wrong: none.
- after passing, Pip shows the outro lines, then each fact with its source in small text, then a finish page with "Next level" and "Map"; a `star` event toasts "Star earned: {star text}" — cost if wrong: copy edits only.
- settings and button labels are plain text, not glossary links (UI chrome, not teaching copy; the brief's list of strings that go through GlossaryText doesn't include them) — cost if wrong: words in settings labels aren't tappable.
- the HUD draws its own icons (IconButton + HudIcons) instead of using symbol glyphs, which Nunito's latin subset lacks; the top bar hides the level title under 520 px and the goals pill shows it instead — cost if wrong: none.
- LevelScreen also handles Ctrl/Cmd+Z and Ctrl/Cmd+Shift+Z (or Ctrl+Y) from the spec's controls table, re-frames the circuit when the board resizes or the view style changes, and the map screen gets the Notebook and glossary popup; PastelTheme gains LineEdit styling; Main gets `--skip-intro` and `--show=` dev switches for captures — cost if wrong: none.
- added tests beyond the brief: test_tray_drag_drops_part_on_board and test_tapping_a_value_label_explains_its_part — cost if wrong: none.

### Checkpoint C

- ZoomLayer no longer uses SubViewportContainer stretch (Task 12's brief said stretch = true): the container refuses manual SubViewport sizes while stretching, so the layer keeps its viewport under a holder node and draws it with a TextureRect; it still extends SubViewportContainer and exposes `viewport` — cost if wrong: a future layer that needs GUI input inside its viewport must forward events itself.
- reviewer-flagged rulings answered — Task 12 ruling 1 is superseded by the I7 fix; Task 14/15 ruling 1 by I12; Task 14b ruling 4 by I13 (ruling 2's fetch caveats stay deferred as M13); Task 14c ruling 2 and its visual check by I9 plus Task 16's framing (L3's default view captured at 1920×1080, meters and holder in frame); Task 15 ruling 4 by I8; Task 15 rulings 5 and 7 stay as recorded with M3 and M10 deferred; Task 2's MSDF promise stays deferred as M9 — cost if wrong: none beyond the deferred minors.

### Task 18

- NASA's image hosts (eoimages.gsfc.nasa.gov, assets.science.nasa.gov, svs.gsfc.nasa.gov) still refuse connections, so instead of the brief's flat LandTexture fallback the globe uses Natural Earth II (public-domain, photo-like shaded relief with bathymetry): tools/make_earth.mjs takes the level-2 tiles from the @cesium/engine 9.0.0 npm package (integrity pinned), stitches them with Godot into a 2048 × 1024 equirectangular JPG, and the manifest pins its sha256; LandTexture is built as specified and used only if that file is missing. No Black Marble night lights: the night side is simply dark — cost if wrong: a less photographic Earth than Blue Marble and no city lights until NASA's host opens.
- tools/make_land.mjs decodes the TopoJSON itself (arcs, delta encoding, reversed arcs) instead of running the downloaded topojson-client package, so no third-party code executes; output is the same outer-ring polygons (125 polygons, 75 KB) — cost if wrong: none.
- the manifest gains source "naturalearth" and a "generator" field; fetch_assets.mjs verifies generated files without downloading them, and test_manifest accepts the new source — cost if wrong: none.
- mipmaps are on for the globe, aerial-beach and sand textures (they're seen at many distances in the title); this fixes deferred minor M12 for those three textures only — cost if wrong: a little more VRAM.
- the six title worlds share a TitleLayer base (camera framing `view` units around `center` at a set pitch); min/max views are chosen to match the links (globe 300–40000, coast 20–40000, beach 1.5–30000, grain 0.4–2000, silica 3–60, atom 200–400); the cables are drawn 16 km thick (far thicker than real) so they read from orbit — cost if wrong: none.
- the coast, beach and grains are procedural approximations built around the CC0 photo textures (a multi-scale shader coastline with hedged fields, woods, moor, a town, shallows and foam; a sloping seabed under a waved sea; noise-shaped frosted quartz grains) rather than hand-modeled scenes; captures show a convincing aerial coast and macro sand, the beach is the least photographic — cost if wrong: the beach and grain shots look CG next to a real photograph.
- the silica patch is 3 × 3 × 3 cells, tilted 22° and −34°, with each SiO₄ drawn as a translucent tetrahedron (the mineralogists' convention) so the tetrahedra read; the atom anchor uses the same tilt — cost if wrong: none.
- the director finishes the moment the camera enters the atom layer and settles it at the atom's home view (400), the same camera skip_to_end gives; the atom's 0.5 rate in RATES is kept but unused — cost if wrong: none.
- on the title, new words get one-line subtitles (simple definition) instead of New word cards, the title drains the queued new_word events, and badge events become toasts; Start reads "Continue" once any level is done; Skip and Settings sit top right; the atom's Go deeper text and Simple picture toggle show only in the atom; glow is limited to the globe (screen-wide bloom washed out the ground and studio scenes) — cost if wrong: none.
- fixed Main's toast growing to full height (its label was sized before it had a width), found when the title raised a badge toast — cost if wrong: none.

### Task 19

- dynamic_child searches 0.4 units around the view's center (as the brief says), and zooming in close (view ≤ 12) over a wire also eases the view a quarter of the way onto that wire per step, so zooming with the cursor over a wire anywhere on screen ends up inside it; EditorLayer gains a public zoom_at() for this path — cost if wrong: the view drifts slightly toward a wire under the cursor when zooming in close.
- the wire layers reuse the title's 3D layer base (TitleLayer) with a new `navigable` option, so wheel, pinch and drag drive the shared zoom inside the wire; the close-up frames the copper's top surface rather than the wire's axis, so the camera never ends up inside the core near the jump — cost if wrong: none.
- the copper patch is 10 × 10 × 2 cells instead of 6 × 6 × 2, so the lattice fills the view through the ×13,000 jump instead of showing a small square; home view 40 Å, max 60 Å (the link's child view) — cost if wrong: 400 atoms instead of 144, drawn as one MultiMesh.
- the copper caption is a HUD label over the board, shown while the copper layer is active; the close-up's insulation uses its own copy of the PVC material with culling off, so the cutaway shows the inside of the insulation; LevelScreen.dev_show accepts closeup, jump and copper for captures; test_electrons_drift_against_conventional_current was added to pin the drift direction a still capture can't show (it passed on first run, as the code already existed) — cost if wrong: none.

### Task 20

- the end-to-end tests run Main in a 1280 × 720 window (the headless runner's own window is 64 × 64, where the HUD lays out off-screen) and restore it after; the driver (tests/helpers/e2e.gd) pushes real mouse and touch events, scrolls a control into view before clicking it, and taps New word cards away when they cover a pin, as a player would — cost if wrong: none.
- test_play_l2_burn_and_replace deletes the shorting wire before Replace (the brief's order replaces the LED while it is still wired straight across the battery, which burns the new one at once), and taps the LED's visible dome rather than its legs — cost if wrong: none.
- fixed a Task 15/C1 picking bug the L2 playthrough found: zoomed out, a small LED's 22 px pin radius covered its whole dome, so "Tap the LED to read its datasheet" (L2's first step) selected a leg; over a part's body a pin now needs a tap within 8 px (test_tapping_a_small_led_dome_opens_its_datasheet RED→GREEN) — cost if wrong: starting a wire from a leg that sits under a body needs a more precise press.
- the title gains `shown_subtitles()` and names on its Skip and Start buttons for the tests; test_play_l8_power_rating swaps the burnt ¼ W part for the 1 W one by deleting it and placing the other (the menu's Replace would revive the same ¼ W part) — cost if wrong: none.

### Task 21

- the browser check served build/web with Python's built-in http.server on 127.0.0.1 instead of `npx serve@14.2.6`, because the permission policy refused running a downloaded npm server package; the page needs no special headers (thread support off) — cost if wrong: none for the check.
- the macOS preset needed `textures/vram_compression/import_etc2_astc=true` (Godot refuses universal/arm64 exports without ETC2/ASTC); 2D MSAA is switched off for web builds (`msaa_2d.web=0`, GLES3 can't do it and warned); the presets embed the pck in the Linux and Windows executables, skip Windows resource editing (no rcedit/wine needed) and ad-hoc sign the macOS app; all four platforms were exported here (Linux 80 MB, Windows 90 MB, macOS 113 MB, web 62 MB zipped), the Linux build ran 120 headless frames with exit 0 and no script errors, and the web build rendered the title in Chromium with no console errors — cost if wrong: none.
- fixed four "Godot 3.x SpatialMaterial remapped parameter" warnings from the title code (it set `specular`; Godot 4 calls it `metallic_specular`), and the end-to-end driver now lets New word cards finish sliding in before clearing them (the L8 playthrough failed once in a full run when a sliding card covered its click) — cost if wrong: none.
- tagging v0.1.0 is left to the owner: the tag makes the release job publish a public GitHub release — cost if wrong: none (nothing published until they say so).

### Checkpoint D

- re-graded six Minors to Important by what a player gets: the "Use a switch" label when two are needed (an instruction that contradicts the board), the calculator saying "a little less" when the real answer is more (a false statement in a teaching tool), missing glyphs (the reviewer assumed no web export, but Task 21 ships one, where Ω and ✓ would be empty boxes), touch targets under 44 px (spec §11 sets 44 px), the globe texture's license wording (a public release must state its terms correctly), and words the copper caption and atom text use without defining them (the owner's rule: define every new word) — cost if wrong: a few small fixes the owner didn't ask for.
- L3's trimmer is rated 0.5 W like a real 3386-style part (it had the 0.25 W fixed-resistor default), and "trimmer" and "cermet" join the glossary (its pinned size goes 56 → 58), because the datasheet now names them — cost if wrong: none for play: at its 100 Ω minimum the trimmer makes 0.245 W, under either rating.
- DejaVu Sans and Sans Bold 2.37 (Debian fonts-dejavu-core 2.37-8, unmodified, 1.4 MB, Bitstream Vera license shipped beside them) are Nunito's fallback, instead of a few-kilobyte subset: subsetting needed fontTools, and `pip install fonttools` was refused by the session's permission policy — cost if wrong: about 1.4 MB more per download.
- the tray's ⓘ gets a 44 px hit area in its tile's corner with the icon still drawn 22 px, rather than a separate row under each tile (which would not fit the portrait strip) — cost if wrong: a press near a tile's corner opens the datasheet instead of placing the part.
- the readability fix uses theme types (SoftLabel, FlatButton, PillPanel) instead of fixed colors, re-renders glossary text when Night changes (link colors are baked into it), highlights the current step with a pale lavender tint by day and the board color by night plus a lavender edge (solid lilac failed 7:1 for links), puts the level title on a paper pill, and outlines unearned badges on paper instead of fading them to 60% (which failed 4.5:1) — cost if wrong: a slightly different look from the Task 17 captures.
- the HUD tests' screen helper gained a `themed` option, and the touch and contrast checks use the real theme; the menu test's row press sets the runner window's size and clears its content scale, which Main tests leave set (a test-order effect, not a product bug) — cost if wrong: none.
- the phone layout fix moves the Test button out of the column to sit beside Hint in both orientations (it never scrolls away), lets the column scroll and stop above them, folds goals and steps on landscape screens under 560 px tall, makes every card fit the screen and scroll (CardFit, up to 380 px wide), shows one New word card at a time when the board is under 520 px tall (two ran off a landscape phone's board), lets the settings menus clip instead of growing to their longest item, and lets the title's text block grow up from the bottom edge with its buttons wrapping and the scale bar above it — cost if wrong: a different look from the Task 17 captures, and test results now show in the column apart from their button.
- declined item "GPU cost of six title layers plus the board's" — stands unmeasured: layers that are not on screen stop rendering (UPDATE_DISABLED), so at most two draw at once — cost if wrong: frame drops on weak phones during the title zoom.
- declined item "how photographic the coast, beach and grains look" — stands as judged in Task 18's captures — cost if wrong: the owner may want photo textures there.
- declined item "legal status of Cesium-tiled Natural Earth II" — settled by treating the tiles as Apache-2.0 and shipping the license (above) — cost if wrong: none; it is the cautious reading.
- declined item "web build behavior" — the web export was built and run in Chromium in Task 21 (no console errors, the title rendered), and its missing glyphs are now fixed — cost if wrong: problems specific to other browsers.
- declined item "scrolling versus tray dragging on real touch hardware, and double touch delivery to New word cards" — untestable here; the emulated-touch end-to-end tests pass — cost if wrong: on some phones a drag from the tray may scroll it instead.
- declined item "Forward+ rendering of the new layers" — Tasks 18 and 19 captured them in Forward+ (lavapipe) — cost if wrong: none known.
- declined item "trackpad gestures on the title" — deferred with Checkpoint C's trackpad decline — cost if wrong: a two-finger pinch on a laptop trackpad may not zoom the title.
- declined item "dev switches in release builds" — kept: --open, --show and --layer work only from a command line after `--` and only open screens — cost if wrong: someone could open a locked level from a terminal.
- declined item "silica drawn as idealized cristobalite, not quartz" — stands for M1: the caption ("silicon and oxygen atoms locked together") and the SiO₄ tetrahedra are true of both — cost if wrong: an expert notices that sand's quartz is arranged differently (a label or real α-quartz coordinates can follow).
- declined item "Checkpoint C minors M1–M18" — stay deferred; M15 is noted with this review's performance minor — cost if wrong: as listed with Checkpoint C.

### Final

- re-graded four Minors to Important and fixed them: the trimmer's definition says its rating is for the whole track while the game lets it take ½ W at any setting (now an honest Go deeper note: test_trimmer_go_deeper_explains_its_derating RED→GREEN); the release notes' claims (the web zip only runs from a web server; "burn out when they really would" contradicted the game's own notes) and the README's Pages setup (documentation, checked by reading); and CI running only on main (spec §15 says every push; now every push, with job time limits and download retries; the YAML parses) — cost if wrong: small changes the owner didn't ask for.
- the phone framing switches to the board at one pick radius (22 px), not the reviewer's two (44 px): at 44, even a 1280 × 720 window dropped the meters and holder from view (undoing Checkpoint C's fix), and with the whole circuit in view a 390 px phone tops out near 23 px anyway — cost if wrong: phone players still pinch to pick pins precisely; desktop players see the whole bench.
- the L8 playthrough failed once in three full runs: a tray press could land on a New word card sliding in across the tray, so the test helper now lets cards land first (three clean runs since) — cost if wrong: none for players beyond a quarter-second window in which a tray tap hits a sliding card.
- removed the orphan test_zz_probe.gd.uid committed by mistake in 84d75cf — cost if wrong: none.
- declined item "frame rate on real GPUs" — stands unmeasured: only software renderers here, and hidden layers stop rendering — cost if wrong: frame drops on weak laptops and phones.
- declined item "the web build on real iOS Safari and Android Chrome" — untestable here; the textures are lossless, so the desktop-only texture compression setting strands none of them — cost if wrong: phone-browser problems found by players first.
- declined item "the universal macOS app on Apple Silicon" — no Mac here; the README covers Gatekeeper — cost if wrong: Mac players can't launch it until a signed build exists.
- declined item "Windows SmartScreen and antivirus" — no Windows here; the README covers SmartScreen's Run anyway — cost if wrong: some antivirus may flag the unsigned exe.
- declined item "Node 20 deprecation of the pinned actions/* major versions" — kept as pinned — cost if wrong: CI warnings, then failures, until the majors are bumped.
- declined item "cost of the per-frame HUD layout" — stands: the reviewer measured no layout thrash — cost if wrong: some battery drain on phones.
- declined items already ruled (the Cesium tiles' license, plain words inside New word cards, the coast's procedural look, trackpad gestures, dev switches in release builds, silica drawn as cristobalite, the content re-audit) — stand as ruled — cost if wrong: as in those rulings.

## Deferred minor findings (44)

Reviewers found these; each was graded minor and left for a later pass.

### Checkpoint A

- Damage still acts on a non-converged solve (now only reachable when stepping also fails); gate burning on converged.
- the 10-burn cap leaves further overloaded parts unburnt without a flag (11 LEDs across their own batteries: L11 stays lit at 489 mA).
- burn ties are decided by rounding (two identical LEDs: L2 burns first by 6e-17 A); break ties by part order.
- DcSolution.iterations counts only the last Newton call, not the total across source stepping.
- leakage shows up as readings (open loops ≈ 5e-12 A; a dangling LED cathode reads 4.25 V; a one-lead voltmeter 50 µV) — revisit before Task 14's on-by-default engineer labels print them.
- result maps are incomplete — part_watts has no switches or burnt parts, and CurrentFlow keys wires and switches in one dictionary, so a wire and a switch sharing an id would collide.
- the voltmeter's same-component check can never fail, because the voltmeter itself joins its two nets.
- GMIN inside the LED's gd only regularizes the Jacobian (it cancels out of the converged current); add a comment.
- game-rule notes — burn order compares an LED's current ratio with a resistor's power ratio, and a ¼ W resistor pops at 0.26 W where a real one survives; worth a Go-deeper label or a margin.

### Checkpoint B

- wording — L4 outro "doing exactly this" (transistors do the same job), L8 fact "turns 1,500 watts into heat" (watts are a rate), L5/L6/parallel phrased by layout ("in a row", "side by side"), L9 "Wires look solid, but…", and "spec" in L2's star text is undefined.
- glossary precision — conductor and insulator should say resistivity, atom's "everything" should be ordinary matter, input resistance's rule doesn't hold for current meters, crystal lattice's precise text only describes copper, standard values treats the term as E12 only, and precise texts use undefined words (electric field, potential energy, packets, leads, nanometers, MΩ, binary, metal film).
- linking gaps — "batteries", "nuclei", hyphenated "short-circuit current" and "open-circuit voltage" (link circuit), a curly-apostrophe "Ohm’s law" (links ohm), "circuit breakers" and the verb "switch it on".
- the checklist ticks steps 2–3 of L4 and 2–4 of L5 for wrong boards (the level tests still fail them).
- in L8 the first message after a ¼ W burn is "Aim for 0.4–0.6 W…" rather than the burn, and "Replace it to continue" would burn the same part again.
- "Hold it…" is touch wording; with a mouse the spec uses right-click.
- storage edge cases — an unparseable leftover .tmp with no main file loads defaults and is overwritten without a backup; a failed backup rename leaves the corrupt file for the next save to overwrite; a newer valid .tmp beside an older main file is ignored.

### Task 16

- on phones in portrait, equipment placed beside the board (MeterRig rows) makes the starting view a thin strip; stacking holders/meters above or below the board in portrait would use the screen better.
- ZoomLayer's SubViewport renders at layout resolution, so with a content scale above 1 (Retina, phones) the 3D and schematic are upscaled and soft; consider scaling_3d_scale / a larger SubViewport on hiDPI (Task 21 builds).

### Checkpoint C

- M1 zoom drifts sideways at its clamp limit.
- M2 when zoomed out, the pin radius swallows small bodies; near the top of the 3D view the vertical hit radius is ~17 px, under 22 px.
- M3 ghost wires' hit zones include their end pins, swallowing real pin taps; ghost parts are tested before real parts.
- M4 DRAG_PX 8 is tiny on phones; scale touch slop by screen density.
- M5 a left+right mouse chord shares id 1000 and makes a zero-distance pinch (pans).
- M6 key repeat isn't filtered: holding R spins the part and floods undo.
- M7 no overlap check on place, move or rotate; leads can share a hole without connecting.
- M8 hole fit: switch lugs 2.0×0.5 mm into Ø1.0 mm holes; jumper insulation goes into holes (WIRE_COPPER_D unused); wires share holes with leads.
- M9 Label3D text uses the engine font, not an MSDF Nunito (Task 2 promise); world-sized labels are unreadable zoomed out (fixed_size).
- M10 wire colors follow list position, so deleting a wire recolors the others.
- M11 the ammeter shows |I| (no minus for reversed leads); battery Explain is wrong while charging; multimeter jacks unlabeled.
- M12 texture imports have mipmaps off and lossless compression (~150 MB VRAM, shimmer when minified).
- M13 fetch_assets needs the network even when all files verify, gives a bare "fetch failed" behind a proxy, has no timeout, and checks md5 only.
- M14 fit_center() valid only after fit_view() (fixed in Task 16); go_home centers on the origin, not the circuit.
- M15 set_state rebuilds rigs and wires on every call (3.5–14 ms); schematic grid dots are one draw_rect each (~9 ms in portrait); workbench and flow view keep processing when not live.
- M16 script error if the wiring source part disappears mid-drag (e.g. undo during a drag).
- M17 refusals are silent: a used-up tray item, rotating or deleting a locked part.
- M18 SSAO/SSIL/SDFGI left at meter-scale defaults in a centimeter world; unstroked fills alias in Compatibility.

### Checkpoint D

- a hint pressed during the intro is used up without its words showing (the bulb is visible during the intro).
- dragging the value slider rebuilds the whole bench on every step (about 7.8 ms here), tier-3 hint ghosts rebuild it on every refresh, and hover runs a pick nobody uses (worsens Checkpoint C's deferred M15).
- words and badges met on the map wait until the next level opens, then arrive together.
- no "start over": reopening a solved level loads the solved draft and plays the outro right after the intro.
- warning noise in Compatibility: depth of field on the close-up layer and project-wide 2D MSAA.

### Final

- in portrait the board area is set at layout time, so a column that grows after pressing Test can cover the top of the board (no pin was covered in the reviewer's probes).
- d4eb827's commit message says the datasheet model renders sharp on high-density screens; only its anti-aliasing follows the setting (it renders at layout resolution).
- test_touch_second_finger_cancels_wire never moves the fingers after the cancel; the pinch that follows is covered only at unit level.
