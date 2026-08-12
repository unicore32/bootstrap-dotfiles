#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT_DIR
# ROOT_DIR is resolved at runtime from this script's location.
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/lib.sh"

COMMAND="install"
PROFILE="personal"
DRY_RUN="false"
COMPONENTS=""

usage() {
  echo 'Usage: ./bootstrap.sh [install|update] [--profile personal|work] [--components packages,dotfiles,mise,vscode,settings] [--dry-run]'
  echo '       ./bootstrap.sh check [--profile personal|work]'
}

while (($#)); do
  case "$1" in
    install|update|check) COMMAND="$1" ;;
    --profile) PROFILE="${2:?--profile requires a value}"; shift ;;
    --components) COMPONENTS="${2:?--components requires a value}"; shift ;;
    --dry-run) DRY_RUN="true" ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

[[ "$(uname -s)" == "Darwin" ]] || die 'macos.sh must run on macOS'
require_profile
if [[ -n "$COMPONENTS" ]]; then
  [[ "$COMMAND" != "check" ]] || die '--components is only supported by install and update'
  parse_components "$COMPONENTS"
fi

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
    bash "$ROOT_DIR/scripts/health-check.sh" --platform macos --profile "$PROFILE"
    bash "$ROOT_DIR/settings/macos/dock.sh" --check
    bash "$ROOT_DIR/settings/macos/finder.sh" --check
    bash "$ROOT_DIR/settings/macos/natural-scroll.sh" --check
    [[ "$PROFILE" == "personal" ]] && bash "$ROOT_DIR/settings/macos/touch-id.sh" --check
    [[ "$PROFILE" == "personal" ]] && bash "$ROOT_DIR/settings/macos/ntp.sh" --check
    return
  fi
  component_selected packages && { install_homebrew; install_packages; }
  component_selected dotfiles && apply_dotfiles
  component_selected mise && install_mise_tools
  if component_selected vscode; then
    install_vscode_extensions "$ROOT_DIR/vscode/extensions-common.txt" \
      "$([[ "$PROFILE" == personal ]] && echo "$ROOT_DIR/vscode/extensions-personal.txt")"
  fi
  if component_selected settings; then
    if [[ "$DRY_RUN" == "true" ]]; then
      bash "$ROOT_DIR/settings/macos/dock.sh" --dry-run
      bash "$ROOT_DIR/settings/macos/finder.sh" --dry-run
      bash "$ROOT_DIR/settings/macos/natural-scroll.sh" --dry-run
    else
      bash "$ROOT_DIR/settings/macos/dock.sh"
      bash "$ROOT_DIR/settings/macos/finder.sh"
      bash "$ROOT_DIR/settings/macos/natural-scroll.sh"
    fi
  fi
  if component_selected settings && [[ "$PROFILE" == "personal" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      bash "$ROOT_DIR/settings/macos/touch-id.sh" --dry-run
      bash "$ROOT_DIR/settings/macos/ntp.sh" --dry-run
    else
      bash "$ROOT_DIR/settings/macos/touch-id.sh"
      bash "$ROOT_DIR/settings/macos/ntp.sh"
    fi
  fi
  [[ "$DRY_RUN" == "true" ]] && { log 'dry-run completed'; return; }
  [[ -z "$COMPONENTS" ]] && bash "$ROOT_DIR/scripts/health-check.sh" --platform macos --profile "$PROFILE"
}

main
