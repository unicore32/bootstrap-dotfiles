#!/usr/bin/env bash
set -Eeuo pipefail

readonly PAM_FILE="/etc/pam.d/sudo_local"
readonly PAM_RULE="auth       sufficient     pam_tid.so"
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

[[ "$(uname -s)" == "Darwin" ]] || { echo '[touch-id] macOS only' >&2; exit 2; }

has_touch_id_rule() {
  [[ -f "$PAM_FILE" ]] && grep -Eq '^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so([[:space:]]|$)' "$PAM_FILE"
}

if has_touch_id_rule; then
  echo '[touch-id] configured for sudo'
  exit 0
fi

if [[ -e "$PAM_FILE" ]]; then
  echo "[touch-id] unmanaged $PAM_FILE exists without a pam_tid.so rule; refusing to overwrite it" >&2
  exit 1
fi

if [[ "$MODE" == "check" ]]; then
  echo "[touch-id] drift: $PAM_FILE is missing" >&2
  exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[dry-run] create $PAM_FILE with Touch ID sudo authentication (personal macOS only)"
  exit 0
fi

[[ -f /usr/lib/pam/pam_tid.so.2 ]] || { echo '[touch-id] pam_tid.so is unavailable' >&2; exit 1; }

temporary_file="$(mktemp)"
trap 'rm -f "$temporary_file"' EXIT
printf '%s\n' "$PAM_RULE" > "$temporary_file"
sudo install -o root -g wheel -m 0444 "$temporary_file" "$PAM_FILE"
echo '[touch-id] configured for sudo'
