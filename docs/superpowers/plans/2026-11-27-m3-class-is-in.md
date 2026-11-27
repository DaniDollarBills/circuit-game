# Milestone 3 "Class Is In" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn Chapter 1 into a school-style course: Lesson 0 (the workbench), Meet the part, and Learn → Try it → Build it → Recap in every lesson, with the Notebook as a textbook. Chapter 1's parts, values, goals and physics stay exactly as they are.

**Architecture:**
- **Content.** Lesson content grows new typed fields on `LevelDef`: a learn deck, a Try it setup, step whys, recap points and questions. They're built with `LevelBuilder` and checked by `LessonRules` in the content tests.
- **Session.** `LevelSession` gets `learn` and `try` phases, replacing `intro`.
- **Try circuit.** While you try, `GameState` swaps in a separate try history, so trying never touches the build draft.
- **Presentation** adds a `Diagram` library (2D, animated, with still frames), `LessonDeck`, `MeetPartCard` (a 3D turntable in a SubViewport), `TryPanel`, `RecapCard`, `GestureHand`, `Spotlight`, and new Notebook tabs.

**Tech Stack:** Godot 4.7.2 and GDScript (static types). Tests run headless with `tools/test.sh [filter]`. Screenshots come from `tools/capture.sh` (Xvfb with Mesa).

**Spec:**
- `docs/superpowers/specs/2026-11-27-course-design.md` (this milestone);
- `docs/superpowers/specs/2026-11-26-circuit-game-design.md` (the main design, binding wherever the course design is silent).

## Global Constraints

- **Chapter 1 is unchanged.** Its parts, values, goals, tests and solutions stay as they are. `test_every_solution_passes` and `test_no_build_level_passes_at_start` pass untouched.
- **Text limits.** Every line of main-path text has at most 2 sentences and 30 words, with the existing `test_copy_limits` rule. That covers each card's text, analogy break, Go deeper line, worked-example step, poke, why, recap point, question and choice explanation.
- **Words.** Every technical word in new text has a two-layer glossary entry. The `test_glossary_terms_exist` scan reads every new field.
- **Sources.** Every history card, and every card that states a measured number, a date or a person, carries a source string that is a citation (`test_fact_sources_are_citations` rule).
- **Analogies** carry a `breaks` line.
- **Diagrams** each draw a still frame when Reduced motion is on.
- **Offline,** with no network use.
- **Screens.** Touch targets are at least 44 px. Large text, Night and Reduced motion apply. Everything works at 360 × 640 and up, in portrait and landscape, and in the Compatibility renderer.
- **Pure logic** (lesson data, rules, session, game state, recap templates, circuit diffs) touches no scene nodes and is tested headless.
- **Saves stay `VERSION 1`.** The new tables are optional. A v0.2.0 save loads, and every lesson a player has completed stays open.
- **Commits** end with this session's attribution lines.

## Review Focus

1. **A returning v0.2.0 player.** Their save has Lessons 1–9 completed and no Lesson 0.
   - Every completed lesson stays unlocked.
   - Opening a completed lesson starts on Build with the Lesson button. Nothing forces the deck on them.
   - Their badges are unchanged.
   - *Test:* Task 2, `test_old_save_keeps_lessons_open` and `test_completed_lesson_opens_on_build`.
2. **Leaving in the middle of Try it.** Going to the map, starting over, undoing past the try's start, or quitting during Try it never writes the try circuit into the build draft. Coming back resumes the build draft.
   - *Tests:* Task 2, `test_try_edits_never_touch_draft` and `test_leaving_during_try_keeps_draft`.
3. **A 360 × 640 phone in portrait, with Large text.**
   - The deck, Meet the part card, try panel and recap all fit on screen or scroll.
   - Every button is reachable and at least 44 px.
   - *Test:* Task 16, `test_course_cards_fit_small_phone`.
4. **Changing the help level in the middle of a lesson, and replays.**
   - Heavy to Off during Learn never leaves the lesson stuck.
   - The Lesson button always gets you back to Build.
   - *Test:* Task 16, `test_help_change_mid_learn`.
5. **Recap numbers when the player's passing circuit differs from the solution.**
   - For example, Lesson 2 passed with 220 Ω instead of 150 Ω.
   - The recap shows the player's real values, never `nan`, an empty slot or the solution's numbers.
   - *Test:* Task 7, `test_recap_uses_players_numbers`.

---

## Shared definitions (used across tasks)

**Card types:** `idea`, `analogy`, `worked`, `meet`, `control`, `real`, `history`, and `tour` (Lesson 0 only).

**Card dictionary:**
```
{type, text, mood: "happy"|"curious"|"wow"|"oops", diagram: String, deeper: String,
 source: String, breaks: String (analogy), steps: PackedStringArray (worked),
 part: String (meet: a PartIntros key), control: String (control: a diagram id),
 target: String (tour: "board"|"tray"|"battery"|"top_bar"|"column"|"hint")}
```

**Deck sequence:** a goals card, then `learn`, then a closing card ("Now let's try it" when the lesson has a Try it, otherwise "Now let's build it"). `LevelDef.deck_size()` is `learn.size() + 2`, or `0` when `learn` is empty.

**Phases:** `"learn" | "try" | "build" | "passed"`. `"intro"` is gone.

**Action flags:** `did:placed`, `did:moved`, `did:rotated`, `did:wired`, `did:deleted`, `did:undone`, `did:zoomed`, `did:panned`, `did:menu`, `did:hint`, `did:calculator`, `did:notebook`. The existing flags `datasheet:<id>`, `value:<id>`, `formula:<name>`, `selected:<id>` and `tested` stay.

**Readout quantities:** `mA` (current through a part), `V` (voltage across a two-pin part), `W` (power in a part), `reading` (a meter's display).

**Recap templates:** `{<part id>.<quantity>}`, using the quantities above plus `ohms`. For example, `{L1.mA}`, `{R1.ohms}`, `{R1.W}`, `{M1.reading}`.

**Part intro keys:** `battery`, `wire`, `resistor`, `resistor_1w`, `trimmer`, `led`, `switch`, `ammeter`, `voltmeter`.

---

### Task 1: Lesson data model, the learn phase, and validation

**Files:**
- Modify: `game/src/lessons/level_def.gd`, `game/src/lessons/level_builder.gd`, `game/src/lessons/level_session.gd`, `game/src/app/game_state.gd`, `game/src/app/game.gd`, `game/src/app/main.gd` (`--skip-intro` now skips learn and try), `game/src/screens/level_screen.gd` (shows learn cards as Pip lines until Task 4)
- Modify: all nine `game/src/content/ch1/l*.gd`: each `b.intro(text, mood)` becomes `b.idea(text, "", mood)`, keeping the text and mood
- Create: `game/src/lessons/lesson_rules.gd`
- Test: `game/tests/lessons/test_lesson_data.gd`, `game/tests/lessons/test_level_session.gd` (the intro tests become learn tests), `game/tests/content/test_content.gd` (`_lines` reads every new field), and any e2e test that walked the intro (`grep -rn '"intro"' game/tests`)

**Interfaces:**
- Produces, on `LevelDef`:
  - `learn_goals: PackedStringArray`
  - `learn: Array[Dictionary]`
  - `try_prompt: String`, `try_circuit: Circuit`, `try_tray: Array[Dictionary]`
  - `pokes: Array[Dictionary]` (`{text, check}`)
  - `readouts: Array[Dictionary]` (`{part, quantity}`)
  - `try_path: Array[Circuit]`
  - `recap: PackedStringArray`
  - `questions: Array[Dictionary]` (`{prompt, choices: [{text, correct: bool, why}]}`)
  - steps gain `why: String`
  - `func deck_size() -> int`
  - `func has_try() -> bool` (true when `try_prompt != ""`)
  - `kind` adds `"tutorial"`
- Produces, on `LevelBuilder`:
  - `learn_goals(goals: Array)`
  - `idea(text, diagram := "", mood := "curious", deeper := "", source := "")`
  - `analogy(text, breaks, diagram, deeper := "")`
  - `worked(text, steps: Array, source := "")`
  - `meet(part_key)`
  - `control(text, diagram)`
  - `real(text, diagram := "")`
  - `history(text, source)`
  - `tour(text, target, mood := "happy")`
  - `why(text)` (attaches to the last `step`)
  - `try_it(prompt)`
  - `try_part(...)`, `try_wire(...)` and `try_tray(...)` (same signatures as `part`, `wire` and `tray`)
  - `poke(text, check)`
  - `readout(part_id, quantity)`
  - `try_path_edit(edit: Callable)`: applies `edit(Circuit) -> Circuit` to the last path circuit and appends the result; the path starts at the try circuit
  - `recap(text)`
  - `question(prompt, choices: Array)`
- Produces, on `LevelSession`:
  - `card_index: int`
  - `start(level, auto: bool)`: auto with a deck → `"learn"`; auto with no deck but a Try it → `"try"`; otherwise `"build"`
  - `next_card(s, level)`: past the last card goes to `"try"` if the level has one, else `"build"`
  - `back_card(s)`
  - `skip_learn(s, level)`
  - removed: `intro_index`, `next_intro`
- Produces, on `GameState` and `Game`: `next_card()`, `back_card()`, `skip_learn()`, replacing `next_intro()`.
- Produces `LessonRules.problems(l: LevelDef) -> PackedStringArray`. It's empty when the lesson is fine. Task 1 checks:
  - card types are known;
  - an analogy has `breaks`;
  - `worked` has at least 2 steps;
  - `meet` has a `part`, and `control` has a `diagram`;
  - `tour` has a known target;
  - every question has exactly 3 choices, exactly one correct, and a non-empty `why` on each;
  - `learn_goals` has 0 or 2–3 entries;
  - every recap point is non-empty;
  - a `has_try()` lesson has at least one poke and a `try_path` of at least one circuit.

- [ ] **Step 1: Write the failing tests** in `test_lesson_data.gd`:
  - `test_builder_records_cards`: each helper produces its card with the given fields, and `deck_size()` is `learn.size() + 2`.
  - `test_why_attaches_to_last_step`.
  - `test_rules_flag_bad_question`: 2 choices, 2 correct, and a missing `why` each give one problem.
  - `test_rules_flag_analogy_without_breaks`.
  - `test_rules_flag_try_without_pokes`.
  - `test_try_path_applies_edits_in_order`.

  In `test_level_session.gd`, `test_intro_then_build` becomes:
  - `test_learn_then_build`: auto start → `learn`, then `deck_size()` nexts → `build`;
  - `test_auto_false_starts_on_build`;
  - `test_back_card_stops_at_zero`;
  - `test_skip_learn_to_build`.

  In `test_content.gd`, `test_every_level_follows_lesson_rules` asserts `LessonRules.problems(l).is_empty()` for every level.
- [ ] **Step 2: Run** `tools/test.sh lesson` and `tools/test.sh content`. Expected: FAIL, because the methods are missing.
- [ ] **Step 3: Implement** the fields, the builder helpers, `LessonRules`, and the session changes.
  - `GameState.start_level` passes `auto := true` for now; Task 2 adds the real rule.
  - Convert the nine levels' intros to idea cards.
  - The level screen shows `learn[card_index - 1]` as the Pip line, with Next (index 0 shows the goals line) until Task 4.
  - `main.gd`'s `--skip-intro` loops `skip_learn` and, from Task 2, `finish_try`.
  - Update every test that reads `intro`.
- [ ] **Step 4: Run** `tools/test.sh`. Expected: everything passes, including the e2e playthroughs.
- [ ] **Step 5: Commit** `feat: lesson data model and the learn phase`.

### Task 2: Course progress, the try phase, and the try circuit

**Files:**
- Modify: `game/src/save/progress.gd`, `game/src/lessons/level_session.gd`, `game/src/lessons/goals.gd`, `game/src/app/game_state.gd`, `game/src/app/game.gd`, `game/src/save/achievements.gd` (copy: "Finish every Chapter 1 lesson.")
- Create: `game/src/course/readouts.gd`
- Test: `game/tests/save/test_progress.gd`, `game/tests/lessons/test_level_session.gd`, `game/tests/lessons/test_goals.gd`, `game/tests/app/test_course_state.gd` (new)

**Interfaces:**
- Consumes Task 1.
- Produces, on `Progress`:
  - `lessons: Dictionary` (level id → `{learn?: int, try?: int, recap?: int}`) and `parts_seen: Dictionary` (key → int), both added to `TABLES` and validated in `from_dict`;
  - `mark_lesson(level_id, step, now)`;
  - `lesson_marks(level_id) -> Dictionary`;
  - `mark_part_seen(key, now) -> bool` (true when new);
  - `is_unlocked` also returns true when `completed.has(level_id)`.
- Produces, on `LevelSession`:
  - `poke_done: Array[bool]`;
  - `finish_try(s)`;
  - `reopen(s, level)`: to `"learn"` with `card_index = 0` when there's a deck, else to `"try"`;
  - in `update()`, when `phase == "try"`, pokes are checked with `Goals.evaluate` and latch in order: poke *i* can tick only after poke *i − 1*, and stays ticked.
- Produces, on `Goals`:
  - kind `"not"` (`{kind:"not", goal:{…}}`), which passes when the inner goal fails;
  - kind `"burnt"` (`{part}`), which passes when that part is burnt.
- Produces, on `GameState`:
  - `start_level` picks auto: help is `heavy`, `!progress.completed.has(id)`, and `!lesson_marks(id).has("learn")`;
  - `finish_try()`;
  - `reopen_lesson()`;
  - `current_tray() -> Array[Dictionary]`;
  - `trying() -> bool`;
  - `readouts() -> Array[Dictionary]` (`[{label, text}]`).
  - Entering `"try"` simulates `level.try_circuit` into its own `CircuitHistory`. Leaving puts the build history back.
  - `_save_draft` does nothing while trying, and `tray_used()` follows `current_tray()`.
  - Finishing the deck marks `learn`, finishing the try marks `try`, and passing marks a level complete as before.
- Produces, on `Game`: `finish_try()` and `reopen_lesson()`, which emit `changed`.
- Produces `Readouts.text(r: Dictionary, circuit: Circuit, sim: SimResult) -> String`, for example `"LED: 13.8 mA"`, `"R1: 0.11 W"`, `"R1: 4.99 V"`. A missing or floating part reads `"—"`.

- [ ] **Step 1: Write the failing tests:**
  - `test_course_state.gd`:
    - `test_first_visit_heavy_starts_on_learn`;
    - `test_light_help_starts_on_build`;
    - `test_completed_lesson_opens_on_build`;
    - `test_learn_then_try_then_build`;
    - `test_try_edits_never_touch_draft` (commit during try; the saved draft is unchanged; `finish_try` gives back the build circuit);
    - `test_undo_in_try_stays_in_try_circuit`;
    - `test_leaving_during_try_keeps_draft` (`start_level` of another lesson, then back, gives the build draft);
    - `test_reopen_keeps_build_circuit`;
    - `test_pokes_latch_in_order` (a two-poke try: "dark" then "lit"; lit first ticks nothing; dark then lit ticks both);
    - `test_readouts_follow_sim`;
    - `test_lesson_marks_recorded`.
  - `test_progress.gd`:
    - `test_lessons_and_parts_round_trip`;
    - `test_bad_lessons_table_rejected`;
    - `test_old_save_keeps_lessons_open` (a v0.2.0 save with L1–L9 completed: each of them is unlocked, and Lesson 0 is unlocked).
  - `test_goals.gd`: `test_not_goal` and `test_burnt_goal`.
- [ ] **Step 2: Run** `tools/test.sh course_state`, `progress` and `goals`. Expected: FAIL.
- [ ] **Step 3: Implement** the interfaces above.
- [ ] **Step 4: Run** `tools/test.sh`. Expected: all pass.
- [ ] **Step 5: Commit** `feat: course progress, the try phase and its own circuit`.

### Task 3: The diagram library and Lesson 1's diagrams

**Files:**
- Create:
  - `game/src/course/diagram.gd` (base class);
  - `game/src/course/diagrams.gd` (registry);
  - `game/src/course/diagrams/` (one script per diagram, or a few grouped by lesson);
  - `game/src/hud/hand_art.gd`.
- Modify: `game/src/lessons/lesson_rules.gd` (an unknown `diagram` id, or a `control` card's id, is a problem).
- Test: `game/tests/course/test_diagrams.gd`.

**Interfaces:**
- Produces `class_name Diagram extends Control`:
  - `var t: float`, which advances in `_process` unless `still`;
  - `var still: bool`, set from the `reduced_motion` setting;
  - `var night: bool`;
  - `func _paint(t: float, scale: float) -> void`, which subclasses override and which draws into a 400 × 220 design box centered and scaled to fit;
  - `var painted := 0`, a frame counter for tests;
  - minimum size 240 × 132.
- Produces `class_name Diagrams`:
  - `const IDS: PackedStringArray`;
  - `static func make(id: String, game: Game) -> Diagram`.
- Produces `class_name HandArt` with `static func draw(ci: CanvasItem, at: Vector2, mode: String, pressed: bool, scale: float)`, where `mode` is `"touch"` or `"mouse"`. Diagrams and Task 9's hand both draw with it.
- **Diagrams in this task:**
  - `charges_in_wire`: a wire full of charges that all move together while the battery pushes;
  - `battery_push`: + and − ends, with the push shown as arrows;
  - `loop_flow`: a loop with sparks moving from + round to −;
  - `loop_gap`: the same loop with a gap, and no sparks anywhere;
  - `current_direction`: a current arrow from + to − beside the electron drift going the other way, labeled.

  Use `Palette` colors and `DrawKit` primitives. Battery, resistor and LED symbols come from `PartArt.ops` through `DrawKit.draw_ops`.

- [ ] **Step 1: Write the failing tests:**
  - `test_every_id_makes_a_diagram`;
  - `test_diagrams_draw_at_phone_and_desktop_sizes`: each id in 240 × 132 and 640 × 352 boxes; after 3 frames `painted > 0` and no errors;
  - `test_still_when_reduced_motion`: `t` stays put over 5 frames;
  - `test_rules_flag_unknown_diagram`.
- [ ] **Step 2: Run** `tools/test.sh diagram`. Expected: FAIL.
- [ ] **Step 3: Implement** the base class, the registry, `HandArt`, the five diagrams, and the rules check.
- [ ] **Step 4: Run** `tools/test.sh`, then `tools/capture.sh` with a small diagram gallery scene (`game/src/course/diagram_gallery.tscn`, every id in a grid) at 1280 × 720. Look at each diagram.
- [ ] **Step 5: Commit** `feat: diagram library and the first lesson's diagrams`.

### Task 4: The Learn deck

**Files:**
- Create: `game/src/hud/lesson_deck.gd`.
- Modify:
  - `game/src/screens/level_screen.gd`: the deck replaces the Pip intro line in `"learn"`; a **Lesson** `IconButton` (book icon, added to `HudIcons`) sits beside the hint button and is visible in `build` and `passed` when `deck_size() > 0` or `has_try()`; `dev_show("deck:<n>")` is added;
  - `game/src/hud/hud_icons.gd`.
- Test: `game/tests/hud/test_lesson_deck.gd`.

**Interfaces:**
- Consumes Tasks 1–3.
- Produces `class_name LessonDeck extends PanelContainer`:
  - signals `next_pressed`, `back_pressed`, `skip_pressed`;
  - `var read_only := false` (the Notebook's mode in Task 12: no Skip, the closing card reads "Close");
  - `func show_card(level: LevelDef, index: int) -> void`;
  - `func card_kind() -> String` (`"goals"`, `"closing"`, or a card type);
  - `func body_text() -> String` (plain text, for tests);
  - `func steps_shown() -> int`.
- **Each card has:**
  - a header with the lesson's number and title;
  - progress dots;
  - a body with the diagram, then the text (`HudText.put`, so new words get their cards);
  - for an analogy, a "Where it breaks:" line;
  - for history, a source line;
  - a **Go deeper** toggle when `deeper` is set;
  - Back, Next and **Skip lesson**.
- **A worked card** reveals one more step per Next. When every step shows, Next goes on.
- **A meet card** shows a placeholder line, "Meet the <title>", until Task 5.
- **Placement.** The deck sits over the bench, centered. Its width is `min(560, area)`, and `CardFit.wrap` and `CardFit.fit` make it scroll on short screens. The guide bubble hides while the deck shows.

- [ ] **Step 1: Write the failing tests:**
  - `test_deck_opens_on_goals_card`: it lists the `learn_goals`;
  - `test_next_and_back_walk_cards`;
  - `test_worked_steps_reveal_one_per_next`;
  - `test_skip_goes_to_try_or_build`;
  - `test_analogy_shows_breaks`;
  - `test_go_deeper_toggles`;
  - `test_history_shows_source`;
  - `test_card_words_become_new_words`: a glossary term in a card is marked seen;
  - `test_lesson_button_reopens_deck`.

  An e2e test, `test_learn_deck_by_tapping`, opens Lesson 1 and taps Next until the phase leaves `learn`.
- [ ] **Step 2: Run** `tools/test.sh lesson_deck`. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`, then capture `--open=level:ch1.light-it-up --show=deck:1` at 1280 × 720 and 390 × 844, and look at both.
- [ ] **Step 5: Commit** `feat: the Learn deck`.

### Task 5: Meet the part

**Files:**
- Create:
  - `game/src/course/part_intros.gd`;
  - `game/src/hud/meet_part_card.gd`;
  - the cutaway diagrams `led_inside`, `resistor_inside`, `aa_cell_inside`, `switch_inside` and `meter_inside` in the library.
- Modify:
  - `game/src/hud/context_menu.gd`: an **About** action;
  - `game/src/screens/level_screen.gd`: unseen-part cards, the About action, the deck's meet card, and `dev_show("meet:<key>")`;
  - `game/src/hud/lesson_deck.gd`: the meet card embeds the compact MeetPartCard;
  - `game/src/lessons/lesson_rules.gd`: a meet `part` must be a known key.
- Test: `game/tests/hud/test_meet_part.gd`, `game/tests/content/test_content.gd`.

**Interfaces:**
- Consumes Tasks 1–4. It also uses `PartModels.build(Part)`, `StudioEnvironment.build`, `PartArt.ops` and `WireMesh` for the wire.
- Produces `class_name PartIntros`:
  - `const KEYS`;
  - `static func key_for(p: Part) -> String`: a `resistor` with `watts >= 1` is `resistor_1w`, `adjustable` is `trimmer`, and otherwise it's the kind;
  - `static func get_intro(key) -> Dictionary`, holding:
    - `title`;
    - `does` (one sentence);
    - `legs: [{pin, text}]`;
    - `where`;
    - `spec` (`{text, source}`);
    - `inside` (a diagram id);
    - `deeper`.
- Produces `class_name MeetPartCard extends PanelContainer`:
  - `static func make(game: Game, key: String, compact := false) -> MeetPartCard`;
  - `func spin(deg: float)`;
  - `func leg_label_texts() -> PackedStringArray`;
  - `func look_inside(on: bool)`;
  - `func showing_inside() -> bool`.
- **The turntable.** A `SubViewportContainer` with `own_world_3d` holds the part on a soft studio backdrop. Dragging spins it. Leg labels are 2D chips at the projected pin positions. The viewport updates only while the card is visible.
- **Unseen parts.** When the build phase begins, at any help level, every key on the board or in the tray that isn't in `parts_seen` gets a card, one at a time. Closing a card marks its key seen. A meet card in the deck marks its key when it shows.

**Content:** write the intros for all nine keys, per the course design §6.3. Each intro's `spec` cites the game's datasheet value, with the same source as the datasheet line. Each `legs` list matches `Catalog.pin_names(kind)`.

- [ ] **Step 1: Write the failing tests:**
  - `test_every_ch1_part_has_intro`: every part and tray item in every ch1 level and try maps to a key with an intro, and its `legs` cover the kind's pins;
  - `test_meet_card_shows_model_and_legs`;
  - `test_look_inside_switches_to_cutaway`;
  - `test_unseen_parts_shown_once_any_help` (help `off`: opening Lesson 1 shows cards for its unseen parts; reopening shows none);
  - `test_about_action_opens_card`;
  - `test_rules_flag_unknown_part_key`.
- [ ] **Step 2: Run** `tools/test.sh meet_part`. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`. Capture `--show=meet:led` and `--show=meet:battery` at 1280 × 720 and 390 × 844, and check them in the Compatibility renderer too (`--rendering-method gl_compatibility`).
- [ ] **Step 5: Commit** `feat: Meet the part cards with a 3D turntable`.

### Task 6: Try it

**Files:**
- Create: `game/src/hud/try_panel.gd`.
- Modify:
  - `game/src/screens/level_screen.gd`: in `"try"`, the column shows the TryPanel instead of the goals, checklist and Test; the hint button is hidden; `dev_show("try")` is added;
  - the editor and tray follow `current_tray()`.
- Test: `game/tests/hud/test_try_panel.gd`.

**Interfaces:**
- Consumes Tasks 1, 2 and 4.
- Produces `class_name TryPanel extends PanelContainer`:
  - `signal ready_pressed`;
  - `func refresh(s: GameState)`;
  - `func poke_rows() -> Array[Dictionary]` (`[{text, done}]`);
  - `func readout_texts() -> PackedStringArray`.
- **The panel shows:**
  - "Try it" as its title;
  - the prompt;
  - the pokes, each ticking when done;
  - the live readouts;
  - **I'm ready to build**, always enabled.
- **Undo, redo and start over** work on the try circuit.

- [ ] **Step 1: Write the failing tests:**
  - `test_try_panel_lists_pokes_and_readouts`;
  - `test_pokes_tick_as_you_build` (commit the try path's circuits through `game`; the rows tick);
  - `test_ready_goes_to_build`;
  - `test_try_hides_goals_and_hints`;
  - `test_start_over_in_try_resets_try_circuit`.
- [ ] **Step 2: Run** `tools/test.sh try_panel`. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`.
- [ ] **Step 5: Commit** `feat: Try it`.

### Task 7: Recap

**Files:**
- Create:
  - `game/src/course/recap_text.gd`;
  - `game/src/hud/recap_card.gd`.
- Modify: `game/src/screens/level_screen.gd`. The RecapCard replaces `_start_outro`, `_pages`, `_show_page` and `_next_page`, and `dev_show("recap")` is added.
- Test: `game/tests/course/test_recap_text.gd`, `game/tests/hud/test_recap_card.gd`, `game/tests/content/test_content.gd`.

**Interfaces:**
- Consumes Tasks 1 and 2, and `Readouts`.
- Produces `class_name RecapText` with `static func fill(text: String, circuit: Circuit, sim: SimResult) -> String`:
  - a template with a missing part or a non-finite value fills `"—"`;
  - `mA` has 1 decimal, `W` 2 decimals, `V` 2 decimals, and `ohms` is formatted by `Catalog.format_ohms`.
- Produces `class_name RecapCard extends PanelContainer`:
  - signals `next_lesson`, `to_map`, `read_again`;
  - `func show_recap(level: LevelDef, outcome: SimOutcome, next_id: String)`;
  - `func point_texts() -> PackedStringArray`;
  - `func choose(question: int, choice: int)`;
  - `func explanation_text(question: int) -> String`.
- **The card shows, in order:**
  1. Pip's first `outro` line;
  2. "What you learned" with the filled points;
  3. each question, with its 3 choice buttons. Choosing one shows that choice's `why` and marks it ✓ or "Not quite". You can choose again; nothing is saved or scored;
  4. the `facts` as history lines with their sources;
  5. the actions **Next lesson** (when there is one), **Map** and **Read again**.
- **Light and Off help:** the questions are folded behind "Check yourself".
- The lesson's `recap` mark is set when the card opens.

- [ ] **Step 1: Write the failing tests:**
  - `test_fill_known_circuit` (Lesson 1's solution gives `{L1.mA}` → "13.8 mA");
  - `test_fill_missing_part_is_dash`;
  - `test_recap_uses_players_numbers` (Lesson 2 passed with 220 Ω shows its own mA, not 19.9);
  - `test_choice_shows_why`;
  - `test_recap_never_blocks` (Next lesson is enabled with no answers);
  - `test_light_help_folds_questions`.
  - In the content tests, `test_every_recap_template_resolves` fills every point against each lesson's solution outcome and finds no `"—"` and no stray braces.
- [ ] **Step 2: Run** `tools/test.sh recap`. Expected: FAIL.
- [ ] **Step 3: Implement.** Each lesson's existing outro lines become its first recap points until content tasks rewrite them. The first outro line stays as Pip's line.
- [ ] **Step 4: Run** `tools/test.sh`.
- [ ] **Step 5: Commit** `feat: the Recap card`.

### Task 8: Why? on steps and mistakes

**Files:**
- Create: `game/src/course/mistake_why.gd`.
- Modify:
  - `game/src/hud/steps_checklist.gd`: each step with a `why` gets a small "Why?" toggle;
  - `game/src/hud/guide_bubble.gd`: a **Why?** action that appends the why text in place;
  - `game/src/screens/level_screen.gd`: mistake lines get the Why? action.
- Test: `game/tests/course/test_mistake_why.gd`, `game/tests/hud/test_hud.gd`.

**Interfaces:**
- Produces `class_name MistakeWhy` with `static func for_message(m: String) -> String`. It's keyed by `LevelScreen.MISTAKES` prefixes, and each why is one or two sentences of physics:
  - **Pop! / burned:** current above the part's absolute maximum heats it until it fails.
  - **Short circuit!:** almost no resistance, so the battery's 1 Ω is all that limits the current.
  - **The LED is backwards:** an LED is a diode and only conducts from anode to cathode.
  - **Careful:** above 20 mA wears the LED out.

- [ ] **Step 1: Write the failing tests:**
  - `test_every_mistake_prefix_has_why`;
  - `test_checklist_why_toggle`;
  - `test_guide_why_expands`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`.
- [ ] **Step 5: Commit** `feat: Why? on steps and mistakes`.

### Task 9: Action flags, the gesture hand and the spotlight

**Files:**
- Create:
  - `game/src/course/circuit_diff.gd`;
  - `game/src/app/input_mode.gd`;
  - `game/src/hud/gesture_hand.gd`;
  - `game/src/hud/spotlight.gd`.
- Modify:
  - `game/src/app/game_state.gd`: `commit` sets `did:*` from the diff, and `undo` sets `did:undone`;
  - `game/src/app/main.gd`: `_input` feeds `InputMode`;
  - `game/src/screens/level_screen.gd`: zoom, pan, menu, hint, calculator and Notebook set their flags.
- Test: `game/tests/course/test_circuit_diff.gd`, `game/tests/hud/test_gesture_hand.gd`, `game/tests/app/test_course_state.gd`.

**Interfaces:**
- Produces `CircuitDiff.actions(before: Circuit, after: Circuit) -> PackedStringArray`, containing any of:
  - `placed`: a new part;
  - `moved`: the same part id at a new position;
  - `rotated`: the same id with a new `rot`;
  - `wired`: a new wire;
  - `deleted`: a part or wire gone.
- Produces `InputMode`:
  - `static var mode := ""`, which starts as `"touch"` on Android and iOS, and in a web build on a touch screen, and as `"mouse"` otherwise;
  - `static func note(event: InputEvent)`.
- Produces `class_name GestureHand extends Control`, which ignores the mouse:
  - `func play(gesture: String, from: Vector2, to := Vector2.ZERO, key := "")`, where `gesture` is one of `tap`, `drag`, `long_press`, `pinch`, `scroll`, `key`;
  - it loops every 1.6 s until `stop()`;
  - `func hand_position() -> Vector2`, for tests;
  - `mode` follows `InputMode`;
  - Reduced motion shows the start and end positions with an arrow instead of moving.
- Produces `class_name Spotlight extends Control`:
  - `func show_rect(r: Rect2)`;
  - it dims everything except `r`, with a rounded cutout;
  - `_has_point` is false inside the hole, so taps reach the control underneath.

- [ ] **Step 1: Write the failing tests:**
  - `test_diff_actions` (one case per action, plus "move and wire in one commit");
  - `test_commit_sets_did_flags`;
  - `test_undo_sets_did_undone`;
  - `test_hand_drag_moves_along_path` (the position at t = 0, the middle and the end);
  - `test_hand_mode_follows_last_input`;
  - `test_spotlight_passes_input_in_hole`;
  - e2e `test_zoom_and_pan_set_flags`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`.
- [ ] **Step 5: Commit** `feat: action flags, the gesture hand and the spotlight`.

### Task 10: Lesson 0 and the course map

**Files:**
- Create: `game/src/content/ch1/l0_workbench.gd`.
- Modify:
  - `game/src/content/levels.gd`: Lesson 0 goes first in `_CH1`;
  - `game/src/screens/level_screen.gd`: tour cards place the deck away from the spotlighted target, the tutorial's current step plays its demo with the GestureHand, and there's a **Skip Lesson 0** action;
  - `game/src/screens/map_screen.gd`;
  - `game/src/content/chapters.gd` (copy);
  - `game/tests/content/test_content.gd`: the count is 10, `test_three_hint_tiers` exempts `tutorial`, and solution tests skip the tutorial.
- Test: `game/tests/content/test_lesson0.gd`, `game/tests/e2e/test_lesson0_playthrough.gd`, `game/tests/hud/test_map.gd` (new, or extend the existing map tests).

**Interfaces:**
- Consumes Tasks 1–9. A step's dictionary gains `demo: {gesture, from, to?, key?}`. Targets are:
  - `{tray: i}`;
  - `{part: id | "placed"}` (`"placed"` is the first unlocked part);
  - `{pin: "B1:pos"}`;
  - `{wire: "placed"}`;
  - `{button: "undo" | "hint"}`;
  - `{board: [x, y]}`.
- Produces `LevelScreen.demo_target(spec: Dictionary) -> Vector2`.
- **Lesson 0's content:**
  - id `ch1.workbench`, kind `tutorial`, title "Your workbench";
  - learn goals: the bench, placing and wiring, and getting help;
  - six `tour` cards: `board`, `tray`, `battery`, `top_bar`, `column`, `hint`;
  - the board holds B1 (battery) and L1 (LED), both locked, and the tray has one 220 Ω resistor;
  - the steps are 2–10 of the course design §6.2, each checked by its `did:*` or `datasheet:L1` flag, with a demo;
  - the goal is `{kind:"all", goals: <every step check>}`;
  - one hint: "Do what the moving hand shows. You can skip any step.";
  - recap: three points and one question ("How do you make a wire?").
- **Skip Lesson 0** marks it complete with no star.
- **The map** labels lessons "Lesson N · Title", with N as the index in the chapter, so Lesson 0 is first.
  - Each lesson's line is its `summary`.
  - Its marks are 📖 learn, ✋ try, ✓ build, 💬 recap and ★. If the fonts lack those glyphs, use the existing icon set instead.
  - The locked tooltip says "Finish Lesson N to unlock this one."

- [ ] **Step 1: Write the failing tests:**
  - `test_lesson0_first_and_open`;
  - `test_skip_lesson0_unlocks_lesson1`;
  - `test_lesson0_steps_tick_with_real_input`, an e2e test with a real tray drag, part drag, R key, pin-to-pin drag, long-press then Delete, Ctrl+Z, scroll, pan drag, tapping the LED, and tapping the hint, ending in `passed`;
  - `test_demo_targets_resolve` (every step's demo resolves to an on-screen point at 1280 × 720 and 390 × 844);
  - `test_map_numbers_lessons_from_zero`;
  - `test_map_shows_course_marks`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`. Capture Lesson 0's tour and steps at both sizes.
- [ ] **Step 5: Commit** `feat: Lesson 0, your workbench, and the course map`.

### Task 11: Lesson 1 as a full course lesson (the slice is complete)

**Files:**
- Modify:
  - `game/src/content/ch1/l1_light_it_up.gd`;
  - `game/src/content/glossary.gd` (new words);
  - `game/tests/content/test_content.gd`: a `COURSE_READY` list holds `ch1.workbench` and `ch1.light-it-up`, and `test_course_lessons_complete` asserts, for each lesson on it:
    - 2–3 learn goals and at least 5 cards;
    - a Try it, unless it's the tutorial;
    - a why on every step;
    - 3 recap points and 1–2 questions;
    - every glossary term known.
- Test: `game/tests/e2e/test_lesson1_course.gd`.

**Lesson 1 content (copy written within the limits; the order is fixed):**
- **Goals:** why electricity needs a loop; what the battery, wire, resistor and LED do.
- **Cards:**
  1. `idea` with `charges_in_wire`: "Electricity is charges on the move. Metal wires are already full of them."
  2. `idea` with `battery_push`: "A battery pushes charges from its + end, round the circuit, back into its − end."
  3. `idea` with `loop_flow`: "A circuit is a complete loop."
  4. `idea` with `loop_gap`: "A gap anywhere stops everything." Go deeper: a break at any point stops the current everywhere at once.
  5. `meet battery`.
  6. `meet wire`.
  7. `meet resistor`.
  8. `meet led`.
  9. `idea` with `current_direction`: "We draw current flowing from + to −."
  10. `history`: Volta's pile, 1800. Source: A. Volta, Philosophical Transactions of the Royal Society 90, 403–431 (1800).
- **Try it:**
  - The finished L1 loop: B1, R1 220 Ω and L1.
  - Prompt: "Here's a working loop. Break it, then fix it."
  - Pokes: "Delete a wire: the light goes out" (`not led_lit L1`), then "Undo it: the light comes back" (`led_lit L1`).
  - Readout: `L1 mA`.
  - `try_path`: delete w1, then the original.
- **Whys on the three steps:** + is where the push starts; the resistor keeps the LED's current safe; the loop has to get back to −.
- **Recap:**
  - "Electricity only flows around a complete loop."
  - "Your loop carried {L1.mA}."
  - "The resistor keeps the LED's current safe."
- **Questions:**
  - "What happens if one wire in the loop is removed?" The choices are "everything stops" (correct), "the LED gets dimmer", and "only parts after the gap stop".
  - "Which end does current leave the battery from, the way we draw it?" The choices are "+" (correct), "−", and "both ends".

- [ ] **Step 1: Write the failing tests:**
  - `COURSE_READY` with both lessons, and `test_course_lessons_complete`;
  - e2e `test_lesson1_full_rhythm`: open Lesson 1 fresh at Heavy, tap through the deck and the meet cards, do the try pokes with real input, press Ready, build the solution with real input, see the RecapCard, answer a question, and press Next lesson to reach Lesson 2.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Write the content** and any new glossary entries.
- [ ] **Step 4: Run** `tools/test.sh`. Capture the whole Lesson 1 rhythm at 390 × 844, 844 × 390 and 1280 × 720.
- [ ] **Step 5: Commit** `feat: Lesson 1 as a full course lesson`.

**Checkpoint S (the slice):**
- A fresh reviewer reviews Tasks 1–11 (`review-package` from BASE to HEAD).
- A second fresh reviewer, briefed as a curious 12-year-old with no electronics background, reads Lesson 0's and Lesson 1's text and diagrams from the captures. They then explain back §2's list for those lessons and flag every place they got lost.
- Fix the Critical and Important findings, each with a test.
- Then ask the owner to try the slice, offering to update the browser version, and carry on with Task 12.

### Task 12: The Notebook as textbook

**Files:**
- Modify:
  - `game/src/hud/notebook_sheet.gd`: tabs **Lessons**, **Parts**, **Words** and **Badges**;
  - `game/src/content/chapters.gd`: `SUMMARY: Dictionary` gets Chapter 1's 5–7 summary lines;
  - `game/src/screens/level_screen.gd` and `game/src/screens/map_screen.gd`: both host the deck and the meet card from the Notebook.
- Test: `game/tests/hud/test_notebook.gd`.

**Interfaces:**
- Produces, on `NotebookSheet`:
  - `func tab_ids() -> PackedStringArray`;
  - `func lesson_rows() -> PackedStringArray` (lessons with a `learn` mark, or completed);
  - `func part_rows() -> PackedStringArray`;
  - `signal open_lesson(level_id: String)` and `signal open_part(key: String)`.

  The host opens a `LessonDeck` with `read_only`. Its recap points are filled from the solution outcome, with the label "Example numbers".
- **Chapter summary.** Once every Chapter 1 lesson is complete, the Lessons tab starts with a **Chapter 1 summary** row.

- [ ] **Step 1: Write the failing tests:**
  - `test_four_tabs`;
  - `test_lessons_tab_lists_learned_lessons`;
  - `test_read_only_deck_has_no_skip`;
  - `test_parts_tab_opens_meet_card`;
  - `test_chapter_summary_after_last_lesson`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`.
- [ ] **Step 5: Commit** `feat: the Notebook becomes the textbook`.

### Task 13: Diagrams for Lessons 2–9

**Files:**
- Create: the diagram scripts.
- Modify: `game/src/course/diagrams.gd`.
- Test: `game/tests/course/test_diagrams.gd` covers every id automatically. Add `test_truth_table_fills_from_states`.

**Diagrams:**
- `led_one_way`: an arrow passes one way and a backwards arrow is blocked.
- `voltage_budget`: a 5 V bar split into 2 V for the LED and 3 V for the resistor.
- `current_vs_resistance`: current falls as resistance rises, with the 20 mA and 30 mA lines and a marker.
- `water_analogy`: a pump, a pipe loop and a narrow section, with pressure, flow and squeeze labels.
- `ohm_triangle`: V over I × R, with the covered letter showing the rearrangement.
- `unit_ladder`: A ↔ mA (×1000) and Ω ↔ kΩ.
- `meter_placement`: the current meter in the loop and the voltage meter across a part.
- `switch_states`: open and closed, with the drawbridge picture.
- `bits`: on/off becomes 1/0.
- `series_paths`: one path through two switches.
- `parallel_paths`: two side-by-side paths.
- `truth_table`: rows light up as states are seen. It has `func mark(row: int)`, and Try it drives it.
- `short_path`: current floods the easy path and the battery heats up.
- `power_heat`: watts against a rating bar, with the ¼ W and 1 W ratings.
- `electron_vs_current`: arrows going opposite ways.
- `copper_lattice`: atoms with free electrons drifting.
- `control_dial`, `control_switch` and `control_test`: New control demos drawn with `HandArt`.

- [ ] **Step 1: Write the failing test** `test_truth_table_fills_from_states`. The other ids are covered once they're in `IDS`, which fails until each exists.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `tools/test.sh`. Capture the gallery and look at every diagram.
- [ ] **Step 5: Commit** `feat: diagrams for Lessons 2 to 9`.

### Task 14: Lessons 2–5 as course lessons

**Files:**
- Modify: `l2_pop.gd`, `l3_push_and_flow.gd`, `l4_on_and_off.gd`, `l5_both.gd`, `glossary.gd`, and `test_content.gd` (`COURSE_READY` adds these four).
- Test: content tests; `test_l5_truth_table_try` (the try path's four states mark all four rows).

**Exact content decisions** (copy written within the limits):

| Lesson | Cards (in order) | Try it | Readouts and pokes | Recap templates | Questions (correct first) |
|---|---|---|---|---|---|
| **2 Pop!** | `led_one_way` idea (an LED is a light-making diode; current goes in at the longer leg); `voltage_budget` idea (the LED takes about 2 V of the 5 V); idea (with no resistor, only the battery's 1 Ω limits the current); `real` (reading a datasheet: 2.0 V at 20 mA, 30 mA absolute maximum); `worked` "(5 V − 2.0 V) ÷ 0.020 A = 150 Ω" in 4 steps, with 20 mA = 0.020 A; idea (E12 standard values: pick the nearest standard value); `history` LED 1962 (the existing fact and source) | B1 and L1 placed; tray 330 Ω | Pokes: "Wire the LED straight to the battery: pop!" (`burnt L1`), then "Undo, then put the 330 Ω in the loop" (`led_lit L1`). Readout: `L1 mA`. `try_path`: wire B1+→L1 anode and L1 cathode→B1−, then the original, then the 330 Ω loop. | "An LED needs a resistor to limit its current." / "R = (5 V − 2.0 V) ÷ 20 mA = 150 Ω." / "Your LED ran at {L1.mA}." | Why does an LED need a resistor? (to limit current / to make it brighter / to change its color). Which leg goes toward +? (the longer leg / the shorter leg / either) |
| **3 Push and flow** | `water_analogy` analogy (breaks: charge isn't used up, a cut wire spills nothing, and the push travels near light speed while electrons drift slowly); `unit_ladder` idea (volts, amps, ohms; 1 mA = 0.001 A); `ohm_triangle` idea; `worked` "I = 5 V ÷ 500 Ω = 0.010 A = 10 mA" (Go deeper: the battery's 1 Ω and the meter's 0.1 Ω make it 9.98 mA); `meet ammeter`; `meet voltmeter`; `meter_placement` idea; `meet trimmer`; `control` `control_dial`; `history` Ohm 1827 (the existing source) | The L3 meter loop, starting at 1 kΩ | Pokes: "Set the dial to 1 kΩ" (`meter_reads M1 0.005 ± 0.0002`), then "Now 2 kΩ" (`meter_reads M1 0.0025 ± 0.0002`). Readouts: `M1 reading`, `R1 ohms`. | "Voltage pushes, current flows, resistance slows it." / "V = I × R." / "Your dial: {R1.ohms} gave {M1.reading}." | Double the resistance: the current… (halves / doubles / stays the same). Where does a current meter go? (in the loop / across a part / anywhere) |
| **4 On and off** | `meet switch`; `switch_states` idea (closed means connected); `bits` idea (on/off is 1/0, a bit); `control` `control_switch`; `control` `control_test`; `history` "bit" 1947 (the existing source) | The L4 loop with S already in it | Pokes: "Turn it off" (`led_dark L1`), then "Turn it on" (`led_lit L1`). Readout: `L1 mA`. | "A switch opens and closes the loop." / "Closed means current flows." / "On and off are a bit: 1 and 0." | A closed switch means… (current flows / current stops / the LED breaks) |
| **5 Both** | `series_paths` idea (one path: the same current through every part); `truth_table` idea (a table lists every case); `real` (two-key safes and two-hand machine guards); idea (two switches in a row light the LED only if both are closed) | Two switches in series, ready-made | The `truth_table` diagram in the try panel marks each seen state. Pokes: "Try all four cases" (`all` four `ui_flag`s `row:0`–`row:3`, set by the panel as it sees each state). Readout: `L1 mA`. | "Series: one path, so both must be closed." / "That's AND." / "Your LED drew {L1.mA} with both closed." | Two switches in series: which cases light the LED? (only both closed / either one closed / always) |

- [ ] **Step 1: Write the failing tests:** add the four lessons to `COURSE_READY`, plus `test_l5_truth_table_try`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Write the content.** The TryPanel drives a `truth_table` diagram when the lesson's try has two switches labeled A and B. It sets `row:<n>` ui flags from the switch states it sees.
- [ ] **Step 4: Run** `tools/test.sh` and capture each lesson's deck, try and recap at 390 × 844.
- [ ] **Step 5: Commit** `feat: Lessons 2 to 5 as course lessons`.

### Task 15: Lessons 6–9 as course lessons, and the chapter summary

**Files:**
- Modify: `l6_either.gd`, `l7_short_circuit.gd`, `l8_too_hot.gd`, `l9_inside_the_wire.gd`, `glossary.gd`, `chapters.gd` (the summary lines), and `test_content.gd` (`test_all_lessons_course_ready`: `COURSE_READY` equals every ch1 id).

| Lesson | Cards | Try it | Pokes and readouts | Recap templates | Questions |
|---|---|---|---|---|---|
| **6 Either** | `parallel_paths` idea (side-by-side paths with the same voltage across each); idea (either closed switch completes the loop); `truth_table`; `real` (a doorbell with a front and a back button: either one rings it) | Two switches in parallel | All four cases, as in Lesson 5. Readout: `L1 mA`. | "Parallel: two paths, so either one works." / "That's OR." / "Each closed switch alone gave {L1.mA}." | Two switches in parallel: which cases light the LED? (either or both closed / only both / never) |
| **7 Short circuit!** | `short_path` idea (a path from + to − with almost no resistance); idea (current floods the easiest path, so the LED's branch is skipped); `worked` "I = 5 V ÷ 1 Ω ≈ 5 A; P = I² × R = 25 W inside the battery"; `real` (fuses and breakers, the existing fact and source) | A working L1-style loop. Wires come from pins, so the tray stays empty. | Pokes: "Add a wire from + straight to −" (`not no_short`), then "Undo it" (`no_short` and `led_lit L1`). Readout: `B1 W` (the battery's heat). | "A short skips your parts and floods the battery." / "Only the battery's 1 Ω limits it: about 5 A." / "Your fixed circuit runs at {L1.mA}." | Why does a shorted battery get hot? (huge current through its own resistance / the LED heats it / wires store heat) |
| **8 Too hot to handle** | `power_heat` idea (P = V × I, in watts); idea (resistors turn energy into heat); `meet resistor_1w`; `worked` "I = 5 V ÷ 48 Ω = 0.104 A; P = I² × R = 0.104² × 47 = 0.51 W"; `real` (hair dryer, the existing fact and source) | B1; tray 220 Ω ¼ W and 47 Ω ¼ W | Pokes: "Put the 220 Ω across the battery: 0.11 W, fine" (`resistor_watts 0.09–0.13`), then "Swap in the 47 Ω: 0.51 W scorches it" (`burnt` on the 47 Ω part). Readout: `R W` for each placed resistor. | "Power is volts × amps, in watts." / "A part burns above its rating." / "Your resistor made {R1.W} of heat." | A ¼ W resistor asked for 0.5 W will… (burn / stay cool / glow like an LED) |
| **9 Inside the wire** | `copper_lattice` idea (copper atoms in a crystal, with free electrons); idea (the push makes them all drift); `electron_vs_current` idea (electrons go − to +, the opposite of the current arrows); idea (the drift is about 0.2 mm a minute here, while the push moves near light speed; the existing source); `history` electron 1897 (J. J. Thomson, Philosophical Magazine 44, 293 (1897)); `history` Franklin named + and − (B. Franklin, letter to P. Collinson, 25 May 1747) | The L9 loop | Poke: "Switch to electron flow, then back" (`ui_flag did:electron_flow`, set by a toggle on the try panel that flips the existing `electron_flow` setting). Readout: `L1 mA`. | "Copper is full of free electrons." / "They drift slowly; the push travels fast." / "Your wire carried {L1.mA}." | Which way do electrons drift? (− to +, against the arrows / + to −, with the arrows / they don't move) |

**Chapter 1 summary** (5–7 lines): loops; V, I and R with Ohm's law; LEDs need resistors; switches and bits; series is AND and parallel is OR; shorts and power ratings; electrons drift.

- [ ] **Step 1: Write the failing tests:** add the four lessons to `COURSE_READY`, plus `test_all_lessons_course_ready`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Write the content.** The power and lattice figures above are rechecked against the simulator (L8: run the try path and read `part_watts`) and their sources.
- [ ] **Step 4: Run** `tools/test.sh`, and capture the decks, tries and recaps.
- [ ] **Step 5: Commit** `feat: Lessons 6 to 9 as course lessons, and the chapter summary`.

### Task 16: Help levels, replays, accessibility and phone fit

**Files:**
- Modify: whatever the tests show: `level_screen.gd`, `lesson_deck.gd`, `meet_part_card.gd`, `try_panel.gd`, `recap_card.gd`.
- Test: `game/tests/hud/test_course_fit.gd`, `game/tests/app/test_course_state.gd`.

- [ ] **Step 1: Write the failing tests:**
  - `test_course_cards_fit_small_phone`: at 360 × 640 portrait and 640 × 360 landscape, with Large text and Night, the deck (every card type), the Meet the part card, the try panel and the recap card stay inside the screen. Every button is at least 44 px and reachable by scrolling.
  - `test_help_change_mid_learn`: Heavy to Off during learn leaves the deck showing, and Skip still reaches build. Off then Lesson reopens it.
  - `test_reduced_motion_course`: every diagram is still, and the hand shows an arrow.
  - `test_turntable_sleeps_when_hidden`: the viewport's update mode is disabled while the card is hidden.
- [ ] **Step 2: Run.** Expected: FAIL wherever the layout breaks.
- [ ] **Step 3: Fix the layout and behavior** until the tests pass.
- [ ] **Step 4: Run** `tools/test.sh`. Capture every course screen at 360 × 640, 640 × 360, 390 × 844 and 1280 × 720, in light and Night, and look at them.
- [ ] **Step 5: Commit** `fix: course screens fit every screen and help level`.

### Task 17: The beginner read-through, release prep and the final review

**Files:**
- Modify:
  - `game/project.godot` (`application/config/version` = `0.3.0`);
  - `game/export_presets.cfg` (Android `version/code` = 3, `version/name` = `0.3.0`);
  - `game/tests/app/test_version.gd` and `test_export_presets.gd`;
  - `docs/release-notes.md` (v0.3.0 "Class Is In");
  - `README.md`;
  - `docs/itch-page.md`, plus new screenshots in `docs/itch/`.

Steps:
- [ ] **Step 1: The beginner read-through.** A fresh reviewer, briefed as a curious beginner, reads Lessons 2–9 and explains back §2's list. Fix every place they got lost; when the fix is behavior, it comes with a test.
- [ ] **Step 2: The version tests fail first**: `test_version` expects 0.3.0 and `test_export_presets` expects code 3. Then make them pass.
- [ ] **Step 3: Write** the release notes, README and itch text. Re-capture the screenshots.
- [ ] **Step 4: Run** `tools/test.sh`, then `tools/export.sh linux` and `tools/export.sh web`, `tools/check_dist.sh`, and the web build in Chromium with no console errors.
- [ ] **Step 5: Commit** `chore: v0.3.0 Class Is In`.
- [ ] **Step 6: The final whole-branch review and one fix pass,** following the executing-plans skill.
