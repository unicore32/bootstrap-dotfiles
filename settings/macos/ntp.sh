#!/usr/bin/env bash
set -Eeuo pipefail

readonly NTP_SERVER="ntp.jst.mfeed.ad.jp"
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

[[ "$(uname -s)" == "Darwin" ]] || { echo '[ntp] macOS only' >&2; exit 2; }

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[dry-run] ensure NTP server is $NTP_SERVER (personal macOS only)"
  echo "[dry-run] sudo systemsetup -setnetworktimeserver $NTP_SERVER"
  echo '[dry-run] sudo systemsetup -setusingnetworktime on'
  exit 0
fi

current_server="$(sudo systemsetup -getnetworktimeserver 2>/dev/null | sed 's/^[^:]*:[[:space:]]*//')"
network_time="$(sudo systemsetup -getusingnetworktime 2>/dev/null | sed 's/^[^:]*:[[:space:]]*//')"

if [[ "$current_server" == "$NTP_SERVER" && "$network_time" == "On" ]]; then
  echo "[ntp] configured: $NTP_SERVER"
  exit 0
fi

if [[ "$MODE" == "check" ]]; then
  echo "[ntp] drift: server=$current_server network-time=$network_time expected=$NTP_SERVER" >&2
  exit 1
fi

sudo systemsetup -setnetworktimeserver "$NTP_SERVER"
sudo systemsetup -setusingnetworktime on
echo "[ntp] configured: $NTP_SERVER"
