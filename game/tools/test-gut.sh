#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

"${GODOT_BIN}" --headless --path "${ROOT_DIR}" --import >/dev/null

"${GODOT_BIN}" --headless -d -s --path "${ROOT_DIR}" addons/gut/gut_cmdln.gd \
  -gdir=res://test/gut \
  -ginclude_subdirs \
  -gexit
