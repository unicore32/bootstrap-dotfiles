# bootstrap-dotfiles

Windows / macOS 向けの初期設定リポジトリです。  
初回実行は `bootstrap.bat` または `bootstrap.sh` から行います。Windows側は PowerShell 7 (`pwsh`) を利用しますが、macOS 側は標準の `bash`/`zsh` で動作します（`pwsh` は必須ではありません）。

## Scope

- パッケージ導入（Windows: winget / macOS: brew）
- dotfiles 適用（chezmoi）
- プロファイル切り替え（`work` / `personal`）

## Out of Scope (current phase)

- OS 設定変更（例: `winget configure`, `defaults write`）

## Requirements

- `git`
- Windows: `winget`, PowerShell 7 (`pwsh`) is recommended (installer prompt is offered on Windows).
- macOS: `brew` and a POSIX shell (`bash`/`zsh`) — `pwsh` is optional on macOS.
- dotfiles適用時: `chezmoi`

## Usage

### Windows

```bat
bootstrap.bat -Profile work -DryRun
bootstrap.bat -Profile personal -Only packages
bootstrap.bat -Only dotfiles
```

### macOS

```bash

**macOS の設定**

- このリポジトリでは macOS 用にシェルベースの manifest をサポートします。
- サンプル manifest: `manifests/macos-settings.sh`（`defaults write` 等の安全なコマンドを想定）。
- 実行方法:

	- ドライラン（表示のみ）:
		```bash
		./bootstrap.sh -Only windows-settings -DryRun
		```

	- 適用（macOS）:
		```bash
		./bootstrap.sh -Only windows-settings
		```

	※ macOS 実行時は `bootstrap.sh` がネイティブシェルランナーを使います（`pwsh` は必須ではありません）。
chmod +x bootstrap.sh
./bootstrap.sh -Profile work -DryRun

## Arguments

- `-Profile`: `work` | `personal`（default: `personal`）
- `-Only`: `all` | `packages` | `dotfiles`（default: `all`）
- `-DryRun`: 実行せずにコマンドのみ表示

## Directory Layout

- `bootstrap.bat` / `bootstrap.sh`: OS別エントリポイント
- `scripts/bootstrap.ps1`: 共通オーケストレーター
- `scripts/lib/preflight.ps1`: 前提条件チェック
- `scripts/lib/installers.ps1`: パッケージ導入 / dotfiles適用
- `manifests/packages.yaml`: 論理的なパッケージ定義（正本）
- `manifests/Brewfile`: macOS導入対象
- `manifests/winget-packages.json`: Windows導入対象
- `dotfiles/`: chezmoi管理対象の実ファイル置き場

## Notes

- 再実行前提（idempotent）で運用する想定です。
- `manifests/packages.yaml` は正本として管理し、必要に応じて `Brewfile` / `winget` manifest を同期してください。

## CI / PR Flow

- GitHub Actions: `.github/workflows/ci.yml`
- 検証内容:
	- Windows: `bootstrap.bat` の DryRun
	- macOS: `bootstrap.sh` の DryRun
	- Ubuntu: `chezmoi doctor` と `chezmoi apply --dry-run`
- 推奨運用:
	1. `main` から作業ブランチを切る
	2. PR を作成して CI 通過を確認する
	3. `main` へマージする

`main` 直pushを避けたい場合は、GitHub の Branch protection で `Require status checks to pass before merging` を有効化してください。

## Local Guard (free)

Branch protection が使えない場合でも、このリポジトリではローカル Git hook で `main` / `master` への直pushをブロックできます。

- hook: `.githooks/pre-push`
- 有効化コマンド:

```bash
git config --local core.hooksPath .githooks
```

意図して `main` に push したい場合だけ、次のように一時的に許可できます。

```bash
ALLOW_MAIN_PUSH=1 git push origin main
```

PowerShell の場合:

```powershell
$env:ALLOW_MAIN_PUSH = "1"
git push origin main
Remove-Item Env:ALLOW_MAIN_PUSH
```

## Quick Branch Workflow

```bash
git switch main
git pull --ff-only
git switch -c feat/your-change
# edit, commit
git push -u origin feat/your-change
```

PR作成後、CIが通ったら `main` にマージする運用にしてください。
