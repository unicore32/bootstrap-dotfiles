#!/usr/bin/env bash
# Sample macOS settings manifest.
# Put safe, idempotent commands here. This file is sourced by
# `scripts/mac/apply-settings.sh` when run (not dot-sourced into other scripts).
# Document sources/refs for each setting.

set -euo pipefail

# Example: set Finder to show hidden files
# source: https://support.apple.com/ (use official docs as needed)
defaults write com.apple.finder AppleShowAllFiles -bool true

# Example: show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Restart Finder to apply
killall Finder 2>/dev/null || true

echo "[INFO] Sample macOS manifest applied. Replace this file with your desired settings."
