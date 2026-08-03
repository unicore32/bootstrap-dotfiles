# Application package catalog

This document records the intended desktop application inventory and the supported installation route for each operating system. It is the package-selection reference for human contributors and AI coding agents.

> [!NOTE]
> An entry in this catalog does not mean that the application is already present in a package manifest. The **Manifest status** column is authoritative for the current implementation state.

## Rules

1. Use Homebrew Cask on macOS and the winget community source on Windows when an official or vendor-backed package is available.
2. Use Microsoft Store packages only when the official Windows application is not available from the winget community source.
3. Bitwarden on Windows must use `Bitwarden.Bitwarden` from the winget community source. Do not use its Microsoft Store package.
4. Do not substitute unofficial ChatGPT clients for the official OpenAI application.
5. Treat device drivers and device-management applications conservatively. Prefer vendor installers or manual installation when package-manager support is unavailable.
6. WSL does not install desktop applications from this catalog. Windows owns Windows GUI applications.
7. Removing an application from this catalog or a manifest does not authorize automatic uninstallation from existing machines.
8. Verify package identifiers before committing because package-manager catalogs can change.

## Common applications

The requested `common` classification means the application is desired across personal macOS and Windows machines. It does not automatically mean that the application is approved for a company-managed Mac; see [Work-profile policy](#work-profile-policy).

| Application | 🍎 macOS | 🪟 Windows | Manifest status | Notes |
|---|---|---|---|---|
| Google Chrome | Cask `google-chrome` | winget `Google.Chrome` | Added to common manifests | Available on both platforms |
| Google Japanese Input | Cask `google-japanese-ime` | winget `Google.JapaneseIME` | Added to common manifests | Input-source selection or a logout/restart may still be required |
| Firefox | Cask `firefox` | winget `Mozilla.Firefox` | Added to common manifests | Available on both platforms |
| Vivaldi | Cask `vivaldi` | winget `Vivaldi.Vivaldi` | Added to common manifests | Available on both platforms |
| Bitwarden | Cask `bitwarden` | winget `Bitwarden.Bitwarden` | Added to common manifests | Windows package uses the vendor's standard installer, not Microsoft Store |
| Zoom | Cask `zoom` | winget `Zoom.Zoom` | Added to common manifests | Package is named Zoom Workplace on Windows |
| Discord | Cask `discord` | winget `Discord.Discord` | Added to common manifests | Applied to personal and work profiles |
| ChatGPT | Cask `chatgpt` | Microsoft Store `9NT1R1C2HH7J` | Added to common manifests | Windows official application is Store-distributed; reject unofficial winget community clients |
| iTunes | Not applicable | winget `Apple.iTunes` | Added to Windows common manifest | Windows only; winget uses Apple's standalone EXE installer |
| Logi Options+ | Cask `logi-options+` | winget `Logitech.OptionsPlus` | Added to common manifests | Device-specific software; macOS installation may require a restart and permissions |
| KensingtonWorks | Vendor installer/manual | winget `Kensington.KensingtonWorks` | Windows added; macOS manual list | No supported Homebrew Cask was confirmed for macOS |
| Visual Studio Code | Cask `visual-studio-code` | winget `Microsoft.VisualStudioCode` | Added to common manifests | Installed on both platforms |
| DBeaver Community | Cask `dbeaver-community` | winget `DBeaver.DBeaver.Community` | Added to common manifests | Community Edition only |
| Docker Desktop | Cask `docker-desktop` | winget `Docker.DockerDesktop` | Added to common manifests | Requires compatible OS, virtualization, and license/policy review |

## Personal applications

Personal applications are installed only with the `personal` profile.

| Application | 🍎 macOS | 🪟 Windows | Manifest status | Notes |
|---|---|---|---|---|
| VLC | Cask `vlc` | winget `VideoLAN.VLC` | Added to personal manifests | Available on both platforms |
| LINE | Mac App Store `539883307` | Microsoft Store `XPFCC4CD725961` | Added to personal manifests | Homebrew Bundle uses `mas` on macOS |
| Krita | Cask `krita` | winget `KDE.Krita` | Added to personal manifests | Available on both platforms |

## Special installation policies

### Bitwarden on Windows

Use:

```text
source: winget
id: Bitwarden.Bitwarden
installer: vendor NSIS executable
```

Do not use the Microsoft Store version. The standard installer supports capabilities such as Windows Hello integration that are not available in the Store build.

### ChatGPT on Windows

The official OpenAI Windows application is distributed through Microsoft Store:

```powershell
winget install `
    --id 9NT1R1C2HH7J `
    --source msstore `
    --exact `
    --accept-package-agreements `
    --accept-source-agreements
```

The Windows manifests encode the source for every package so the official Store application is selected explicitly.

### LINE

LINE requires Store-aware or vendor-installer logic on both desktop platforms:

- macOS: prefer Mac App Store ID `539883307` through `mas`, or document manual installation from LINE.
- Windows: prefer Microsoft Store product ID `XPFCC4CD725961`, or document manual installation from LINE.

Do not add a similarly named third-party package as a replacement.

### KensingtonWorks on macOS

Kensington provides an official macOS installer, but no supported Homebrew Cask was confirmed during the catalog review. Keep it manual until a stable, verifiable automation route is implemented. Driver and privacy permissions may still require user interaction.

### Docker Desktop

Treat Docker Desktop as a desktop application, not as the WSL Docker Engine package. Before enabling it:

- Confirm the host OS meets the current Docker Desktop requirements.
- Confirm virtualization and WSL 2 requirements on Windows.
- Confirm organizational licensing and device policy for `work` machines.
- Do not install a second Docker engine inside WSL unless ownership and integration are deliberately redesigned.

## Work-profile policy

The repository currently defines `work` as common state without personal state. Adding every requested common application directly to `Brewfile.common` would therefore install it on company-managed Macs.

The requested classification is now implemented as written: common applications apply to both `personal` and `work`. The following categories remain useful if company policy later requires a narrower split:

| Decision | Meaning |
|---|---|
| `common-core` | Safe and intended for personal and work profiles |
| `personal-common` | Shared by personal macOS and Windows, excluded from work |
| `device` | Installed only when the matching hardware or capability is requested |
| `work-owned` | Not managed here; company repository decides |

Review candidates include Discord, ChatGPT, Zoom, Docker Desktop, Logi Options+, KensingtonWorks, and the three web browsers. Their current common classification is intentional, but it does not override company device policy.

## Remaining limitations

1. macOS KensingtonWorks remains a manual common application.
2. LINE installation through `mas` requires an App Store account that is already signed in.
3. Common applications are installed for `work`; company device policy can still prohibit them.
4. Device-feature selection is not implemented, so Logi Options+ and KensingtonWorks are not hardware-gated.
5. Package removal is not reconciled automatically.
6. Package identifiers must be revalidated when an installation starts failing.

## Verification commands

Windows community-source package:

```powershell
winget search --id <PACKAGE_ID> --exact --source winget
winget show --id <PACKAGE_ID> --exact --source winget
```

Windows Store package:

```powershell
winget search <NAME> --source msstore
```

macOS Cask:

```bash
brew search --cask <TOKEN>
brew info --cask <TOKEN>
```

Package availability was reviewed and implemented on 2026-08-04. Revalidate identifiers when maintaining the manifests.
