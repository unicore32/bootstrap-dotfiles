# bootstrap-dotfiles

Cross-platform workstation bootstrap and dotfiles for personal macOS, Windows, WSL, and company-managed macOS devices.

This repository is the source of truth for public, reproducible machine state: packages, development runtimes, editor extensions, and shared configuration. It uses [chezmoi](https://www.chezmoi.io/) for file deployment and selects either a `personal` or `work` profile.

> [!IMPORTANT]
> This is an initial implementation. Repeated runs are designed to converge safely, but strict idempotency, automatic removal of unmanaged software, and automatic repository pulling are not yet guaranteed. See [State synchronization and idempotency](#state-synchronization-and-idempotency).

## 🎯 Goals and scope

Supported environments:

| Environment | Profile | Package manager | Applied state |
|---|---|---|---|
| 🍎 Personal macOS | `personal` | Homebrew | Common and personal |
| 🪟 Personal Windows | `personal` | winget | Windows applications and WSL orchestration |
| 🐧 Personal WSL | `personal` | apt | Linux CLI tools and runtimes |
| 🍎 Company macOS | `work` | Homebrew | Common state only |

This repository manages:

- CLI tools and GUI applications
- zsh and Git configuration
- VS Code settings and extensions
- Node.js, Python, and Go through mise
- Windows-to-WSL bootstrap orchestration

## 🐚 Shell architecture

The shell environment is intentionally small, composable, and AI-friendly.

| Role | Choice |
|---|---|
| Primary interactive shell | zsh |
| Automation shell | Bash |
| Terminal emulator | WezTerm (shared macOS/Windows configuration) |
| Prompt | Starship |
| History | Atuin |
| Directory navigation | zoxide |
| Fuzzy selection | fzf |
| File previews | bat |
| Directory listings | eza (`ll` includes Git status) |
| Runtime and project environments | mise / `mise.toml` |
| AI-facing repository guidance | `AGENTS.md` |

Oh My Zsh and large theme or plugin collections are deliberately not used. Shell behavior should remain understandable from the checked-in files without framework-specific knowledge.

The default interactive experience includes zsh completion, fzf key bindings and completion, zsh-autosuggestions, and zsh-syntax-highlighting. tmux and Nushell remain optional tools.

The operating principles are:

- Humans use zsh for interactive terminal work.
- WezTerm owns local tabs and panes. Its leader is `Ctrl+G`, leaving tmux and
  Herdr free to use their conventional `Ctrl+B` prefix in nested or remote
  sessions. On Windows, WezTerm starts the bootstrapped Ubuntu WSL domain in
  zsh when available; PowerShell 7 and Command Prompt remain explicit launch
  targets for Windows-host work.
- WSL installs zsh but does not change the login shell automatically. After bootstrap, run `chsh -s "$(command -v zsh)"` and start a new terminal when you want zsh as the default.
- zsh keeps a local fallback history in `~/.zsh_history`; Atuin provides the interactive and cross-terminal history experience. Commands prefixed with a space are excluded from the local history, but secrets should never be passed as command-line arguments.
- Automation and bootstrap scripts use Bash.
- Projects declare runtimes and environment tooling through `mise.toml`.
- AI agents read `AGENTS.md` and the canonical English README before changing the repository.

This repository does not manage:

- Credentials, private keys, tokens, or VPN secrets
- Internal company information or company-only tooling
- Security-policy bypasses
- Automatic removal of software that is absent from a manifest

Company-specific state belongs in a separate, company-controlled `company-workstation` repository. That repository may populate the extension points documented below, but it must not manage the same destination files as this repository.

## 👤 Profiles

### `personal`

Applies common state plus public personal applications, extensions, and local overlays. It is intended for personally owned machines.

### `work`

Applies common state only. It deliberately contains no company-specific or personal-only state. A separate company repository is responsible for approved company packages and configuration.

The selected profile is stored by chezmoi during initial configuration. Changing `--profile` on a later run does not currently guarantee that an existing chezmoi profile is replaced. Inspect the chezmoi configuration before changing an existing machine from one profile to another.

## 🗂️ Repository structure

```text
bootstrap-dotfiles/
├── README.md                    # Canonical project and contributor documentation
├── AGENTS.md                    # Instructions for AI coding agents
├── install-macos.sh             # Remote macOS Stage 0 installer
├── install-windows.ps1          # Remote Windows Stage 0 installer
├── bootstrap.sh                # macOS/WSL dispatcher
├── bootstrap.ps1               # Windows dispatcher
├── bootstrap/
│   ├── macos.sh                # Homebrew, chezmoi, mise, and VS Code orchestration
│   ├── windows.ps1             # winget, chezmoi, mise, VS Code, and WSL orchestration
│   └── wsl.sh                  # apt, chezmoi, mise, and VS Code orchestration
├── home/                       # chezmoi source state
│   ├── .chezmoi.toml.tmpl      # Initial interactive profile selection
│   ├── .chezmoiignore          # OS/profile exclusions
│   ├── dot_gitconfig
│   ├── dot_zshrc.tmpl
│   ├── dot_config/             # Cross-platform and Linux configuration
│   ├── Library/                # macOS-specific configuration
│   └── AppData/                # Windows-specific configuration
├── packages/
│   ├── README.md                 # Application catalog and package policies
│   ├── Brewfile.common
│   ├── Brewfile.personal
│   ├── winget-common.ps1
│   ├── winget-personal.ps1
│   ├── windows-manual-common.txt
│   ├── wsl-common.txt
│   └── wsl-personal.txt
├── vscode/
│   ├── extensions-common.txt
│   ├── extensions-personal.txt
│   ├── extensions-windows.txt
│   └── extensions-wsl.txt
├── mise/
│   ├── config.toml             # Cross-profile runtime source of truth
│   └── personal-wsl.toml       # Personal WSL CLI tools installed by mise
├── scripts/
│   ├── lib.sh                  # Shared Bash helpers
│   └── health-check.sh
├── settings/
│   ├── macos/ntp.sh            # Personal macOS NTP convergence
│   ├── macos/dock.sh           # Common Dock preferences
│   ├── macos/finder.sh         # Common Finder preferences
│   ├── macos/natural-scroll.sh # Common macOS scrolling preference
│   ├── macos/touch-id.sh       # Personal macOS Touch ID sudo configuration
│   └── windows/ntp.ps1         # Personal Windows NTP convergence
└── .github/workflows/ci.yml
```

The ignored `private/` directory may contain local-language notes or machine-local documentation. Nothing in it is part of the public contract or automation input.

## 🚀 Execution

### Prerequisites

All environments require network access. The macOS and Windows Stage 0 installers install Git when it is absent; manual installation and direct WSL installation require Git before cloning this repository.

- 🍎 macOS must permit Homebrew installation and usage.
- 🪟 Windows requires winget through App Installer.
- 🐧 WSL requires an initialized Linux distribution with `sudo` access.
- Company devices must permit every requested operation under their management policy.

Start with a dry run. Review package manifests before executing a real installation.

### 🍎 macOS

After the desired revision has been pushed to `main`, start a personal installation with one command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/unicore32/bootstrap-dotfiles/main/install-macos.sh)" -- --profile personal
```

The Stage 0 installer prepares Homebrew and Git, clones or fast-forward updates the repository at `~/.local/share/bootstrap-dotfiles`, and starts Stage 1. It can trigger interactive Command Line Tools, `sudo`, App Store, and macOS permission prompts; those prompts are intentionally not bypassed.

To inspect Stage 0 without changing the machine:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/unicore32/bootstrap-dotfiles/main/install-macos.sh)" -- --profile personal --dry-run
```

Manual clone remains supported:

```bash
git clone https://github.com/unicore32/bootstrap-dotfiles.git
cd bootstrap-dotfiles
bash bootstrap.sh install --profile personal --dry-run
bash bootstrap.sh install --profile personal
# Only reconcile selected responsibilities from an existing checkout.
bash bootstrap.sh install --profile personal --components packages,dotfiles --dry-run
```

Use `--profile work` on a company-managed Mac only after confirming that the device policy permits the listed common packages.

### 🪟 Windows

After the desired revision has been pushed to `main`, start a personal installation from PowerShell with:

```powershell
& ([scriptblock]::Create((Invoke-RestMethod -Uri "https://raw.githubusercontent.com/unicore32/bootstrap-dotfiles/main/install-windows.ps1"))) -Profile personal
```

The Stage 0 installer verifies that winget is available, installs Git when necessary, clones or fast-forward updates the repository at `%LOCALAPPDATA%\bootstrap-dotfiles`, and starts Stage 1. It may require a new PowerShell session after installing Git, WSL initialization, or elevation for the personal NTP setting; those prompts are intentionally not bypassed.

If PowerShell reports that script execution is disabled, allow it only for the current PowerShell process, then rerun the command above. This setting is cleared when the window closes.

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Do not change the execution policy at the `LocalMachine` scope. On a company-managed device, a Group Policy may prevent even the process-scoped setting; follow the device policy in that case.

To inspect Stage 0 without changing the machine:

```powershell
& ([scriptblock]::Create((Invoke-RestMethod -Uri "https://raw.githubusercontent.com/unicore32/bootstrap-dotfiles/main/install-windows.ps1"))) -Profile personal -DryRun
```

Manual clone remains supported when Git is already installed:

```powershell
git clone https://github.com/unicore32/bootstrap-dotfiles.git
Set-Location bootstrap-dotfiles
.\bootstrap.ps1 install -Target all -Profile personal -DryRun
.\bootstrap.ps1 install -Target all -Profile personal
# The same selection is forwarded to the WSL bootstrap for -Target wsl or all.
.\bootstrap.ps1 install -Target all -Profile personal -Components packages,dotfiles -DryRun
```

Available targets are `windows`, `wsl`, and `all`. A newly installed command may not become visible to the current PowerShell process; reopen the terminal and rerun the same command when instructed.

Run a real `personal` Windows installation from an elevated PowerShell session when the NTP setting is not already configured. Dry runs do not require elevation.

### 🐧 WSL

Run directly inside WSL:

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/unicore32/bootstrap-dotfiles.git
cd bootstrap-dotfiles
bash bootstrap.sh install --profile personal --dry-run
bash bootstrap.sh install --profile personal
```

The Windows entrypoint can also invoke the WSL bootstrap for a repository stored on the Windows filesystem.

### Commands

🍎 macOS and 🐧 WSL:

```bash
bash bootstrap.sh install [--profile personal|work] [--components packages,dotfiles,mise,vscode,settings] [--dry-run]
bash bootstrap.sh update  [--profile personal|work] [--components packages,dotfiles,mise,vscode,settings] [--dry-run]
bash bootstrap.sh check   [--profile personal|work]
```

🪟 Windows:

```powershell
.\bootstrap.ps1 install [-Target windows|wsl|all] [-Profile personal|work] [-Components packages,dotfiles,mise,vscode,settings] [-DryRun]
.\bootstrap.ps1 update  [-Target windows|wsl|all] [-Profile personal|work] [-Components packages,dotfiles,mise,vscode,settings] [-DryRun]
.\bootstrap.ps1 check   [-Target windows|wsl|all] [-Profile personal|work]
```

`install` and `update` also accept an optional component selector. Omit it to
preserve the full convergence path. `check` intentionally remains a full health
check and does not accept a selector.

```bash
bash bootstrap.sh install --profile personal --components packages,dotfiles --dry-run
bash bootstrap.sh update --profile work --components mise,vscode
```

```powershell
.\bootstrap.ps1 install -Target windows -Profile personal -Components packages,settings -DryRun
.\bootstrap.ps1 update -Target all -Profile personal -Components dotfiles,mise
```

| Component | Responsibility | Availability |
|---|---|---|
| `packages` | Homebrew Bundle, winget, or apt package manifests | macOS, Windows, WSL |
| `dotfiles` | chezmoi initialization and apply | macOS, Windows, WSL |
| `mise` | mise runtime installation | macOS, Windows, WSL |
| `vscode` | VS Code extension lists | macOS, Windows, WSL |
| `settings` | Managed operating-system preferences | macOS and Windows; skipped with a message on WSL |

Selectors are comma-separated, case-insensitive names; surrounding whitespace
is ignored. Empty names, unknown names, and duplicates are errors. Components
are independent of Windows `-Target`: `windows`, `wsl`, and `all` choose the
host(s), then the requested responsibilities run on each applicable host. For
`-Target wsl` or `all`, the Windows dispatcher forwards the normalized selector
to WSL. A selected component that does not exist on an OS is safely skipped with
a message. A component run assumes its prerequisite command is already present
when that command is normally supplied by `packages`; use `packages,...` for a
first installation, or run the package component first. Individual applications
remain outside this interface: install or remove them directly with Homebrew,
winget, or apt.

At present, `install` and `update` execute the same convergence path. `check` validates required commands and runs `chezmoi doctor`; it does not yet produce a complete managed-versus-installed state diff.

### Working from a repository checkout

Use a local checkout when developing or reviewing bootstrap changes. Run commands
from the checkout so the dry run and installation use the revision you are
editing, rather than the revision currently published on `main`.

On macOS or inside WSL:

```bash
git clone https://github.com/unicore32/bootstrap-dotfiles.git
cd bootstrap-dotfiles
bash bootstrap.sh install --profile personal --dry-run
bash bootstrap.sh install --profile personal
```

On Windows, clone and run the Windows target from PowerShell. The `all` target
will invoke the WSL bootstrap using the same checkout.

```powershell
git clone https://github.com/unicore32/bootstrap-dotfiles.git
Set-Location bootstrap-dotfiles
.\bootstrap.ps1 install -Target all -Profile personal -DryRun
.\bootstrap.ps1 install -Target all -Profile personal
```

When working from a checkout, do not also run the remote Stage 0 installer for
the same change. Before committing, run the applicable syntax checks, dry run,
and `git diff --check` as described in [Validation](#validation).

## 🔄 State synchronization and idempotency

Git is the synchronization mechanism. Installing an application manually on one machine does not add it to another machine. To propagate a change:

1. Change the appropriate source-of-truth file in this repository.
2. Run a dry run and the relevant checks.
3. Commit and push the change.
4. Pull the commit on another machine.
5. Run `update` for that machine and profile.

Source-of-truth mapping:

| State | Source of truth |
|---|---|
| macOS packages | `packages/Brewfile.*` |
| Windows packages | `packages/winget-*.ps1` |
| WSL packages | `packages/wsl-*.txt` |
| Development runtimes | `mise/config.toml` |
| Personal WSL CLI tools | `mise/personal-wsl.toml` |
| Managed files | `home/` |
| VS Code extensions | `vscode/extensions-*.txt` |
| macOS and Windows settings | `settings/` |

Current convergence behavior:

- Homebrew Bundle, apt, mise, and chezmoi generally converge when rerun.
- winget treats successful and already-installed results as non-fatal.
- VS Code extensions are installed with `--force`, so a rerun can perform unnecessary work.
- apt metadata is refreshed on every applicable run.
- Removing an entry from a manifest does not uninstall it from existing machines.
- The scripts do not automatically run `git pull`.
- Profile switching on an already initialized machine is not fully implemented.

The safe policy is: automatically add missing declared state, never automatically delete extra software, and report drift before destructive reconciliation. Future strict-idempotency work should add profile validation, extension diffing, package drift reporting, and a CI test proving that a second apply produces no managed-file changes.

## 🕐 Network time

Personal macOS and Windows hosts use `ntp.jst.mfeed.ad.jp` as their NTP server.

- 🍎 macOS uses `systemsetup` and prompts for `sudo` only when the personal NTP step runs or is checked.
- 🪟 Windows uses W32Time and requires an elevated PowerShell session when the current configuration must change.
- 🐧 WSL is not configured separately; the Windows host owns time synchronization.
- 🏢 The `work` profile never changes NTP because company policy, MDM, or an Active Directory domain may own it.

The scripts compare current state before applying a change. A dry run prints the intended operation without requesting elevation or changing system state.

## 🆔 Touch ID for `sudo`

Personal macOS hosts enable Touch ID for local `sudo` authentication through `/etc/pam.d/sudo_local`. The managed rule prefers Touch ID and retains password authentication as a fallback when Touch ID is unavailable, such as over SSH.

- The bootstrap never edits `/etc/pam.d/sudo` directly.
- The `work` profile does not manage this setting.
- If an unmanaged `sudo_local` already exists without a Touch ID rule, the bootstrap stops rather than overwriting it.

## 🖱️ macOS preferences

The following current-user preferences apply to both `personal` and `work` profiles and do not require administrator privileges.

### Dock

- Icon size: `28` points, representing a small Dock of roughly 10% on the settings slider.
- Magnified icon size: `72` points, representing roughly 50% on the magnification slider.
- Magnification: enabled.
- Automatically hide and show the Dock: enabled.

### Finder

- New Finder windows show the startup volume (`Macintosh HD`, represented by `file:///`).
- All filename extensions are visible.
- Finder sidebar Recents is intentionally not managed yet.

### Scrolling

Natural scrolling is disabled.

```text
NSGlobalDomain com.apple.swipescrolldirection = false
```

The scripts change preferences only when necessary. Dock and Finder restart only after their settings change. Restart other affected applications or log in again if the scrolling direction does not change immediately. Windows and WSL are not affected.

## 🧩 Configuration ownership and overlays

One repository must own each destination file.

- This repository owns `~/.zshrc` and `~/.gitconfig`.
- This repository owns `~/.config/wezterm/wezterm.lua`.
- `~/.zshrc` sources `~/.config/shell/local.zsh` when present.
- `~/.gitconfig` includes `~/.config/git/local.gitconfig`.
- Under `personal`, chezmoi may own those local overlay files.
- Under `work`, the separate company repository may own those overlay files.
- The company repository must not overwrite files already owned here.

VS Code has no general include mechanism for JSON settings. Common settings live here; company settings should use a separate VS Code `Work` Profile. Do not hard-code VS Code's internal profile identifier.

## 🛠️ Development workflow

### Adding or changing packages

1. Select the OS-specific common or personal manifest under `packages/`.
2. Add the package's stable package-manager identifier.
3. Run the corresponding dry run.
4. Run a real install only on an appropriate test machine.
5. Verify a second run does not fail.

Do not introduce a generated universal package manifest unless the repository explicitly adopts one. The native manifests are currently canonical.

### Adding or changing dotfiles

1. Add or edit the file under `home/` using chezmoi naming conventions.
2. Add OS/profile conditions to `.chezmoiignore` or a template when required.
3. Preview with `chezmoi apply --source home --dry-run --verbose` or the bootstrap dry run.
4. Confirm that no unrelated destination file is claimed.
5. Apply and rerun to check convergence.

Do not put secrets in templates. A profile exclusion is not a security boundary because excluded data remains in Git history.

### WezTerm keybindings

WezTerm uses `Ctrl+G` as a 1.5-second leader, rather than the tmux/Herdr
`Ctrl+B` prefix. This lets the outer terminal and a nested or remote
multiplexer remain independently controllable.

| Key sequence | Action |
|---|---|
| `Ctrl+G`, `|` | Split to the right |
| `Ctrl+G`, `-` | Split below |
| `Ctrl+G`, `h` / `j` / `k` / `l` | Focus left / down / up / right pane |
| `Ctrl+G`, `H` / `J` / `K` / `L` | Resize the focused pane |
| `Ctrl+G`, `z` | Toggle pane zoom |
| `Ctrl+G`, `x` | Close the focused pane (with confirmation) |
| `Ctrl+G`, `c` | New tab in the current domain |
| `Ctrl+G`, `o` | Open the fuzzy launcher |
| `Ctrl+G`, `p` | Windows: new PowerShell 7 tab |
| `Ctrl+G`, `m` | Windows: new Command Prompt tab |
| `Ctrl+G`, `r` | Reload WezTerm configuration |
| `Ctrl+G`, `Ctrl+G` | Send `Ctrl+G` to the terminal program |

### Adding VS Code extensions or runtimes

- Add extension identifiers to the narrowest applicable file under `vscode/`.
- Add cross-platform runtimes to `mise/config.toml`.
- Add personal-only WSL CLI tools managed by mise to `mise/personal-wsl.toml`.
- Keep `home/dot_config/mise/config.toml` consistent with the canonical runtime configuration until duplication is removed.
- Keep interactive shell tools composable; do not add a shell framework as an implicit dependency.

### Validation

Run the checks relevant to the edited platform:

```bash
bash -n install-macos.sh bootstrap.sh bootstrap/*.sh scripts/*.sh settings/macos/*.sh
bash bootstrap.sh install --profile personal --dry-run
bash bootstrap.sh install --profile personal --components packages,dotfiles --dry-run
```

```powershell
.\bootstrap.ps1 install -Target windows -Profile personal -DryRun
.\bootstrap.ps1 install -Target all -Profile personal -Components packages,dotfiles -DryRun
```

Also run:

```bash
git diff --check
```

CI performs Bash syntax checks, ShellCheck, and PowerShell parser checks. A dry run is necessary but does not prove that package downloads or a real apply will succeed.

## 📏 Development rules

These rules are normative for both human contributors and AI coding agents:

1. Treat this README and the checked-in manifests as the public source of truth.
2. Preserve the `personal`/`work` security boundary. Never add company-internal state here.
3. Never commit secrets, credentials, private hosts, private certificates, or personal authentication data.
4. Keep Windows host state and WSL state separate.
5. Use the native package manager for each OS; do not duplicate ownership across package systems.
6. Keep bootstrap operations rerunnable. Check current state before adding a non-convergent operation.
7. Do not automatically uninstall undeclared software or overwrite unmanaged local files.
8. Keep `--dry-run` side-effect free. A dry run must not install, update, or edit machine state.
9. Preserve the command-line interface unless a documented migration is included.
10. Update this README whenever behavior, ownership, structure, or commands change.
11. Do not treat files under ignored `private/` as requirements or implementation inputs.
12. Validate syntax and dry-run behavior before committing.

When an AI agent changes this repository, it should first inspect the current manifests and entrypoints, make the smallest coherent change, avoid unrelated user modifications, and report unverified platform-specific behavior explicitly.

## 🔐 Secrets and private data

Never commit:

- SSH private keys
- API keys, access tokens, or login credentials
- VPN credentials
- Private host information
- Company-internal information

Use Keychain, Credential Manager, a password manager, a company-approved secret manager, interactive first-run input, or an untracked machine-local file.

## 🚧 Status

The initial cross-platform structure, profiles, package manifests, dotfiles, runtime configuration, editor extension lists, health checks, dry-run paths, and CI definitions are present. The next reliability milestone is strict state reconciliation and idempotency testing.

## 📄 License

No license has been selected yet.
