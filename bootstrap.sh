#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR

case "$(uname -s)" in
  Darwin) exec bash "$ROOT_DIR/bootstrap/macos.sh" "$@" ;;
  Linux)  exec bash "$ROOT_DIR/bootstrap/wsl.sh" "$@" ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
