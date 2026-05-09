#!/usr/bin/env bash
set -euo pipefail

GAME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "${GAME_DIR}/.." && pwd)"
DOCS_DIR="${REPO_DIR}/docs"

failed=0

fail() {
  echo "docs check failed: $*" >&2
  failed=1
}

require_file() {
  local path="$1"
  if [[ ! -f "${path}" ]]; then
    fail "missing file ${path#${REPO_DIR}/}"
  fi
}

require_file "${REPO_DIR}/AGENTS.md"
require_file "${DOCS_DIR}/README.md"
require_file "${DOCS_DIR}/status.md"
require_file "${DOCS_DIR}/designs/README.md"
require_file "${DOCS_DIR}/testing/README.md"
require_file "${DOCS_DIR}/testing/checklist.md"
require_file "${DOCS_DIR}/testing/gates.md"
require_file "${DOCS_DIR}/testing/prototype-rule-coverage.md"
require_file "${DOCS_DIR}/todo/backlog.md"
require_file "${DOCS_DIR}/tech-debt/register.md"

while IFS= read -r root_file; do
  if [[ "$(basename "${root_file}")" == "agents.md" ]]; then
    fail "use AGENTS.md, not agents.md"
  fi
done < <(find "${REPO_DIR}" -maxdepth 1 -type f -print)

if [[ -e "${DOCS_DIR}/todo/testing-checklist.md" ]]; then
  fail "testing checklist moved to docs/testing/checklist.md"
fi

if [[ -f "${DOCS_DIR}/designs/README.md" ]]; then
  while IFS= read -r design_file; do
    design_name="$(basename "${design_file}")"
    case "${design_name}" in
      README.md|template.md)
        continue
        ;;
    esac

    if ! grep -Fq "\`${design_name}\`" "${DOCS_DIR}/designs/README.md"; then
      fail "design index missing ${design_name}"
    fi
  done < <(find "${DOCS_DIR}/designs" -maxdepth 1 -type f -name '*.md' -print | sort)
fi

if [[ -f "${DOCS_DIR}/README.md" ]]; then
  for required_entry in "status.md" "designs/" "testing/" "todo/" "tech-debt/"; do
    if ! grep -Fq "${required_entry}" "${DOCS_DIR}/README.md"; then
      fail "docs README missing ${required_entry}"
    fi
  done
fi

if [[ "${failed}" -ne 0 ]]; then
  exit 1
fi

echo "docs check passed"
