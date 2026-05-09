#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
ARTIFACT_DIR="${GAMEPLAY_SMOKE_ARTIFACT_DIR:-${REPO_DIR}/ci-artifacts/gameplay-smoke/native}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "missing python3" >&2
  exit 1
fi

ARTIFACT_DIR="$(
  python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).expanduser().resolve(strict=False))' \
    "${ARTIFACT_DIR}"
)"

rm -rf "${ARTIFACT_DIR}"
mkdir -p "${ARTIFACT_DIR}"

RUNNER=("${GODOT_BIN}" --path "${ROOT_DIR}" --script "res://tools/gameplay_smoke_runner.gd")

if [[ "$(uname -s)" == "Linux" && -z "${DISPLAY:-}" ]]; then
  if ! command -v xvfb-run >/dev/null 2>&1; then
    echo "missing xvfb-run for Linux gameplay smoke without DISPLAY" >&2
    exit 1
  fi
  RUNNER=(xvfb-run -a "${RUNNER[@]}")
fi

set +e
GAMEPLAY_SMOKE_ARTIFACT_DIR="${ARTIFACT_DIR}" "${RUNNER[@]}" 2>&1 | tee "${ARTIFACT_DIR}/godot.log"
status="${PIPESTATUS[0]}"
set -e

if [[ -f "${ARTIFACT_DIR}/report.md" ]]; then
  sed -n '1,220p' "${ARTIFACT_DIR}/report.md"
fi

if [[ "${status}" -ne 0 ]]; then
  echo "Gameplay smoke failed; artifacts: ${ARTIFACT_DIR}" >&2
  exit "${status}"
fi

echo "Gameplay smoke passed; artifacts: ${ARTIFACT_DIR}"
