# Circuit — Chapter 1 as a course, and Chapter 2's structure

> Written 2026-11-27, after Milestone 2 shipped (v0.2.0). It adds a milestone before "First Chip" and changes how every chapter teaches. The main design, `2026-11-26-circuit-game-design.md`, still holds everywhere this document doesn't say otherwise.

---

## 1. What the owner asked for

In the owner's words:

- "Upgrade the first chapter to be more teaching so it is easier for beginners (don't simplify the actual course, just make more and better explanations). And then begin structure and completing another chapter."
- What was hard: "what are the different pieces that are given to you, how do you move them, what do they do, and why does everything work. Basically I just need it explained to me like it's a course in school."

The owner approved this shape ("Sounds good, start"):

- **Lesson 0: Your workbench.** Before Level 1, Pip walks you through every control and you do each one yourself, with a moving hand showing each gesture. You can't fail. Later controls (the resistor's dial, the Test button) are shown the same way when they first appear.
- **Meet the part.** The first time a piece appears, a card shows it large and turnable: what it is, what it does, which leg is which, its circuit symbol, and where you'd find one in real life. Parts you meet go into the Notebook.
- **Every level becomes a class in four steps:**
  - **Learn:** a short illustrated lesson, one idea per card, with moving pictures and a worked example with real numbers.
  - **Try it:** a ready-made circuit to poke at, break safely, and see why.
  - **Build it:** today's level, whose steps and mistake messages also say *why*.
  - **Recap:** what you learned in three points, using your own circuit's numbers. Then one or two quick questions: wrong answers get explained, with no grades, and they never block you.
- **The Notebook becomes the textbook:** you can re-read any lesson, part or word.
- **The real content stays exactly as it is.** Chapter 2 uses the same format from the start.

## 2. Intent

Chapter 1 works, but it assumes too much. A beginner meets a bench full of objects with no introduction, gets two or three one-line messages from Pip, and is asked to build. They can't tell what the pieces are, how to handle them, what each one does, or why the circuit behaves as it does.

Pip's messages and the hints only tell you *what to do*. The fix is to *teach* the way a good school course does:
1. Say what you'll learn.
2. Explain one idea at a time with pictures.
3. Work an example.
4. Let you try it.
5. Let you do it yourself.
6. Sum up and check.

None of this changes what the player builds or how real it is.

**Success:** someone with no background plays Lesson 0 to Lesson 9 and can then explain, in their own words:
- what a battery, wire, resistor, LED, switch, current meter and voltage meter are and do;
- how to place, move, turn, wire and delete parts;
- why a circuit must be a loop, and what voltage, current and resistance are;
- Ohm's law, why an LED needs a resistor, and how to work out its value;
- series versus parallel, short circuits, power and heat, and what moves inside a wire.

## 3. Goals, non-goals, anti-goals

**Goals**
- Every piece, control and idea is taught before it's needed, in the order a school course would teach it.
- Each lesson runs in the same rhythm: goals, Learn, Try it, Build it, Recap. That makes it predictable, like chapters in a textbook.
- Everything taught can be found again in the Notebook.
- The format is a reusable system, so Chapter 2 and every later chapter is written in it.

**Non-goals (this milestone)**
- No change to Chapter 1's parts, values, goals, physics or tests.
- No voice narration. It would need recorded speech; text, pictures and motion carry the teaching.
- No grades, scores or failing a lesson.
- No Chapter 2 content yet (that's the next milestone; see §9).

**Anti-goals** (a failure even if it technically works)
- Walls of text. Every card keeps the main-path limit of at most 2 sentences and about 30 words. Pictures and motion do the heavy lifting.
- A lesson that blocks you, can't be skipped on a replay, or repeats itself every visit.
- Questions that feel like a test: no score, every answer explained, never required.
- Analogies presented as the truth. Every analogy card also says where the analogy breaks.
- Motion that lies about physics. Animated values come from the simulation or from sourced constants. A slowed-down or sped-up animation says so.

## 4. Constraints (from the main design)

- Works offline, with no network requests.
- Phone and desktop, portrait and landscape, touch and mouse, 44 px touch targets.
- Large text, Night, Reduced motion and Patterns all apply to the new screens. Reduced motion shows still diagrams with arrows.
- Every visual works in the Compatibility renderer (the browser version).
- Every technical word on screen has a glossary entry. The automatic scan covers the new text.
- Every fact (a measured number, a date, a person) carries a source in the game data.
- Pure logic stays separate from presentation. Content is typed GDScript data built with a builder and checked by tests.

## 5. Approaches considered

| Approach | Trade-offs | Verdict |
|---|---|---|
| **A. Illustrated cards only** (2D diagrams in the game's pastel style) | Fast to make, crisp on every renderer and screen, and matches the Schematic look. But you never see the real parts or the real bench while learning. | Not alone. |
| **B. Lessons acted out on the real 3D workbench** (camera moves, parts animate on the bench) | Matches the realistic look. But it's slow to build and heavy on phones and the browser. Ideas like voltage or charge have no real-life look to show. | Not alone. |
| **C. A mix (chosen)** | Learn cards use 2D animated diagrams for ideas. Meet the part shows the real 3D model on a turntable, plus a "Look inside" cutaway drawing. Try it and Build it happen on the real bench. Each medium does what it's best at. | **Chosen.** |

Content is **data, not hand-built scenes**. A lesson lists its cards, and each card names a diagram from a shared library. Tests check the text limits, words, sources and that every named diagram exists. That keeps lessons cheap to write and Chapter 2 cheap to add.

## 6. The course format

### 6.1 The course map

- The map shows a chapter as a course outline: **Lesson 0 · Your workbench**, then **Lesson 1 · Light it up** through **Lesson 9 · Inside the wire**. The old "levels" are now called lessons everywhere a player sees.
- Each lesson shows its one-line learning goal, for example "Why electricity needs a loop".
- Each lesson shows its progress: Learn, Try it, Build it, Recap, and its star.
- Lesson 0 unlocks first. Lesson 1 unlocks when Lesson 0 is done, or skipped once.

### 6.2 Lesson 0: Your workbench

A hands-on tour. Each step names one control, and a moving hand shows the gesture on the real screen. The step ticks off by itself once the player does it. Nothing can go wrong, and every step can be skipped.

1. **The bench.** A spotlight tour of what's where:
   - the board (a perforated prototyping board on a cutting mat);
   - the parts tray;
   - the battery pack and meters beside the board;
   - the top bar (map, start over, undo and redo, calculator, Notebook, settings);
   - the goals and steps column;
   - the hint button.
2. **Place a part:** drag a resistor from the tray onto the board, or tap it, then tap the board.
3. **Move it:** drag it somewhere else.
4. **Turn it:** use the R key, or long-press (right-click) and choose Rotate.
5. **Wire two pins:** drag from one metal dot to another. Wires always go pin to pin.
6. **Delete:** tap the wire, then long-press (right-click) and choose Delete, or press the Delete key.
7. **Undo it:** use the undo button or Ctrl/Cmd+Z.
8. **Zoom and look around:** pinch or scroll to zoom, and drag empty space to pan.
9. **Read a part:** tap a part to open its datasheet, the real spec sheet engineers use.
10. **Get help:** the lightbulb for hints, the calculator for formulas, and the Notebook for words.

The hand shows a finger on touch screens and a pointer with the mouse. It follows the device's last input, and is the finger by default on phones. The same hand demo appears in later lessons as a **New control** card the first time a lesson needs a new control:
- the resistor's dial (Lesson 3);
- flipping a switch and the Test button (Lesson 4).

### 6.3 Meet the part

- **When:** the first time a part kind appears in any lesson, on the board or in the tray. The card comes in the Learn deck, before you build. It's always available afterwards through the part's long-press menu ("About this part") and in the Notebook. Like New word cards, it shows at every help level, once.
- **What the card shows:**
  - The **real 3D part on a turntable**: drag to spin it, and the legs are labeled.
  - Its name, and one line on **what it does**.
  - **Which leg is which.** For example, the LED's longer leg is + (anode), and the flat spot on its rim marks − (cathode).
  - Its **circuit symbol**, as engineers draw it.
  - **Where you'd find one** in real life.
  - One key number from its datasheet, explained.
  - **Look inside:** a labeled cutaway drawing, such as the LED's tiny chip and reflector cup, the resistor's carbon film, or an AA cell's layers.
- **Chapter 1 parts:**
  - the battery pack (4 × AA in a holder);
  - the jumper wire;
  - the resistor (¼ W, the 1 W kind, and the adjustable trimmer);
  - the LED;
  - the switch;
  - the current meter;
  - the voltage meter.
- Every part you've met is kept in the **Notebook → Parts** tab.

### 6.4 Every lesson: Learn → Try it → Build it → Recap

**Learn** is a deck of about 4–8 cards with Back and Next, progress dots, and a Skip button that's always there.
- It opens with **"In this lesson you'll learn"** and two or three goals.
- It closes with **"Now let's try it"**.

Card types:

| Card | What it is |
|---|---|
| Idea | One idea: an animated diagram and at most 2 sentences. |
| Analogy | A picture analogy plus a line that says where it breaks. |
| Worked example | A formula solved one step per tap, with real numbers and units. |
| Meet the part | §6.3. |
| New control | §6.2's hand demo for one control. |
| In real life | Where you meet this idea every day. |
| History | A dated fact with its people and its source (the old "fact" lines move here). |

Any card can add a **Go deeper** line with the precise, expert detail, the way New word cards add "More precisely".

**Try it** is a ready-made circuit on the real bench, separate from the build. It comes with:
- a prompt ("Turn the dial and watch the current");
- one to three suggested pokes that tick off when done ("Break the loop", "Fix it");
- a live readout of the one or two values that matter, such as the LED's milliamps or a resistor's watts, straight from the simulation.

A Try it uses only controls the player has already been taught.

The simulation is real, so breaking things is allowed and Undo brings them back. "I'm ready to build" is always available. The try circuit is never saved as your draft.

**Build it** is the existing level, unchanged in goals and checks. Two additions:
- Each checklist step gets a short **Why?** line.
- Each mistake message (backwards LED, pop, short circuit, burn) gets a **Why?** that explains the physics in one or two sentences.

**Recap** follows the pass:
- **What you learned:** three points, at least one using your own circuit's numbers ("14 mA flowed around your loop"). The numbers come from the passed simulation.
- **One or two questions:** three choices each. Every choice has its own explanation, shown when tapped. There's no score, the answers aren't saved, and "Next lesson" is always there.
- **The history card,** if the lesson has one.

The current outro lines are folded into the recap.

### 6.5 First visits, replays and help levels

- **First visit at Heavy help** (the default): Learn plays, then Try it, then Build, then Recap.
- **Replays, and Light or Off help:** the lesson opens straight on Build. A **Lesson** button reopens Learn and Try it whenever you want.
- **Questions:** at Light or Off, the recap's points still show, and the questions sit behind one tap.
- **What's saved per lesson:** which steps you've seen. The map uses it, and it decides what plays automatically.
- **Meet the part and New word cards** appear once each, at every help level.

### 6.6 The Notebook becomes the textbook

Its tabs:
- **Lessons:** every Learn deck you've opened, re-readable in full, with its recap points.
- **Parts:** every Meet the part card.
- **Words:** as now.
- **Badges:** as now.

A chapter is complete when its last lesson is built. Its Lessons tab then gets a one-page **chapter summary**.

### 6.7 Accuracy for teaching material

- **Analogies.**
  - The water picture: pressure is voltage, flow rate is current, a narrow pipe is resistance.
  - Where it breaks:
    - Charge isn't used up; the same current comes back to the battery.
    - A cut wire doesn't spill anything; the current just stops.
    - The push travels along the wire at a large fraction of the speed of light, while the electrons themselves drift slowly.
- **Numbers.** Worked examples use the game's real values: the 5 V pack behind 1 Ω, the datasheet LED, the E12 resistors. Recap numbers come from the player's own simulation.
- **Sources.** Every card that states a measured number, a date or a person carries a source. Tests enforce it.

## 7. Chapter 1, lesson by lesson

The goals, parts and checks of Lessons 1–9 are the current levels'. What's new is around them. The text below is the outline; the plan writes the final copy within the limits above.

| # | Lesson | You'll learn | Learn deck (ideas, in order) | Try it |
|---|---|---|---|---|
| 0 | Your workbench | The bench and every control | §6.2 tour | (Lesson 0 is all hands-on) |
| 1 | Light it up | Electricity needs a loop. What the battery, wire, resistor and LED do. | Electricity is moving charges, which are already in the wires. A battery pushes them, from its + end round to its − end. A circuit is a loop, and a gap anywhere stops everything. Meet the battery pack, wire, resistor and LED. We draw current going from + to −. | A finished loop: delete a wire and watch the light go out, then undo. |
| 2 | Pop! | An LED lets current go one way and needs its current limited. How to read a datasheet and work out the resistor. | An LED is a diode that glows: current goes in at the longer leg and out at the flat side. It takes about 2 V of the battery's 5 V; the rest must drop across something. With no resistor only the battery's 1 Ω limits the current: pop. Read the datasheet: 2.0 V at 20 mA, 30 mA absolute maximum. Worked example: (5 V − 2.0 V) ÷ 0.020 A = 150 Ω, including milliamps to amps. Standard values (E12). | Connect the LED straight to the battery and watch it pop. Undo, then close the loop through the kit's 330 Ω resistor for a safe glow (about 9 mA on the live readout). It uses only Lesson 0's controls and no meter. |
| 3 | Push and flow | What volts, amps and ohms measure. Ohm's law. How to use both meters. | Voltage is the push (volts), current is the flow (amps; 1 mA = 1/1000 A), and resistance makes flowing harder (ohms). The water analogy and where it breaks. Ohm's law V = I × R, rearranged. Worked example: 5 V ÷ 500 Ω = 10 mA. Meet the current meter (it goes in the loop) and the voltage meter (it goes across a part). New control: the dial. | The metered loop with the dial (shown on the Learn deck's New control card): set 1 kΩ, then 2 kΩ. Twice the resistance gives half the current (5 mA, then 2.5 mA). Those settings stay well inside the trimmer's real rating. |
| 4 | On and off | Switches open and close the loop. On and off are a bit. | Meet the switch. "Closed" means connected and current flows, the opposite of a door. On/off is 1/0, a bit. New control: tap to flip, and the Test button tries every case. | Flip a ready-made switch. |
| 5 | Both | Series: one path, so everything on it must be closed (AND). Truth tables. | Series means one path: the same current goes through every part. Two switches in a row light the LED only if both are closed. A truth table lists every case. | Two switches in series: try all four cases, and the truth table fills in. |
| 6 | Either | Parallel: two paths, so either one works (OR). | Parallel means side-by-side paths with the same voltage across each. The branch currents add up. Either closed switch lights the LED. Truth table. | Two switches in parallel: all four cases. |
| 7 | Short circuit! | What a short is, why it's dangerous, and how to spot one. | A short is a path from + to − with almost no resistance. Current takes every path but floods the easiest one, so the LED's branch is skipped. 5 V across the pack's 1 Ω inside means about 5 A, and 25 W of heat inside the battery. Fuses and breakers. | Add a wire from + straight to −, watch the battery heat up, then undo. |
| 8 | Too hot to handle | Power and heat. Power ratings. | Power is energy per second: P = V × I, in watts. Resistors turn it into heat. Ratings: a ¼ W part burns above ¼ W. Worked example: I = 5 V ÷ (47 Ω + 1 Ω) = 0.104 A, so P = I² × R = 0.51 W. | Put a 220 Ω and then a 47 Ω resistor (both ¼ W) across the battery: 0.11 W is fine, 0.51 W scorches. |
| 9 | Inside the wire | Metals have free electrons that drift slowly while the push travels fast. Electron flow versus conventional current. | Copper atoms in a crystal, with free electrons between them. The battery's push makes them all drift together. They drift about 0.2 mm per minute here, but the push moves at a large fraction of light speed. Electrons go − to +, against the current arrows. | Switch the view between current arrows and electron flow. |

**Recap questions** (one or two per lesson) check that lesson's ideas. For example:
- "What happens if one wire in the loop is removed?" Everything stops.
- "Which LED leg goes toward +?" The longer one.
- "Double the resistance: the current…" Halves.
- "A closed switch means…" Current flows.
- "Two switches in series: which cases light the LED?" Only both closed.

**New words.** The new text brings words such as:
- anode, cathode, forward voltage, absolute maximum;
- series, parallel, truth table;
- internal resistance, power rating;
- drift, free electron, prototyping board.

Each gets a glossary entry in two layers. The automatic scan enforces it.

**History cards** (each with a source):
- Volta's battery (1800);
- Ohm's law (1827);
- the first visible LED (1962);
- "bit" (1947);
- fuses and breakers;
- the discovery of the electron (1897).

## 8. Data, saves and tests (for the builder)

**Lesson data.** A level definition grows these fields, built with the same builder and checked by tests:
- learning goals;
- a Learn deck (cards with a type, text, mood, a diagram id, an optional Go deeper line, an optional source);
- a Try it circuit with its prompt and pokes;
- Why? lines on steps;
- recap points (with number templates such as `{L1.mA}`);
- questions (a prompt, three choices, one correct, an explanation for each).

Lesson 0 is a new level of kind `tutorial`. Its steps use new checks:
- a part placed;
- a part moved;
- a part rotated;
- a wire added;
- a wire deleted;
- undo used;
- zoomed;
- panned;
- the menu opened;
- a datasheet opened.

**Diagram library.** About 18–20 small animated 2D diagrams drawn with the existing schematic and pastel kit:
- a loop with flowing sparks;
- charges in a wire;
- the LED as a one-way gate;
- the voltage budget (2 V for the LED, 3 V for the resistor);
- current against resistance, with the 20 mA and 30 mA lines;
- the water analogy;
- the Ohm's law triangle;
- the unit ladder (A, mA; Ω, kΩ);
- meter placement;
- switch states;
- bits;
- series paths;
- parallel paths;
- a live truth table;
- a short-circuit path;
- power and heat against a rating;
- conventional current against electron flow.

Each has a still frame for Reduced motion.

**Saves.** A new per-lesson table records which steps were seen and when. Older saves load with it empty, and nothing else in the format changes.

**Tests** cover:
- content rules: word limits, glossary coverage, sources, exactly one correct answer, diagram ids exist, recap templates resolve against the solution circuit;
- the session's phases (learn, try, build, passed, recap) and the replay and help-level rules;
- the Lesson 0 checks;
- the Notebook tabs;
- a playthrough of Lesson 0 and of Lesson 1's full rhythm;
- screenshot captures of every new card at phone and desktop sizes for visual review.

**Build order.**
1. **The slice first:** the course system, Lesson 0, and Lesson 1 all the way through.
2. **The owner tries it.** The owner is invited to play the slice and say what they understood, checked against §2's list. The browser version can be updated so they can play it on their phone.
3. **The rest goes on meanwhile.** Lessons 2–9 continue while we wait, and they take in the feedback when it comes.
4. **A beginner's read of every lesson.** A fresh reviewer reads each lesson cold, as a beginner would, and explains it back. That catches what automated tests can't.

## 9. Chapter 2's structure (the next milestone)

Chapter 2 keeps the main design's learning goals (§6 there) and uses the course format from day one. Its exact copy and numbers are settled in its own plan, after this milestone. The proposed lessons:

| # | Lesson | You'll learn | Build or do |
|---|---|---|---|
| 1 | Sand to silicon | Sand is silica (SiO₂). Carbon in an arc furnace turns it into silicon, then it's purified to electronic grade. | Run the furnace and purifier, an interactive illustrated process labeled as such, with real temperatures and purities. |
| 2 | Grow a crystal | The Czochralski method: melt, seed, pull and spin. Then the ingot is sliced into wafers. | Pull a crystal at the right speed to hold its diameter. |
| 3 | Doping | Phosphorus gives N-type (spare electrons) and boron gives P-type (holes). Conductivity rises. | Dope two samples and measure their resistance. |
| 4 | The diode | The PN junction and its depletion region. A one-way valve with about 0.6–0.7 V forward voltage. LEDs are diodes. | Protect a circuit from a battery put in backwards. |
| 5 | The transistor (NMOS) | A switch controlled by voltage: gate, drain and source, threshold voltage, on-resistance, and why a gate mustn't float. | Switch an LED with an NMOS transistor. |
| 6 | PMOS | The opposite kind, on when its gate is low. | Switch an LED from the + side. |
| 7 | The NOT gate | CMOS: one PMOS and one NMOS. In-between voltages near the threshold. | Build an inverter, test both inputs, and sweep the input to draw its curve. |
| 8 | Your first chip | Packaging: pins, power pins, a datasheet. Reuse. | Package your NOT gate (name, color, pins) into the Library, then use it. |
| 9 | Inside your chip | Zoom from the chip to the transistor, the channel forming, and the silicon lattice with dopant atoms. | Zoom to the dopant atoms. |

**New engine pieces** (from the main design's "First Chip" milestone):
- a MOSFET model in the circuit solver (threshold voltage, on-resistance, and the in-between region);
- a silicon diode part;
- a regulated supply and a potentiometer part;
- chips as reusable parts (a circuit inside a package);
- the Library;
- part internals;
- the new zoom layers;
- 3D models for each new part.

## 10. Milestones

This design inserts a milestone. Later ones shift by one.

| # | Milestone | Contents |
|---|---|---|
| M3 | **Class Is In** | The course system (§6), Lesson 0, Meet the part, all of Chapter 1 rewritten as a course (§7), the Notebook as textbook, a release |
| M4 | **First Chip** | Chapter 2 in the course format (§9), with the engine pieces above |
| M5 onward | as the main design's M4 onward | |

## 11. Calls made without asking (please check)

1. The new milestone is called **"Class Is In"**. Chapter 2 becomes M4.
2. Levels are called **lessons** on screen, numbered 0–9.
3. Learn and Try it **play automatically only on a first visit at Heavy help**. Otherwise they're one tap away. Everything can be skipped.
4. **Meet the part shows once at every help level**, like New word cards.
5. **Questions have three choices,** each explained. They have no score and aren't saved.
6. **No voice narration** this milestone.
7. **Look inside** is a 2D cutaway drawing, not a 3D cutaway.
8. **The water analogy is used,** always with where it breaks.
9. **The hand demo follows touch or mouse,** whichever you last used.
10. **Lesson 1 unlocks after Lesson 0 is done or skipped once,** so returning players aren't held up.

## 12. Left to the builder

- Card layout and sizes per screen.
- Diagram drawing and animation details within the style.
- Exact copy within the limits.
- Field and class names.
- The order of work.
- Test names.
