#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPOSITORY_URL="https://github.com/unicore32/bootstrap-dotfiles.git"
readonly DEFAULT_INSTALL_DIR="$HOME/.local/share/bootstrap-dotfiles"

PROFILE="common"
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
BRANCH=""
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
Usage: install-macos.sh [--profile common|personal] [--branch BRANCH] [--install-dir PATH] [--dry-run]
EOF
}

while (($#)); do
  case "$1" in
    --profile) PROFILE="${2:?--profile requires a value}"; shift ;;
    --branch) BRANCH="${2:?--branch requires a value}"; shift ;;
    --install-dir) INSTALL_DIR="${2:?--install-dir requires a value}"; shift ;;
    --dry-run) DRY_RUN="true" ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

[[ "$PROFILE" == "common" || "$PROFILE" == "personal" ]] || die "invalid profile: $PROFILE"
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

validate_branch() {
  [[ -n "$BRANCH" ]] || return 0
  [[ "$BRANCH" != -* ]] || die "invalid branch: $BRANCH"
  git check-ref-format --branch "$BRANCH" >/dev/null 2>&1 || die "invalid branch: $BRANCH"
}

ensure_clean_repository() {
  [[ -z "$(git -C "$INSTALL_DIR" status --porcelain --untracked-files=all)" ]] || \
    die "repository has local changes; refusing to switch branch: $INSTALL_DIR"
}

fetch_branch() {
  local remote_ref="refs/remotes/origin/$BRANCH"
  git -C "$INSTALL_DIR" fetch origin "refs/heads/$BRANCH:$remote_ref" || \
    die "could not fetch branch from origin: $BRANCH"
}

switch_to_branch() {
  local remote_ref="refs/remotes/origin/$BRANCH"
  if git -C "$INSTALL_DIR" show-ref --verify --quiet "refs/heads/$BRANCH"; then
    local local_commit remote_commit
    local_commit="$(git -C "$INSTALL_DIR" rev-parse "$BRANCH^{commit}")"
    remote_commit="$(git -C "$INSTALL_DIR" rev-parse "$remote_ref^{commit}")"
    git -C "$INSTALL_DIR" merge-base --is-ancestor "$local_commit" "$remote_commit" || \
      die "local branch has diverged from origin/$BRANCH"
    git -C "$INSTALL_DIR" switch "$BRANCH"
  else
    git -C "$INSTALL_DIR" switch --track -c "$BRANCH" "$remote_ref"
  fi
}

fast_forward_branch() {
  git -C "$INSTALL_DIR" merge --ff-only "refs/remotes/origin/$BRANCH"
}

update_existing_repository() {
  if [[ -z "$BRANCH" ]]; then
    run git -C "$INSTALL_DIR" pull --ff-only
    return
  fi
  ensure_clean_repository
  fetch_branch
  switch_to_branch
  fast_forward_branch
}

clone_repository() {
  [[ ! -e "$INSTALL_DIR" ]] || die "install path exists but is not a Git repository: $INSTALL_DIR"
  run mkdir -p "$(dirname -- "$INSTALL_DIR")"
  if [[ -n "$BRANCH" ]]; then
    run git clone --branch "$BRANCH" "$REPOSITORY_URL" "$INSTALL_DIR"
  else
    run git clone "$REPOSITORY_URL" "$INSTALL_DIR"
  fi
}

checkout_repository() {
  if [[ -d "$INSTALL_DIR/.git" ]]; then
    update_existing_repository
  else
    clone_repository
  fi
}

main() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log '[dry-run] ensure Homebrew and Command Line Tools are available'
    log '[dry-run] ensure Git is available'
    if [[ -n "$BRANCH" ]]; then
      log "[dry-run] clone or fast-forward $REPOSITORY_URL at $INSTALL_DIR (branch=$BRANCH)"
    else
      log "[dry-run] clone or fast-forward $REPOSITORY_URL at $INSTALL_DIR"
    fi
    log "[dry-run] bash $INSTALL_DIR/bootstrap.sh install --profile $PROFILE"
    return
  fi
  configure_homebrew_path
  install_homebrew
  install_git
  validate_branch
  checkout_repository
  exec bash "$INSTALL_DIR/bootstrap.sh" install --profile "$PROFILE"
}

main
