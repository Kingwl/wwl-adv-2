#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
ARTIFACT_DIR="${STRUCTURE_ARTIFACT_DIR:-${REPO_DIR}/ci-artifacts/structure}"
CACHE_DIR="${STRUCTURE_CACHE_DIR:-${REPO_DIR}/build/structure-cache}"
VENV_DIR="${STRUCTURE_VENV_DIR:-${CACHE_DIR}/venv}"
GRAMMAR_TAG="${STRUCTURE_GDSCRIPT_GRAMMAR_TAG:-v6.1.0}"
GRAMMAR_URL="${STRUCTURE_GDSCRIPT_GRAMMAR_URL:-https://github.com/PrestonKnopp/tree-sitter-gdscript.git}"
GRAMMAR_DIR="${STRUCTURE_GDSCRIPT_GRAMMAR_DIR:-${CACHE_DIR}/tree-sitter-gdscript-${GRAMMAR_TAG}}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

mkdir -p "${ARTIFACT_DIR}" "${CACHE_DIR}"

if ! command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
  echo "Python 3 is required for structural lint. Set PYTHON_BIN if needed." >&2
  exit 1
fi

if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
  "${PYTHON_BIN}" -m venv "${VENV_DIR}"
fi

if ! "${VENV_DIR}/bin/python" -c "import tree_sitter" >/dev/null 2>&1; then
  PIP_DISABLE_PIP_VERSION_CHECK=1 "${VENV_DIR}/bin/python" -m pip install --quiet -r "${ROOT_DIR}/tools/requirements-structure.txt"
fi

if [[ ! -d "${GRAMMAR_DIR}/src" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "git is required to fetch ${GRAMMAR_URL} for structural lint." >&2
    exit 1
  fi

  rm -rf "${GRAMMAR_DIR}"
  git -c advice.detachedHead=false clone \
    --quiet \
    --depth 1 \
    --branch "${GRAMMAR_TAG}" \
    "${GRAMMAR_URL}" \
    "${GRAMMAR_DIR}"
fi

"${VENV_DIR}/bin/python" "${ROOT_DIR}/tools/check-structure.py" \
  --repo-root "${REPO_DIR}" \
  --artifact-dir "${ARTIFACT_DIR}" \
  --cache-dir "${CACHE_DIR}" \
  --grammar-dir "${GRAMMAR_DIR}"
