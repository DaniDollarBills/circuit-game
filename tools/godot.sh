#!/usr/bin/env bash
set -euo pipefail
VERSION="4.7.2-stable"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/.tools/godot-$VERSION"
BIN="$DIR/Godot_v${VERSION}_linux.x86_64"
if [ ! -x "$BIN" ]; then
  mkdir -p "$DIR"
  BASE="https://github.com/godotengine/godot/releases/download/$VERSION"
  curl -fsSL --retry 4 --retry-delay 5 --retry-all-errors -o "$DIR/godot.zip" "$BASE/Godot_v${VERSION}_linux.x86_64.zip"
  curl -fsSL --retry 4 --retry-delay 5 --retry-all-errors -o "$DIR/SHA512-SUMS.txt" "$BASE/SHA512-SUMS.txt"
  EXPECTED="$(grep " Godot_v${VERSION}_linux.x86_64.zip\$" "$DIR/SHA512-SUMS.txt" | cut -d' ' -f1)"
  echo "$EXPECTED  $DIR/godot.zip" | sha512sum -c - >/dev/null
  unzip -q -o "$DIR/godot.zip" -d "$DIR" && rm "$DIR/godot.zip"
fi
echo "$BIN"
