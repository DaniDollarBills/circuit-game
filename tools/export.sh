#!/usr/bin/env bash
# Exports the game for download: tools/export.sh [linux|windows|macos|web|all]
# Fetches Godot's export templates on first use (SHA-512 checked against the
# release's SHA512-SUMS.txt, like tools/godot.sh), exports each platform with
# its preset, and zips each one to build/dist/Circuit-<platform>.zip.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="4.7.2-stable"
TEMPLATES="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${VERSION/-/.}"
GODOT="$("$ROOT/tools/godot.sh")"
WHAT="${1:-all}"

if [ ! -f "$TEMPLATES/version.txt" ]; then
  DIR="$ROOT/.tools/templates-$VERSION"
  mkdir -p "$DIR" "$TEMPLATES"
  BASE="https://github.com/godotengine/godot/releases/download/$VERSION"
  TPZ="Godot_v${VERSION}_export_templates.tpz"
  curl -fsSL --retry 4 --retry-delay 5 --retry-all-errors -o "$DIR/$TPZ" "$BASE/$TPZ"
  curl -fsSL --retry 4 --retry-delay 5 --retry-all-errors -o "$DIR/SHA512-SUMS.txt" "$BASE/SHA512-SUMS.txt"
  EXPECTED="$(grep " ${TPZ}\$" "$DIR/SHA512-SUMS.txt" | cut -d' ' -f1)"
  echo "$EXPECTED  $DIR/$TPZ" | sha512sum -c - >/dev/null
  unzip -q -o "$DIR/$TPZ" -d "$DIR"
  cp -r "$DIR/templates/." "$TEMPLATES/"
  rm -rf "$DIR"
fi

# Every download carries the texts its parts' licenses require, and the
# credits: tools/check_dist.sh checks them.
licenses_into() {
  local dir="$1/Licenses"
  rm -rf "$dir" && mkdir -p "$dir"
  cp "$ROOT/game/assets/third_party/CREDITS.md" "$dir/CREDITS.md"
  cp "$ROOT/game/assets/fonts/LICENSE" "$dir/Nunito-OFL.txt"
  cp "$ROOT/game/assets/fonts/LICENSE-DejaVu.txt" "$dir/DejaVu-LICENSE.txt"
  cp "$ROOT/game/assets/third_party/naturalearth/LICENSE-Apache-2.0.md" "$dir/NaturalEarthII-tiles-Apache-2.0.md"
  "$GODOT" --headless --path "$ROOT/game" -s res://tools/write_licenses.gd -- "$dir" >/dev/null
}

export_one() {
  local platform="$1" preset="$2" out="$3"
  mkdir -p "$ROOT/build/$platform" "$ROOT/build/dist"
  "$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
  "$GODOT" --headless --path "$ROOT/game" --export-release "$preset" "$ROOT/$out"
  rm -f "$ROOT/build/dist/Circuit-$platform.zip"
  licenses_into "$ROOT/build/$platform"
  if [ "$platform" = macos ]; then
    # Godot writes the app as a zip already: the licenses go in beside it.
    (cd "$ROOT/build/macos" && zip -q -r "$ROOT/$out" Licenses)
    cp "$ROOT/$out" "$ROOT/build/dist/Circuit-$platform.zip"
  else
    (cd "$ROOT/build/$platform" && zip -q -r "$ROOT/build/dist/Circuit-$platform.zip" .)
  fi
  echo "exported $platform -> build/dist/Circuit-$platform.zip"
}

case "$WHAT" in
  linux) export_one linux "Linux" build/linux/Circuit.x86_64 ;;
  windows) export_one windows "Windows Desktop" build/windows/Circuit.exe ;;
  macos) export_one macos "macOS" build/macos/Circuit.zip ;;
  web) export_one web "Web" build/web/index.html ;;
  all)
    export_one linux "Linux" build/linux/Circuit.x86_64
    export_one windows "Windows Desktop" build/windows/Circuit.exe
    export_one macos "macOS" build/macos/Circuit.zip
    export_one web "Web" build/web/index.html
    ;;
  *) echo "usage: tools/export.sh [linux|windows|macos|web|all]" >&2; exit 2 ;;
esac
