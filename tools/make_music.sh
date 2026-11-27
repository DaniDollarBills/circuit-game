#!/usr/bin/env bash
# Renders the game's music loop (game/tools/music_score.gd) and encodes it to
# game/assets/audio/ambient_loop.ogg (Ogg Vorbis, imported as a loop).
# Needs ffmpeg. Usage: tools/make_music.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$ROOT/tools/godot.sh")"
WORK="$ROOT/build/music"
mkdir -p "$WORK" "$ROOT/game/assets/audio"
"$GODOT" --headless --path "$ROOT/game" -s res://tools/make_music.gd -- "$WORK/ambient_loop.wav"
# Godot's own encoder isn't available; ffmpeg's built-in Vorbis encoder is.
ffmpeg -hide_banner -loglevel error -y -i "$WORK/ambient_loop.wav" -c:a vorbis -strict -2 -q:a 8 "$ROOT/game/assets/audio/ambient_loop.ogg"
ls -l "$ROOT/game/assets/audio/ambient_loop.ogg"
