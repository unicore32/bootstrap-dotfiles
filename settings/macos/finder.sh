#!/usr/bin/env bash
set -Eeuo pipefail

readonly FINDER_DOMAIN="com.apple.finder"
readonly WINDOW_TARGET="PfLo"
readonly WINDOW_PATH="file:///"
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

[[ "$(uname -s)" == "Darwin" ]] || { echo '[finder] macOS only' >&2; exit 2; }

current_target="$(defaults read "$FINDER_DOMAIN" NewWindowTarget 2>/dev/null || true)"
current_path="$(defaults read "$FINDER_DOMAIN" NewWindowTargetPath 2>/dev/null || true)"
current_extensions="$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null || true)"

drift="false"
[[ "$current_target" == "$WINDOW_TARGET" ]] || drift="true"
[[ "$current_path" == "$WINDOW_PATH" ]] || drift="true"
[[ "$current_extensions" == "1" ]] || drift="true"

if [[ "$drift" == "false" ]]; then
  echo '[finder] configured: new windows show Macintosh HD; all extensions visible'
  exit 0
fi

if [[ "$MODE" == "check" ]]; then
  echo "[finder] drift: target=${current_target:-unset}/$WINDOW_TARGET path=${current_path:-unset}/$WINDOW_PATH extensions=${current_extensions:-unset}/1" >&2
  exit 1
fi

write_if_needed() {
  local domain="$1"
  local key="$2"
  local type="$3"
  local value="$4"
  local current="$5"
  local expected="${6:-$value}"
  [[ "$current" == "$expected" ]] && return
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] defaults write $domain $key $type $value"
  else
    defaults write "$domain" "$key" "$type" "$value"
  fi
}

write_if_needed "$FINDER_DOMAIN" NewWindowTarget -string "$WINDOW_TARGET" "$current_target"
write_if_needed "$FINDER_DOMAIN" NewWindowTargetPath -string "$WINDOW_PATH" "$current_path"
write_if_needed NSGlobalDomain AppleShowAllExtensions -bool true "$current_extensions" 1

if [[ "$DRY_RUN" == "true" ]]; then
  echo '[dry-run] restart Finder if a setting changes'
else
  killall Finder 2>/dev/null || true
  echo '[finder] configured: new windows show Macintosh HD; all extensions visible'
fi
