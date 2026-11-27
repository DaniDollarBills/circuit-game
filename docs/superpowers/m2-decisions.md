# Milestone 2 decisions

Every decision taken on the owner's behalf while building Milestone 2 ("Take It Home"), in the order it was taken, each with what it costs if it turns out wrong, and then the review findings left for later. Copied from the build ledger, which was scratch space and is gone now. Milestone 1's are in [m1-decisions.md](m1-decisions.md).

- Plan: [plans/2026-11-27-m2-take-it-home.md](plans/2026-11-27-m2-take-it-home.md)
- Design: [specs/2026-11-26-circuit-game-design.md](specs/2026-11-26-circuit-game-design.md)

Each ruling reads: what was decided — why — what it costs if wrong.

## Rulings (24)

### Setup

- started on the owner's message "Permission to do whatever needed to continue is given", taken as approval to plan and build Milestone 2 without a plan-review stop — cost if wrong: the owner reviews the plan after the fact.
- the roadmap's "update check" becomes a version line plus a button that opens the Releases page in the player's browser; the spec's rules that the game makes no real network connections (§9) and has no online features (§13) outrank a one-line roadmap entry — cost if wrong: players check for updates themselves.
- v0.1.0 stays untagged: pushing the tag was refused by the session's permission policy as an unwanted action, so publishing a release waits for the owner's explicit go-ahead — cost if wrong: no public downloads until then (CI already builds and checks every platform on every push).
- integration choice: the work stays on claude/zealous-goldberg-sqjca5 (no merge to main, no pull request): neither is needed to continue, and the environment allows only this branch without explicit permission — cost if wrong: the owner merges later.

### Task 2

- the Music and Sfx buses are created in code by Audio (when missing) instead of a default_bus_layout.tres file — one place to read, nothing for the editor to rewrite — cost if wrong: none.
- effects are generated lazily on first play and cached (each takes a few ms in GDScript), not all at startup — cost if wrong: a first-play delay of a few milliseconds per sound.

### Task 3

- the music ships as Ogg Vorbis (ffmpeg's built-in encoder at q8, 907 KB) instead of the plan's QOA-compressed WAV (a 12 MB WAV in the repository); libvorbis isn't available here, and the built-in encoder measured 24 dB SNR, which soft pads mask — cost if wrong: slight encoding artifacts audible on good headphones; re-encode with libvorbis later via tools/make_music.sh.
- MusicScore lives in game/tools (left out of exports); the game ships only the rendered loop, and tools/make_music.sh rebuilds it (25 s) — cost if wrong: none.

### Task 4

- sounds come from what changed between refreshes (a new part id: place; else a new wire id: connect; an LED crossing 5% brightness: light; a new test report object: pass or fail), plus events (burn: pop, pass: success, star and badge: badge, each New word card as it shows: word); undo plays nothing, redo plays what it brings back — cost if wrong: a redo makes the same soft click as the first placement.
- the end-to-end driver's start() now stops a Main that is still running: a test that started twice left the first Main alive, with its Audio node first in the "audio" group (a test-infrastructure bug, not a product one) — cost if wrong: none.

### Task 5

- installing apksigner and adb (apt) was refused by the session's permission policy, so the APK is built and checked only by CI on GitHub's runners (which carry the Android SDK); locally, tools/export.sh skips Android with a message — cost if wrong: Android problems surface in CI, not here.
- release builds are signed with a keystore from repository secrets when the owner adds them (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS), else with a debug key made per build — cost if wrong: until the secrets exist, each version needs the previous one uninstalled first.

### Task 6

- the licenses are a page inside the Settings card (LicensesPage, with Back) rather than a separate LicensesCard over it: one scrolling card, no card on top of a card — cost if wrong: none.
- Godot's section shows its MIT license, the list of libraries built into it, and their license texts (from the engine itself), built only when the page first opens; the page is in the "definitions" group so its legal words aren't introduced as game vocabulary — cost if wrong: a moment's pause the first time the page opens.

### Task 7

- Start over sits in the top bar on every screen size (no overflow menu): on narrow screens the bar's buttons sit 4 px apart instead of 8, so its seven 48 px buttons fit a 390 px phone (360 of 366 px) — cost if wrong: a slightly tighter bar on phones.
- the bench keeps its wire and equipment meshes while their shapes are unchanged (a signature of ids, paths, colors and positions) and updates meter readings and the holder's heat in place; parts already rebuilt only when their own props change — cost if wrong: a stale mesh if some visual depends on a property missing from the signature.

### Final

- re-graded "effect tails cut off" from Minor to Important (an abrupt stop you hear on every test sound, at −14 to −19 dB) and fixed it with a 40 ms raised-cosine fade — test_effect_tails_fade_smoothly RED→GREEN, suite 495/495 — cost if wrong: a fix the owner didn't ask for.
- two documentation minors were fixed in the same edits as the signing docs (the README said every download has a Licenses folder, which the APK doesn't; the itch text said LEDs burn out past their rated current, not their absolute maximum) — cost if wrong: none.
- declined item "how the sounds and music sound" — no audio device for either the reviewer or me; judged by code, measured numbers and decoded data — cost if wrong: a sound the owner dislikes, easy to retune in sfx.gd or music_score.gd.
- declined item "behavior on real Android hardware" (Back gestures against tray drags, shell_open on Android 11+, the Vulkan-to-OpenGL fallback, launcher icon masking) — no device here; CI builds and checks the APK — cost if wrong: phone-only problems reported by players.
- declined item "web build audio with buses made at runtime" — untested here; one manual check of the Sound switch and Music slider in a browser is worth doing — cost if wrong: web players can't silence the game from Settings.
- declined item "muting when a desktop window is minimized or a web tab hidden" — the plan asked only for mobile pause; desktop conventions vary — cost if wrong: music keeps playing in a background desktop window.
- declined items "the never-run tag release job", "Ogg versus QOA" (graded by its measured effect, deferred above), "Node 20 deprecation warnings" (ruled in Milestone 1) and "publishing the itch.io page" (needs the owner's account) — stand as ruled — cost if wrong: as in those rulings.
- declined item "Milestone 1's 13 px overflow at 360 px" — resolved by the top bar fix above (it now fits 360 px exactly) — cost if wrong: none.

## Deferred minor findings (8)

Reviewers found these; each was graded minor and left for a later pass.

### Final

- the music's right channel encodes at 21 dB SNR (the left 35 dB); re-encode with libvorbis or ship the planned QOA WAV.
- the Licenses page shows the credits as raw Markdown, and its first open blocks about 650 ms (146,000 characters in single labels).
- Start over's icon sits 4 px from undo on phones with no touch tooltip, undo history is lost on leaving a level, and on an untouched board Start over adds an empty undo step.
- the effect players are reused round-robin even while still sounding, and the test log `played` grows for the whole session.
- tools/check_dist.sh exits silently (status 2) with an APK present and no ANDROID_HOME, and its aapt2 permission check passes if aapt2 itself fails.
- the Android version code (2) is kept by hand and untested.
- Check for updates gives no feedback when no browser opens.
- test gaps: the background mute, the shipped Ogg's own seam, network classes beyond the scanned list (UPNP, IP, DTLS, multiplayer peers), and the slider test's values.
