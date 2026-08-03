#!/usr/bin/env bash
set -Eeuo pipefail

readonly DOMAIN="NSGlobalDomain"
readonly KEY="com.apple.swipescrolldirection"
MODE="apply"
DRY_RUN="false"

while (($#)); do
  case "$1" in
    --check) MODE="check" ;;
    --dry-run) DRY_RUN="true" ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

[[ "$(uname -s)" == "Darwin" ]] || { echo '[natural-scroll] macOS only' >&2; exit 2; }

current="$(defaults read "$DOMAIN" "$KEY" 2>/dev/null || true)"
if [[ "$current" == "0" ]]; then
  echo '[natural-scroll] disabled'
  exit 0
fi

if [[ "$MODE" == "check" ]]; then
  echo "[natural-scroll] drift: current=${current:-unset} expected=0" >&2
  exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[dry-run] defaults write $DOMAIN $KEY -bool false"
  exit 0
fi

defaults write "$DOMAIN" "$KEY" -bool false
echo '[natural-scroll] disabled; restart applications or log in again if needed'

