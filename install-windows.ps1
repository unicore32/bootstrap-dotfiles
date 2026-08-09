[CmdletBinding()]
param(
    [ValidateSet("personal", "work")]
    [string]$Profile = "personal",
    [ValidateSet("windows", "wsl", "all")]
    [string]$Target = "all",
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA "bootstrap-dotfiles"),
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepositoryUrl = "https://github.com/unicore32/bootstrap-dotfiles.git"

function Write-Stage0([string]$Message) {
    Write-Host "[stage-0] $Message"
}

function Invoke-Stage0([scriptblock]$Action, [string]$Description) {
    if ($DryRun) {
        Write-Host "[dry-run] $Description"
        return
    }
    & $Action
}

function Get-GitCommand {
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($git) { return $git.Source }

    $pathEntries = @(
        [Environment]::GetEnvironmentVariable("Path", "Process"),
        [Environment]::GetEnvironmentVariable("Path", "User"),
        [Environment]::GetEnvironmentVariable("Path", "Machine")
    ) | Where-Object { $_ } | ForEach-Object { $_ -split ";" } | Select-Object -Unique
    $env:Path = ($pathEntries -join ";")

    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($git) { return $git.Source }
    return $null
}

function Install-Git {
    if (Get-GitCommand) { return }
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw "winget is required. Install or update App Installer first."
    }
    Invoke-Stage0 -Description "winget install --id Git.Git --source winget" -Action {
        & winget.exe install --id Git.Git --source winget --exact --silent `
            --accept-package-agreements --accept-source-agreements --disable-interactivity
        if ($LASTEXITCODE -notin @(0, -1978335189)) {
            throw "winget failed to install Git.Git (exit $LASTEXITCODE)"
        }
    }
    if (-not (Get-GitCommand)) {
        throw "Git was installed but is not available in this PowerShell session. Open a new PowerShell session and rerun this command."
    }
}

function Update-Repository([string]$Git) {
    $gitDirectory = Join-Path $InstallDir ".git"
    if (Test-Path -LiteralPath $gitDirectory -PathType Container) {
        Invoke-Stage0 -Description "git -C $InstallDir pull --ff-only" -Action {
            & $Git -C $InstallDir pull --ff-only
            if ($LASTEXITCODE -ne 0) { throw "git pull failed (exit $LASTEXITCODE)" }
        }
        return
    }
    if (Test-Path -LiteralPath $InstallDir) {
        throw "install path exists but is not a Git repository: $InstallDir"
    }
    Invoke-Stage0 -Description "create $(Split-Path -Parent $InstallDir)" -Action {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $InstallDir) | Out-Null
    }
    Invoke-Stage0 -Description "git clone $RepositoryUrl $InstallDir" -Action {
        & $Git clone $RepositoryUrl $InstallDir
        if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit $LASTEXITCODE)" }
    }
}

if ($DryRun) {
    Write-Stage0 "[dry-run] ensure winget and Git are available"
    Write-Stage0 "[dry-run] clone or fast-forward $RepositoryUrl at $InstallDir"
    Write-Stage0 "[dry-run] & $InstallDir/bootstrap.ps1 install -Target $Target -Profile $Profile -DryRun"
}
else {
    Install-Git
    $git = Get-GitCommand
    Update-Repository -Git $git
    & (Join-Path $InstallDir "bootstrap.ps1") install -Target $Target -Profile $Profile
}
