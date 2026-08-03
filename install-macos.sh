#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPOSITORY_URL="https://github.com/unicore32/bootstrap-dotfiles.git"
readonly DEFAULT_INSTALL_DIR="$HOME/.local/share/bootstrap-dotfiles"

PROFILE="personal"
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
DRY_RUN="false"

log() { printf '[stage-0] %s\n' "$*"; }
die() { printf '[stage-0] ERROR: %s\n' "$*" >&2; exit 1; }

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

usage() {
  cat <<'EOF'
Usage: install-macos.sh [--profile personal|work] [--install-dir PATH] [--dry-run]
EOF
}

while (($#)); do
  case "$1" in
    --profile) PROFILE="${2:?--profile requires a value}"; shift ;;
    --install-dir) INSTALL_DIR="${2:?--install-dir requires a value}"; shift ;;
    --dry-run) DRY_RUN="true" ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

[[ "$PROFILE" == "personal" || "$PROFILE" == "work" ]] || die "invalid profile: $PROFILE"
[[ "$(uname -s)" == "Darwin" ]] || die 'this Stage 0 installer currently supports macOS only'

configure_homebrew_path() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_homebrew() {
  command -v brew >/dev/null 2>&1 && return
  if [[ "$DRY_RUN" == "true" ]]; then
    log '[dry-run] install Homebrew (may request Command Line Tools)'
    return
  fi
  log 'Installing Homebrew; follow any Command Line Tools prompts'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  configure_homebrew_path
  command -v brew >/dev/null 2>&1 || die 'Homebrew installation did not make brew available'
}

install_git() {
  if command -v git >/dev/null 2>&1 && git --version >/dev/null 2>&1; then
    return
  fi
  command -v brew >/dev/null 2>&1 || {
    [[ "$DRY_RUN" == "true" ]] && { log '[dry-run] brew install git'; return; }
    die 'brew is required to install Git'
  }
  run brew install git
}

checkout_repository() {
  if [[ -d "$INSTALL_DIR/.git" ]]; then
    run git -C "$INSTALL_DIR" pull --ff-only
    return
  fi
  [[ ! -e "$INSTALL_DIR" ]] || die "install path exists but is not a Git repository: $INSTALL_DIR"
  run mkdir -p "$(dirname -- "$INSTALL_DIR")"
  run git clone "$REPOSITORY_URL" "$INSTALL_DIR"
}

main() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log '[dry-run] ensure Homebrew and Command Line Tools are available'
    log '[dry-run] ensure Git is available'
    log "[dry-run] clone or fast-forward $REPOSITORY_URL at $INSTALL_DIR"
    log "[dry-run] bash $INSTALL_DIR/bootstrap.sh install --profile $PROFILE"
    return
  fi
  configure_homebrew_path
  install_homebrew
  install_git
  checkout_repository
  exec bash "$INSTALL_DIR/bootstrap.sh" install --profile "$PROFILE"
}

main
