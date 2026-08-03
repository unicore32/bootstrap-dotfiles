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
| Prompt | Starship |
| History | Atuin |
| Directory navigation | zoxide |
| Fuzzy selection | fzf |
| Runtime and project environments | mise / `mise.toml` |
| AI-facing repository guidance | `AGENTS.md` |

Oh My Zsh and large theme or plugin collections are deliberately not used. Shell behavior should remain understandable from the checked-in files without framework-specific knowledge.

Optional, non-default tools are zsh-autosuggestions, zsh-syntax-highlighting, tmux, and Nushell. They must remain opt-in until explicitly added to a profile or installation interface.

The operating principles are:

- Humans use zsh for interactive terminal work.
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
│   ├── wsl-common.txt
│   └── wsl-personal.txt
├── vscode/
│   ├── extensions-common.txt
│   ├── extensions-personal.txt
│   ├── extensions-windows.txt
│   └── extensions-wsl.txt
├── mise/
│   └── config.toml             # Runtime source of truth
├── scripts/
│   ├── lib.sh                  # Shared Bash helpers
│   └── health-check.sh
├── settings/
│   ├── macos/ntp.sh            # Personal macOS NTP convergence
│   ├── macos/natural-scroll.sh # Common macOS scrolling preference
│   └── windows/ntp.ps1         # Personal Windows NTP convergence
└── .github/workflows/ci.yml
```

The ignored `private/` directory may contain local-language notes or machine-local documentation. Nothing in it is part of the public contract or automation input.

## 🚀 Execution

### Prerequisites

All environments require network access and Git to clone this repository.

- 🍎 macOS must permit Homebrew installation and usage.
- 🪟 Windows requires winget through App Installer.
- 🐧 WSL requires an initialized Linux distribution with `sudo` access.
- Company devices must permit every requested operation under their management policy.

Start with a dry run. Review package manifests before executing a real installation.

### 🍎 macOS

```bash
git clone https://github.com/unicore32/bootstrap-dotfiles.git
cd bootstrap-dotfiles
bash bootstrap.sh install --profile personal --dry-run
bash bootstrap.sh install --profile personal
```

Use `--profile work` on a company-managed Mac only after confirming that the device policy permits the listed common packages.

### 🪟 Windows

```powershell
git clone https://github.com/unicore32/bootstrap-dotfiles.git
Set-Location bootstrap-dotfiles
.\bootstrap.ps1 install -Target all -Profile personal -DryRun
.\bootstrap.ps1 install -Target all -Profile personal
```

Available targets are `windows`, `wsl`, and `all`. A newly installed command may not become visible to the current PowerShell process; reopen the terminal and rerun the same command when instructed.

Run a real `personal` Windows installation from an elevated PowerShell session when the NTP setting is not already configured. Dry runs do not require elevation.

### 🐧 WSL

Run directly inside WSL:

```bash
git clone https://github.com/unicore32/bootstrap-dotfiles.git
cd bootstrap-dotfiles
bash bootstrap.sh install --profile personal --dry-run
bash bootstrap.sh install --profile personal
```

The Windows entrypoint can also invoke the WSL bootstrap for a repository stored on the Windows filesystem.

### Commands

🍎 macOS and 🐧 WSL:

```bash
bash bootstrap.sh install [--profile personal|work] [--dry-run]
bash bootstrap.sh update  [--profile personal|work] [--dry-run]
bash bootstrap.sh check   [--profile personal|work]
```

🪟 Windows:

```powershell
.\bootstrap.ps1 install [-Target windows|wsl|all] [-Profile personal|work] [-DryRun]
.\bootstrap.ps1 update  [-Target windows|wsl|all] [-Profile personal|work] [-DryRun]
.\bootstrap.ps1 check   [-Target windows|wsl|all] [-Profile personal|work]
```

At present, `install` and `update` execute the same convergence path. `check` validates required commands and runs `chezmoi doctor`; it does not yet produce a complete managed-versus-installed state diff.

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
| Managed files | `home/` |
| VS Code extensions | `vscode/extensions-*.txt` |

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

## 🖱️ macOS preferences

Natural scrolling is disabled on macOS for both `personal` and `work` profiles. The setting is applied to the current user and does not require administrator privileges.

```text
NSGlobalDomain com.apple.swipescrolldirection = false
```

The script changes the preference only when necessary. Restart affected applications or log in again if the scrolling direction does not change immediately. Windows and WSL are not affected.

## 🧩 Configuration ownership and overlays

One repository must own each destination file.

- This repository owns `~/.zshrc` and `~/.gitconfig`.
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

### Adding VS Code extensions or runtimes

- Add extension identifiers to the narrowest applicable file under `vscode/`.
- Add cross-platform runtimes to `mise/config.toml`.
- Keep `home/dot_config/mise/config.toml` consistent with the canonical runtime configuration until duplication is removed.
- Keep interactive shell tools composable; do not add a shell framework as an implicit dependency.

### Validation

Run the checks relevant to the edited platform:

```bash
bash -n bootstrap.sh bootstrap/*.sh scripts/*.sh settings/macos/*.sh
bash bootstrap.sh install --profile personal --dry-run
```

```powershell
.\bootstrap.ps1 install -Target windows -Profile personal -DryRun
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
