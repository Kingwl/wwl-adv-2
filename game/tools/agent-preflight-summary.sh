#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "${ROOT_DIR}/.." && pwd)"

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
REPORT_JSON="${REPO_DIR}/ci-artifacts/godot-log/report.json"
if [[ -f "${REPORT_JSON}" ]]; then
  python3 - "${REPORT_JSON}" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1], encoding="utf-8"))
known = report.get("findings", {}).get("known_warnings", [])
if not known:
    print("- none detected")
else:
    for item in known:
        print(f"- {item.get('id', 'known')}: {item.get('message', '')}")
PY
elif [[ -f "${REPO_DIR}/ci-artifacts/check-all.log" ]] \
  && grep -Fq "ObjectDB instances leaked at exit" "${REPO_DIR}/ci-artifacts/check-all.log"; then
  echo "- ObjectDB instances leaked at exit: known TD-007"
else
  echo "- none detected"
fi

echo
echo "== Pages =="
echo "- playable: https://kingwl.github.io/wwl-adv-2/play/"
