#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"${ROOT_DIR}/tools/check-docs.sh"
"${ROOT_DIR}/tools/check-assets.sh"
"${ROOT_DIR}/tools/check-structure.sh"
"${ROOT_DIR}/tools/check-env.sh"
"${ROOT_DIR}/tools/godot-headless.sh"
"${ROOT_DIR}/tools/test-gut.sh"
