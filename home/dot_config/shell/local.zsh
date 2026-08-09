# Personal, non-secret shell customizations belong here.
export PERSONAL_DEV_DIR="$HOME/src/personal"

if [[ "$(uname -s)" == "Linux" ]] && command -v mise >/dev/null 2>&1; then
  eza() {
    mise exec eza@latest -- eza "$@"
  }
fi
