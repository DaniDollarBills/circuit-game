# Circuit (working title)

A real-life-looking building game that takes you from a grain of sand to artificial intelligence. You work with electricity, transistors, logic gates, your own chips, and a PC or phone you design yourself. Then come the internet, pretend hacking, and AI. Every step is really simulated, and everything is explained as you go.

- Game design: [docs/superpowers/specs/2026-11-26-circuit-game-design.md](docs/superpowers/specs/2026-11-26-circuit-game-design.md)
- Milestone 1 plan: [docs/superpowers/plans/2026-11-26-m1-first-light.md](docs/superpowers/plans/2026-11-26-m1-first-light.md)

## Development

The game is a Godot 4.7.2 project in `game/`.

- Run the tests: `tools/test.sh`. On first use it downloads Godot 4.7.2 from the official release and checks its SHA-512 checksum.
- Run only some tests: `tools/test.sh <part of a test path or name>`

## Play it

Download the zip for your computer from the latest release on this repository's Releases page.

- **Windows:** unzip and run `Circuit.exe`. If Windows shows "Windows protected your PC", choose **More info → Run anyway** (the game isn't code-signed yet).
- **Mac:** unzip, then right-click **Circuit** and choose **Open** (the first time only, because the app isn't notarized yet).
- **Linux:** unzip, run `chmod +x Circuit.x86_64`, then `./Circuit.x86_64`.
- **Browser:** the GitHub Pages link, once Pages is enabled for this repository (set the repository variable `PAGES_ENABLED` to `true`).

To build the downloads yourself: `tools/export.sh all` (it fetches Godot 4.7.2 and its export templates, checking their SHA-512 sums).
