# AGENTS.md

This file defines repository-specific instructions for AI coding agents. Read `README.md` for the full public architecture and operating guide before making changes.

## Shell architecture

- Use zsh as the primary interactive shell on macOS and WSL.
- Use Bash for automation scripts. New bootstrap automation must not require zsh.
- Do not introduce Oh My Zsh or a large theme/plugin framework.
- Keep `~/.zshrc` small, readable, and fast.
- Use Starship for the prompt, Atuin for shell history, zoxide for directory navigation, fzf for fuzzy selection, and mise for tools and project environments.
- Treat zsh-autosuggestions, zsh-syntax-highlighting, tmux, and Nushell as opt-in tools. Do not install or activate them by default without an explicit decision.
- Define project runtimes and environment tooling in `mise.toml` or the repository's canonical mise configuration, not through ad hoc shell startup installation.

## Repository invariants

- Preserve the `personal` and `work` boundary.
- Never add secrets or company-internal state.
- Keep Windows host and WSL ownership separate.
- One repository and one mechanism must own each destination file or installed tool.
- Keep dry-run paths side-effect free.
- Prefer convergent, rerunnable operations and do not automatically remove undeclared software.
- Update `README.md` when commands, ownership, architecture, or development rules change.
- Never depend on files under the ignored `private/` directory.
- Apply the custom NTP server only to `personal` macOS and Windows hosts. Do not configure NTP in WSL or the `work` profile.
- Keep macOS natural scrolling disabled for both `personal` and `work` profiles. Do not apply this preference to Windows or WSL.
- Apply the declared Dock and Finder preferences to both macOS profiles. Finder sidebar Recents is intentionally unmanaged until a stable interface is selected.

## Required validation

Run the applicable syntax checks, bootstrap dry run, and `git diff --check`. Report any platform behavior that could not be tested.
