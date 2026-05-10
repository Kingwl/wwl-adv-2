#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

WWL_PREFLIGHT_PRINT_SUMMARY=0 "${ROOT_DIR}/tools/agent-preflight-fast.sh"

echo
echo "== Native UI smoke =="
"${ROOT_DIR}/tools/check-ui-smoke.sh"

echo
echo "== Native gameplay smoke =="
"${ROOT_DIR}/tools/check-gameplay-smoke.sh"

"${ROOT_DIR}/tools/agent-preflight-summary.sh"

echo
echo "Agent preflight full passed."
