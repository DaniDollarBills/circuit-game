# Milestone 4a "Into Silicon" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chapter 2's first seven lessons, in Chapter 1's course format: sand to silicon, growing a crystal, doping, the diode, the N- and P-channel transistors, and the CMOS NOT gate, on a real transistor model.

**Architecture:**
- **Parts with any number of pins.** Each kind lists which pin pairs conduct (a MOSFET's gate never does), and the solution reports a current for every pin. Two-pin parts keep their one-number current, so Chapter 1 doesn't change.
- **New devices in the Newton solver:**
  - a silicon diode, using the LED's junction code with its own constants;
  - N- and P-channel MOSFETs: the Shichman–Hodges model, fitted to the datasheets' threshold and on-resistance;
  - a bench supply: constant voltage with a 1 A current limit.
- **A new lesson kind, "process", for Lessons 1–2.** An illustrated process (furnace, purifier, crystal puller) runs on a small labeled model, driven by sliders. Its goals are stages reached.
- **Lesson 7's transfer curve.** A sweep steps the input supply from 0 to 5 V, re-solves the circuit at each step and plots the output.
- **Chapter 2 follows Chapter 1 on the map.** Lessons 8–9 (packaging a chip, the Library, the zoom into a chip) are Milestone 4b.

**Tech Stack:** Godot 4.7.2 and GDScript (static types). Tests run headless with `tools/test.sh [filter]`. Screenshots come from `tools/capture.sh` (Xvfb with Mesa).

**Spec:**
- `docs/superpowers/specs/2026-11-27-course-design.md`: §9 (Chapter 2's structure) and §6 (the course format), this milestone.
- `docs/superpowers/specs/2026-11-26-circuit-game-design.md`: §6 (Chapter 2), §10 (what is simulated), §13 (your stuff). Binding wherever the course design is silent.
- `docs/superpowers/research/2026-11-27-chapter2-facts.md`: the facts, with sources. Each value used is checked again against its source when its lesson is written.

## Calls made in this plan (please check)

1. **Chapter 2 is two milestones.** 4a here: Lessons 1–7 and the engine they need. 4b next: packaging your NOT gate as a chip, the Library, and the zoom into a chip (Lessons 8–9). Each ships something playable.
2. **The era banner reads 1947–1963,** from the transistor to CMOS. Czochralski's crystal (1916) and Ohl's PN junction (1940) are history from before it, and say so.
3. **Lesson 4 protects an LED with a diode across it, pointing the other way.**
   - With the 9 V supply reversed, the silicon diode carries the current at about 0.7 V, so the LED never sees more than 0.7 V backwards. Without it, the LED sees 9 V against its 5 V reverse rating.
   - This is a real technique (indicator LEDs on AC). It's chosen over a series diode because two reverse-biased junctions in series share the voltage by their leakage, which this simulator doesn't model honestly.
4. **The transistors' numbers.**
   - **2N7000:** typical values, threshold 2.1 V and 1.8 Ω at V_GS = 4.5 V, giving k = 0.23 A/V².
   - **BS250:** its datasheet gives no 5 V figures. The game uses a typical part within the datasheet's limits: threshold −2.0 V (the range is −1 to −3.5 V), and k = 0.018 A/V², which is 18.5 Ω at −5 V and 6.9 Ω at −10 V (the limit is 14 Ω). Its datasheet card says "this one".
5. **A floating gate** is never silently 0 V. The transistor is treated as off in the solve, it's drawn with a "?", Pip explains why a real one would switch at random, and goals that need it don't pass.
6. **TO-92 legs are bent to 5.08 mm (two holes apart),** as people often do on a breadboard. That keeps every leg tappable on a phone; one hole apart would halve the gap.
7. **The potentiometer waits** for a lesson that needs it. In Lessons 5 and 7, the bench supply's knob sets the input voltage.
8. **Lessons 1–2 are illustrated processes** with real temperatures, purities and sizes. Each is labeled "Illustration" (and "sped up"), since the course design and main design §10 say refining and crystal growth are shown, not simulated. They have no Try it: the process is the hands-on part, so they run Learn → Do it → Recap.
9. **Doped samples come in five kinds:** undoped, and phosphorus or boron at 10¹⁵ or 10¹⁶ atoms per cm³. Their resistances come from ASTM F723 for a 10 mm × 1 mm × 1 mm bar.
10. **The LED gets its 5 V reverse rating,** in the datasheet and on the bench. Chapter 1's 5 V battery reaches it exactly and never passes it, so Chapter 1 is unchanged.

## Global Constraints

- **Chapter 1 is unchanged.** Its parts, values, goals, tests, solutions and numbers stay as they are. `test_every_solution_passes`, `test_no_build_level_passes_at_start` and the recap numbers (13.8 mA and the rest) pass untouched.
- **Text limits.** Every line of main-path text has at most 2 sentences and 30 words (`test_copy_limits`). That covers every card, break, Go deeper line, worked step, poke, why, recap point, question and choice explanation.
- **Words.** Every technical word in new text has a two-layer glossary entry, and the glossary scan reads every new field. Everyday words with a technical meaning are linked only when marked (`EXPLICIT_ONLY`).
- **Sources.** Every history card, and every card or line that states a measured number, a date or a person, carries a citation (`test_fact_sources_are_citations`). Values come from `docs/superpowers/research/2026-11-27-chapter2-facts.md`; anything marked [U] there is checked before use, or left out.
- **Labeled illustrations.** Anything shown rather than simulated (refining, crystal growth, doping, electron motion) is labeled on screen. Moving pictures that run faster than life say "sped up".
- **Diagrams** each draw a still frame when Reduced motion is on.
- **Offline,** with no network use.
- **Screens.**
  - Touch targets are at least 44 px.
  - Large text, Night and Reduced motion apply.
  - Everything works at 360 × 640 and up, in portrait and landscape, and in the Compatibility renderer.
- **Pure logic** touches no scene nodes and is tested headless: the solver, process models, the sweep, goals and readouts.
- **Saves stay `VERSION 1` and circuit `FORMAT 1`.** New kinds and tables are optional, and a v0.3.0 save loads with everything it had.
- **Real companies** appear only in history and sources. Part numbers (2N7000, BS250, 1N4001) are industry part numbers and may appear on screen.
- **Commits** end with this session's attribution lines.

## Review Focus

1. **A floating gate:** a gate wired to nothing, or only through an open switch. It never reads as 0 V. It's shown and explained, and no goal passes by luck.
   - *Test:* Task 4, `test_floating_gate_is_shown_not_zero`; Task 5, `test_floating_gate_fails_its_goals`.
2. **Newton with transistors in feedback.** The inverter at its switching point (input 2.3 V) and a sweep in 0.05 V steps always converge (source stepping as the fallback) and never show NaN.
   - *Test:* Task 4, `test_inverter_converges_across_the_sweep`.
3. **Chapter 1 unchanged, and a v0.3.0 save.**
   - Chapter 1's numbers, labels and tests stay the same.
   - A v0.3.0 save that finished Chapter 1 opens with Chapter 2 unlocked. One that hasn't opens with it locked, and says why.
   - *Test:* Task 11, `test_old_save_meets_chapter_2`, with the existing Chapter 1 suite untouched.
4. **Process lessons on a 360 × 640 phone with Large text and Reduced motion.** Sliders are at least 44 px and reachable, the picture holds a still frame, and "Illustration" shows.
   - *Test:* Task 9, `test_process_fits_small_phone`.
5. **The supply reversed at 12 V, with every Chapter 2 part.** Each part's damage is reported and explained, nothing shows NaN, and the solver stays converged.
   - *Test:* Task 4, `test_reversed_supply_fuzz`.

---

### Task 1: Parts with three pins in the model and the solver's bookkeeping

**Files:**
- Modify:
  - `game/src/circuit/catalog.gd`: a pin entry may carry its own outward direction; `conducting_pairs(kind)` and `is_source(kind)`; entries (pins, size, defaults only) for `nmos`, `pmos`, `diode`, `supply` and `sample`, whose behavior later tasks add.
  - `game/src/circuit/geometry.gd`: `pin_outward` honors a pin's own direction.
  - `game/src/sim/netlist.gd`: devices carry every pin and net; components join only by conducting pairs; the reference net is the `neg` of a component's first source (battery or supply).
  - `game/src/sim/dc_solution.gd`, `dc_solver.gd` (`_fill_outputs`), `sim_result.gd` and `simulator.gd`: `pin_amps`.
  - `game/src/sim/current_flow.gd`: `_pin_injections` from `pin_amps`, all pins.
  - `game/src/editor/visual_state.gd`: `anchored_nets` links by conducting pairs.
- Test: `game/tests/sim/test_netlist.gd`, `test_dc_solver.gd`, `test_current_flow.gd`; `game/tests/circuit/test_geometry.gd`.

**Interfaces:**
- Produces:
  - `Catalog.PARTS[kind]["pins"]` entries are `[name, Vector2i offset]` or `[name, Vector2i offset, Vector2i outward]`.
  - `static func conducting_pairs(kind: String) -> Array`: the pin pairs that can carry DC.
    - battery and supply: `[["pos", "neg"]]`;
    - resistor, switch, ammeter and sample: `[["a", "b"]]`; voltmeter: `[["pos", "neg"]]`;
    - led and diode: `[["anode", "cathode"]]`;
    - nmos and pmos: `[["drain", "source"]]` (never the gate).
  - `static func is_source(kind: String) -> bool`: battery and supply.
  - A Netlist device is `{"part": Part, "kind": String, "pins": PackedStringArray, "nets": PackedInt32Array}`, nets in pin order.
  - `DcSolution.pin_amps` and `SimResult.pin_amps: Dictionary`, keyed `"part:pin"`: the current flowing into the part at that pin. For every part they sum to 0 (within 1e-9 A).
  - `device_amps` and `part_amps` are unchanged for two-pin kinds. For nmos and pmos they hold the current into the drain.
- New kinds' catalog entries (pins at rotation 0, in grid units of 2.54 mm):
  - `nmos`: title "N-channel MOSFET"; pins source (−2, 0), gate (0, 0, outward (0, 1)), drain (2, 0). This is the 2N7000's left-to-right order with its flat face toward you (onsemi NDS7002A/D).
  - `pmos`: title "P-channel MOSFET"; pins in the BS250's order, taken from its datasheet (Vishay 70209 or Diodes BS250P) before this task's commit and ledgered.
  - `diode`: anode (−2, 0), cathode (2, 0).
  - `supply`: pos (0, −2), neg (0, 2), equipment beside the board like the battery; defaults `{"volts": 5.0}`.
  - `sample`: a (−2, 0), b (2, 0); defaults `{"dopant": "none", "per_cm3": 0.0}`.

- [ ] **Step 1: Write the failing tests.**
  - `test_pin_amps_sum_to_zero` (test_dc_solver):
    - For `TestCircuits.compact_loop()`, `meter_loop(500.0)` and a loop with a short, every part's `pin_amps` sum to 0 within 1e-9.
    - `pin_amps["L1:anode"]` equals `part_amps["L1"]`.
  - `test_gate_is_its_own_island` (test_netlist):
    - Circuit: battery, 150 Ω and LED, with an nmos Q1 whose drain is on the LED's cathode and source on the battery's −, and whose gate is wired to nothing.
    - `n.floating.has(n.net_of["Q1:gate"])` is true.
    - The drain and source nets are in the battery's component.
  - `test_center_pin_points_out` (test_geometry): for an nmos at rot 0, `pin_outward(q, "gate") == Vector2i(0, 1)`; at rot 90, `Vector2i(-1, 0)`.
  - `test_gate_wire_carries_nothing` (test_current_flow): with Q1's gate wired to the battery's +, that wire's current is 0.
- [ ] **Step 2: Run** `tools/test.sh test_pin_amps_sum_to_zero` (and each of the others). *Expected:* each fails: no `pin_amps`, no `nmos` kind, or no outward direction.
- [ ] **Step 3: Implement** the interfaces above. At this task, an nmos or pmos has no stamp yet, so it conducts nothing.
- [ ] **Step 4: Run** `tools/test.sh`. *Expected:* all pass. Chapter 1's suite passes untouched; it pins every two-pin number.
- [ ] **Step 5: Commit** `feat: parts with three pins in the model and the solver`.

### Task 2: The silicon diode (1N4001)

**Files:**
- Modify:
  - `game/src/sim/devices.gd`: `DIODE` constants.
  - `game/src/sim/dc_solver.gd`: junctions include diodes, each with its own Is, N and series R; `vcrit` per junction.
  - `game/src/sim/damage.gd`: a diode over 1 A is "overcurrent".
  - `game/src/circuit/catalog.gd`: the datasheet rows.
  - `game/src/editor/part_art.gd`, `explain.gd` and `editor_controller.gd` (ID prefix "D"); `game/src/hud/parts_tray.gd`, `go_deeper.gd`; `game/src/course/mistake_why.gd`.
  - `game/src/workbench/part_models.gd` and `part_dims.gd`: DO-41, a black body 5.2 mm long and 2.7 mm across with a grey cathode band and 0.8 mm leads.
  - `game/src/course/part_intros.gd`: a "diode" card with its inside picture (Task 12 draws it).
  - `game/src/content/glossary.gd`: any datasheet term not yet in it.
- Test: `game/tests/sim/test_dc_solver.gd`, `test_damage.gd`; the every-kind tests in `test_part_art.gd`, `test_part_models.gd`, `test_meet_part.gd` and `test_content.gd` take the new kind as they stand.

**Interfaces:**
- Produces:
  - `Devices.DIODE := {"is": 14.11e-9, "n": 1.984, "rs": 0.0339, "max_amps": 1.0}`. These give about 0.69 V at 10 mA and 0.96 V at 1 A, against the datasheet's 0.93 V typical and 1.1 V maximum at 1 A (onsemi 1N4001/D Rev. 17).
  - Datasheet rows:
    - Type: "Silicon rectifier diode, 1N4001";
    - Forward voltage: "about 0.7 V at 10 mA; 0.93 V at 1 A";
    - Maximum current: "1 A";
    - Reverse voltage (max): "50 V";
    - Polarity: "the band marks the cathode, −".

- [ ] **Step 1: Write the failing tests.**
  - `test_diode_forward_voltage`:
    - In series with 430 Ω from the 5 V battery (about 10 mA), V(anode) − V(cathode) is between 0.65 and 0.75 V.
    - In series with 3.3 Ω (about 0.9 A), it's between 0.90 and 1.00 V.
  - `test_diode_blocks_backwards`: reversed in the 430 Ω loop, |current| is under 1 µA.
  - `test_diode_burns_past_one_amp`: straight across the battery, the diode burns, with reason "overcurrent".
- [ ] **Step 2: Run** the tests. *Expected:* FAIL (the diode conducts nothing yet).
- [ ] **Step 3: Implement.** Generalize the LED junction code to a list of junctions with their own constants; don't copy it.
- [ ] **Step 4: Run** `tools/test.sh`. *Expected:* all pass, including the every-kind tests for the diode's art, 3D leads at every rotation, intro and glossary rows.
- [ ] **Step 5: Commit** `feat: the silicon diode`.

### Task 3: The bench supply, its knob, and the LED's reverse rating

**Files:**
- Modify:
  - `game/src/sim/devices.gd`: `SUPPLY_OHMS := 0.01`, `SUPPLY_LIMIT_AMPS := 1.0`, `SUPPLY_MAX_VOLTS := 12.0`, `LED_MAX_REVERSE_VOLTS := 5.0`.
  - `game/src/sim/dc_solver.gd`:
    - The supply holds its set voltage behind 0.01 Ω until it would deliver more than 1 A. From then on it's a 1 A current source.
    - Each Newton iteration chooses the mode from the last iterate, and source stepping scales it.
  - `game/src/sim/damage.gd`: an LED reversed past 5.0 V (tolerance 0.01 V) is "reverse".
  - `game/src/sim/simulator.gd` and `sim_result.gd`: `limited_supplies: PackedStringArray`; a supply short counts like a battery's.
  - `game/src/circuit/catalog.gd`:
    - supply rows: "Output: 0–12 V, set to 5.0 V" and "Current limit: 1 A";
    - LED row "Reverse voltage (max): 5 V", cited to the LED datasheet the game's LED follows (checked and ledgered).
  - `game/src/hud/value_popover.gd` and `game/src/screens/level_screen.gd`: the value slider takes a spec instead of hard-coded ohms.
  - `game/src/workbench/meter_rig.gd`, `part_models.gd` and `workbench_3d.gd`: a bench supply beside the board, left of the battery's place. It has a display showing its volts and red and black binding posts, and its leads run to the pin holes.
  - `game/src/editor/part_art.gd`: a supply symbol; `game/src/course/mistake_why.gd`: "Backwards past 5 V"; `game/src/course/part_intros.gd`: "supply".
- Test: `game/tests/sim/test_dc_solver.gd`, `test_damage.gd`; `game/tests/hud/test_value_popover.gd` (new); `game/tests/content/test_chapter1_unchanged.gd` (new).

**Interfaces:**
- Produces:
  - `static func value_spec(p: Part) -> Dictionary`, in `Catalog`:
    - `{"prop": "ohms", "min": 100.0, "max": 2000.0, "step": 10.0, "unit": "Ω"}` for a trimmer;
    - `{"prop": "volts", "min": 0.0, "max": 12.0, "step": 0.1, "unit": "V"}` for a supply;
    - `{"prop": "sample", "options": [...]}` for a sample (Task 8);
    - `{}` for a part with no value.
  - `ValuePopover.open(p: Part, spec: Dictionary)`.
  - `SimResult.limited_supplies`.
  - A supply's `"reversed": bool` prop, default false, swaps its polarity as if its leads were crossed. Lesson 4's tests set it. The datasheet says "Leads: crossed (reversed)" and the bench draws them crossed.

- [ ] **Step 1: Write the failing tests.**
  - `test_supply_holds_its_voltage`: at 9 V across 1 kΩ, the voltage across is 9.000 V ± 0.001.
  - `test_supply_limits_at_one_amp`: at 9 V across 1 Ω, the current is 1.000 A ± 0.001, the voltage is 1.00 V ± 0.01, and `limited_supplies` has the supply.
  - `test_led_reverse_rating`: an LED reversed in series with 330 Ω across the supply at 9 V burns with reason "reverse". At 5.0 V it doesn't.
  - `test_chapter1_led_backwards_survives`: in `ch1.pop`, the LED reversed straight across the 5 V battery doesn't burn (exactly its rating). Also `test_chapter1_numbers_hold`: Lessons 1–9's solutions give their recap numbers as they do today, e.g. Lesson 1 at 13.8 mA.
  - `test_supply_reversed_swaps_polarity`: at 9 V with `reversed`, the pin `pos` sits 9 V below `neg`.
  - `test_value_popover_takes_a_spec` (test_value_popover): a supply's slider runs 0–12 V in 0.1 V steps, shows "9.0 V", and commits `volts`. The trimmer's runs 100 Ω–2 kΩ as before.
- [ ] **Step 2: Run** the tests. *Expected:* FAIL (no supply stamp, no reverse damage, popover fixed to ohms).
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`. *Expected:* all pass.
- [ ] **Step 5: Commit** `feat: the bench supply and the LED's reverse rating`.

### Task 4: N- and P-channel MOSFETs, and floating gates

**Files:**
- Modify:
  - `game/src/sim/devices.gd`: `NMOS` and `PMOS` constants.
  - `game/src/sim/dc_solver.gd`: the MOSFET stamp.
  - `game/src/sim/dc_solution.gd` and `sim_result.gd`: `floating_gates` and `mos_region`.
  - `game/src/sim/damage.gd`: "overcurrent" past `max_amps` and "overheat" past `max_watts`.
  - `game/src/circuit/catalog.gd`: the datasheet rows.
  - `game/src/editor/part_art.gd`: enhancement-mode MOSFET symbols, and a "?" on a floating gate's part; `game/src/editor/visual_state.gd`: the region and the floating flag.
  - `game/src/workbench/part_models.gd` and `part_dims.gd`: TO-92 (a black half-cylinder 4.8 mm wide and 4.6 mm tall with a flat face, legs bent to 5.08 mm); `explain.gd`; `go_deeper.gd`; `parts_tray.gd`; `editor_controller.gd` (prefix "Q"); `mistake_why.gd` ("The gate is floating"); `part_intros.gd` ("nmos" and "pmos").
- Test: `game/tests/sim/test_mosfet.gd` (new), `test_damage.gd`, `test_simulator.gd`.

**Interfaces:**
- Produces:
  - `Devices.NMOS := {"vth": 2.1, "k": 0.23, "lambda": 0.02, "max_amps": 0.2, "max_watts": 0.4}`: 2N7000 typical, onsemi NDS7002A/D Rev. 11. k = 1 ÷ (1.8 Ω × (4.5 V − 2.1 V)).
  - `Devices.PMOS := {"vth": -2.0, "k": 0.018, "lambda": 0.02, "max_amps": 0.23, "max_watts": 0.7}`: a typical BS250 within Vishay 70209's −1 to −3.5 V and ≤14 Ω at −10 V; ratings from Diodes Inc. BS250P.
  - λ = 0.02 V⁻¹ is assumed (neither datasheet gives it) and the Go deeper card says so. Without it, an inverter's output drops as a vertical step at its switching point, which is both untrue and badly conditioned for Newton.
  - `SimResult.floating_gates: PackedStringArray`.
  - `SimResult.mos_region: Dictionary`: part id → "off", "linear" or "saturation".
- The model (Shichman–Hodges, SPICE level 1, no body diode). For an nmos with V_ds ≥ 0 (otherwise drain and source swap; a pmos negates every voltage and current), with V_ov = V_gs − V_th and m = 1 + λ·V_ds:
  - **off,** V_ov ≤ 0: I_d = 0 (GMIN across drain–source);
  - **linear,** V_ds < V_ov: I_d = k(V_ov·V_ds − V_ds²/2)·m;
  - **saturation:** I_d = (k/2)·V_ov²·m;
  - g_m and g_ds are the partial derivatives of I_d (with GMIN added to g_ds).
- The Newton stamp: g_ds between drain and source; a VCCS g_m from (gate, source) driving drain → source; and the equivalent current I_d − g_m·V_gs − g_ds·V_ds.
- V_gs moves at most 0.5 V per iteration (counted as "limited"). Converged also needs |I_d predicted − I_d computed| ≤ ABSTOL + RELTOL·|I_d|.
- **A floating gate** (its net is floating) makes the transistor off, and adds its id to `floating_gates`.

- [ ] **Step 1: Write the failing tests** (test_mosfet). Circuit A: 5 V battery, 150 Ω, a red LED, and Q1's drain on the LED's cathode with its source on −.
  - `test_nmos_switches_an_led`, using circuit A:
    - Gate wired to +: the LED is at 19.6 mA ± 0.3 and the region is "linear".
    - Gate wired to −: the LED is under 0.5 mA and the region is "off".
  - `test_nmos_threshold`: the gate driven from a supply.
    - At 2.0 V: under 0.01 mA.
    - At 2.3 V: 4.8 mA ± 0.2 ((k/2)·0.2²·(1 + 0.02·2.5 V)), "saturation".
    - At 3.0 V: "linear".
  - `test_pmos_high_side`: Q2's source on +, drain to the LED, then 150 Ω to −.
    - Gate on −: 17.8 mA ± 0.4.
    - Gate on +: off.
  - `test_inverter_levels`: pmos source to +, nmos source to −, the drains joined (out), the gates joined and driven by a supply (in).
    - in 0 V: out above 4.99 V.
    - in 5 V: out below 0.01 V.
    - The output crosses 2.5 V for an input between 2.25 and 2.35 V (the switching point; the matched-current input is 2.30 V).
  - `test_inverter_converges_across_the_sweep`: for in = 0.00 to 5.00 in 0.05 V steps, the solve converges (directly or stepped), out is finite, and out never rises by more than 1e-3 V as in rises.
  - `test_floating_gate_is_shown_not_zero`: Q2's source on + and its gate wired to nothing. `floating_gates` has Q2, and the LED is dark (not fully on, as a silent 0 V gate would make it).
  - `test_mosfet_burns_past_its_rating`: Q1's drain straight to + and its gate on. Q1 burns, "overcurrent".
  - `test_reversed_supply_fuzz` (test_simulator):
    - 200 seeded random small circuits of the new kinds plus Chapter 1's kinds, with the supply set from −12 to 12 V.
    - Each converges or reports stepped, no non-floating net is NaN, and every damage reason is one of overcurrent, overheat, fuse, reverse.
- [ ] **Step 2: Run** `tools/test.sh test_mosfet.gd`. *Expected:* FAIL (no stamp).
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`. *Expected:* all pass.
- [ ] **Step 5: Commit** `feat: N- and P-channel MOSFETs`.

### Task 5: Goals, readouts and recap numbers for the new parts

**Files:**
- Modify:
  - `game/src/lessons/goals.gd`:
    - new kinds `volts_between`, `transistor`, `gate_driven`;
    - `_battery_drives` becomes "a source drives", so `led_lit`'s "current is going around it" message works with a supply.
  - `game/src/hud/goals_panel.gd`: their labels.
  - `game/src/course/readouts.gd`: quantities `Vgs`, `Vds` and `Id` for nmos and pmos, `volts` for a supply, and `V` (anode to cathode) for a diode.
  - `game/src/course/recap_text.gd`: the template's quantities come from `Readouts.QUANTITIES`.
  - `game/src/course/truth_rows.gd`: a level's own truth spec.
  - `game/src/lessons/level_def.gd` and `level_builder.gd`: `truth`.
- Test: `game/tests/lessons/test_goals.gd`, `game/tests/course/test_readouts.gd`, `test_recap_text.gd`, `test_truth_rows.gd` (new).

**Interfaces:**
- Produces:
  - Goal `{"kind": "volts_between", "a": "Q1:drain", "b": "B1:neg", "min": float, "max": float}`.
    - It passes when V(a) − V(b) is within [min, max].
    - It fails, saying which pin, when either pin is floating.
  - Goal `{"kind": "transistor", "part": "Q1", "state": "on" | "off"}`.
    - "on" means the region is linear and |I_d| ≥ 1 mA; "off" means the region is off.
    - A floating gate passes neither, with the message "The gate is floating".
  - Goal `{"kind": "gate_driven", "part": "Q1"}`: the gate's net is not floating.
  - `LevelDef.truth: Dictionary`, from `LevelBuilder.truth(inputs: Array, output: Dictionary)`.
    - Each input is `{"part": id, "prop": "closed"}` (a switch) or `{"part": id, "prop": "volts"}` (a supply).
    - The output is `{"led": id}` or `{"pin": "Q1:drain"}`.
    - Without it, Lessons 5–6 of Chapter 1 keep their switches A and B.
  - `TruthRows.row(c: Circuit, level: LevelDef) -> int` and `TruthRows.lit(c, sim, level) -> int`. The latter returns 1, 0, or −1 for "in between".
    - Logic levels at 5 V: an input or output counts as 0 at or below 1.5 V and as 1 at or above 3.5 V. That's 30 % and 70 % of the supply, the 74HC family's rule (TI SCLS078H).

- [ ] **Step 1: Write the failing tests.**
  - `test_volts_between_goal`.
  - `test_transistor_goal_on_off`, on Task 4's circuit A.
  - `test_floating_gate_fails_its_goals`: with Q1's gate wired to nothing, `transistor` on, `transistor` off and `gate_driven` all fail, and the message names the gate.
  - `test_led_lit_on_a_supply`.
  - `test_readouts_for_transistors`: "Gate to source: 4.98 V" and "Drain current: 19.7 mA" (± its rounding).
  - `test_recap_fills_transistor_values`.
  - `test_truth_rows_for_an_inverter`: input 0 V → row 0, output 1; input 5 V → row 1, output 0; input 2.3 V → row −1. The switch lessons' rows stay as they are.
- [ ] **Step 2: Run** the tests. *Expected:* FAIL (unknown goal kinds, missing quantities).
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`. *Expected:* all pass.
- [ ] **Step 5: Commit** `feat: goals and readouts for transistors`.

### Task 6: The sweep and its curve

**Files:**
- Create:
  - `game/src/course/sweep.gd` (pure).
  - `game/src/hud/curve_plot.gd`: axes "input (V)" and "output (V)", a band at 0–1.5 V labeled "counts as 0" and one at 3.5–5 V labeled "counts as 1", the points as a line, and the switching point marked.
- Modify:
  - `game/src/lessons/level_def.gd` and `level_builder.gd`: `sweep`.
  - `game/src/app/game_state.gd`: `last_sweep`, `run_sweep()`.
  - `game/src/lessons/goals.gd`: the `curve` kind.
  - `game/src/screens/level_screen.gd`: a Sweep button beside Test when the level has a sweep, which opens the plot as a card.
  - `game/src/course/recap_text.gd`: `{sweep.switch}`.
- Test: `game/tests/course/test_sweep.gd` (new), `game/tests/lessons/test_goals.gd`, `game/tests/hud/test_curve_plot.gd` (new).

**Interfaces:**
- Produces:
  - `LevelDef.sweep: Dictionary = {"source": "VIN", "prop": "volts", "from": 0.0, "to": 5.0, "step": 0.1, "read": "Q1:drain"}`.
  - `Sweep.run(c: Circuit, spec: Dictionary) -> PackedVector2Array`: x is the input, y is the read pin's voltage to the circuit's 0 V, one point per step (51 for 0–5 V in 0.1 V steps).
  - `Sweep.switch_point(points: PackedVector2Array, level := 2.5) -> float`: the input where the output crosses `level`, by linear interpolation; NAN if it never does.
  - `GameState.run_sweep()`: sets `last_sweep` and the ui flag `swept`.
  - Goal `{"kind": "curve", "high_until": 1.5, "low_from": 3.5}`: the last sweep's output is ≥ 3.5 V for every input ≤ 1.5 V, and ≤ 1.5 V for every input ≥ 3.5 V.
  - `{sweep.switch}` in a recap reads, for example, "2.3 V".

- [ ] **Step 1: Write the failing tests.**
  - `test_sweep_traces_an_inverter`: on Task 4's inverter there are 51 points; y(0) > 4.9, y(5) < 0.1; y never rises; `switch_point` is between 2.25 and 2.35.
  - `test_curve_goal`: passes for the inverter, fails for an output stuck at 5 V, fails before any sweep.
  - `test_sweep_button_draws_the_curve`, on a level with a sweep: pressing Sweep shows the plot with 51 points and sets `swept`.
  - `test_curve_plot_fits_small_phone`: 360 × 640 and 640 × 360, Large text and Night: on screen, its Close button ≥ 44 px.
- [ ] **Step 2: Run** the tests. *Expected:* FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`. *Expected:* all pass.
- [ ] **Step 5: Commit** `feat: the sweep and its curve`.

### Task 7: Doped silicon samples

**Files:**
- Modify:
  - `game/src/sim/devices.gd`: `SAMPLES`.
  - `game/src/sim/dc_solver.gd`: a sample is a resistor of its table value.
  - `game/src/circuit/catalog.gd`: rows and `value_spec` options.
  - `game/src/editor/part_art.gd`: a grey bar with an "N", "P" or "pure" tag.
  - `game/src/workbench/part_models.gd` and `part_dims.gd`: a dark grey 10 × 1 × 1 mm silicon bar on its two legs.
  - `explain.gd`, `parts_tray.gd` and `go_deeper.gd`; `game/src/course/part_intros.gd` ("sample").
- Test: `game/tests/sim/test_samples.gd` (new), `game/tests/hud/test_value_popover.gd`.

**Interfaces:**
- Produces `Devices.SAMPLES: Array[Dictionary]`, in this order, each `{"id", "dopant", "per_cm3", "ohms"}`:
  - `undoped`: none, 0, 3.2e7;
  - `p15`: phosphorus, 1e15, 450.0;
  - `p16`: phosphorus, 1e16, 52.0;
  - `b15`: boron, 1e15, 1340.0;
  - `b16`: boron, 1e16, 143.0.
- These are R = ρ × 100 cm⁻¹ for the 10 mm × 1 mm × 1 mm bar. ρ comes from ASTM F723 (NBS SP 400-64) at 23 °C, and the undoped value from Ioffe's 3.2 × 10⁵ Ω·cm.
- Datasheet rows: "Bar: 10 mm × 1 mm × 1 mm", "Doping: phosphorus, 10¹⁶ atoms per cm³ (N-type)", "Resistance: 52 Ω".

- [ ] **Step 1: Write the failing tests.**
  - `test_sample_resistances`: each sample in series with 100 Ω and the current meter on the 5 V battery reads 5 V ÷ (R + 101.1 Ω), ± 1 %. For example, p16 reads 32.7 mA and b16 20.5 mA.
  - `test_undoped_sample_barely_conducts`: under 1 µA.
  - `test_sample_value_spec_lists_five`: in the table's order, labeled in plain words, e.g. "Phosphorus, 10¹⁶ per cm³ (N-type)".
- [ ] **Step 2: Run.** *Expected:* FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`. *Expected:* all pass (with the every-kind tests).
- [ ] **Step 5: Commit** `feat: doped silicon samples`.

### Task 8: Process lessons, and the furnace

**Files:**
- Create:
  - `game/src/process/process_model.gd`: the pure base.
  - `game/src/process/furnace_model.gd`.
  - `game/src/process/process_view.gd`: base Control. It draws from the model's state in the diagrams' style, with the label "Illustration" always and "sped up ×N" while it runs.
  - `game/src/process/furnace_view.gd`.
  - `game/src/hud/process_panel.gd`: the model's controls as labeled sliders and buttons (≥ 44 px), and its readouts.
- Modify:
  - `game/src/lessons/level_def.gd` and `level_builder.gd`: kind "process", `process: String`.
  - `game/src/lessons/goals.gd`: `process_reached`.
  - `game/src/lessons/lesson_rules.gd`: a process lesson has no Try it and no circuit.
  - `game/src/app/game_state.gd`: `process_stage`, `process_seen`, `set_process_stage()`, and the model's values for recaps.
  - `game/src/screens/level_screen.gd`: for kind "process", the process view takes the bench's place and the panel the column's top. No tray, no zoom, no Test.
  - `game/src/course/recap_text.gd`: `{process.<readout id>}`.
- Test: `game/tests/process/test_furnace.gd` (new), `game/tests/hud/test_process_screen.gd` (new), `game/tests/lessons/test_goals.gd`.

**Interfaces:**
- Produces:
  - `ProcessModel`, extends RefCounted:
    - `controls() -> Array[Dictionary]`: `{id, label, min, max, step, unit, value}`, or `{id, label, action: true}` for a button;
    - `set_control(id: String, v: float)` and `press(id: String)`;
    - `step(minutes: float)`: model time; the view runs it sped up;
    - `stage() -> String`;
    - `stages() -> PackedStringArray`, in order;
    - `readouts() -> Array[Dictionary]`: `{id, label, text}`;
    - `message() -> String`: why nothing is happening, "" when all is well;
    - `state() -> Dictionary`, for the view.
  - `ProcessModel.make(id: String) -> ProcessModel`: "furnace" or "puller" (Task 9).
  - Goal `{"kind": "process_reached", "stage": "mg_silicon"}`: passes once the stage has been reached in this visit, as `zoom_reached` does.
- **FurnaceModel** (an illustration with real figures; each from the facts file, cited on its card):
  - Controls:
    - `carbon`, carbon per silica as a ratio of atoms, 0–3 in steps of 0.1, starting at 1.0; the reaction needs 2;
    - `heat`, the furnace in °C, 0–2200 in steps of 50, starting at 20;
    - later `rod_heat`, the Siemens reactor's rods in °C, 0–1300 in steps of 25;
    - an action `chlorinate`.
  - Stages: loaded → reducing → mg_silicon → chlorinated → depositing → eg_silicon.
  - **Reducing** runs while the heat is 1900–2100 °C and carbon is 1.8–2.2. That's the hottest zone's "about 2000 °C" (NREL 89464), drawn as a window.
    - Too little carbon: "There isn't enough carbon to take all the oxygen: silica is left."
    - Too much: "Extra carbon makes silicon carbide instead of silicon."
    - Below 1900 °C: "Too cold: the reaction needs about 2,000 °C."
  - After 120 model minutes of reducing: **mg_silicon**, purity "98.5 % (metallurgical grade)", energy "about 12 kWh per kg".
  - `chlorinate` → chlorinated ("trichlorosilane, distilled"). Then rods at 1050–1150 °C for 240 model minutes → **eg_silicon**, purity "99.9999999 % (nine nines)".

- [ ] **Step 1: Write the failing tests.**
  - `test_furnace_needs_heat_and_carbon`:
    - At 1500 °C nothing happens, with the cold message.
    - At 2000 °C with carbon 2.0, 120 model minutes reach mg_silicon at 98.5 %.
    - With carbon 1.0 it stays "reducing" no further, with the silica message.
  - `test_purifier_reaches_nine_nines`.
  - `test_process_goal`.
  - `test_process_lesson_hosts_the_furnace` (screen), on a test level of kind "process":
    - the view is visible, the bench hidden, the sliders are in the column, and "Illustration" is drawn;
    - with Reduced motion, the picture holds still.
- [ ] **Step 2: Run.** *Expected:* FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`. *Expected:* all pass.
- [ ] **Step 5: Commit** `feat: process lessons and the furnace`.

### Task 9: The crystal puller

**Files:**
- Create: `game/src/process/puller_model.gd`, `game/src/process/puller_view.gd`.
- Test: `game/tests/process/test_puller.gd` (new), `game/tests/hud/test_process_screen.gd`.

**Interfaces:**
- **PullerModel**, an illustration whose real figures are cited on its cards:
  - Controls:
    - `melt` in °C, 1300–1500 in steps of 2, starting at 1380;
    - `pull` in mm per minute, 0–6 in steps of 0.1, starting at 0;
    - actions `dip` and `slice`.
  - Stages: solid → melted → seeded → necked → ingot → sliced.
  - **melted** at 1414 °C or above (silicon's melting point). Below it: "Still solid: silicon melts at 1,414 °C."
  - **seeded** on `dip`.
  - **necked**: the first 30 mm pulled at 3 mm/min or faster grow a 3 mm neck that dislocations can't follow (Dash 1959). Pulling slower first gives "Too slow at the start: the crystal is full of defects. Dip again."
  - **ingot**: the body's diameter D moves toward D\* with a 15-minute time constant:
    - D\* = clamp(300 mm × (1.0 ÷ pull) × (1 − (melt − 1420) ÷ 40), 0, 450);
    - faster or hotter gives thinner (US 6,726,764);
    - 1,000 mm of body held at 300 ± 15 mm reaches ingot.
  - **sliced** on `slice`: wafers "0.775 mm thick" (SEMI M1, 300 mm).
  - Readouts: melt, pull, diameter, length, and the stage's words.

- [ ] **Step 1: Write the failing tests.**
  - `test_puller_needs_liquid_silicon`.
  - `test_neck_then_body`: 4 mm/min for 30 mm, then 1.0 mm/min at 1420 °C reaches 300 ± 15 mm and, after 1,000 mm, ingot.
  - `test_pull_faster_is_thinner` and `test_hotter_is_thinner`, on D\*.
  - `test_slow_start_is_full_of_defects`.
  - `test_slice_gives_775_um_wafers`.
  - `test_process_fits_small_phone` (Review Focus 4): both processes at 360 × 640 and 640 × 360, with Large text, Night and Reduced motion:
    - every slider and button is ≥ 44 px and reachable (scrolling if need be);
    - the view is on screen with "Illustration" drawn;
    - the picture holds still.
- [ ] **Step 2: Run.** *Expected:* FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`. *Expected:* all pass.
- [ ] **Step 5: Commit** `feat: the crystal puller`.

### Task 10: Pictures for Chapter 2

**Files:**
- Create:
  - `game/src/course/diagrams/sand_diagrams.gd`: `sand_to_silicon`, `nines_purity`, `czochralski`, `wafer_slices`;
  - `game/src/course/diagrams/doping_diagrams.gd`: `silicon_bonds`, `n_type`, `p_type`, `pn_junction`, `diode_curve`;
  - `game/src/course/diagrams/mos_diagrams.gd`: `mosfet_channel`, `nmos_switch`, `pmos_switch`, `floating_gate`, `cmos_inverter`, `logic_levels`, `transfer_curve`;
  - plus `diode_inside` and `mosfet_inside` cutaways for the Meet cards.
- Modify: `game/src/course/diagrams.gd`: `SCRIPTS` and `IDS`.
- Test: `game/tests/course/test_diagrams.gd`. The existing every-id tests (words drawn, 4.5:1 contrast, a clean frame at every moment, a still frame and "sped up") cover the new ids as they stand.

**What each must show (in words a beginner reads):**
- `sand_to_silicon`: SiO₂ + 2C → Si + 2CO as atoms, the carbon carrying the oxygen away as gas. It's labeled "about 2,000 °C".
- `nines_purity`: a field of a billion-to-one, showing one foreign atom among many. It's labeled "nine nines: 99.9999999 %".
- `czochralski`: a seed turning one way and the crucible the other, with the crystal drawn up out of the melt. It's labeled "1,414 °C" and "sped up".
- `wafer_slices`: an ingot sliced into wafers, each "0.775 mm".
- `silicon_bonds`: each silicon atom sharing four bonds.
- `n_type`: phosphorus with its spare electron free to move.
- `p_type`: boron with its hole, moving like a + charge (moving charges "sped up").
- `pn_junction`: the depletion region with no free charges, narrowing when pushed forward and widening backwards.
- `diode_curve`: current against voltage for the silicon diode (about 0.7 V) and the red LED (about 2 V).
- `mosfet_channel`: a cross-section with the gate on its thin glass layer and a channel of electrons forming above the threshold.
- `nmos_switch` and `pmos_switch`: the gate high or low, and on or off.
- `floating_gate`: a gate on nothing, with a "?".
- `cmos_inverter`: one PMOS above, one NMOS below, the input low or high, and which one is on.
- `logic_levels`: 0–1.5 V counts as 0, 3.5–5 V counts as 1, and "in between: neither".
- `transfer_curve`: the inverter's output against input, dropping near 2.3 V.

- [ ] **Step 1: Write the failing tests.**
  - `test_chapter2_pictures_registered`: all the ids above are in `Diagrams.IDS`.
  - `test_diode_curve_labels`: "0.7 V" and "2 V".
  - `test_transfer_curve_marks_its_levels`: "counts as 0" and "counts as 1".
  - `test_czochralski_says_melting_point`: "1,414 °C".
- [ ] **Step 2: Run.** *Expected:* FAIL.
- [ ] **Step 3: Draw them.** Use the existing helpers (`label`, `box`, `dashes`, `speed_note`) and the 400 × 220 design box.
- [ ] **Step 4: Run** `tools/test.sh`. Capture the gallery (`--ids=` each, light and Night) and look at every picture. *Expected:* all pass, and no label overlaps another.
- [ ] **Step 5: Commit** `feat: pictures for Chapter 2`.

### Task 11: Chapter 2 on the map

**Files:**
- Modify:
  - `game/src/content/chapters.gd`: "ch2", titled "Sand", era "1947–1963";
  - `game/src/lessons/levels.gd`: Chapter 2's lessons in order;
  - `game/src/screens/map_screen.gd`: Chapter 2's lessons under their banner;
  - `game/src/app/game.gd`: unlocking;
  - `game/src/hud/notebook_sheet.gd`: lessons grouped by chapter.
- Test: `game/tests/app/test_chapter2_unlock.gd` (new), `game/tests/content/test_content.gd`.

**Interfaces:**
- Chapter 2's ids, in order: `ch2.sand`, `ch2.crystal`, `ch2.doping`, `ch2.diode`, `ch2.nmos`, `ch2.pmos`, `ch2.not`.
- Unlocking:
  - Lesson 1 of Chapter 2 unlocks when every lesson of Chapter 1 except the tour is completed.
  - Each later lesson unlocks when the one before is completed, as in Chapter 1.
  - A locked lesson says "Finish Chapter 1 to open Chapter 2", or the existing per-lesson line.

- [ ] **Step 1: Write the failing tests.**
  - `test_old_save_meets_chapter_2` (Review Focus 3):
    - A v0.3.0 save with Chapter 1's nine lessons completed (no tour) opens with `ch2.sand` unlocked.
    - One with Lesson 9 not done opens with it locked, and with the message.
    - Every Chapter 1 record and badge is unchanged.
  - `test_ch2_lessons_in_order`.
  - `test_map_shows_chapter_2_banner`: "Sand" and "1947–1963".
- [ ] **Step 2: Run.** *Expected:* FAIL.
- [ ] **Step 3: Implement.** Content files for the seven lessons start here as stubs that pass `LessonRules`; Tasks 12–15 fill them.
- [ ] **Step 4: Run** `tools/test.sh`. *Expected:* all pass.
- [ ] **Step 5: Commit** `feat: Chapter 2 on the map`.

### Task 12: Lessons 1–2, from sand to a wafer

**Files:**
- Create/modify: `game/src/content/ch2/l1_sand.gd`, `game/src/content/ch2/l2_crystal.gd`; `game/src/content/glossary.gd`.
- Test: `game/tests/content/test_chapter2.gd` (new); the existing content scans (copy limits, glossary, sources, `LessonRules`) cover them as they stand.

**What each lesson teaches and asks** (copy is the implementer's, within the limits; every number cited from the facts file):
- **Lesson 1, "Sand to silicon"** (process "furnace"). Learn goals: what sand is made of; how silicon is freed from it; how pure chip silicon must be.
  - Cards:
    1. Sand is mostly quartz, silica: silicon and oxygen, SiO₂ (`sand_to_silicon`).
    2. Heated with carbon at about 2,000 °C, the carbon takes the oxygen away as CO gas (NREL 89464; Brown et al.).
    3. That's metallurgical-grade silicon, about 98–99 % pure: too dirty for chips (NREL 89464).
    4. To purify it, it becomes a liquid, trichlorosilane, which is distilled. Silicon then grows back onto rods heated to about 1,100 °C (Wacker; Föll).
    5. Chip silicon is 9 to 11 nines pure, at most one foreign atom in a billion (`nines_purity`; Bernreuter 2025).
    6. A real card: the furnace uses about 12 kWh per kg (NREL 89464).
  - Do it: run the furnace to mg_silicon, then the purifier to eg_silicon. Steps and whys follow the stages.
  - Recap uses `{process.purity}` and `{process.heat}`. Two questions: why carbon, and how pure.
  - Fact: Wacker's best silicon has about 9 foreign dopant atoms per trillion (Bernreuter 2025).
- **Lesson 2, "Grow a crystal"** (process "puller"). Learn goals: why chips need one perfect crystal; how a crystal is pulled; how it becomes wafers.
  - Cards:
    1. Silicon melts at 1,414 °C, held in a quartz crucible under argon (Föll).
    2. A seed crystal dips in, and turns as it's pulled up slowly, about 1 mm a minute (`czochralski`; patents, cited as such).
    3. A thin neck first lets defects grow out (Dash 1959).
    4. Pull faster or run hotter and the crystal grows thinner (US 6,726,764).
    5. The ingot is sliced into wafers 0.775 mm thick (`wafer_slices`; SEMI M1, via the vendor sheet).
    6. History: in 1916 Jan Czochralski, the story goes, dipped his pen into molten tin and drew out a crystal thread (Tomaszewski & Cahn 2004).
    7. A real card: a 300 mm ingot weighs about 165 kg per metre (π × (15 cm)² × 2.329 g/cm³).
  - Do it: melt, dip, neck, hold 300 mm for a metre, slice.
  - Recap uses `{process.diameter}` and `{process.pull}`.
- **Glossary:** silica, quartz, metallurgical grade, trichlorosilane, distill, purity, crystal (already there as crystal lattice: link), seed crystal, ingot, wafer, Czochralski method.

- [ ] **Step 1: Write the failing test** `test_chapter2_lessons_1_2`: each is of kind "process", passes `LessonRules` and the course-ready checks, and its process's last stage is its goal. Its cited figures appear on cards with sources: 2,000 °C, 98–99 %, 1,414 °C, 0.775 mm.
- [ ] **Step 2: Run.** *Expected:* FAIL (stubs).
- [ ] **Step 3: Write the two lessons and their glossary entries.**
- [ ] **Step 4: Run** `tools/test.sh`. Capture each card at 1280 × 720 and 390 × 844 and look at them. *Expected:* all pass.
- [ ] **Step 5: Commit** `feat: Chapter 2 Lessons 1 and 2`.

### Task 13: Lessons 3–4, doping and the diode

**Files:** `game/src/content/ch2/l3_doping.gd`, `l4_diode.gd`; `game/src/content/glossary.gd`; `game/tests/content/test_chapter2.gd`.

- **Lesson 3, "Doping"** (build). Learn goals: why pure silicon barely conducts; what N-type and P-type are; why a tiny amount changes so much.
  - Cards:
    1. Each silicon atom shares its four outer electrons in four bonds (`silicon_bonds`).
    2. So pure silicon has very few free charges: about 10¹⁰ per cm³ among 5 × 10²² atoms (Altermatt 2003; PVEducation).
    3. Phosphorus has five, leaving one spare: N-type (`n_type`).
    4. Boron has three, leaving a hole that moves like a + charge: P-type (`p_type`).
    5. One atom in 50 million is enough (worked: 5 × 10²² ÷ 10¹⁵).
    6. Electrons move about three times more easily than holes (NBS SP 400-64 mobilities).
  - Meet: sample.
  - Try it: the 5 V battery, 100 Ω, the current meter and an undoped sample, which reads 0.0 mA. Then swap in p16 (32.7 mA). Readouts: the meter.
  - Build: tray samples set to undoped, with the dial offering all five. Goal: the meter reads 20.5 mA ± 1.0. Only b16 does it; p16 gives 32.7 and b15 3.5.
    - Steps: read the sample's datasheet; try phosphorus; then boron.
    - Whys: holes move less easily, so the same doping resists more.
  - Recap uses `{M1.reading}`. Questions: which dopant makes N-type; why P-type resists more at the same doping.
  - Fact: one phosphorus atom per 50 million silicon atoms makes the bar conduct about 70,000 times better (32 MΩ → 450 Ω).
- **Lesson 4, "The diode"** (build). Learn goals: what happens where P meets N; why a diode lets current one way; why an LED needs more voltage.
  - Cards:
    1. Where P meets N, electrons fill nearby holes, leaving a thin depletion region with no free charges (`pn_junction`; Sze & Lee).
    2. Push + on the P side and it narrows: above about 0.6–0.7 V current flows. Backwards it widens and blocks (`diode_curve`; onsemi 1N914/1N4001).
    3. An LED is a diode too, needing about 2 V because its material's band gap is wider (Vishay TLHR5400; Ioffe).
    4. History: Russell Ohl found the PN junction at Bell Labs in 1940 (CHM). This card says it's from before the chapter's era.
    5. A real card: the 1N4001 is rated 1 A and 50 V backwards (onsemi 1N4001/D).
  - Meet: diode and supply.
  - Try it: the supply at 5 V, 430 Ω and the diode, forward then reversed (`reversed` toggled by the path edits). Readouts: the diode's V and the current.
  - Build: the supply at 9 V, 390 Ω and a red LED (17.9 mA forward, under its 20 mA). Tests run the supply forward and reversed (the supply's `reversed` prop, Task 3). Reversed, the protecting diode carries (9 − 0.7) ÷ 390 ≈ 21 mA, well inside its 1 A.
    - Goals: forward, the LED lit; reversed, nothing burnt.
    - Placing the diode across the LED, pointing the other way, passes. Without it, reversed, the LED burns: "reverse".
  - Recap uses `{L1.mA}`. The reversed case is a point in words ("Backwards, your diode carries the current at about 0.7 V, so the LED is safe"); recaps read the passing circuit, not the tests' runs. Questions: which way current flows; why the LED needs protecting at 9 V and not at 5 V.
- **Glossary:** dopant, doping, N-type, P-type, hole, free electron (link electron), PN junction, depletion region, band gap, rectifier, reverse voltage.

- [ ] **Step 1: Write the failing test** `test_chapter2_lessons_3_4`:
  - Each passes `LessonRules`, the course-ready checks and its solution's tests.
  - In Lesson 3 only b16 passes the build: the other four fail it, each tried.
  - In Lesson 4, without the protecting diode, the reversed test burns the LED.
- [ ] **Step 2: Run.** *Expected:* FAIL.
- [ ] **Step 3: Write the two lessons and their glossary entries.**
- [ ] **Step 4: Run** `tools/test.sh` and capture as in Task 12. *Expected:* all pass.
- [ ] **Step 5: Commit** `feat: Chapter 2 Lessons 3 and 4`.

### Task 14: Lessons 5–6, the transistor and its opposite

**Files:** `game/src/content/ch2/l5_nmos.gd`, `l6_pmos.gd`; `game/src/content/glossary.gd`; `game/tests/content/test_chapter2.gd`.

- **Lesson 5, "The transistor"** (build). Learn goals: what a transistor's three legs do; what the threshold voltage is; why a gate must never float.
  - Cards:
    1. A MOSFET has a gate, a drain and a source (`mosfet_channel`).
    2. The gate sits on a thin layer of glass, so no current flows into it.
    3. Above its threshold, about 2.1 V for this one, the gate pulls electrons into a channel and current flows from drain to source (2N7000 datasheet).
    4. It's a switch controlled by a voltage (`nmos_switch`).
    5. A floating gate can switch at random, so it's always tied down, here by a resistor to − (`floating_gate`; TI SCBA004).
    6. History: Mohamed Atalla and Dawon Kahng made the first MOSFET at Bell Labs in 1959 (CHM).
  - Meet: nmos.
  - Try it: circuit A with the gate on a second supply. Pokes: 2.0 V (dark), 2.5 V (glowing), 5.0 V (fully on). Readouts: Vgs and Id.
  - Build: tray switch, 10 kΩ and the nmos.
    - Goals: `gate_driven`; with the switch closed, `transistor` on and the LED lit; with it open, off and dark (the level's tests).
    - Steps: the drain to the LED; the source to −; the gate to the switch from +; then the 10 kΩ from the gate to −. Each has a why.
  - Recap uses `{Q1.Vgs}` and `{L1.mA}`.
  - Fact: the Intel 4004 of 1971 had 2,300 transistors (Intel museum; history).
- **Lesson 6, "The other kind"** (build). Learn goals: how a PMOS differs; why it switches from the + side; how its gate stays off.
  - Cards:
    1. A PMOS is the opposite: it turns on when its gate is about 2 V below its source (BS250 datasheet).
    2. It carries holes.
    3. So it sits on the + side.
    4. Its gate is pulled up to its source to stay off (`pmos_switch`).
  - Meet: pmos. Its datasheet card says the threshold "−1 to −3.5 V; this one −2.0 V".
  - Try it: the PMOS high-side switch with its gate on a supply stepped down from 5 V.
  - Build: tray switch, 10 kΩ and the pmos. The source goes to +, the drain to the LED, 10 kΩ from the gate to +, and the switch from the gate to −. Tests: closed on, open off.
  - Recap uses `{Q1.Vgs}` (negative) and `{L1.mA}`.
- **Glossary:** transistor, MOSFET, gate, drain, source (a transistor leg: explicit only), threshold voltage, channel, oxide, NMOS, PMOS, floating, pull-down resistor, pull-up resistor.

- [ ] **Step 1: Write the failing test** `test_chapter2_lessons_5_6`:
  - Each passes `LessonRules`, the course-ready checks and its tests.
  - The build without the 10 kΩ fails `gate_driven` with the switch open.
  - Lesson 5's Try it pokes pass at 2.0, 2.5 and 5.0 V.
- [ ] **Step 2: Run.** *Expected:* FAIL.
- [ ] **Step 3: Write the two lessons and their glossary entries.**
- [ ] **Step 4: Run** `tools/test.sh` and capture. *Expected:* all pass.
- [ ] **Step 5: Commit** `feat: Chapter 2 Lessons 5 and 6`.

### Task 15: Lesson 7, the NOT gate

**Files:** `game/src/content/ch2/l7_not.gd`; `game/src/content/glossary.gd`; `game/tests/content/test_chapter2.gd`.

- **Lesson 7, "The NOT gate"** (build, with `truth` and `sweep`). Learn goals: how a PMOS and an NMOS make a NOT gate; what counts as 0 and as 1; why CMOS uses so little power.
  - Cards:
    1. CMOS puts one PMOS above one NMOS, gates joined as the input and drains joined as the output (`cmos_inverter`).
    2. Input low: the PMOS is on and the NMOS off, so the output is high. Input high: the reverse. Output is NOT input.
    3. Only one is on at a time, so almost no current flows (Wanlass & Sah 1963, "nanowatt logic").
    4. Below 1.5 V counts as 0 and above 3.5 V counts as 1 at 5 V; in between is neither (`logic_levels`; TI SCLS078H).
    5. A worked example: where this one switches, from the transistors' currents (V_M ≈ 2.3 V, `transfer_curve`).
    6. History: Frank Wanlass and Chih-Tang Sah, Fairchild, 1963 (CHM). It's an "after" note against the era.
  - Try it: the inverter with its input on a supply. Pokes: 0 V and 5 V fill the two-row truth table.
  - Build: tray pmos, nmos and the wires.
    - Goals: tests at in 0 V (out ≥ 3.5 V) and 5 V (out ≤ 1.5 V), then `curve` after a sweep.
    - Steps: place both; join the gates; join the drains; the PMOS source to +; the NMOS source to −; press Test; press Sweep.
  - Recap uses `{sweep.switch}` and the output at each input.
  - Fact: a 74HC04 chip holds six of these gates (TI SCLS078H); Lesson 8 packages yours.
- **Glossary:** CMOS, inverter, NOT gate (link logic gate), logic level, transfer curve, switching point, shoot-through.
- **The chapter's closing card** points to Milestone 4b's Lesson 8: "Next: package your NOT gate into your first chip."

- [ ] **Step 1: Write the failing test** `test_chapter2_lesson_7`:
  - It passes `LessonRules`, the course-ready checks and its tests.
  - The solution's sweep passes `curve`, and its switch point is between 2.25 and 2.35 V.
  - Its truth table fills both rows.
- [ ] **Step 2: Run.** *Expected:* FAIL.
- [ ] **Step 3: Write the lesson and its glossary entries.**
- [ ] **Step 4: Run** `tools/test.sh` and capture. *Expected:* all pass.
- [ ] **Step 5: Commit** `feat: Chapter 2 Lesson 7, the NOT gate`.

### Task 16: Help levels, phones and accessibility for Chapter 2

**Files:** `game/tests/hud/test_course_fit.gd`; fixes wherever they lead.

- [ ] **Step 1: Write the failing tests.** Extend the small-phone tests to Chapter 2 (360 × 640 and 640 × 360, Large text and Night):
  - every deck card of all seven lessons, and every new Meet card;
  - the try panels of Lessons 3–7, including Lesson 7's one-input truth table;
  - the process panels;
  - the curve plot;
  - the recaps.

  Also `test_help_change_mid_process`: Heavy to Off during a process lesson leaves it workable.
- [ ] **Step 2: Run.** *Expected:* whatever doesn't fit fails.
- [ ] **Step 3: Fix the layout** until they pass.
- [ ] **Step 4: Run** `tools/test.sh`. Capture every Chapter 2 screen at 360 × 640, 640 × 360, 390 × 844 and 1280 × 720, in light and Night, and look at them. *Expected:* all pass.
- [ ] **Step 5: Commit** `fix: Chapter 2 fits every screen and help level`.

### Task 17: The beginner read-through, release prep and the final review

**Files:**
- Modify:
  - `game/project.godot`: `application/config/version` = `0.4.0`;
  - `game/export_presets.cfg`: Android `version/code` = 4, `version/name` = `0.4.0`;
  - `game/tests/app/test_version.gd` and `test_export_presets.gd`;
  - `docs/release-notes.md`: v0.4.0 "Into Silicon";
  - `README.md`, `docs/itch-page.md` and its screenshots in `docs/itch/`.

- [ ] **Step 1: The beginner read-through.** A fresh reviewer, briefed as a curious beginner who has finished Chapter 1, reads Chapter 2's Lessons 1–7 and explains back what they learned. Fix every place they got lost; a fix that changes behavior comes with a test.
- [ ] **Step 2: The version tests fail first** (0.4.0, code 4). Then make them pass.
- [ ] **Step 3: Write** the release notes, README and itch text. Capture new screenshots from a clean save.
- [ ] **Step 4: Run** `tools/test.sh`, `tools/export.sh linux`, `tools/export.sh web` and `tools/check_dist.sh`. Then load the web build in Chromium at the title, a Chapter 2 deck card, a process lesson and Lesson 7's sweep. *Expected:* no console errors.
- [ ] **Step 5: Commit** `chore: v0.4.0 Into Silicon`.
- [ ] **Step 6: The final whole-branch review and one fix pass,** following the executing-plans skill.
