# Milestone 3 decisions

Every decision taken on the owner's behalf while building Milestone 3 ("Class Is In"), in the order it was taken, each with what it costs if it turns out wrong, and then the review findings left for later. Copied from the build ledger, which was scratch space. Milestones 1 and 2's are in [m1-decisions.md](m1-decisions.md) and [m2-decisions.md](m2-decisions.md).

- Plan: [plans/2026-11-27-m3-class-is-in.md](plans/2026-11-27-m3-class-is-in.md)
- Design: [specs/2026-11-27-course-design.md](specs/2026-11-27-course-design.md), with [specs/2026-11-26-circuit-game-design.md](specs/2026-11-26-circuit-game-design.md) wherever it is silent

Each ruling reads: what was decided — why — what it costs if wrong. "(set aside)" marks a behavior the final reviewer set aside as outside the plan, ruled on here.

## Rulings (97)

### Before Task 1: where tasks meet

- T1→T2: T1 moves phases in LevelSession (pure); T2 swaps circuits on entering/leaving "try". Ruling: GameState wraps every phase-changing call (next_card, skip_learn, finish_try, reopen_lesson, start_level) and runs one `_enter_phase(was, now)` that swaps the try history in or out — cost if wrong: a phase change that bypasses GameState would show the wrong circuit; tests cover each entry point.
- T1→T3: LessonRules' diagram check. Ruling: an empty `diagram` is allowed (cards without a picture, and T1's converted intro lines); a non-empty id must be in Diagrams.IDS — cost if wrong: none.
- T2→T7: Readouts and RecapText both format part values. Ruling: one formatter — `Readouts.value(part_id, quantity, circuit, sim) -> float` and `Readouts.format(quantity, v) -> String`; RecapText fills templates with them — cost if wrong: none (one place to change).
- T5→T10: T5 shows Meet the part cards for unseen parts when Build begins, at any help level; Lesson 0 has a battery, an LED and a resistor. Ruling: lessons of kind "tutorial" show no unseen-part cards (Lesson 1's deck introduces those parts) — cost if wrong: a player who skips Lesson 1's deck at Light help still gets the cards in Lesson 1's build, so nothing is lost.
- T1→T7: converted outro lines. Ruling: until a lesson's content task, its recap points are its outro lines after the first, and the first outro line is Pip's line, so nothing shows twice — cost if wrong: a temporary thin recap in lessons not yet rewritten.
- T6→T14: the truth table in Try it. Ruling: T14 extends TryPanel (a `truth_table` readout kind fed by switches A and B), not T6 — cost if wrong: none.

### Task 1

- until Task 4's deck, the learn phase shows its cards as Pip lines — "In this lesson: <goals or summary>", each card's text, then "Now let's build it!" — so every lesson stays playable — cost if wrong: two extra Pip lines per lesson for three tasks.
- test_new_word_card_on_first_sight_only and test_new_word_cards_shown_with_help_off look for "led" instead of "electricity" — the first card is now the goals card, so "LED" shows first; what the tests guard (a card on first sight only, at every help level) is unchanged — cost if wrong: none.
- try wires default to unlocked and try parts to locked (LevelBuilder.try_wire/try_part) — Try it is for poking at wires, and its parts stay put — cost if wrong: a try that needs a movable part passes locked := false.

### Task 2

- leaving the deck marks "learn" whether it was read to the end or skipped, and leaving Try it marks "try" either way — a skipped deck isn't forced again on the next visit; the Lesson button reopens it — cost if wrong: a player who skipped by accident must tap Lesson to see it.
- reopening the lesson after passing returns to "build" (not "passed") when Try it ends; the pass is already saved and isn't announced twice — cost if wrong: a lesson with tests needs Test pressed again to show it passed.
- during Try it, LevelSession.update ticks pokes only and leaves the build's goal results alone; the goals panel is hidden while trying (Task 6) — cost if wrong: none.
- test helpers (test_hud, test_phone_layout, test_wire_zoom, test_game_state, main.gd --skip-intro) now finish Try it as well as skip learn — lessons gain Try its from Task 11 — cost if wrong: none.

### Task 3

- HandArt moves to Task 9, where the gesture hand first uses it under a test — no production code without a failing test that needs it — cost if wrong: none (Task 13's control demos come after Task 9).
- Diagram.symbol() recolors the part art's outside-tile text (a resistor's value, a switch's label, a meter's reading) to the theme's ink — PartArt draws them in day ink, unreadable on the night card — cost if wrong: none.
- the five Lesson 1 diagrams live in one script (diagrams/loop_diagrams.gd) that draws by id — the plan allowed grouping by lesson — cost if wrong: none.

### Task 4

- while the deck shows, the build's tray and column are hidden — on a phone the goals column competed with the deck for the top of the screen (capture t4-deck-phone-0); the lesson gets the stage, and building brings them back — test_lesson_has_the_stage_to_itself RED→GREEN — cost if wrong: a player can't glance at the goals mid-lesson (Skip or the last card shows them).
- the Lesson button sits in the bottom row left of Test (or Hint), icon-only under 420 px in portrait; the portrait scale bar now re-checks its room every frame — cost if wrong: none.
- Levels.lesson_number counts from 0 when a chapter opens with a tutorial and from 1 otherwise, so Lesson 1 is "Lesson 1" before and after Lesson 0 arrives — cost if wrong: none.
- the level screen's tray already follows GameState.current_tray() (planned for Task 6) — the tray had to be touched here anyway — cost if wrong: none.

### Task 5

- a part card's spec cites a real source when it states a fact about the world (IEC 60086-2, ASTM B258, IEC 60062, IEC 60115-1, Schubert, Horowitz & Hill), and "This part's datasheet (tap the part to read it)" when it restates the game part's own datasheet (the trimmer's range, the meters' burden and input) — the game's datasheet rows carry no sources to copy — cost if wrong: three spec lines would need outside citations for values that are the game's models.
- unseen-part cards come up in Try it as well as Build (any help level, never in a tutorial) — a player who skips the deck meets the parts on the try bench first — cost if wrong: none.
- the wire's card builds its own jumper-wire model (wires aren't catalog parts); "wire" is met only through a deck card — cost if wrong: a player who skips Lesson 1's deck never gets the wire card (it stays in Notebook → Parts once Task 12 lands... only if seen; the About menu works on parts, not wires).
- a sixth cutaway, trimmer_inside (track and wiper), joins the five planned — the trimmer isn't built like a fixed resistor — cost if wrong: none.
- E2E.skip_intro also closes Meet the part cards with their close buttons, as a player would — the cards correctly cover the bench the first time — cost if wrong: none.

### Task 7

- until a lesson has its own recap points, RecapCard shows its outro lines after the first (the first is Pip's cheer), as the pre-flight ruled — done in RecapCard._point_sources rather than by editing nine content files twice — cost if wrong: none.
- dev_show("recap") marks the solution's parts as met before passing, so the screenshot isn't covered by a part card — dev hook only — cost if wrong: none.
- tests that read Pip's outro through the guide bubble (test_start_over_after_passing_builds_again, test_play_l1_by_mouse, test_every_word_defined_on_first_sight) now read the recap card — the outro pages are gone by design — cost if wrong: none.

### Task 8

- only the checklist's current step shows its Why? — the column is 300 px wide and portrait shows only the current step anyway — cost if wrong: a player can't read a past step's why without reopening the lesson.

### Task 9

- InputMode ignores a finger's emulated mouse events and mouse moves under 2 px, so a tap on a touch screen never flips the hand to a pointer — cost if wrong: a jittery mouse could flip it back to touch for one demo.
- EditorLayer gains a view_moved signal (zoomed/panned) for the flags — the editor had no signal for view changes — cost if wrong: none.

### Task 10

- a tutorial keeps its tray, column and Hint in view while its deck shows (other lessons hide them, Task 4) — the tour spotlights them — test_tutorial_keeps_its_tools_in_view — cost if wrong: none.
- Lesson 0 has ten steps (one per control), one hint and no Try it; the content tests allow up to ten steps for a tutorial and one hint — cost if wrong: none.
- Skip Lesson 0 sits at the top of the column; it marks Lesson 0 done with no star and opens Lesson 1 — cost if wrong: a player who skips by mistake can replay Lesson 0 from the map.
- tests about motion, touch, navigation and saving open Lesson 1 with ignore_lock (it now waits for Lesson 0 on a fresh save); playthroughs mark Lesson 0 done, and the every-word playthrough reads Lesson 0's tour then presses Skip, as a new player might — cost if wrong: none.
- the Lesson 0 playthrough places the resistor by tap-then-tap (the demo shows a drag; both count as placing, and tap-tap is what the existing playthroughs drive reliably) and right-clicks the wire halfway along it; the in-game wire demo points there too — cost if wrong: none.

### Task 11

- Lesson 1's resistor step says why without implying order ("The resistor limits the current all the way round the loop") — in a series loop the order of parts doesn't change the current — cost if wrong: none.
- Lesson 1's outro becomes the cheer "You made light!"; its "About 14 milliamps" line moves to the recap as {L1.mA}, the player's own number — cost if wrong: none.
- tests that assumed Lesson 1 goes straight from the deck to building now expect its Try it in between — cost if wrong: none.

### Task 12

- the Notebook opens on its Lessons tab (the textbook first); opening a lesson or part from it closes the Notebook and shows a Textbook overlay (a read-only deck with its own place, or a part card) — cost if wrong: a player returns to the Notebook with one more tap.
- the chapter summary's seven lines are written here (Chapters.SUMMARY); Task 15 may refine them — cost if wrong: none.

### Checkpoint S

- the glossary test's "4 × AA cells" now links "cell" (test_render_unit_symbols_after_numbers updated) — the unit-symbol rule it guards (no "amp" for AA, no link for switch "A") is unchanged — cost if wrong: none.
- Lesson 1's deck stays 10 cards (12 pages with the goals and closing cards) against the spec's "about 4–8" — the owner asked for more and better explanation; each card is one idea and Skip is always there — cost if wrong: a longer first lesson.
- Lessons 2–9's stand-in copy (e.g. Lesson 2's "150 Ω is exactly right here" shown to a 220 Ω passer) is rewritten in Tasks 14–15 — cost if wrong: none if those land before release.
- plan defect carried to Task 15: recap templates name parts by id, and a tray part's id depends on placement order, so Lesson 8's "{R1.W}" could read a burnt ¼ W resistor — Task 15 names the part the template means by role (or tests other passing circuits) — cost if wrong: a wrong number in one recap line.
- auto-play keys on the learn mark only; every lesson with a Try it has a deck (test_course_lessons_complete) — no change — cost if wrong: a deckless lesson would replay its Try it.
- kept as designed (reviewer declined to judge): map marks as ✓/○ words; burns in Try it count toward stats and Magic Smoke; returning players meet parts on Build (now closable everywhere); the tour's spotlight holds back the top bar; Start over ticks did:deleted; no keyboard control for the deck — cost if wrong: small, each.

### Task 13

- the truth table's mark is mark(row: int, lit: bool), not the plan's mark(row) — the picture can't know what the LED did; Try it reports what it saw, so one table serves AND (Lesson 5) and OR (Lesson 6) — cost if wrong: none, one more argument.
- on a Learn card the truth table shows the four cases with "?" for the LED and a highlight walking the rows; Try it fills in the answers — predict, then test — cost if wrong: the card shows no answers until Try it.
- the series and parallel loops (and the switch demo) include the 220 Ω resistor, which the plan's descriptions leave out — Lesson 2 teaches that an LED loop needs one — cost if wrong: none.
- in the water picture the flow has one speed all round the loop and slows everywhere as the narrow pipe squeezes; faster water in the narrow part (true of water) would suggest current changes along a series loop — cost if wrong: a less literal water picture.
- the copper crystal says "speeds not to scale" (electrons zip about far faster, and drift far slower, than shown); every other moving picture of charge says "sped up" — cost if wrong: none.
- the gallery takes --ids= to show a few pictures at once (thirty in one grid are too small to judge) — cost if wrong: none.

### Task 14

- the game state notes Try it's switch cases (row:<n> flags, with the LED's state) and the try panel shows them, where the plan had the panel set the flags — same behavior, testable without a screen, and the content test can walk it — cost if wrong: none.
- Lesson 3's Try it starts the dial at 1.5 kΩ (the plan: 1 kΩ) so "Set the dial to 1 kΩ" needs a turn — cost if wrong: none.
- Lesson 5's third recap line has no {L1.mA}: the player's switches may be open when they finish, which would read "0.0 mA with both closed" — "Both closed, the loop is complete, just like Lesson 1's" — cost if wrong: one recap line without the player's number.
- Lesson 3's analogy breaks where it really does (a cut wire spills nothing; the push races near light speed while electrons drift), dropping the plan's "charge isn't used up", which is true of water in a closed loop too — cost if wrong: none.
- the current-vs-resistance picture goes on Lesson 2's datasheet card (the plan's table placed it nowhere) — cost if wrong: none.
- Lesson 5 has a fifth card, Boole's 1854 logic of AND and OR (course lessons need at least five) — cost if wrong: none.
- worked() takes a Go deeper (Lesson 3's 9.98 mA) and real() a source (the two-hand control standard, ISO 13851) — cost if wrong: none.
- history cards that would repeat their lesson's fact tell a neighbouring story instead (Ohm the schoolteacher; Shannon's bits, 1948), so the recap doesn't say it twice — cost if wrong: none.
- New word cards for a lesson card's words still pop over the card's picture on a phone (Milestone 1's behavior), and Lesson 5's try panel scrolls on a portrait phone — both carried to Task 16's phone fit — cost if wrong: a covered picture until the card is closed.

### Task 15

- Lesson 7's readout is the battery's "heat" (current² × its 1 Ω), a new readout quantity — the plan's "B1 W" is the power it delivers, about 0 W in a short — test_battery_heat_in_a_short — cost if wrong: none.
- (the plan defect carried from checkpoint S) recap templates can name a part by kind ({resistor.W}: the unburnt one doing the most), since a tray part's id depends on the order it's placed — test_recap_names_a_part_by_kind — cost if wrong: none.
- readouts for parts not on the bench are hidden (Lesson 8 names R1 and R2, whichever are placed), readouts use the parts' own names ("Battery pack", "Trimmer"), and resistors are told apart by value ("220 Ω resistor: 0.11 W") — test_readouts_skip_parts_not_on_the_bench — cost if wrong: none.
- Lesson 8's second poke checks that something burned, not "R2 burnt", for the same id-order reason — cost if wrong: none (only the 47 Ω can burn there).
- Lesson 6's third recap line has no number (the player's switches may be open at the end): "One switch or both, the LED gets the same current" — cost if wrong: one line without the player's number.
- Lesson 7 has a fifth card, never join a real battery's + and − (course lessons need five; it's the safety point) — cost if wrong: none.
- Lesson 8's real-life card is a toaster's glowing wires; the hair dryer stays the recap's fact, so it isn't said twice — cost if wrong: none.
- Lesson 9's Try it has two pokes (the electrons' way, then the current's way) ticked by a try-panel button that flips the Electron flow setting; its path is one unchanged step, since only the button acts — test_electron_flow_toggle — cost if wrong: none.
- "Joseph John Thomson" is spelled out on the card (the copy rule counts "J." as a sentence's end); the source keeps "J. J. Thomson" — cost if wrong: none.
- Lesson 6's Try it puts switch B at (4, −9), clear of switch A in 3D (the build's ghost layout stays as it was) — cost if wrong: none.
- the chapter summary written in Task 12 already says what the lessons teach; unchanged — cost if wrong: none.

### Task 16

- test_course_cards_fit_small_phone is four tests (deck, meet, try, recap), so a failure names its card — cost if wrong: none.
- test_help_change_mid_learn and test_turntable_sleeps_when_hidden passed from the start (help changes never pulled the deck; SubViewportContainer already stops a hidden viewport); kept as pins for Review Focus 3 — cost if wrong: none.
- with --open, Night and Large text hold only when asked for, so screenshots come out the same every time (development only) — cost if wrong: none.

### Task 17

- the repeat test allows Lesson 9's Franklin and Thomson history cards, which tell the story Lesson 1 only hints at in a Go deeper (a callback, on purpose); within a lesson no source repeats, and no history card or fact is retold later — cost if wrong: a player who opened Lesson 1's Go deeper meets the names again in Lesson 9.
- the calculator's power working keeps leaving out the battery's 1 Ω (0.53 W); Lesson 8's Go deeper says so — cost if wrong: none, both are about half a watt.
- Lesson 3's Try it keeps framing the board (pins stay tappable); the meters' readings show in the Try it panel instead — cost if wrong: the meters' own displays are off screen until the player pans.
- the store screenshots are made from a clean save (every part and word met, no saved circuits), since captures share one save file and an earlier capture's finished circuit came back — cost if wrong: none (development only).
- nine store screenshots (four new course shots: a lesson card, Meet the part, Try it with its truth table, the recap); the coast shot is dropped to keep the page short — cost if wrong: the page loses one title view.

### The final review

- Lesson 0's recap is about the controls, with no circuit to quote; the numbers test leaves tutorials out — cost if wrong: none.
- kept Task 5's ruling (:33/:98: the wire is met only through Lesson 1's deck) — Lesson 1's cards and Lesson 0's tour teach the wire — cost if wrong: a returning player who never opens Lesson 1's deck has no wire card in Notebook → Parts.
- kept Task 2's ruling (:17: reopening the lesson after passing returns to build); its side effect is M7, deferred — cost if wrong: in Lessons 4–6, Test must be pressed again after reading the lesson again.
- the deferred note on save strictness (:100) was wrong: an unknown lesson step makes a save count as corrupt, unlike settings; the tolerance must ship before a newer version writes a new step — deferred as M14.
- (set aside by the reviewer) "passed" staying passed after later edits, Milestone 1's rule, stands; its new effect on the recap is fixed (I3) — cost if wrong: none.
- (set aside) the landscape tray column kept when the tray is empty, Milestone 2's layout, stands — cost if wrong: about 128 px of board on a landscape phone in lessons without a tray.
- (set aside) Magic Smoke for Lesson 2's instructed burn, and Try it burns counting in stats, stand (an earlier recorded ruling) — cost if wrong: a badge for a burn the lesson asked for.
- (set aside) map marks as words, not glyphs, stand (checkpoint S) — cost if wrong: cosmetic.
- (set aside) per-frame layout work and Levels.all() rebuilding levels stand until measured on a device — cost if wrong: frame time on a low-end phone.
- (set aside) Franklin's letter cited as 25 May 1747 stands (the manuscript's date; the printed version is dated 11 July 1747) — cost if wrong: a citation date off by seven weeks.
- (set aside) IEC 62133-2 as the citation for a phone battery surviving a short stands — cost if wrong: the standard requires surviving a short, not a particular circuit.
- (set aside) Shannon 1938 read as series = AND stands (the standard reading) — cost if wrong: none.
- (set aside) the Meet card's 4× MSAA viewport stands; the browser smoke test (software WebGL2) showed it drawing, with 0 console errors, but no real phone was tried — cost if wrong: a slow Meet card on a low-end phone.
- (set aside) the --open development flag rewriting the saved Night and Large text stands (development only) — cost if wrong: none for players.
- (set aside) the store screenshots and Android signing and install are outside a code review — cost if wrong: none.
- (set aside) the glossary's electron constants without a source (Milestone 1 content) stand, with M12's sourcing — cost if wrong: two numbers without a citation.

## Deferred minor findings (23)

Found by the reviews and left for later; none blocks play.

- **checkpoint S:** board readouts are tiny on a phone, a lit LED's glow is faint, and on a portrait phone the battery pack sits off-screen (its leads show) — Milestone 1's framing.
- **checkpoint S:** text behind the course cards peeks out around them (Lesson 0's column, the recap's goals) — a light scrim would hide it.
- **checkpoint S:** grey captions are small (they pass 4.5:1).
- **checkpoint S:** per-frame work — deck/recap/Meet card resize twice a frame, Levels.lesson_number rebuilds lessons per deck render, chips find_child per frame, one Sky bake per Meet card.
- **checkpoint S:** Go deeper or a worked step resets the deck's scroll (the 360 px width was fixed in Task 16).
- **checkpoint S:** the turntable spins twice as fast on touch (emulated mouse events aren't filtered).
- **checkpoint S:** the wire's Meet card is only reachable from Lesson 1's deck.
- **checkpoint S:** two doc comments disagree with the code (readouts.gd's floating part; game_state.gd's readouts() keys).
- **checkpoint S:** the part icon on Meet and datasheet cards draws its value text in day ink on the night card (tiny at that size).
- **checkpoint S:** at true proportions the Meet card's new LED is small in its stage (its legs are three times its height); Look inside shows the details large.
- **Task 17:** the bench's value tags are small on a phone (about 6 px at 390 × 844) and some sit behind 3D parts; the Try it panel shows the readings at full size.
- **Task 17:** Lesson 8 frames the true-size battery pack, so the board is small beside it, fiddly on a phone.
- **Task 17:** the LED graph's moving marker passes over its "20 mA" label for part of its sweep.
- **Task 17:** in Lesson 2, Pip's offer of the calculator comes up under the LED's datasheet when reading it ticks the step (the card the player opened stays on top).
- **final review:** M5 Lesson 3's fact says "Your loop's 10 mA through 0.5 kΩ", though a pass can be 480–520 Ω.
- **final review:** M6 Try it's zoom and flags carry into the build (in Lesson 9, zooming in during Try it passes the build at once).
- **final review:** M7 returning from Try it clears the build's test report (Lessons 4–6: press Test again).
- **final review:** M8 the resistor cutaway's stripes say 150 Ω on the 220 Ω resistor's card.
- **final review:** M9 on small phones Lesson 5's truth table sits below the fold of the Try it column (it scrolls).
- **final review:** M12 three lines state facts without a source: why I stands for current (Ampère), copper's atom spacing, and "a few billionths of a second".
- **final review:** M13 Lesson 0's hint says "You can skip any step"; the deck's "Skip lesson" goes to Try it.
- **final review:** M14 an unknown lesson step in a save is treated as corrupt; tolerate it before a newer version writes one.
- **final review:** Lesson 9 says the push travels at "nearly the speed of light"; in insulated wire it's a large fraction of it (about two-thirds), as the course design words it.
