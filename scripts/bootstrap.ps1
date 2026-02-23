Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param(
    [ValidateSet('work', 'personal')]
    [string]$Profile = 'personal',

    [ValidateSet('all', 'packages', 'dotfiles')]
    [string]$Only = 'all',

    [switch]$DryRun
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot '..')

. (Join-Path $scriptRoot 'lib/preflight.ps1')
. (Join-Path $scriptRoot 'lib/installers.ps1')

Write-Host "[INFO] Profile: $Profile"
Write-Host "[INFO] Mode: $Only"
Write-Host "[INFO] DryRun: $($DryRun.IsPresent)"

$os = Invoke-Preflight
Write-Host "[INFO] Detected OS: $os"

if ($Only -in @('all', 'packages')) {
    if ($os -eq 'macos') {
        Install-PackagesMac -RepoRoot $repoRoot -DryRun ([bool]$DryRun.IsPresent)
    }

    if ($os -eq 'windows') {
        Install-PackagesWindows -RepoRoot $repoRoot -DryRun ([bool]$DryRun.IsPresent)
    }
}

if ($Only -in @('all', 'dotfiles')) {
    Apply-Dotfiles -RepoRoot $repoRoot -Profile $Profile -DryRun ([bool]$DryRun.IsPresent)
}

Write-Host '[INFO] Bootstrap completed.'
