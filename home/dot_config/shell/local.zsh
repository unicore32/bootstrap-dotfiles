# Personal, non-secret shell customizations belong here.
export PERSONAL_DEV_DIR="$HOME/src/personal"

if [[ "$(uname -s)" == "Linux" ]] && command -v mise >/dev/null 2>&1; then
  EZA_MISE_CONFIG="$HOME/.config/mise/personal-wsl.toml"
  if [[ -f "$EZA_MISE_CONFIG" ]]; then
    EZA_BIN_DIR="$(MISE_CONFIG_FILE="$EZA_MISE_CONFIG" mise where eza 2>/dev/null)"
    [[ -n "$EZA_BIN_DIR" ]] && path=("$EZA_BIN_DIR" $path)
  fi
  unset EZA_BIN_DIR EZA_MISE_CONFIG
fi
