#!/usr/bin/env bash
set -u

PLATFORM=""
PROFILE="personal"
while (($#)); do
  case "$1" in
    --platform) PLATFORM="${2:?}"; shift ;;
    --profile) PROFILE="${2:?}"; shift ;;
  esac
  shift
done

failed=0
check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    printf '[ok]      %s\n' "$1"
  else
    printf '[missing] %s\n' "$1"
    failed=1
  fi
}

echo "platform=$PLATFORM profile=$PROFILE"
for command in git chezmoi jq mise rg; do check_command "$command"; done
[[ "$PLATFORM" == macos ]] && check_command brew
[[ "$PLATFORM" == wsl ]] && check_command zsh

if command -v chezmoi >/dev/null 2>&1; then
  chezmoi doctor || failed=1
fi

exit "$failed"

