#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
ARTIFACT_DIR="${REPO_DIR}/ci-artifacts"

mkdir -p "${ARTIFACT_DIR}"

echo "== Project gate =="
set +e
"${ROOT_DIR}/tools/check-all.sh" 2>&1 | tee "${ARTIFACT_DIR}/check-all.log"
status="${PIPESTATUS[0]}"
set -e
if [[ "${status}" -ne 0 ]]; then
  echo "Project gate failed; artifacts: ${ARTIFACT_DIR}" >&2
  exit "${status}"
fi

echo
echo "== Native UI smoke =="
"${ROOT_DIR}/tools/check-ui-smoke.sh"

echo
echo "== Native gameplay smoke =="
"${ROOT_DIR}/tools/check-gameplay-smoke.sh"

echo
echo "== Changed files =="
git -C "${REPO_DIR}" status --short || true

echo
echo "== Generated artifacts =="
if [[ -d "${REPO_DIR}/ci-artifacts" ]]; then
  find "${REPO_DIR}/ci-artifacts" -maxdepth 5 -type f -print \
    | sed "s#^${REPO_DIR}/#- #"
else
  echo "- none"
fi

echo
echo "== Known warnings =="
if [[ -f "${REPO_DIR}/ci-artifacts/check-all.log" ]] \
  && grep -Fq "ObjectDB instances leaked at exit" "${REPO_DIR}/ci-artifacts/check-all.log"; then
  echo "- ObjectDB instances leaked at exit: known TD-007"
else
  echo "- none detected"
fi

echo
echo "== Pages =="
echo "- playable: https://kingwl.github.io/wwl-adv-2/play/"

echo
echo "Agent preflight passed."
