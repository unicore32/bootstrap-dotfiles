#!/usr/bin/env bash

log() { printf '[bootstrap] %s\n' "$*"; }
die() { printf '[bootstrap] ERROR: %s\n' "$*" >&2; exit 1; }

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

require_profile() {
  case "$PROFILE" in
    personal|work) ;;
    *) die "profile must be personal or work: $PROFILE" ;;
  esac
}

read_list() {
  sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$1"
}

install_vscode_extensions() {
  command -v code >/dev/null 2>&1 || { log 'VS Code CLI not found; skipping extensions'; return; }
  local file extension
  for file in "$@"; do
    [[ -f "$file" ]] || continue
    while IFS= read -r extension; do
      [[ -n "$extension" ]] && run code --install-extension "$extension" --force
    done < <(read_list "$file")
  done
}

apply_dotfiles() {
  if ! command -v chezmoi >/dev/null 2>&1; then
    [[ "$DRY_RUN" == "true" ]] && { log '[dry-run] chezmoi init/apply'; return; }
    die 'chezmoi is not installed'
  fi
  local args=(--source "$ROOT_DIR/home")
  if [[ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml" ]]; then
    run chezmoi init "${args[@]}" --promptChoice "profile=$PROFILE"
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    chezmoi apply "${args[@]}" --dry-run --verbose
  else
    chezmoi apply "${args[@]}" --verbose
  fi
}

install_mise_tools() {
  command -v mise >/dev/null 2>&1 || { log 'mise not found; skipping runtimes'; return; }
  if [[ "$DRY_RUN" == "true" ]]; then
    log "[dry-run] MISE_CONFIG_FILE=$ROOT_DIR/mise/config.toml mise install"
  else
    MISE_CONFIG_FILE="$ROOT_DIR/mise/config.toml" mise install
  fi
}
