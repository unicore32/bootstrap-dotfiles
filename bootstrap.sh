#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v pwsh >/dev/null 2>&1; then
  echo "[ERROR] PowerShell 7 (pwsh) is required."
  echo "Install from: https://learn.microsoft.com/powershell/scripting/install/installing-powershell"
  exit 1
fi

pwsh -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/scripts/bootstrap.ps1" "$@"
