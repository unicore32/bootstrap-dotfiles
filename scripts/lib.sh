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

VALID_COMPONENTS=(packages dotfiles mise vscode settings)
SELECTED_COMPONENTS=()

parse_components() {
  local value="$1" component normalized existing
  local -a supplied=() normalized_components=()
  [[ -n "$value" ]] || die '--components requires at least one component'
  [[ "$value" != *, ]] || die '--components must not contain an empty component'

  IFS=',' read -r -a supplied <<< "$value"
  ((${#supplied[@]})) || die '--components requires at least one component'
  for component in "${supplied[@]}"; do
    normalized="$(printf '%s' "$component" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [[ -n "$normalized" ]] || die '--components must not contain an empty component'
    case "$normalized" in
      packages|dotfiles|mise|vscode|settings) ;;
      *) die "unknown component: $component (valid: ${VALID_COMPONENTS[*]})" ;;
    esac
    for existing in "${normalized_components[@]:-}"; do
      [[ "$existing" == "$normalized" ]] && die "duplicate component: $normalized"
    done
    normalized_components+=("$normalized")
  done
  SELECTED_COMPONENTS=("${normalized_components[@]}")
}

component_selected() {
  local component="$1" selected
  ((${#SELECTED_COMPONENTS[@]} == 0)) && return 0
  for selected in "${SELECTED_COMPONENTS[@]}"; do
    [[ "$selected" == "$component" ]] && return 0
  done
  return 1
}

report_unsupported_components() {
  local platform="$1"
  shift
  local selected supported
  for selected in "${SELECTED_COMPONENTS[@]}"; do
    for supported in "$@"; do
      [[ "$selected" == "$supported" ]] && continue 2
    done
    log "component '$selected' is not available on $platform; skipping"
  done
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
  local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml"
  if [[ "$DRY_RUN" == "true" && ! -f "$config_file" ]]; then
    log "[dry-run] chezmoi init (profile=$PROFILE; Git identity prompts)"
    log '[dry-run] chezmoi apply skipped because no config exists yet'
    return
  fi
  run chezmoi init "${args[@]}" --promptChoice "Select a profile=$PROFILE"
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
