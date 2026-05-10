#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
EXPORT_DIR="${1:-${WEB_SMOKE_EXPORT_DIR:-${REPO_DIR}/build/web-smoke}}"
ARTIFACT_DIR="${WEB_SMOKE_ARTIFACT_DIR:-${REPO_DIR}/ci-artifacts/web-smoke}"
SKIP_EXPORT="${WEB_SMOKE_SKIP_EXPORT:-0}"
BOOTSTRAP_PLAYWRIGHT="${WEB_SMOKE_BOOTSTRAP_PLAYWRIGHT:-1}"
WEB_SMOKE_VENV_DIR="${WEB_SMOKE_VENV_DIR:-${REPO_DIR}/build/web-smoke-python}"

if ! command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
  echo "missing ${PYTHON_BIN}" >&2
  exit 1
fi

EXPORT_DIR="$(
  "${PYTHON_BIN}" -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).expanduser().resolve(strict=False))' \
    "${EXPORT_DIR}"
)"
ARTIFACT_DIR="$(
  "${PYTHON_BIN}" -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).expanduser().resolve(strict=False))' \
    "${ARTIFACT_DIR}"
)"

case "${EXPORT_DIR}/" in
  "${ROOT_DIR}/"*)
    echo "refusing to smoke Web build inside Godot project: ${EXPORT_DIR}" >&2
    echo "use a path outside ${ROOT_DIR}, for example ${REPO_DIR}/build/web-smoke" >&2
    exit 1
    ;;
esac

rm -rf "${ARTIFACT_DIR}"
mkdir -p "${ARTIFACT_DIR}"

if [[ "${SKIP_EXPORT}" != "1" ]]; then
  set +e
  "${ROOT_DIR}/tools/export-web.sh" "${EXPORT_DIR}" 2>&1 | tee "${ARTIFACT_DIR}/export.log"
  export_status="${PIPESTATUS[0]}"
  set -e

  if [[ "${export_status}" -ne 0 ]]; then
    echo "Web export failed; see ${ARTIFACT_DIR}/export.log" >&2
    exit "${export_status}"
  fi
else
  if [[ ! -f "${EXPORT_DIR}/index.html" ]]; then
    echo "WEB_SMOKE_SKIP_EXPORT=1 but ${EXPORT_DIR}/index.html does not exist" >&2
    exit 1
  fi
fi

RUNNER_PYTHON="${PYTHON_BIN}"
if ! "${RUNNER_PYTHON}" -c 'from playwright.sync_api import sync_playwright' >/dev/null 2>&1; then
  if [[ "${BOOTSTRAP_PLAYWRIGHT}" != "1" ]]; then
    echo "missing Playwright for ${RUNNER_PYTHON}" >&2
    echo "install it with: ${RUNNER_PYTHON} -m pip install playwright && ${RUNNER_PYTHON} -m playwright install chromium" >&2
    exit 1
  fi

  if [[ -x "${WEB_SMOKE_VENV_DIR}/bin/python" ]] \
    && "${WEB_SMOKE_VENV_DIR}/bin/python" -c 'from playwright.sync_api import sync_playwright' >/dev/null 2>&1; then
    RUNNER_PYTHON="${WEB_SMOKE_VENV_DIR}/bin/python"
  else
    echo "Playwright is missing for ${RUNNER_PYTHON}; creating local venv at ${WEB_SMOKE_VENV_DIR}"
    "${PYTHON_BIN}" -m venv "${WEB_SMOKE_VENV_DIR}"
    RUNNER_PYTHON="${WEB_SMOKE_VENV_DIR}/bin/python"
    "${RUNNER_PYTHON}" -m pip install --upgrade pip
    "${RUNNER_PYTHON}" -m pip install "playwright>=1.40,<2"
    "${RUNNER_PYTHON}" -m playwright install chromium
  fi
fi

set +e
"${RUNNER_PYTHON}" "${ROOT_DIR}/tools/web_smoke_runner.py" \
  "${EXPORT_DIR}" \
  --artifact-dir "${ARTIFACT_DIR}" \
  2>&1 | tee "${ARTIFACT_DIR}/runner.log"
runner_status="${PIPESTATUS[0]}"
set -e

if [[ -f "${ARTIFACT_DIR}/report.md" ]]; then
  cat "${ARTIFACT_DIR}/report.md"
fi

exit "${runner_status}"
