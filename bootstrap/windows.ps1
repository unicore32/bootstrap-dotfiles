[CmdletBinding()]
param(
    [ValidateSet("install", "update", "check")]
    [string]$Command = "install",
    [ValidateSet("windows", "wsl", "all")]
    [string]$Target = "all",
    [ValidateSet("personal", "work")]
    [string]$Profile = "personal",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $PSScriptRoot

function Write-Step([string]$Message) {
    Write-Host "[bootstrap] $Message"
}

function Invoke-Step([scriptblock]$Action, [string]$Description) {
    if ($DryRun) {
        Write-Host "[dry-run] $Description"
    }
    else {
        & $Action
    }
}

function Test-Command([string]$Name) {
    if (Get-Command $Name -ErrorAction SilentlyContinue) {
        Write-Host "[ok]      $Name"
        return $true
    }
    Write-Host "[missing] $Name"
    return $false
}

function Install-WingetPackages {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        if ($DryRun) {
            Write-Step "[dry-run] winget package installation"
            return
        }
        throw "winget is required. Install or update App Installer first."
    }

    $manifestFiles = @((Join-Path $RootDir "packages/winget-common.ps1"))
    if ($Profile -eq "personal") {
        $manifestFiles += Join-Path $RootDir "packages/winget-personal.ps1"
    }

    foreach ($manifest in $manifestFiles) {
        $packages = & $manifest
        foreach ($package in $packages) {
            $packageId = $package.Id
            $packageSource = $package.Source
            if (-not $packageId -or -not $packageSource) {
                throw "Invalid package record in $manifest. Id and Source are required."
            }
            $description = "winget install --id $packageId --source $packageSource"
            Invoke-Step -Description $description -Action {
                & winget install --id $packageId --source $packageSource --exact --silent `
                    --accept-package-agreements --accept-source-agreements `
                    --disable-interactivity
                if ($LASTEXITCODE -notin @(0, -1978335189)) {
                    throw "winget failed for $packageId from $packageSource (exit $LASTEXITCODE)"
                }
            }
        }
    }
}

function Show-ManualWindowsApplications {
    $manualList = Join-Path $RootDir "packages/windows-manual-common.txt"
    if (-not (Test-Path -LiteralPath $manualList)) { return }

    Write-Step "Manual common applications:"
    Get-Content -LiteralPath $manualList |
        Where-Object { $_ -and -not $_.TrimStart().StartsWith("#") } |
        ForEach-Object { Write-Step "  $($_.Trim())" }
}

function Install-VSCodeExtensions {
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Step "VS Code CLI not found; skipping extensions"
        return
    }
    $lists = @(
        (Join-Path $RootDir "vscode/extensions-common.txt"),
        (Join-Path $RootDir "vscode/extensions-windows.txt")
    )
    if ($Profile -eq "personal") {
        $lists += Join-Path $RootDir "vscode/extensions-personal.txt"
    }
    foreach ($list in $lists) {
        Get-Content -LiteralPath $list |
            Where-Object { $_ -and -not $_.TrimStart().StartsWith("#") } |
            ForEach-Object {
                $extension = $_.Trim()
                Invoke-Step -Description "code --install-extension $extension" `
                    -Action { & code --install-extension $extension --force }
            }
    }
}

function Install-Dotfiles {
    if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
        if ($DryRun) {
            Write-Step "[dry-run] chezmoi init/apply"
            return
        }
        throw "chezmoi is not available in this PowerShell session. Reopen the terminal and rerun."
    }
    $source = Join-Path $RootDir "home"
    $config = Join-Path $HOME ".config/chezmoi/chezmoi.toml"
    if ($DryRun -and -not (Test-Path -LiteralPath $config)) {
        Write-Step "[dry-run] chezmoi init (profile=$Profile; Git identity prompts)"
        Write-Step "[dry-run] chezmoi apply skipped because no config exists yet"
        return
    }
    Invoke-Step -Description "chezmoi init (profile=$Profile)" `
        -Action { & chezmoi init --source $source --promptChoice "Select a profile=$Profile" }
    if ($DryRun) {
        & chezmoi apply --source $source --dry-run --verbose
    }
    else {
        & chezmoi apply --source $source --verbose
    }
}

function Install-MiseTools {
    if ($DryRun) {
        Write-Host "[dry-run] MISE_CONFIG_FILE=mise/config.toml mise install"
        return
    }
    if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
        Write-Step "mise is not available in this PowerShell session; runtimes will be installed on the next run"
        return
    }
    $previousConfig = $env:MISE_CONFIG_FILE
    try {
        $env:MISE_CONFIG_FILE = Join-Path $RootDir "mise/config.toml"
        & mise install
        if ($LASTEXITCODE -ne 0) { throw "mise install failed (exit $LASTEXITCODE)" }
    }
    finally {
        $env:MISE_CONFIG_FILE = $previousConfig
    }
}

function Invoke-WSLBootstrap {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        throw "wsl.exe is not available. Install WSL with: wsl --install -d Ubuntu"
    }
    $linuxRoot = (& wsl.exe wslpath -a $RootDir).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $linuxRoot) {
        throw "Could not translate repository path for WSL. Complete the first Ubuntu launch first."
    }
    $dryRunArg = if ($DryRun) { " --dry-run" } else { "" }
    $commandLine = "'$linuxRoot/bootstrap/wsl.sh' $Command --profile $Profile$dryRunArg"
    Write-Step "Running WSL bootstrap"
    & wsl.exe bash -lc $commandLine
    if ($LASTEXITCODE -ne 0) { throw "WSL bootstrap failed (exit $LASTEXITCODE)" }
}

function Invoke-HealthCheck {
    $failed = $false
    foreach ($name in @("git", "chezmoi", "winget")) {
        if (-not (Test-Command $name)) { $failed = $true }
    }
    if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
        & chezmoi doctor
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    }
    if ($Profile -eq "personal") {
        try {
            & (Join-Path $RootDir "settings/windows/ntp.ps1") -CheckOnly
        }
        catch {
            Write-Warning $_
            $failed = $true
        }
    }
    if ($failed) { throw "One or more health checks failed." }
}

function Set-PersonalNtp {
    if ($Profile -ne "personal") { return }
    & (Join-Path $RootDir "settings/windows/ntp.ps1") -DryRun:$DryRun
}

if ($Command -eq "check") {
    if ($Target -in @("windows", "all")) { Invoke-HealthCheck }
    if ($Target -in @("wsl", "all")) { Invoke-WSLBootstrap }
    return
}

if ($Target -in @("windows", "all")) {
    Install-WingetPackages
    Show-ManualWindowsApplications
    Install-Dotfiles
    Install-MiseTools
    Install-VSCodeExtensions
    Set-PersonalNtp
}
if ($Target -in @("wsl", "all")) {
    Invoke-WSLBootstrap
}
if (-not $DryRun -and $Target -in @("windows", "all")) {
    Invoke-HealthCheck
}
