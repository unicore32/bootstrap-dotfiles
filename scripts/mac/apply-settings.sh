#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Defaults
ONLY='all'
DRYRUN=false

# Parse args: support `-Only value`, `-Only=value`, and `-DryRun`
while [ $# -gt 0 ]; do
  case "$1" in
    -DryRun)
      DRYRUN=true
      shift
      ;;
    -Only)
      shift
      ONLY="${1:-all}"
      shift
      ;;
    -Only=*)
      ONLY="${1#-Only=}"
      shift
      ;;
    *)
      # ignore other args
      shift
      ;;
  esac
done

MANIFEST="$REPO_ROOT/manifests/macos-settings.sh"

echo "[INFO] mac runner: Only=$ONLY DryRun=$DRYRUN"

if [[ "$ONLY" == "all" || "$ONLY" == "windows-settings" || "$ONLY" == "macos-settings" ]]; then
  if [[ ! -f "$MANIFEST" ]]; then
    echo "[WARN] macOS manifest not found: $MANIFEST. Skipping settings." >&2
  else
    echo "[INFO] Applying macOS settings from manifest: $MANIFEST (DryRun=$DRYRUN)"
    if $DRYRUN; then
      echo "[DRYRUN] The manifest contains the following commands:"
      sed -n '1,200p' "$MANIFEST"
    else
      echo "[INFO] Sourcing manifest..."
      # shellcheck source=/dev/null
      source "$MANIFEST"
      echo "[INFO] macOS settings applied."
    fi
  fi
fi

# Handle packages via brew when requested
if [[ "$ONLY" == "all" || "$ONLY" == "packages" ]]; then
  BREWFILE="$REPO_ROOT/manifests/Brewfile"
  if [[ ! -f "$BREWFILE" ]]; then
    echo "[WARN] Brewfile not found: $BREWFILE. Skipping brew step." >&2
  else
    if $DRYRUN; then
      echo "[DRYRUN] brew bundle check --file \"$BREWFILE\""
    else
      if ! command -v brew >/dev/null 2>&1; then
        if $DRYRUN; then
          echo "[DRYRUN] Would install Homebrew via the official installer: https://brew.sh/"
        else
          echo "[WARN] Homebrew not found."
          if [ "${AUTO_YES:-0}" = "1" ]; then
            echo "[INFO] AUTO_YES=1 set; installing Homebrew non-interactively."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
          else
            read -r -p "Install Homebrew now? [y/N] " _ans
            if [[ "$_ans" =~ ^[Yy]$ ]]; then
              /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            else
              echo "[ERROR] Homebrew is required to install packages. Skipping brew step." >&2
            fi
          fi

          # ensure brew is available in PATH for this session if installed
          if command -v brew >/dev/null 2>&1; then
            export PATH="$(brew --prefix)/bin:$PATH"
          fi
        fi
      else
        echo "[INFO] Running: brew bundle --file \"$BREWFILE\""
        brew bundle --file "$BREWFILE"
      fi
    fi
  fi
fi

exit 0
