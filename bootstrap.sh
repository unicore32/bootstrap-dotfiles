#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(uname -s)" == "Darwin" ]]; then
  # On macOS prefer the native shell runner (no pwsh required)
  if [[ -x "$SCRIPT_DIR/scripts/mac/apply-settings.sh" ]]; then
    exec "$SCRIPT_DIR/scripts/mac/apply-settings.sh" "$@"
  else
    echo "[ERROR] macOS runner not found: $SCRIPT_DIR/scripts/mac/apply-settings.sh"
    exit 1
  fi
else
  if ! command -v pwsh >/dev/null 2>&1; then
    echo "[ERROR] PowerShell 7 (pwsh) is required on non-macOS hosts."
    echo "Install from: https://learn.microsoft.com/powershell/scripting/install/installing-powershell"
    exit 1
  fi

  pwsh -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/scripts/bootstrap.ps1" "$@"
fi
