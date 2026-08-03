#!/usr/bin/env bash
set -Eeuo pipefail

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"

COMMAND="install"
PROFILE="personal"
DRY_RUN="false"

usage() {
  echo 'Usage: ./bootstrap.sh [install|update|check] [--profile personal|work] [--dry-run]'
}

while (($#)); do
  case "$1" in
    install|update|check) COMMAND="$1" ;;
    --profile) PROFILE="${2:?--profile requires a value}"; shift ;;
    --dry-run) DRY_RUN="true" ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

[[ "$(uname -s)" == "Darwin" ]] || die 'macos.sh must run on macOS'
require_profile

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    [[ "$DRY_RUN" == "true" ]] && { log '[dry-run] install Homebrew'; return; }
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
}

install_packages() {
  run brew bundle --file="$ROOT_DIR/packages/Brewfile.common"
  [[ "$PROFILE" == "personal" ]] && run brew bundle --file="$ROOT_DIR/packages/Brewfile.personal"

  if [[ -f "$ROOT_DIR/packages/macos-manual-common.txt" ]]; then
    log 'Manual common applications:'
    while IFS= read -r item; do
      [[ -n "$item" ]] && log "  $item"
    done < <(read_list "$ROOT_DIR/packages/macos-manual-common.txt")
  fi
}

main() {
  if [[ "$COMMAND" == "check" ]]; then
    exec bash "$ROOT_DIR/scripts/health-check.sh" --platform macos --profile "$PROFILE"
  fi
  install_homebrew
  install_packages
  apply_dotfiles
  install_mise_tools
  install_vscode_extensions "$ROOT_DIR/vscode/extensions-common.txt" \
    "$([[ "$PROFILE" == personal ]] && echo "$ROOT_DIR/vscode/extensions-personal.txt")"
  [[ "$DRY_RUN" == "true" ]] && { log 'dry-run completed'; return; }
  bash "$ROOT_DIR/scripts/health-check.sh" --platform macos --profile "$PROFILE"
}

main
