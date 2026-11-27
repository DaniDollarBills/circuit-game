#!/usr/bin/env bash
# Runs the headless GDScript test suite. Usage: tools/test.sh [filter]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$ROOT/tools/godot.sh")"
# Re-import every run so the class_name cache matches the scripts on disk.
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
set +e
"$GODOT" --headless --path "$ROOT/game" -s res://tests/run_tests.gd -- "--filter=${1:-}"
CODE=$?
set -e
exit $CODE
