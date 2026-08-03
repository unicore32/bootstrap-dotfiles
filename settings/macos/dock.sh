#!/usr/bin/env bash
set -Eeuo pipefail

readonly DOMAIN="com.apple.dock"
readonly TILE_SIZE="28"
readonly LARGE_SIZE="72"
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

[[ "$(uname -s)" == "Darwin" ]] || { echo '[dock] macOS only' >&2; exit 2; }

read_default() {
  defaults read "$DOMAIN" "$1" 2>/dev/null || true
}

current_tile_size="$(read_default tilesize)"
current_large_size="$(read_default largesize)"
current_magnification="$(read_default magnification)"
current_autohide="$(read_default autohide)"

drift="false"
[[ "$current_tile_size" == "$TILE_SIZE" ]] || drift="true"
[[ "$current_large_size" == "$LARGE_SIZE" ]] || drift="true"
[[ "$current_magnification" == "1" ]] || drift="true"
[[ "$current_autohide" == "1" ]] || drift="true"

if [[ "$drift" == "false" ]]; then
  echo "[dock] configured: size=$TILE_SIZE magnification=$LARGE_SIZE autohide=on"
  exit 0
fi

if [[ "$MODE" == "check" ]]; then
  echo "[dock] drift: size=${current_tile_size:-unset}/$TILE_SIZE magnification=${current_large_size:-unset}/$LARGE_SIZE enabled=${current_magnification:-unset}/1 autohide=${current_autohide:-unset}/1" >&2
  exit 1
fi

apply_default() {
  local key="$1"
  local type="$2"
  local value="$3"
  local current="$4"
  local expected="${5:-$value}"
  [[ "$current" == "$expected" ]] && return
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] defaults write $DOMAIN $key $type $value"
  else
    defaults write "$DOMAIN" "$key" "$type" "$value"
  fi
}

apply_default tilesize -int "$TILE_SIZE" "$current_tile_size"
apply_default largesize -int "$LARGE_SIZE" "$current_large_size"
apply_default magnification -bool true "$current_magnification" 1
apply_default autohide -bool true "$current_autohide" 1

if [[ "$DRY_RUN" == "true" ]]; then
  echo '[dry-run] restart Dock if a setting changes'
else
  killall Dock 2>/dev/null || true
  echo "[dock] configured: size=$TILE_SIZE magnification=$LARGE_SIZE autohide=on"
fi
