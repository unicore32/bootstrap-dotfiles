# bootstrap-dotfiles

Windows / macOS 向けの初期設定リポジトリです。  
初回実行は `bootstrap.bat` または `bootstrap.sh` から行い、実体は PowerShell 7 (`pwsh`) の共通スクリプトで処理します。

## Scope

- パッケージ導入（Windows: winget / macOS: brew）
- dotfiles 適用（chezmoi）
- プロファイル切り替え（`work` / `personal`）

## Out of Scope (current phase)

- OS 設定変更（例: `winget configure`, `defaults write`）

## Requirements

- PowerShell 7 (`pwsh`)
- `git`
- Windows: `winget`
- macOS: `brew`
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
chmod +x bootstrap.sh
./bootstrap.sh -Profile work -DryRun
./bootstrap.sh -Profile personal -Only packages
./bootstrap.sh -Only dotfiles
```

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
