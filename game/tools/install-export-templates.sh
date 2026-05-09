#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
GODOT_VERSION="${GODOT_VERSION:-4.6.2}"
GODOT_RELEASE="${GODOT_RELEASE:-stable}"
TEMPLATE_VERSION="${GODOT_VERSION}.${GODOT_RELEASE}"
TEMPLATE_ASSET="Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_export_templates.tpz"
TEMPLATE_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/${TEMPLATE_ASSET}"

case "$(uname -s)" in
  Darwin)
    TEMPLATE_DIR="${HOME}/Library/Application Support/Godot/export_templates/${TEMPLATE_VERSION}"
    ;;
  Linux)
    TEMPLATE_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/godot/export_templates/${TEMPLATE_VERSION}"
    ;;
  *)
    echo "unsupported OS for automatic Godot export template install: $(uname -s)" >&2
    exit 1
    ;;
esac

if [[ -f "${TEMPLATE_DIR}/web_release.zip" && -f "${TEMPLATE_DIR}/web_nothreads_release.zip" ]]; then
  echo "Godot export templates already installed: ${TEMPLATE_DIR}"
  exit 0
fi

if [[ ! -x "${GODOT_BIN}" && "${GODOT_BIN}" != "godot" ]]; then
  echo "missing executable GODOT_BIN=${GODOT_BIN}" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "missing curl" >&2
  exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "missing unzip" >&2
  exit 1
fi

CACHE_DIR="${GODOT_EXPORT_TEMPLATE_CACHE:-${REPO_DIR}/build/cache/godot-export-templates}"
ARCHIVE_PATH="${CACHE_DIR}/${TEMPLATE_ASSET}"
mkdir -p "${CACHE_DIR}" "${TEMPLATE_DIR}"

if [[ ! -f "${ARCHIVE_PATH}" ]]; then
  echo "Downloading ${TEMPLATE_URL}"
  curl -fsSL "${TEMPLATE_URL}" -o "${ARCHIVE_PATH}"
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

unzip -q "${ARCHIVE_PATH}" -d "${TMP_DIR}"

WEB_TEMPLATE_COUNT=0
while IFS= read -r template_path; do
  cp "${template_path}" "${TEMPLATE_DIR}/$(basename "${template_path}")"
  WEB_TEMPLATE_COUNT=$((WEB_TEMPLATE_COUNT + 1))
done < <(find "${TMP_DIR}" -type f -name 'web*.zip' | sort)

if [[ "${WEB_TEMPLATE_COUNT}" -eq 0 ]]; then
  echo "Web export templates not found in ${ARCHIVE_PATH}" >&2
  exit 1
fi

echo "Installed Godot web export templates: ${TEMPLATE_DIR}"
