#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DRYRUN=false
for arg in "$@"; do
  case "$arg" in
    -DryRun) DRYRUN=true ;;
  esac
done

MANIFEST="$REPO_ROOT/manifests/macos-settings.sh"

if [[ ! -f "$MANIFEST" ]]; then
  echo "[WARN] macOS manifest not found: $MANIFEST. Nothing to do." >&2
  exit 0
fi

echo "[INFO] Applying macOS settings from manifest: $MANIFEST (DryRun=$DRYRUN)"

if $DRYRUN; then
  echo "[DRYRUN] The manifest contains the following commands:" 
  sed -n '1,200p' "$MANIFEST"
  exit 0
fi

# Execute manifest (it should be idempotent and documented)
echo "[INFO] Sourcing manifest..."
source "$MANIFEST"

echo "[INFO] macOS settings applied."
