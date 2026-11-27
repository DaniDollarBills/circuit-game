# Circuit (working title)

A real-life-looking building game that takes you from a grain of sand to artificial intelligence. You work with electricity, transistors, logic gates, your own chips, and a PC or phone you design yourself. Then come the internet, pretend hacking, and AI. Every step is really simulated, and everything is explained as you go.

- Game design: [docs/superpowers/specs/2026-11-26-circuit-game-design.md](docs/superpowers/specs/2026-11-26-circuit-game-design.md)
- Milestone 1 plan: [docs/superpowers/plans/2026-11-26-m1-first-light.md](docs/superpowers/plans/2026-11-26-m1-first-light.md)

## Development

The game is a Godot 4.7.2 project in `game/`.

- Run the tests: `tools/test.sh`. On first use it downloads Godot 4.7.2 from the official release and checks its SHA-512 checksum.
- Run only some tests: `tools/test.sh <part of a test path or name>`
