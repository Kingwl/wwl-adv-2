#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
OUTPUT_DIR="${1:-${REPO_DIR}/build/web}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "missing python3" >&2
  exit 1
fi

OUTPUT_DIR="$(
  python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).expanduser().resolve(strict=False))' \
    "${OUTPUT_DIR}"
)"

case "${OUTPUT_DIR}/" in
  "${ROOT_DIR}/"*)
    echo "refusing to export Web build inside Godot project: ${OUTPUT_DIR}" >&2
    echo "use a path outside ${ROOT_DIR}, for example ${REPO_DIR}/build/web" >&2
    exit 1
    ;;
esac

"${ROOT_DIR}/tools/install-export-templates.sh"

rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

"${GODOT_BIN}" --headless --path "${ROOT_DIR}" --import >/dev/null
"${GODOT_BIN}" --headless --path "${ROOT_DIR}" --export-release "Web" "${OUTPUT_DIR}/index.html"

echo "Web export written to ${OUTPUT_DIR}"
if command -v du >/dev/null 2>&1; then
  du -sh "${OUTPUT_DIR}"
fi

if command -v find >/dev/null 2>&1; then
  find "${OUTPUT_DIR}" -maxdepth 1 -type f -print0 \
    | xargs -0 ls -lh \
    | awk '{print $5 "\t" $9}'
fi
