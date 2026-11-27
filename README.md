# Circuit (working title)

A real-life-looking building game that takes you from a grain of sand to artificial intelligence. You work with electricity, transistors, logic gates, your own chips, and a PC or phone you design yourself. Then come the internet, pretend hacking, and AI. Every step is really simulated, and everything is explained as you go.

- Game design: [docs/superpowers/specs/2026-11-26-circuit-game-design.md](docs/superpowers/specs/2026-11-26-circuit-game-design.md)
- Milestone 1 plan: [docs/superpowers/plans/2026-11-26-m1-first-light.md](docs/superpowers/plans/2026-11-26-m1-first-light.md)

## Development

The game is a Godot 4.7.2 project in `game/`.

- Run the tests: `tools/test.sh`. On first use it downloads Godot 4.7.2 from the official release and checks its SHA-512 checksum.
- Run only some tests: `tools/test.sh <part of a test path or name>`
- Rebuild the music loop: `tools/make_music.sh` (needs ffmpeg). The sound effects are synthesized in code (`game/src/audio/sfx.gd`).
- Check the downloads carry their licenses: `tools/check_dist.sh` (after `tools/export.sh all`; Android needs `ANDROID_HOME`).

## Play it

Download the zip for your computer from the latest release on this repository's Releases page.

- **Windows:** unzip and run `Circuit.exe`. If Windows shows "Windows protected your PC", choose **More info → Run anyway** (the game isn't code-signed yet).
- **Mac:** unzip and open **Circuit**. The app isn't notarized yet, so the first time, macOS stops it. On macOS 15 (Sequoia) or later, open **System Settings → Privacy & Security**, find the message about Circuit and click **Open Anyway**. On older versions, right-click **Circuit** and choose **Open**.
- **Linux:** unzip, run `chmod +x Circuit.x86_64`, then `./Circuit.x86_64`.
- **Android:** download `Circuit-android.apk` on your phone and open it. Android asks to allow installs from your browser or Files app the first time: allow it for this app. It's signed for sideloading, not from the Play Store yet; until the project has a permanent signing key, uninstall the old version before installing a new one. The game asks for no permissions.
- **Browser:** this repository's GitHub Pages site, once it's switched on: in the repository's **Settings → Pages**, set **Source** to **GitHub Actions**, and set the repository variable `PAGES_ENABLED` to `true`. The `Circuit-web.zip` download is for putting the game on a web server; browsers won't run it straight from a downloaded file.

Every download has a `Licenses` folder: the credits, and the license texts for the fonts, the Earth imagery and the Godot engine.

To build the downloads yourself: `tools/export.sh all` (it fetches Godot 4.7.2 and its export templates, checking their SHA-512 sums).
