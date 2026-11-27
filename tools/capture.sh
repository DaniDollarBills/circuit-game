#!/usr/bin/env bash
# Renders a scene to a PNG for visual review.
# Usage: tools/capture.sh <res://scene.tscn> <out.png> [WxH] [rendering_method] [scene args...]
#   rendering_method: gl_compatibility (default), forward_plus or mobile
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$ROOT/tools/godot.sh")"
SCENE="$1"; OUT="$2"; SIZE="${3:-1280x720}"; METHOD="${4:-gl_compatibility}"
shift $(( $# < 4 ? $# : 4 ))
if ! command -v xvfb-run >/dev/null; then
  echo "xvfb-run is missing. Install: apt-get install -y xvfb libgl1-mesa-dri mesa-vulkan-drivers" >&2
  exit 2
fi
mkdir -p "$(dirname "$OUT")"
OUT_ABS="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
xvfb-run -a -s "-screen 0 ${SIZE}x24" "$GODOT" --path "$ROOT/game" \
  --rendering-method "$METHOD" --resolution "$SIZE" --audio-driver Dummy \
  -s res://tools/capture.gd -- "--scene=$SCENE" "--out=$OUT_ABS" "$@"
