[CmdletBinding()]
param(
    [ValidateSet("install", "update", "check")]
    [string]$Command = "install",
    [ValidateSet("common", "personal")]
    [string]$Profile = "common",
    [string]$Components,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $PSScriptRoot
$ValidComponents = @("packages", "chocolatey", "dotfiles", "mise", "vscode", "settings")
$SelectedComponents = @()

if ($PSBoundParameters.ContainsKey("Components")) {
    if ([string]::IsNullOrWhiteSpace($Components)) {
        throw "-Components requires at least one component."
    }
    foreach ($rawComponent in $Components.Split(",")) {
        $component = $rawComponent.Trim().ToLowerInvariant()
        if (-not $component) {
            throw "-Components must not contain an empty component."
        }
        if ($component -notin $ValidComponents) {
            throw "Unknown component '$rawComponent'. Valid components: $($ValidComponents -join ', ')."
        }
        if ($component -in $SelectedComponents) {
            throw "Duplicate component '$component'."
        }
        $SelectedComponents += $component
    }
    if ($Command -eq "check") {
        throw "-Components is only supported by install and update. Check always runs the full health check."
    }
}

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

function Install-Chocolatey {
    $chocoCommand = Get-Command choco -ErrorAction SilentlyContinue
    if (-not $chocoCommand) {
        if ($DryRun) {
            Write-Host "[dry-run] install Chocolatey"
        }
        else {
            $principal = New-Object Security.Principal.WindowsPrincipal(
                [Security.Principal.WindowsIdentity]::GetCurrent())
            if (-not $principal.IsInRole(
                    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
                throw "Chocolatey installation requires an elevated PowerShell session."
            }
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol =
                [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
                    "https://community.chocolatey.org/install.ps1"))
            $chocoPath = Join-Path $env:ChocolateyInstall "bin/choco.exe"
            if (Test-Path -LiteralPath $chocoPath) {
                $chocoCommand = Get-Command $chocoPath
            }
            else {
                $chocoCommand = Get-Command choco -ErrorAction SilentlyContinue
            }
            if (-not $chocoCommand) {
                throw "Chocolatey was installed, but choco is not available in this session."
            }
        }
    }

    $description = "choco install font-hackgen-nerd"
    if ($DryRun) {
        Write-Host "[dry-run] $description --yes --no-progress"
    }
    else {
        & $chocoCommand.Source install font-hackgen-nerd --yes --no-progress
        if ($LASTEXITCODE -ne 0) {
            throw "Chocolatey failed for font-hackgen-nerd (exit $LASTEXITCODE)"
        }
    }
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

function Test-ComponentSelected([string]$Name) {
    return $SelectedComponents.Count -eq 0 -or $Name -in $SelectedComponents
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
    Invoke-HealthCheck
    return
}

if (Test-ComponentSelected "chocolatey") { Install-Chocolatey }
if (Test-ComponentSelected "packages") {
    Install-WingetPackages
    Show-ManualWindowsApplications
}
if (Test-ComponentSelected "dotfiles") { Install-Dotfiles }
if (Test-ComponentSelected "mise") { Install-MiseTools }
if (Test-ComponentSelected "vscode") { Install-VSCodeExtensions }
if (Test-ComponentSelected "settings") { Set-PersonalNtp }
if (-not $DryRun -and $SelectedComponents.Count -eq 0) {
    Invoke-HealthCheck
}
