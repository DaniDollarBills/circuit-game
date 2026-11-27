# Milestone 2 "Take It Home" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The game goes home with the player: an Android app, gentle sound and music, its version and licenses inside the game, and the polish Milestone 1's reviews asked for.

**Architecture:** Sound is synthesized in code: short effects at startup, and a music loop rendered offline by a tool script into a committed WAV, so no audio asset needs a license. One `Audio` node, owned by `Main`, plays everything; the settings and the Game's events drive it. Android reuses the Mobile renderer and the existing touch input, signed with a debug key for sideloading. "Update check" becomes a version line and a button that opens the Releases page in the player's browser: the game itself never goes online (spec §9 and §13).

**Tech Stack:** Godot 4.7.2 (GDScript, static typing), Godot's Android export (non-Gradle, apksigner), GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-26-circuit-game-design.md` (roadmap row M2, §9, §11, §13, §14). Milestone 1's deferred findings: `docs/superpowers/m1-decisions.md`.

## Global Constraints

- The game makes **no real network connections** (§9), and has **no accounts, no ads, no purchases, no online features** (§13). The Android app asks for **no permissions**.
- Sound (§11): "soft clicks, chimes and lo-fi ambient music". Sound never carries information that isn't also on screen.
- Version: `0.2.0`, in `application/config/version`.
- Text contrast is at least 7:1 for main text and 4.5:1 for secondary text; touch targets are at least 44 px; every new word is defined the first time it shows (all from §11 and Milestone 1).
- Every download, and the app itself, carries the license texts its parts require.
- Tests: `tools/test.sh [filter]`. Commits end with the session's attribution lines; no model names in the repository.

## Review Focus

1. **Sound off means silent:** with Sound off, nothing plays, including after toggling mid-level, on a new screen, and while the app is in the background. *Test:* Task 2 `test_sound_off_plays_nothing`, Task 4 `test_sound_toggle_mid_level`.
2. **Old saves load:** a v0.1.0 save (no `sound` or `music_volume`) loads with the new defaults, and invalid volumes are rejected. *Test:* Task 2 `test_old_save_gets_sound_defaults`.
3. **No network, no permissions:** no network class appears anywhere under `game/src`, and the Android preset declares no permissions. *Test:* Task 1 `test_game_never_opens_a_connection`, Task 5 `test_android_preset_asks_for_nothing`.
4. **Start over is safe:** Start over keeps the locked parts, can be undone, and clears the old test report. *Test:* Task 7 `test_start_over_is_undoable`.
5. **The music loop has no click at its seam,** and volume changes apply at once. *Test:* Task 3 `test_music_loops_without_a_click`.

---

## File map

- `game/src/app/version.gd`: `Version.text()`, `Version.RELEASES_URL`.
- `game/src/audio/sfx.gd`: `Sfx.make(name) -> AudioStreamWAV`, synthesized.
- `game/src/audio/audio.gd`: `Audio` node: `play(name)`, music, volumes, mute in background.
- `game/default_bus_layout.tres`: Master, Music and Sfx buses.
- `game/tools/make_music.gd`: renders `game/assets/audio/ambient_loop.wav`.
- `game/src/hud/licenses_card.gd`: credits and license texts in the game.
- `game/src/hud/settings_sheet.gd`: Sound, Music volume, and About (version, updates, licenses).
- `game/export_presets.cfg`, `tools/export.sh`, `tools/check_dist.sh`, `.github/workflows/build.yml`: Android.
- `docs/itch-page.md`, `README.md`, `docs/release-notes.md`.

### Task 1: Version, the updates button, and no network

**Files:** Create `game/src/app/version.gd`; modify `game/project.godot`, `game/src/hud/settings_sheet.gd`. Test: `game/tests/app/test_version.gd`.

**Interfaces:** Produces `Version.text() -> String` ("0.2.0"), `const Version.RELEASES_URL := "https://github.com/DaniDollarBills/circuit-game/releases/latest"`, and `SettingsSheet.opener: Callable` (defaults to `OS.shell_open`; tests swap it).

- [ ] **Step 1: Write the failing tests.** `test_version_reads_the_project_setting` (asserts "0.2.0"); `test_updates_button_opens_the_releases_page` (presses the button, asserts the opener got `RELEASES_URL`); `test_game_never_opens_a_connection` (scans every `.gd` under `res://src` for `HTTPRequest`, `HTTPClient`, `StreamPeerTCP`, `StreamPeerTLS`, `PacketPeerUDP`, `WebSocketPeer`, `TCPServer`, `UDPServer` and `JavaScriptBridge`, and expects none).
- [ ] **Step 2:** `tools/test.sh test_version`. Expected: FAIL (no Version class).
- [ ] **Step 3:** Add `config/version="0.2.0"`, `Version`, and an About row in Settings: "Circuit 0.2.0" plus a "Check for updates" button that calls `opener.call(Version.RELEASES_URL)`.
- [ ] **Step 4:** Run again. Expected: PASS.
- [ ] **Step 5:** Commit `feat: version, and a Check for updates button that opens the Releases page`.

### Task 2: Sound effects, the Audio node and sound settings

**Files:** Create `game/src/audio/sfx.gd`, `game/src/audio/audio.gd`, `game/default_bus_layout.tres`; modify `game/src/save/progress.gd`, `game/src/app/main.gd`, `game/src/hud/settings_sheet.gd`. Test: `game/tests/audio/test_audio.gd`.

**Interfaces:** `const Sfx.NAMES := ["click", "place", "connect", "light", "pop", "success", "word", "badge", "test_pass", "test_fail"]`. `Sfx.make(name: String) -> AudioStreamWAV` returns 16-bit mono at 44.1 kHz, deterministic, peak ≤ 0.89 (−1 dBFS), 20–900 ms. `Audio.play(name: String)`, `Audio.played: Array[String]` (the names played since start, for tests), `Audio.apply_settings(settings: Dictionary)`. Settings `"sound": true` and `"music_volume": 0.5` (a float in 0–1).

- [ ] **Step 1: Write the failing tests.**
  - `test_every_effect_is_short_clean_and_repeatable`: for each name, the frame count is within 20–900 ms, the peak is ≤ 0.89, and two calls give identical bytes.
  - `test_sound_off_plays_nothing`: with `sound: false`, `play` adds nothing to `played`; with `sound: true` it does.
  - `test_old_save_gets_sound_defaults`: a settings dictionary without the keys loads with `true` and `0.5`; `is_valid_setting("music_volume", 1.5)` and `("music_volume", -0.1)` are false.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement. Effects are sines and soft noise with attack/decay envelopes:
  - **click:** a 25 ms soft tick;
  - **place:** a 90 ms low "tock";
  - **connect:** two quick clicks;
  - **light:** a C6–G6 chime with a 600 ms decay;
  - **pop:** filtered noise plus a 60 Hz thump;
  - **success:** a C–E–G–C pentatonic arpeggio;
  - **word:** a soft single chime;
  - **badge:** a sparkle (three high partials);
  - **test pass/fail:** a rising or falling pair.

  `Audio` holds a few pooled `AudioStreamPlayer`s on the Sfx bus and one on the Music bus. It mutes both buses while the app is paused (`NOTIFICATION_APPLICATION_PAUSED` and `RESUMED`). `Main` owns it and applies the settings on `changed`. Settings get a Sound toggle and a Music volume slider (a 44 px tall track).
- [ ] **Step 4:** Run. Expected: PASS. Then run the full suite.
- [ ] **Step 5:** Commit `feat: synthesized sound effects, the Audio node and sound settings`.

### Task 3: The music loop

**Files:** Create `game/tools/make_music.gd` and `game/assets/audio/ambient_loop.wav` (generated; import set to loop and QOA-compressed); modify `game/src/audio/audio.gd`. Test: `game/tests/audio/test_music.gd`.

**Interfaces:** `make_music.gd` writes a seamless loop: 96 s, 32 kHz, stereo, 16-bit. `Audio.music_playing() -> bool`.

- [ ] **Step 1: Write the failing tests.**
  - `test_music_loops_without_a_click`: the first and last samples are within 0.02; the mean absolute level of the last 50 ms is within 30% of the first 50 ms; the peak is ≤ 0.8; the import loops.
  - `test_music_follows_the_volume`: `music_volume` 0 stops it, and 0.5 plays at linear 0.5 times the bus base level.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** The generator writes a calm progression in D major pentatonic (Dmaj9 → Bm7 → Gmaj7 → A6sus, 12 s each, twice):
  - soft pads of detuned sine pairs through a one-pole low-pass;
  - a sparse "felt piano" of sines with fast attack and 1.5 s decay, on a seeded random pattern;
  - very quiet vinyl crackle;
  - a short feedback-delay "room".

  Every voice's phase and envelope wraps at the loop length, so the end meets the start. Run it with `godot --headless --path game -s res://tools/make_music.gd`.
- [ ] **Step 4:** Run. Expected: PASS. Listen-check proxy: the RMS curve has no jumps of more than 6 dB between 100 ms windows.
- [ ] **Step 5:** Commit `feat: a generated lo-fi ambient music loop`.

### Task 4: Sounds for what happens in the game

**Files:** Modify `game/src/app/main.gd`, `game/src/screens/level_screen.gd`, `game/src/screens/map_screen.gd`, `game/src/screens/title_screen.gd`. Test: `game/tests/audio/test_game_sounds.gd`.

**Interfaces:** Consumes `Audio.play` and `Audio.played` (Task 2). Each screen asks `get_tree().get_first_node_in_group("audio")` for the node, and does nothing when there is none (tests without Main).

- [ ] **Step 1: Write the failing tests** (they drive Main through the E2E helper):
  - `test_placing_and_wiring_make_soft_clicks`: placing a part plays "place" and joining a wire plays "connect";
  - `test_light_burn_and_pass_have_their_sounds`: an LED lighting plays "light", a burn "pop", and a pass "success";
  - `test_new_words_badges_and_tests_chime`: "word", "badge", "test_pass" and "test_fail";
  - `test_buttons_click`: any button press plays "click";
  - `test_sound_toggle_mid_level`: turning Sound off stops all of the above at once.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** The screens map Game events to sounds. "light" plays when an LED goes from dark to lit between two commits. Main gives every `BaseButton` that enters the tree a click, via `SceneTree.node_added`.
- [ ] **Step 4:** Run, then run the full suite. Expected: PASS.
- [ ] **Step 5:** Commit `feat: clicks, chimes and pops for what happens in the game`.

### Task 5: Android

**Files:** Modify `game/export_presets.cfg`, `tools/export.sh`, `tools/check_dist.sh`, `.github/workflows/build.yml`, `README.md`. Test: `game/tests/app/test_export_presets.gd`.

**Interfaces:**
- `tools/export.sh android` writes `build/dist/Circuit-android.apk`.
- The preset is named "Android":
  - package `io.github.circuitgame.circuit`, label "Circuit", version code 2, version name 0.2.0;
  - architectures `arm64-v8a` and `armeabi-v7a`;
  - sensor orientation; no permissions; Gradle build off.
- Signing:
  - the key comes from `ANDROID_KEYSTORE_BASE64` / `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_ALIAS` when they are set;
  - otherwise a debug key at `~/.local/share/circuit-game/debug.keystore` (created by `keytool` if missing).
- The Android SDK path:
  - `ANDROID_HOME` when set (GitHub's runners have one);
  - else a minimal folder whose `build-tools/34.0.0/apksigner` links to the system `apksigner`.

- [ ] **Step 1: Write the failing tests.** `test_android_preset_asks_for_nothing`: it parses `export_presets.cfg` and checks the preset's platform, package name, architectures, that every `permissions/*` is false, and that `gradle_build/use_gradle_build` is false. Then extend `tools/check_dist.sh`: the APK must contain `assets/` resources and pass `apksigner verify`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Add the preset and the export path.
  - **CI:** add `android` to the export job, upload `Circuit-android.apk`, and attach it to the release.
  - **README:** install steps (allow installing from this source; it's a debug-signed app for sideloading, and the Play Store comes later with the owner's account).
- [ ] **Step 4:** Run the tests; run `tools/export.sh android` and `tools/check_dist.sh`. Expected: PASS, and an APK of about 70–90 MB. If the session cannot install `apksigner` (permission policy), rule it, verify the preset by test, and let CI build and verify the APK.
- [ ] **Step 5:** Commit `feat: Android app, debug-signed for sideloading`.

### Task 6: Licenses and credits inside the game

**Files:** Create `game/src/hud/licenses_card.gd`; modify `game/src/hud/settings_sheet.gd` and `game/export_presets.cfg` (include filters). Test: `game/tests/hud/test_licenses_card.gd`.

**Interfaces:** `LicensesCard.SOURCES` lists:
- the credits, `res://assets/third_party/CREDITS.md`;
- Nunito, `res://assets/fonts/LICENSE`;
- DejaVu, `res://assets/fonts/LICENSE-DejaVu.txt`;
- the globe tiles, `res://assets/third_party/naturalearth/LICENSE-Apache-2.0.md`;
- Godot, from `Engine.get_license_text()` and `Engine.get_copyright_info()`.

`LicensesCard.section_titles() -> PackedStringArray`.

- [ ] **Step 1: Write the failing tests.**
  - `test_licenses_card_shows_every_license`: every section is non-empty, and Godot's text contains "MIT".
  - `test_license_files_ship_in_every_preset`: every preset's include filter covers each `SOURCES` path.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Settings → About gains a "Licenses" button. It opens a scrolling CardFit card with a section per source; the text is plain, selectable, and readable at 7:1.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit `feat: credits and licenses inside the game`.

### Task 7: Polish from Milestone 1

**Files:** Modify `game/src/app/game_state.gd`, `game/src/app/game.gd`, `game/src/hud/top_bar.gd`, `game/src/screens/level_screen.gd`, `game/src/editor/editor_layer.gd`. Test: `game/tests/app/test_game_state.gd`, `game/tests/hud/test_hud.gd`, `game/tests/hud/test_phone_layout.gd`.

**Interfaces:** `GameState.start_over()` commits the level's start circuit (one undo step). `TopBar` gets a "restart" icon button with the tooltip "Start over".

- [ ] **Step 1: Write the failing tests.**
  - `test_start_over_is_undoable`: after edits, `start_over()` gives the start circuit with its locked parts, clears the test report, and one undo brings the edits back.
  - `test_hint_waits_for_the_intro`: the bulb is hidden during the intro.
  - `test_portrait_column_never_covers_the_board`: at 390×844 after Test in L5, the column's rect doesn't reach into `editor.safe_rect`.
  - `test_slider_drag_rebuilds_the_bench_once`: ten preview steps on L3's trimmer cause at most one full bench rebuild; values update in place.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement.
  - **Start over:** a top-bar button; on phones it goes in the bar's overflow, with no confirmation, because it is undoable.
  - **Hint:** the bulb is hidden while the intro is on.
  - **Portrait column:** it keeps the height reserved at layout and scrolls to show new test results.
  - **Slider:** previews update meters, labels and the trimmer dial in place, and only a change in parts or wires rebuilds the bench.
- [ ] **Step 4:** Run, then run the full suite. Expected: PASS.
- [ ] **Step 5:** Commit `fix: Milestone 1 polish: start over, hint timing, portrait column, smooth slider`.

### Task 8: Release copy and the itch.io page text

**Files:** Modify `README.md` and `docs/release-notes.md`; create `docs/itch-page.md`.

- [ ] **Step 1:** Write the v0.2.0 notes: Android, sound and music, Start over, licenses in the game, and fixes. Write the itch.io page copy (title, short and long description, install steps per platform, credits, and a screenshot list) for the owner to paste; making the page needs their account.
- [ ] **Step 2:** Capture the screenshots the page lists into `build/captures/itch/` (1280×720 and 390×844) and check each against the copy.
- [ ] **Step 3:** Commit `docs: v0.2.0 release notes and itch.io page text`.

### Task 9: Final review

- [ ] Run the full suite. Export all five platforms and run `tools/check_dist.sh`. Then dispatch a fresh whole-milestone reviewer with this plan, the spec and the ledger's rulings, and make one fix pass.

## Execution notes

- Captures: `tools/capture.sh`. Exports: `tools/export.sh all`.
- Installing `apksigner` (apt) may be refused by the session's permission policy. If so, record a ruling and rely on GitHub's runner, which has the Android SDK.
- Tagging a release needs the owner's explicit go-ahead: the tag push for v0.1.0 was refused by the permission policy.
