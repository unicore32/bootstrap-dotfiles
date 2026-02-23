Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Install-PackagesMac {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [bool]$DryRun
    )

    $brewfile = Join-Path $RepoRoot 'manifests/Brewfile'
    if (-not (Test-Path $brewfile)) {
        Write-Host '[WARN] Brewfile not found. Skipping package step.' -ForegroundColor Yellow
        return
    }

    if ($DryRun) {
        Write-Host "[DRYRUN] brew bundle check --file `"$brewfile`""
        return
    }

    brew bundle --file "$brewfile"
}

function Install-PackagesWindows {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [bool]$DryRun
    )

    $manifest = Join-Path $RepoRoot 'manifests/winget-packages.json'
    if (-not (Test-Path $manifest)) {
        Write-Host '[WARN] winget manifest not found. Skipping package step.' -ForegroundColor Yellow
        return
    }

    if ($DryRun) {
        Write-Host "[DRYRUN] winget import --import-file `"$manifest`" --ignore-versions"
        return
    }

    winget import --import-file "$manifest" --ignore-versions --accept-package-agreements --accept-source-agreements
}

function Apply-Dotfiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$Profile,
        [Parameter(Mandatory = $true)]
        [bool]$DryRun
    )

    if (-not (Get-Command -Name 'chezmoi' -ErrorAction SilentlyContinue)) {
        Write-Host '[WARN] chezmoi not found. Skipping dotfiles apply.' -ForegroundColor Yellow
        return
    }

    if ($DryRun) {
        Write-Host "[DRYRUN] chezmoi init --apply --source `"$RepoRoot/dotfiles`" --data profile=$Profile"
        return
    }

    chezmoi init --apply --source "$RepoRoot/dotfiles" --data "profile=$Profile"
}
