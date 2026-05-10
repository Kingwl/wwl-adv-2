#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
ARTIFACT_DIR="${REPO_DIR}/ci-artifacts"
PRINT_SUMMARY="${WWL_PREFLIGHT_PRINT_SUMMARY:-1}"

mkdir -p "${ARTIFACT_DIR}"

echo "== Project gate (fast) =="
set +e
"${ROOT_DIR}/tools/check-all.sh" 2>&1 | tee "${ARTIFACT_DIR}/check-all.log"
status="${PIPESTATUS[0]}"
set -e

echo
echo "== Godot/GUT log report =="
"${ROOT_DIR}/tools/summarize-godot-log.py" \
  "${ARTIFACT_DIR}/check-all.log" \
  --exit-status "${status}" \
  --out-dir "${ARTIFACT_DIR}/godot-log"

if [[ "${status}" -ne 0 ]]; then
  echo "Project gate failed; artifacts: ${ARTIFACT_DIR}" >&2
  exit "${status}"
fi

if [[ "${PRINT_SUMMARY}" == "1" ]]; then
  "${ROOT_DIR}/tools/agent-preflight-summary.sh"
  echo
  echo "Agent preflight fast passed."
fi
