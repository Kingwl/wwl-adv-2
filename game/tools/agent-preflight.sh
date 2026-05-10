#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "--full" ]]; then
  exec "${ROOT_DIR}/tools/agent-preflight-full.sh"
fi

exec "${ROOT_DIR}/tools/agent-preflight-fast.sh"
