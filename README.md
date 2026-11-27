# Circuit (working title)

A real-life-looking building game that takes you from a grain of sand to artificial intelligence. You work with electricity, transistors, logic gates, your own chips, and a PC or phone you design yourself. Then come the internet, pretend hacking, and AI. Every step is really simulated, and everything is explained as you go.

Chapter 1, "Spark", is a course of ten lessons, from a tour of your workbench to the inside of a wire. Each lesson says what you'll learn, explains one idea at a time with a picture, lets you meet each new part in 3D and try things on a ready-made circuit, then has you build it yourself, and ends with a recap and a quick question or two. The Notebook keeps every lesson, part and word to read again.

- Game design: [docs/superpowers/specs/2026-11-26-circuit-game-design.md](docs/superpowers/specs/2026-11-26-circuit-game-design.md)
- The course design (Chapter 1 as a course, and Chapter 2's plan): [docs/superpowers/specs/2026-11-27-course-design.md](docs/superpowers/specs/2026-11-27-course-design.md)
- Milestone plans: [1, First Light](docs/superpowers/plans/2026-11-26-m1-first-light.md) · [3, Class Is In](docs/superpowers/plans/2026-11-27-m3-class-is-in.md)

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
- **Android:** download `Circuit-android.apk` on your phone and open it. Android asks to allow installs from your browser or Files app the first time: allow it for this app. It isn't on the Play Store yet. Each release is signed with the project's permanent key, so a new version installs over the old one and keeps your progress. The game asks for no permissions.
- **Browser:** this repository's GitHub Pages site, once it's switched on: in the repository's **Settings → Pages**, set **Source** to **GitHub Actions**, and set the repository variable `PAGES_ENABLED` to `true`. The `Circuit-web.zip` download is for putting the game on a web server; browsers won't run it straight from a downloaded file.

Every desktop download has a `Licenses` folder: the credits, and the license texts for the fonts, the Earth imagery and the Godot engine. The game shows the same in Settings → Licenses, which is where the Android app keeps them.

### Release signing (Android)

A release can only be tagged once the repository has the permanent Android signing key (CI refuses otherwise): every version must be signed with the same key, or phones won't install it over the old one, and uninstalling deletes the player's progress. To make the key, once, and keep it safe (a lost key means installed copies can never be updated):

1. `keytool -genkeypair -keystore circuit-release.keystore -alias circuit -keyalg RSA -keysize 2048 -validity 10000` and use the same password for the key as for the store.
2. `base64 -w0 circuit-release.keystore` and add the output as the repository secret `ANDROID_KEYSTORE_BASE64`; add the password as `ANDROID_KEYSTORE_PASSWORD` and `circuit` as `ANDROID_KEY_ALIAS`.

Builds of other commits (CI artifacts) are signed with a throwaway debug key, for testing only.

To build the downloads yourself: `tools/export.sh all` (it fetches Godot 4.7.2 and its export templates, checking their SHA-512 sums).
