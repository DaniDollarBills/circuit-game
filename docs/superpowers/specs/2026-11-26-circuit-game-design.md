# Circuit — Game Design

> **Working title.** Written 2026-11-26. The owner asked for "the full plan with your best guesses", so every gap below is filled with a best guess instead of a question. §19 lists the calls made without asking, so they can be checked.

---

## 1. What the owner asked for

Condensed from the owner's messages:

- A completely interactive game for a computer or a phone. The graphics are good and smooth, with a **pastel look**.
- You **design your own chips** and every single part, **build a PC or a phone, and see if it works**.
- Once it's connected, you build "the internet stuff", connect to it, and **learn hacking**. **Everything is pretend.** You never really hack anything.
- **Extremely realistic**: from the tiniest parts (gates, and what gates are made of) up to the highest level.
- **You see everything.** For example, you can zoom out from your connection to the **undersea cables**, the **data centers** and the servers, with every moving part visible.
- **Understandable for beginners**: super advanced, but it **walks you through everything, step by step and visually**.
- **By default it is super advanced, just like real life, and it still gives heavy help.** Real-life depth is the starting point, not an option you unlock.
- **Easy for beginners to understand.** Whenever something appears that a beginner might not know, the game defines it right then.
- **Expert-level accuracy and precision**, while it walks you through and teaches you: "the ultimate game for learning and having fun with technology."
- **As real-life looking as possible.**
- **Include artificial intelligence**: the whole chain from having nothing to modern-day tech.
- **Platform:** whatever makes the better game. The owner prefers a **downloadable game** over a website, because a download unlocks more power.

## 2. The pitch

Circuit is a calm, pastel building game that takes you from nothing to modern technology one small step at a time.

You start on a quiet beach with sand and a spark of electricity. You turn sand into silicon, and silicon into transistors. Transistors become logic gates, and gates become your own chips. Your chips go into a computer or a phone you design yourself, and then you press the power button and find out whether it works. Next you connect your devices and build your own small internet. You zoom out to see the undersea cables and data centers that carry it. You learn how attackers break in (in a pretend world) and how to stop them. Finally, you build the artificial intelligence that answers questions on the phone you made.

Everything is really simulated. If you wire something wrong, it really doesn't work, and the game shows you exactly where and why. You can zoom into anything to see the moving parts inside, from electrons drifting through a wire to packets crossing an ocean.

## 3. Who it's for (best guess)

- Curious people aged about 11 and up, adults included, with **no background** in electronics or computers.
- **Real life by default.** You work with real parts and their datasheets, real circuit symbols, real numbers and units, real formulas and real-world limits, the way engineers do.
- **Every new word is defined the moment it appears**, in plain words first and then precisely. Nothing assumes you already know it.
- **Heavy help by default.** A step-by-step checklist, a guide who explains every mistake as it happens, "tap any number to see where it comes from", a built-in formula calculator, and hints carry beginners through the real thing.
- **Help levels.** Experts can turn the help down to **Light** or **Off**. The content itself never gets simplified.
- The test of success: a beginner can finish the whole game, and an engineer still learns something.

## 4. What success looks like

- A player who finishes can explain in their own words how a phone works from the transistor up, how a message crosses the internet, why passwords and encryption matter, and what an AI model actually does.
- Every "it works!" moment is earned. The result comes from the player's own design, never from a script.
- An expert could check any number, formula, definition or fact in the game and find it correct.
- Players come back because it's fun, not because they have to.
- It feels calm and beautiful, and runs smoothly on an ordinary laptop and a mid-range phone.

## 5. Pillars

1. **Real simulation, honest results.** Every level runs a real simulation of what you built. Simplifications are allowed, but they are always labeled ("Go deeper: real chips also …"), and the outcome is never faked.
2. **See every moving part.** You can zoom into anything you built and out to anything it connects to, smoothly, across about 17 powers of ten: from atoms out to the whole planet (§7).
3. **Real life by default, heavy help always there.** Every level uses real parts, real values and real rules. Heavy help walks you through it step by step: a live checklist, instant explanations of mistakes, and hints in three levels, the last of which shows the answer. No one hits a dead end, and the content is never dumbed down.
4. **Every new idea defined on the spot.** The first time any word or idea appears, anywhere in the game, it is explained right there. You get a plain-words definition, and underneath it a precise, expert-level one.
5. **Expert accuracy.** Numbers come from the simulation or from verified constants. Every fact carries its source. Simplifications are always labeled in a "Go deeper" card.
6. **You build it, you keep it.** Your NOT gate goes into your adder, your adder into your CPU, and your CPU into your phone. Your own creations carry forward.
7. **Fun, not homework.** Playful failures (pop!, magic smoke), "wow" zooms, badges, stars, a Notebook that fills up with what you've learned, a workshop that grows, and a free-build sandbox.
8. **Real-life looking, smooth, calm.**
   - Parts and places look like the real thing: built to their real sizes, with real materials and studio lighting.
   - The soft pastel palette stays in the interface and the backdrops.
   - Gentle motion, and no timers or punishment for mistakes. Breaking things is part of learning.
9. **Pretend and safe.** The internet and all hacking happen inside the game's own make-believe world. The game never touches real networks.

## 6. The journey: 13 chapters, from nothing to modern technology

Each chapter has an era banner (real dates), teaches with small levels, and adds new layers you can zoom into. The world around you grows as you go. It starts as a beach with a workshop shack, then becomes a garage lab, a chip factory, a house full of your devices, a town network, the planet, a data center and an AI lab.

### Act I — From nothing to a chip

**Chapter 1 · Spark — electricity** *(1800s)*
- **Learn:** circuits are loops. Voltage pushes, current flows, and resistance slows it down. LEDs only let current go one way. Switches open and close the loop. Series means "both", parallel means "either". Short circuits are dangerous. And you'll see what's inside a wire.
- **Build:** light an LED. Read the LED's datasheet and work out its resistor (R = (5 V − 2.0 V) ÷ 20 mA = 150 Ω), then pick it from a kit of standard resistor values. Hit exactly 10 milliamps using Ohm's law. Add a switch, then make "both switches" and "either switch" circuits. Fix a short circuit. Build a small heater, choosing a resistor with the right power rating. Finally, zoom into a wire.
- **Does it work?** A real circuit solver computes every volt, milliamp and watt. Parts behave like their real datasheets:
  - An LED glows up to its recommended 20 mA, wears out above that, and burns out above its 30 mA absolute maximum.
  - A ¼-watt resistor burns if you ask it to make half a watt of heat.
  - A short circuit really overheats the battery.
  - The meters behave like a real multimeter's.
- **Zoom adds:** circuit → wire → copper atoms, with electrons drifting through them.

**Chapter 2 · Sand — from sand to the transistor** *(1947–1960)*
- **Learn:** sand is silica. You purify it into silicon, grow a crystal, and slice it into wafers. Doping makes N-type and P-type silicon. Then come the diode, and the MOSFET transistor, a switch controlled by voltage, in its NMOS and PMOS kinds.
- **Build:** refine silicon (an interactive furnace and crystal puller), dope a crystal, control an LED with a transistor, build a NOT gate from one PMOS and one NMOS, and package it as **your first chip**.
- **Does it work?** Transistors use a real transistor model (threshold voltage, on-resistance), so you see real output voltages, including the in-between ones.
- **Zoom adds:** chip → transistor → the channel forming → silicon lattice with dopant atoms.

**Chapter 3 · Logic — gates and your own chips** *(1960s)*
- **Learn:** truth tables, NAND and NOR built from transistors, every gate built from NAND, De Morgan's laws, and packaging and reusing your designs.
- **Build:** NAND from 4 transistors, NOR, and then NOT, AND, OR and XOR from NANDs. You package them the real way: four gates in a 14-pin chip with power pins, like the classic 74-series logic chips, each with its own datasheet. You design each chip's look (name, color, pin layout). Optional star challenges ask for the fewest parts.
- **Does it work?** Every chip is tested against its truth table, row by row, and the failing row is highlighted.
- **Zoom adds:** chip → gates → transistors.

**Chapter 4 · Numbers — binary and arithmetic** *(1960s)*
- **Learn:** binary counting, adding with gates, carries, negative numbers (two's complement), choosing with multiplexers, and the ALU.
- **Build:** half adder, full adder, 4-bit and 8-bit adders (watch the carry ripple through), subtractor, comparator, multiplexer, decoder, and your own ALU with flags.
- **Does it work?** Automatic tests check thousands of cases. Signal delay is simulated, so slow designs visibly lag.

**Chapter 5 · Memory — remembering, and the clock** *(1970)*
- **Learn:** feedback, latches, the clock, flip-flops, registers, counters, RAM and ROM. Go-deeper panels show real memory cells: SRAM, DRAM and flash.
- **Build:** SR latch, D latch, a clock from a ring of NOT gates, D flip-flop, 8-bit register, counter, 16-byte RAM, and ROM.
- **Does it work?** Timing is simulated, so glitches and race conditions show up the way they would on real hardware.

**Chapter 6 · The Brain — your own CPU** *(1971)*
- **Learn:** programs are numbers too. You'll learn instruction sets, the fetch–decode–execute loop, control signals, jumps and conditions, and assembly language.
- **Build, in two stages:**
  1. **First, learn the ideas on a small 8-bit CPU** for the game's own teaching instruction set (working name **Petal-8**), one piece at a time: program counter, instruction memory, decoder, registers with the ALU, load and store, and jumps. You program it in machine code and in assembly.
  2. **Then build a real one:** a 32-bit **RISC-V** CPU (the RV32I base instruction set). RISC-V is an open, free standard used in real chips today. The CPU in your PC or phone in Chapter 8 is this design.
- **Does it work?** A full instruction test suite runs on your design. Once it passes, your CPU runs programs at full speed. You can still freeze time and zoom into any gate in the middle of a program. The fast mode is constantly cross-checked against your gate-level design, which is how real CPUs are verified.

**Chapter 7 · The Factory — making real chips** *(1970s to today)*
- **Learn:** photolithography, etching, doping and metal layers. Wafers, dies and yield. Packaging. Moore's law, and how transistors shrank from micrometers to a few nanometers.
- **Build:** run the factory line for your NOT gate, lay out a gate on silicon layers (guided, with automatic design-rule checks), arrange your CPU's blocks on a die, and package it with your own logo. Then design or buy the support chips: memory, display controller, power and radio.
- **Does it work?** Defects, yield and wire length are modeled. Big dies give fewer good chips, and long wires make chips slower.

### Act II — Devices

**Chapter 8 · The Machine — build a PC or a phone** *(1981 to 2007)*
- **Learn:** circuit boards, power delivery, clock crystals, memory and storage, screens (pixels and subpixels), keyboards and touchscreens, sound, heat and cooling, and batteries.
- **Build:** design the board (place chips, route the traces) and set up power. Then assemble the device in 3D. A **PC** has a case, board, CPU, RAM, storage, power supply and fans. A **phone of your own design** has a screen, frame, logic board with a system-on-chip, battery, cameras and antennas. You pick which one to build first; the other unlocks afterwards.
- **Does it work?** Press the power button and the game boots **your** CPU design. Missing traces, wrong voltages, weak power supplies or overheating cause real failures. Diagnostic lights and beep codes point to the problem, and power wired the wrong way gives off the "magic smoke".
- **Zoom adds:** device → board → chip → gates.

**Chapter 9 · Software — bringing it to life** *(1970s to 2000s)*
- **Learn:** firmware and booting, text and fonts as numbers, programming languages and compilers, operating systems (programs taking turns, memory, files), drivers and apps.
- **Build:** a boot program and printing text. You write programs in **C** (a real subset of the language engineers use), and watch the compiler turn them into RISC-V instructions for your CPU. Then a tiny operating system, apps (drawing, a calculator, a small game) and a home screen.
- **Does it work?** Every program runs on the CPU you built, inside the device you built.

### Act III — Connection

**Chapter 10 · Connect — your home network** *(1973 to 1999)*
- **Learn:** sending bits down a wire, timing, framing, noise and checksums, addresses, network switches, and Wi-Fi radio.
- **Build:** link two devices with a single wire, agree on a speed, design a message format, survive noise, then add addresses and a switch. Set up Wi-Fi and see the signal strength through the walls of your house.
- **Does it work?** A packet-level network simulator runs with real timing and **real protocol formats**: Ethernet frames, MAC addresses, ARP. A packet inspector shows the real header fields and bytes, with every field explained when you tap it. If the speeds don't match you get garbage, noise flips bits, and collisions happen.
- **Zoom adds:** device → room → house.

**Chapter 11 · The Internet** *(1969 to today)*
- **Learn:** IP addresses, routers and routing, internet providers, fiber optics, internet exchanges, **undersea cables**, satellites, cell towers, **data centers**, DNS, TCP, the web and the cloud.
- **Build:** route packets across a network. Follow your connection from the house to the street cabinet, the city and an exchange. Plan a route across the ocean on undersea cables. Fill a server rack in a data center, host your own website, and open it from your phone on another continent.
- **Does it work?** Real distances and the speed of light set the delays. A round trip across the Atlantic takes about 70 milliseconds, and you can see why. The protocols are the real ones: IPv4 (with IPv6 explained), routing tables, DNS, TCP with its handshake and retransmissions, UDP and HTTP. They use real header layouts, real port numbers and real status codes. Cut a cable and watch the traffic find another way.
- **Zoom adds:** house → street → city → country → **the whole planet with its undersea cables** → down into a data center → hall → rack → server → chip → transistor.

### Act IV — Security (pretend)

**Chapter 12 · White Hat — the pretend hacking academy** *(today)*
- **Frame:** you join a pretend security team. Every mission has the same three steps: test it (with permission), explain it, fix it. It all happens inside the game's make-believe internet.
- **Missions:**
  - why weak passwords fall, and how fast; hashing and salting
  - codes from Caesar to modern encryption: break a Caesar code by counting letters, see why an XOR key must never repeat, and learn public-key "padlocks" through paint mixing
  - unencrypted Wi-Fi traffic compared with HTTPS, and spotting phishing
  - finding open doors (ports) and closing them with a firewall
  - tricking a pretend login with an injection, then fixing it
  - overflowing a buffer on **the CPU you built** and watching the stack get overwritten
  - how a worm spreads through unpatched machines; flood attacks and how to defend against them
  - a final capture-the-flag, and then defending your own network
- **Does it work?** The weaknesses are real mechanics inside pretend machines. The buffer overflow, for example, really overwrites memory in your own CPU. You work in a realistic pretend terminal with Linux-style commands such as `ls`, `cat` and `ssh` into make-believe machines. It can only ever reach the game's own world.
- **Safety rules:** see §9.

### Act V — Intelligence

**Chapter 13 · Thinking Machines — AI** *(1958 to today)*
- **Learn:** what "learning" means for a machine, a neuron (a weighted sum plus a threshold), training by nudging weights, and why one neuron can't do XOR but two layers can. Then backpropagation and gradient descent, training data and overfitting, image filters, and why AI needs special chips. For language: tokens, embeddings, attention and next-word prediction. Finally, how today's large models are trained in huge data centers, and their mistakes, bias and safety.
- **Build:** a neuron made from your own ALU, trained to sort fruit. A small network that reads digits you draw on your phone's screen. An AI chip with a grid of multiply-add units. A tiny language model, trained on a small book, that goes from gibberish to words while you watch.
- **Does it work?** Real (small) neural networks train on the player's own device. The real math is shown by default (weighted sums, matrix multiplies, gradients, softmax, attention scores), and heavy help explains each piece in plain words. Giant modern models are explained with live visuals, never faked.
- **Finale:** you ask your AI a question on the phone you built. The camera follows it through your network, across the undersea cable, into a data center, through the AI chip's grid and down to the transistors and electrons, and then the answer travels all the way back. Pip, your guide, turns out to be running on what you built.

### Epilogue · Free Build

Everything is unlocked. Build anything, and share your designs as files.

## 7. The zoom: "see every moving part"

The zoom is the game's signature feature. Pinch (phone), scroll (mouse) or use a trackpad to move smoothly through these levels:

| Level | Real size on screen | What you see |
|---|---|---|
| Atom | 0.1–1 nm | nucleus, electron shells (simplification labeled) |
| Crystal lattice | 1–10 nm | silicon or copper atoms, dopants, drifting electrons |
| Transistor | 10–100 nm | the channel switching on and off |
| Gate | 0.1–1 µm | a few transistors working together |
| Chip block | 1–100 µm | adders, registers |
| Die | 1–20 mm | the floor plan of the whole chip |
| Board | 1–30 cm | chips and traces, signals flowing |
| Device | 10–50 cm | the phone or PC, in an exploded view |
| Room / desk | 1–10 m | your devices, the router |
| House and street | 10–500 m | cables on poles or underground, cell towers |
| City | 1–50 km | exchanges, fiber rings, data-center campus |
| Country / continent | 100–5,000 km | backbones, internet exchange points |
| Planet | 10,000–40,000 km | undersea cables, landing stations, satellites |

How the zoom works:
- **Continuous.** Each level fades into the next while the camera keeps moving, with no loading screens between levels.
- **Real scale bar.** The scale bar always shows the real size ("300 m", "5 nm").
- **Honest skipping.** Where nothing changes for many powers of ten (inside a sand grain, for example), the zoom speeds up and shows a "skipping ×1,000" badge instead of pretending the scales line up.
- **Follow mode.** You can pin a signal, electron or packet, and the camera follows it across levels, for example a packet going from your phone into the ocean cable and out to a server.
- **Dive in anywhere.** You can enter at any point you're looking at, such as a wire, a chip in your PC, or a data center on the globe.

## 8. How teaching works: real life by default, heavy help

**What's real by default**
- Real parts with real **datasheets**. Tap any part to see its specs, where every line is explained in plain words.
- Real **standard values**, such as resistors in the E12 series: 100, 150, 220, 330, 470 Ω and so on.
- **Real-looking parts on a real workbench**, built true to size in 3D. A **Schematic** toggle switches to standard circuit symbols, the way engineers draw them.
- Real **numbers and units everywhere**: volts, milliamps, watts, and later nanoseconds, bytes and packets.
- Real **formulas** and real **terminology**.
- Real **limits**: maximum currents, power ratings, timing, bandwidth.

**Defined on the spot (always on, at every help level)**
- **The engine finds new words automatically.** Every piece of text the game shows (guide lines, steps, hints, error messages, datasheets, calculator steps, captions) is scanned for words in the glossary.
- **The first time you meet a word,** a small **New word** card slides in. It gives the plain meaning first (for example "Resistor: a part that limits current, like a narrow section of pipe") and then **More precisely** at expert level ("A part made to have a specific resistance, so V = I × R across it…").
- **Definitions build on each other.** They only use everyday words or other defined words, so you never meet a definition you can't read.
- **After that, the word stays underlined:** tap it any time to read it again.
- **Your Notebook** collects every word you've learned, with both definitions, plus your badges.

**Accuracy policy**
- Every number on screen comes from the simulation or from a verified constant.
- Every fact in the game carries a source in the game data, and each chapter's facts are checked before release.
- Real-world simplifications are labeled in a "Go deeper" card, never hidden.

**Heavy help, on by default**
- **The level rhythm:** *see it* (a short animated intro), *try it* (poke a ready-made example), *build it*, *test it* (the game shows exactly what failed and why), *use it* (it goes into your toolbox).
- **A live step checklist** breaks every level into small steps that tick off by themselves as you build.
- **Pip steps in the moment something goes wrong.** You get an explanation right away, such as "The LED is backwards", "That's more than the LED's 20 mA", or "Short circuit!", followed by what to try. If you're stuck for 30 seconds, Pip offers a hint.
- **"Where does this number come from?"** Tap any value to see its calculation with the real numbers, for example "Current = 3.04 V ÷ 220 Ω = 13.8 mA".
- **Formula calculator:** Ohm's law, LED resistor and power. It can pull values straight from your circuit and shows every step.
- **Glossary everywhere.** Any underlined word opens a plain explanation.
- **Three hint levels:**
  1. a nudge
  2. highlighting the right parts
  3. "show me", which places ghost parts and wires you can tap to accept
- **History cards** with real dates and people (Ohm in 1827, the transistor in 1947, the perceptron in 1958, and so on).

**Help levels** (in Settings)

| Level | What you get |
|---|---|
| **Heavy** (default) | Everything above |
| **Light** | No checklist; Pip and hints only when you ask |
| **Off** | Goals only, a real engineering challenge |

The help level never changes the content: the parts, values and physics are the same at every level. New-word definitions appear at every help level, because understanding the words is never optional.

**What makes it fun**
- **Breaking things is fun and safe.** LEDs pop, resistors smoke, the battery glows hot, and Pip explains what happened. The first burn even earns the "Magic Smoke" badge.
- **"Wow" moments:** the zoom from Earth to an atom, diving into a wire, watching your own CPU think, following a packet across the ocean.
- **Badges** for milestones and discoveries.
- **Optional star challenges**, such as "brightest glow within spec" or "fewest gates".
- **Collecting:** words in the Notebook and chips in the Library.
- **A workshop that grows** from a beach shack to an AI lab.
- **Free Build:** make anything with what you've unlocked.

## 9. Pretend hacking: safety rules

- The game makes **no real network connections**. Every machine, network and website in Chapters 10–12 is simulated inside the game.
- Attacks are taught as **concepts and in-game tools** that only work on pretend machines. The game never ships real attack tools, and never names real targets or real exploits.
- Every mission ends with the **defense**, and the ethics card is always shown: only test things you own or have permission to test. Real-world pointers lead to legal practice such as capture-the-flag events and bug bounty programs.

## 10. Realism: what is truly simulated

| Chapter | Simulated for real | Shown as animation or illustration (labeled) |
|---|---|---|
| Electricity | DC circuit solve: volts, amps, LED forward voltage, burnout, short circuits | electron drift |
| Sand | transistor model (threshold voltage, on-resistance) | refining, crystal growth, doping |
| Logic, numbers, memory | event-driven gate simulation with real delays, glitches, oscillation | — |
| CPU | your gate-level design executes; a fast mode is verified against it | — |
| Factory | yield vs. die size and defect density; wire length vs. speed | lithography steps |
| Machine | connections of every trace, power budget, heat and throttling, a real boot of your CPU | assembly |
| Software | real programs on your CPU: compiler, operating system, apps | — |
| Network and internet | packets with real bandwidth, distance-based latency (light in fiber ≈ 200,000 km/s), queues, loss, routing, DNS/TCP/HTTP-style protocols | radio waves, light in fiber |
| Security | real vulnerability mechanics inside pretend machines | — |
| AI | real training of small networks on the player's device | the scale of large models |

**Real-life defaults in every chapter**
- Parts have datasheets with real-world values. Examples: a red 5 mm LED at 2.0 V and 20 mA (30 mA absolute maximum); a ¼ W carbon-film resistor at ±5%; a voltmeter with 10 MΩ input resistance like a real multimeter.
- Standard series and real formats: E12 resistor values, 14-pin logic chips with power pins, the RISC-V RV32I instruction set, C, Ethernet/IPv4/TCP/UDP/DNS/HTTP header layouts.
- Real limits cause real failures, with heavy help explaining each one.
- Where the game simplifies, it says so in a "Go deeper" card.

Real examples sit inside the game's own fiction. The phone is your own design, not an iPhone (Apple's name and look belong to Apple). Real companies only appear in history facts. Open standards such as RISC-V and the internet protocols are used as they really are.

## 11. Look and feel

**Real-life looking by default**
- **Real materials and real sizes.** Physically based materials (molded plastic, clear epoxy, carbon film, copper, solder, glass, circuit board) on parts built to their datasheet dimensions:
  - a 5 mm LED is 5.0 mm across its dome and 8.6 mm tall
  - a ¼ W resistor body is 6.3 × 2.4 mm
  - AA cells are 50.5 × 14.5 mm
- **Real light.**
  - Scenes are lit by photographed studio and sky lighting (HDRI).
  - Soft shadows, global illumination, ambient occlusion and reflections.
  - Depth of field for close-ups, like macro photography.
  - Glow only where real light is made: an LED lights the board around it.
- **The workbench:**
  - a perforated prototyping board on a pastel self-healing cutting mat, on a wooden desk
  - jumper wires with real insulation colors and gentle bends
  - the battery pack and multimeters sit beside the board, connected by real-looking leads and clips
- **Real effects:**
  - burnt LEDs darken and smoke
  - overloaded resistors scorch
  - a shorted battery glows hot
  - a blown meter fuse shows a dark display
- **Real places:**
  - Earth from public-domain NASA imagery, with oceans, clouds and city lights
  - a real coastline, photographic sand, sand grains that look like real quartz
  - atoms shown the way physicists picture them, as electron clouds. The simple shell picture is a labeled option.
- **Teaching overlays** (on by default, and can be turned off):
  - glowing current flow, live values and highlights, drawn on top of the real-looking scene like augmented reality
  - they let you see what is invisible in real life
- **Graphics quality** is picked automatically (Low / Medium / High / Ultra), and you can change it in Settings.

**The pastel side** (menus, cards, Pip, backdrops)
- **Palette (light):**
  - background cream `#FFF8EF`, panels `#FFFFFF`, ink `#3D3A4B`
  - lavender `#CDB8F0`, lilac `#E6DAFB`, mint `#BDEBD7`, sky `#BFDDF8`, peach `#FFD3B8`, butter `#FFF0A6`, rose `#F8C3D6`, warning coral `#FF9F8A`
  - signals: low `#B9B3D1`, high `#FF8FAB`; current sparks `#FFE58A`
- **Night palette:** deep plum background `#24212F`, panels `#2F2B3D`, light ink `#F3EEFF`. The pastel accents stay the same.
- **Shapes:** rounded everything (12–20 px corners on panels), soft drop shadows, 2 px soft-ink outlines.
- **Part views:**
  - By default you see the **real-looking 3D parts**.
  - The **Schematic** toggle shows the real circuit symbols instead (zigzag resistor, LED triangle with light arrows, battery plates, switch lever, round meters), drawn crisply with pastel accents.
  - Every datasheet card shows both views.
- **Motion:** 60 fps, gentle ease-out, parts pop in with a tiny overshoot, current flows as moving sparks, glows breathe softly. A reduced-motion setting replaces large zooms with gentle fades and turns the flowing sparks into still arrows.
- **Type:** Nunito, a rounded sans-serif (Open Font License).
- **Sound** (from Milestone 2): soft clicks, chimes and lo-fi ambient music.
- **Accessibility:** on/off signals differ in brightness, glow and motion, not just hue, and a "patterns" option adds stripes. Text contrast is at least 7:1 for main text and 4.5:1 for secondary text. Touch targets are at least 44 px. There are keyboard shortcuts and a large-text option.

## 12. Controls

| Action | Mouse / keyboard | Touch | Trackpad |
|---|---|---|---|
| Place a part | drag from tray, or click tray then click board | drag from tray, or tap tray then tap board | — |
| Wire | drag from pin to pin, or click pin then pin | drag from pin to pin, or tap pin then pin | — |
| Move | drag a part | drag a part | — |
| Rotate / delete / replace | `R` / `Delete` / right-click menu | long-press menu | — |
| Toggle a switch | click it | tap it | — |
| Zoom | scroll wheel | pinch | pinch |
| Pan | drag empty space | drag empty space, or two-finger drag | two-finger scroll |
| Undo / redo | `Ctrl/Cmd+Z` / `Ctrl/Cmd+Shift+Z` | buttons | — |

## 13. Your stuff

- **Library:** every chip you package (name, color, icon, pin layout). It can be reused in any later level and in Free Build.
- **Notebook:** every word you've learned (plain and precise definitions) and every badge you've earned.
- **Drafts autosave** for every level.
- **Design files:** export and import as files you can share.
- **No accounts, no ads, no purchases, no online features.** Saves stay on the device.

## 14. Platforms: download first

| Version | What it is | Quality |
|---|---|---|
| **Desktop download (main)** | An app you download and install on **Windows, Mac or Linux**. It works offline. | Full: best renderer, all effects, full speed and memory |
| **Phone app** | Android app (from Milestone 2). iPhone app through the App Store later, which needs an Apple developer account. | High: mobile renderer |
| **Browser version** | The same game in a web page, for quick looks while it's being built | Lighter: simpler renderer, fewer effects |

It's the same game and the same save format everywhere. Builds are produced automatically and published as downloads on the project's GitHub Releases page. Later the game can go on itch.io or Steam, which handle downloads and updates.

## 15. Technology

- **Engine:** Godot 4.7.2 (open source, MIT license, no fees). It's one engine for 2D and 3D, and it exports to Windows, macOS, Linux, Android, iOS and the web. Scenes and logic are built in code, which suits a code-first workflow.
- **Languages:**
  - **GDScript** for the game, the UI and the Milestone 1 simulation.
  - **Rust**, through godot-rust (crate `godot` 0.5.x), for the heavy engines from the digital-logic milestone on: the gate-level simulator, CPU co-simulation, the network simulator and neural-network training. These run natively at full speed on all CPU cores. GPU compute shaders are used for AI training.
- **Renderers:**
  - Forward+ on desktop, with every realism effect: PBR materials, HDRI lighting, SDFGI global illumination, SSAO, screen-space reflections, depth of field and glow.
  - Mobile on phones, with PBR and fewer effects.
  - Compatibility for the browser version, with simpler lighting.
  - Every visual must still work in Compatibility.
- **Realistic assets:**
  - Parts are modeled in code from datasheet dimensions.
  - Photographic textures and HDRI lighting come from Poly Haven (CC0), and Earth imagery from NASA (public domain).
  - A script downloads them with pinned checksums, and they are credited in `CREDITS.md`.
- **Architecture:**
  - **Pure logic** (circuit model, simulators, lessons, saves, zoom math, gestures, editor rules) never touches scene nodes. It is tested headless.
  - **Presentation** (scenes, drawing, UI) is a thin layer over that logic.
  - **Content** (levels, glossary) is typed GDScript data built with a small builder, and checked by tests: every level's solution must pass its own goals.
  - **ZoomStage** stacks each zoom level as its own viewport, cross-fades neighbors, and passes the camera between levels using pure zoom math (§7).
- **Simulation engines by chapter:**
  - analog DC solver (Ch. 1–2)
  - event-driven digital simulator with hierarchical chips (Ch. 3–7)
  - CPU co-simulation with a verified fast mode (Ch. 6+)
  - board power and heat model (Ch. 8)
  - discrete-event network simulator (Ch. 10–12)
  - neural networks (Ch. 13)
- **Saves:** versioned JSON in the app's user folder, written safely (temporary file, then rename). Corrupt saves are backed up, and the game starts fresh instead of crashing.
- **Testing:**
  - a headless test runner for logic and scene tests
  - screenshot captures (Xvfb with Mesa) for visual review
  - GitHub Actions runs the tests and exports on every push
- **Data:** world coastlines from Natural Earth (public domain), converted once into a compact file. Cable routes in the title sequence are stylized. Real routes arrive in Chapter 11, hand-authored, not copied from licensed maps.
- **Performance budget:**
  - 60 fps on a 2020 laptop with integrated graphics and on a 2021 mid-range phone
  - DC solve under 2 ms for the circuits in Chapter 1
  - memory under 1 GB
  - every part of the game works offline

## 16. Goals, non-goals, anti-goals

**Goals**
- The full journey across 13 chapters, delivered in playable milestones, each one a real download.
- An honest simulation at every level, and a seamless zoom across every scale.
- A beginner can finish it, and experts find depth.

**Non-goals (for now)**
- Multiplayer, accounts, cloud saves, chat or any online features.
- Ads, in-app purchases or loot boxes.
- Photo-realistic graphics. The look is stylized pastel on purpose.
- A full SPICE-grade analog simulator, a real operating system, or running a full-size AI model.
- Using real brands as things you build (no "iPhone", no "Intel chip").

**Anti-goals** (failure even if it technically works)
- It feels like homework: walls of text, or quizzes without building.
- Scripted "success" that doesn't depend on what the player built.
- Overwhelming beginners with too many parts or options at once.
- Stutter or jank on a normal laptop or phone.
- Teaching harmful real-world attacks against real systems.
- Dead ends where a player is stuck with no way forward.

## 17. Constraints

- It must run offline and make no network requests at runtime.
- Touch and mouse are first-class from day one, in portrait and landscape.
- All art, text and characters are original. Fonts, textures, lighting and data must have open licenses (OFL, CC0, public domain), with credits.
- Every visual must work in the Compatibility renderer (browser version), even if desktop adds effects on top.
- Main-path text: at most 2 sentences and about 30 words per guide bubble.
- Every technical word on screen must have a glossary entry with a plain and a precise definition. Automatic checks keep this true.
- Every fact must carry a source.

## 18. Approaches considered

**Platform and engine**

| Option | Trade-offs | Verdict |
|---|---|---|
| **A. Godot 4, downloadable native game** | Real game engine. Native speed and memory, a full 3D renderer, desktop and phone exports, free and open source, code-first. Its UI toolkit is less rich than the web's, and testing needs a headless runner plus screenshot captures. | **Chosen.** It matches the owner's wish for a downloadable game with full power. |
| B. Web technology (three.js) packaged as a desktop app | Best UI tools and the easiest testing. The renderer is one step below native, and it's still a browser engine inside. | Rejected: the owner wants a true game engine, download first. |
| C. Browser only | Easiest to share, least capable. | Rejected. |
| Unity / Unreal | Powerful, but they need account or license activation and very large installs that don't fit a code-only build setup. Unreal is far more than pastel visuals need. | Rejected. |

**Simulation honesty**
- A. Real simulation at every level, with verified fast modes. **Chosen.**
- B. Scripted outcomes. Rejected, because it would make "see if it works" fake.

**First milestone**
- A. A vertical slice: Chapter 1, the title zoom from Earth to an atom, and downloadable builds. **Chosen**, because it proves the look, the simulation, the zoom and the teaching all at once.
- B. Engine first, content later. Rejected, because there would be nothing to play for a long time.

## 19. Calls made without asking (please check)

1. **Godot 4.7.2**, with the **desktop download as the main version**. Phone apps and a lighter browser version are built from the same project.
2. **Working title "Circuit"**, and a guide called **Pip**, a small spark.
3. **Audience:** curious beginners aged about 11 and up, adults included. **Real-life content by default with Heavy help**, which can be turned down to Light or Off.
4. The game **starts on a beach with sand**, because sand is where silicon comes from.
5. The PC and the phone are **your own designs**, with no real brands.
6. Hacking is a **"White Hat" academy** in a pretend world: test with permission, then defend.
7. **Real-looking 3D everywhere**, including the circuit workbench. Flat schematic symbols are a toggle.
8. **No accounts, ads or online features.** Saves stay on your device.
9. **Milestone 1** is Chapter 1 plus the title zoom from Earth down to a silicon atom, delivered as downloadable builds.
10. **Two CPUs in Chapter 6:** a small teaching CPU with the game's own instruction set (working name Petal-8) to learn the ideas, then a **real 32-bit RISC-V (RV32I)** CPU, which is what your PC or phone runs.
11. **Real-looking 3D parts are the default look**, with a Schematic toggle for circuit symbols.
12. **Software uses real C** (a subset) compiled to RISC-V. **Networking uses the real protocol formats**, shown in a packet inspector.
13. The Chapter 1 battery is a **4 × AA pack treated as 5 V with 1 Ω internal resistance**, matching a partly used pack. Chapter 2 introduces regulated supplies.
14. **New words are explained automatically** with a New word card the first time they appear, in a plain layer and a precise layer. This happens at every help level.
15. **Badges and a Notebook** add the collecting side of the fun. M1 has 8 badges.
16. **The world looks real and the interface stays pastel.** Real materials, real sizes and real lighting for everything you build and visit. Soft pastel colors for menus, cards, Pip and backdrops, such as the pastel cutting mat on the desk.
17. **Big items sit beside the board, as in real life.** The battery holder and multimeters are on the desk, connected to the board by leads and clips.
18. **A 1 W resistor has longer legs** (15.24 mm between its leads) than a ¼ W one (10.16 mm), because its body is bigger.

## 20. Roadmap

Each milestone ends with something playable and downloadable. Each one gets its own detailed plan when it starts, informed by what the previous milestone taught us.

| # | Milestone | Contents |
|---|---|---|
| M1 | **First Light** | Foundation, a realistic 3D workbench with true-to-size parts, datasheets and a schematic toggle, analog simulator, lessons with heavy help (checklist, instant explanations, value explanations, formula calculator), automatic new-word definitions, Notebook and badges, the zoom system, the title zoom from Earth to an atom, Chapter 1 (9 levels), the wire zoom, downloadable builds |
| M2 | **Take It Home** | Android build, sound and music, an update check, polish from M1 feedback, an optional itch.io page |
| M3 | **First Chip** | Chapter 2 (sand → transistor → your first chip), the transistor model, chip packaging and Library, part internals |
| M4 | **Logic & Numbers** | Rust digital engine, Chapters 3–4, buses, star challenges |
| M5 | **Memory & the Brain** | Chapters 5–6: the Petal-8 teaching CPU, then a real RISC-V RV32I CPU, assemblers, CPU test suites, fast mode with co-simulation |
| M6 | **The Factory** | Chapter 7 |
| M7 | **The Machine** | Chapter 8: board editor, power and heat, 3D assembly, boot and diagnostics |
| M8 | **Software** | Chapter 9: compiler, mini operating system, apps |
| M9 | **The Internet** | Chapters 10–11: network engine, the zoom from house to planet, undersea cables, data centers |
| M10 | **White Hat** | Chapter 12 |
| M11 | **Thinking Machines** | Chapter 13 and the grand-zoom finale |
| M12 | **Ship** | Performance, an accessibility audit, store releases (App Store, Play Store, Steam) if wanted |

## 21. Left to later plans

- The exact level lists for Chapters 2–13. Each milestone plan settles them, keeping this document's learning goals.
- The Petal-8 instruction encoding, how much of RISC-V beyond RV32I to include, which C subset the compiler supports, and the AI model sizes.
- Whether the PC assembly and data-center scenes need extra 3D detail beyond the stylized look.
- The app-store and Steam release decisions, which need the owner's accounts.
