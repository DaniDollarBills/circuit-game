#!/usr/bin/env bash
# Checks that every download in build/dist carries the license texts and
# credits its parts require (the fonts' licenses, the globe tiles' Apache-2.0
# text, Godot's license and the notices of the libraries built into it).
# Usage: tools/check_dist.sh   (after tools/export.sh)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NEEDED=(CREDITS.md Nunito-OFL.txt DejaVu-LICENSE.txt NaturalEarthII-tiles-Apache-2.0.md Godot-LICENSE.txt Godot-third-party.txt)
status=0
shopt -s nullglob
zips=("$ROOT"/build/dist/Circuit-*.zip)
if [ ${#zips[@]} -eq 0 ]; then
  echo "no downloads in build/dist: run tools/export.sh first" >&2
  exit 1
fi
for z in "${zips[@]}"; do
  listing="$(unzip -Z1 "$z")"
  for f in "${NEEDED[@]}"; do
    if ! grep -qx "Licenses/$f" <<<"$listing"; then
      echo "MISSING $(basename "$z"): Licenses/$f"
      status=1
    fi
  done
done
[ $status -eq 0 ] && echo "every download carries its licenses and credits"
exit $status
