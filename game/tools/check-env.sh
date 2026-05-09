#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

echo "Project: ${ROOT_DIR}"

if [[ -x "${GODOT_BIN}" ]]; then
  "${GODOT_BIN}" --version
else
  echo "missing: GODOT_BIN=${GODOT_BIN}"
fi

if [[ -f "${ROOT_DIR}/addons/gut/plugin.cfg" ]]; then
  awk -F'=' '/^version=/ { gsub(/"/, "", $2); print "GUT " $2 }' "${ROOT_DIR}/addons/gut/plugin.cfg"
else
  echo "missing: addons/gut"
fi
