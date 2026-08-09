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

[[ "$(uname -s)" == "Linux" ]] || die 'wsl.sh must run on Linux'
require_profile

install_packages() {
  local files=("$ROOT_DIR/packages/wsl-common.txt") packages=()
  [[ "$PROFILE" == "personal" ]] && files+=("$ROOT_DIR/packages/wsl-personal.txt")
  mapfile -t packages < <(read_list "${files[0]}")
  if ((${#files[@]} > 1)); then
    while IFS= read -r package; do packages+=("$package"); done < <(read_list "${files[1]}")
  fi
  run sudo apt-get update
  ((${#packages[@]})) && run sudo apt-get install -y "${packages[@]}"
}

install_mise() {
  command -v mise >/dev/null 2>&1 && return
  if [[ "$DRY_RUN" == "true" ]]; then
    log '[dry-run] install mise into ~/.local/bin'
  else
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

main() {
  if [[ "$COMMAND" == "check" ]]; then
    exec bash "$ROOT_DIR/scripts/health-check.sh" --platform wsl --profile "$PROFILE"
  fi
  install_packages
  install_mise
  if ! command -v chezmoi >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log '[dry-run] install chezmoi into ~/.local/bin'
    else
      sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
      export PATH="$HOME/.local/bin:$PATH"
    fi
  fi
  apply_dotfiles
  install_mise_tools
  if [[ "$PROFILE" == "personal" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log "[dry-run] MISE_CONFIG_FILE=$ROOT_DIR/mise/personal-wsl.toml mise install"
    else
      MISE_CONFIG_FILE="$ROOT_DIR/mise/personal-wsl.toml" mise install
    fi
  fi
  install_vscode_extensions "$ROOT_DIR/vscode/extensions-common.txt" \
    "$ROOT_DIR/vscode/extensions-wsl.txt" \
    "$([[ "$PROFILE" == personal ]] && echo "$ROOT_DIR/vscode/extensions-personal.txt")"
  [[ "$DRY_RUN" == "true" ]] && { log 'dry-run completed'; return; }
  bash "$ROOT_DIR/scripts/health-check.sh" --platform wsl --profile "$PROFILE"
  if [[ "${SHELL:-}" != "$(command -v zsh)" ]]; then
    log "zsh is installed. To make it your login shell, run: chsh -s $(command -v zsh)"
  fi
}

main
