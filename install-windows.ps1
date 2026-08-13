[CmdletBinding()]
param(
    [ValidateSet("common", "personal")]
    [string]$Profile = "common",
    [string]$Branch,
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

function Validate-Branch([string]$Git) {
    if (-not $Branch) { return }
    if ($Branch.StartsWith("-")) {
        throw "Invalid branch: $Branch"
    }
    & $Git check-ref-format --branch $Branch *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Invalid branch: $Branch"
    }
}

function Ensure-CleanRepository([string]$Git) {
    $status = & $Git -C $InstallDir status --porcelain --untracked-files=all
    if ($LASTEXITCODE -ne 0) { throw "Could not inspect repository status: $InstallDir" }
    if ($status) {
        throw "Repository has local changes; refusing to switch branch: $InstallDir"
    }
}

function Fetch-Branch([string]$Git) {
    $remoteRef = "refs/remotes/origin/$Branch"
    & $Git -C $InstallDir fetch origin "refs/heads/$Branch:$remoteRef"
    if ($LASTEXITCODE -ne 0) { throw "Could not fetch branch from origin: $Branch" }
}

function Switch-ToBranch([string]$Git) {
    $remoteRef = "refs/remotes/origin/$Branch"
    & $Git -C $InstallDir show-ref --verify --quiet "refs/heads/$Branch"
    $localBranchExists = $LASTEXITCODE -eq 0
    if ($localBranchExists) {
        $localCommit = (& $Git -C $InstallDir rev-parse "$Branch`^{commit}").Trim()
        $remoteCommit = (& $Git -C $InstallDir rev-parse "$remoteRef`^{commit}").Trim()
        & $Git -C $InstallDir merge-base --is-ancestor $localCommit $remoteCommit
        if ($LASTEXITCODE -ne 0) {
            throw "Local branch has diverged from origin/$Branch"
        }
        & $Git -C $InstallDir switch $Branch
        if ($LASTEXITCODE -ne 0) { throw "Could not switch to branch: $Branch" }
    }
    else {
        & $Git -C $InstallDir switch --track -c $Branch $remoteRef
        if ($LASTEXITCODE -ne 0) { throw "Could not create branch: $Branch" }
    }
}

function Fast-Forward-Branch([string]$Git) {
    & $Git -C $InstallDir merge --ff-only "refs/remotes/origin/$Branch"
    if ($LASTEXITCODE -ne 0) { throw "Could not fast-forward branch: $Branch" }
}

function Update-ExistingRepository([string]$Git) {
    if (-not $Branch) {
        Invoke-Stage0 -Description "git -C $InstallDir pull --ff-only" -Action {
            & $Git -C $InstallDir pull --ff-only
            if ($LASTEXITCODE -ne 0) { throw "git pull failed (exit $LASTEXITCODE)" }
        }
        return
    }
    Ensure-CleanRepository -Git $Git
    Fetch-Branch -Git $Git
    Switch-ToBranch -Git $Git
    Fast-Forward-Branch -Git $Git
}

function Clone-Repository([string]$Git) {
    if (Test-Path -LiteralPath $InstallDir) {
        throw "install path exists but is not a Git repository: $InstallDir"
    }
    Invoke-Stage0 -Description "create $(Split-Path -Parent $InstallDir)" -Action {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $InstallDir) | Out-Null
    }
    $cloneArguments = @("clone")
    if ($Branch) { $cloneArguments += @("--branch", $Branch) }
    $cloneArguments += @($RepositoryUrl, $InstallDir)
    Invoke-Stage0 -Description "git $($cloneArguments -join ' ')" -Action {
        & $Git @cloneArguments
        if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit $LASTEXITCODE)" }
    }
}

function Update-Repository([string]$Git) {
    $gitDirectory = Join-Path $InstallDir ".git"
    if (Test-Path -LiteralPath $gitDirectory -PathType Container) {
        Update-ExistingRepository -Git $Git
    }
    else {
        Clone-Repository -Git $Git
    }
}

if ($DryRun) {
    Write-Stage0 "[dry-run] ensure winget and Git are available"
    if ($Branch) {
        Write-Stage0 "[dry-run] clone or fast-forward $RepositoryUrl at $InstallDir (branch=$Branch)"
    }
    else {
        Write-Stage0 "[dry-run] clone or fast-forward $RepositoryUrl at $InstallDir"
    }
    Write-Stage0 "[dry-run] & $InstallDir/bootstrap.ps1 install -Profile $Profile -DryRun"
}
else {
    Install-Git
    $git = Get-GitCommand
    Validate-Branch -Git $git
    Update-Repository -Git $git
    & (Join-Path $InstallDir "bootstrap.ps1") install -Profile $Profile
}
