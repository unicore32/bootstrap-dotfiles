Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-HostOs {
    if ($IsMacOS) { return 'macos' }
    if ($IsWindows) { return 'windows' }
    return 'unsupported'
}

function Test-RequiredCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    return [bool](Get-Command -Name $CommandName -ErrorAction SilentlyContinue)
}

function Invoke-Preflight {
    $os = Get-HostOs
    if ($os -eq 'unsupported') {
        throw 'Unsupported OS. This repository currently supports Windows and macOS only.'
    }

    function Prompt-YesNo {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message
        )

        $resp = Read-Host "$Message [y/N]"
        return ($resp -match '^[Yy]')
    }

    function Try-Install-WithWinget {
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$Candidates
        )

        foreach ($c in $Candidates) {
            try {
                Write-Host "[INFO] Attempting winget install: $c"
                & winget install --id $c --accept-package-agreements --accept-source-agreements -e
                if ($LASTEXITCODE -eq 0) { return $true }
            } catch {
                try {
                    & winget install --name $c --accept-package-agreements --accept-source-agreements
                    if ($LASTEXITCODE -eq 0) { return $true }
                } catch { }
            }
        }

        return $false
    }

    # Ensure git is present (attempt install on Windows via winget with confirmation)
    if (-not (Test-RequiredCommand -CommandName 'git')) {
        if ($os -eq 'windows' -and (Test-RequiredCommand -CommandName 'winget')) {
            if (Prompt-YesNo 'git is not found. Install Git via winget now?') {
                $gitCandidates = @('Git.Git', 'Git.GitForWindows', 'Git')
                if (-not (Try-Install-WithWinget -Candidates $gitCandidates)) {
                    throw 'git is required but installation via winget failed.'
                }
            } else {
                throw 'git is required but not installed.'
            }
        } else {
            throw 'git is required but not found on PATH.'
        }
    }

    if (-not (Test-RequiredCommand -CommandName 'chezmoi')) {
        Write-Warning 'chezmoi is not found on PATH. Dotfiles apply step will fail until chezmoi is installed.'
    }

    if ($os -eq 'macos' -and -not (Test-RequiredCommand -CommandName 'brew')) {
        Write-Warning 'Homebrew is not found. Package installation on macOS requires brew.'
    }

    if ($os -eq 'windows' -and -not (Test-RequiredCommand -CommandName 'winget')) {
        Write-Warning 'winget is not found. Package installation on Windows requires winget.'
    }

    # If pwsh (PowerShell Core) is not installed on Windows, offer to install via winget.
    if ($os -eq 'windows' -and -not (Test-RequiredCommand -CommandName 'pwsh')) {
        if (Test-RequiredCommand -CommandName 'winget') {
            if (Prompt-YesNo 'pwsh (PowerShell Core) is not found. Install via winget now?') {
                $pwshCandidates = @('PowerShell.PowerShell', 'Microsoft.PowerShell', 'PowerShell')
                if (-not (Try-Install-WithWinget -Candidates $pwshCandidates)) {
                    Write-Warning 'Failed to install pwsh via winget. You may need to install it manually.'
                } else {
                    Write-Host 'pwsh installed. You may need to restart your shell to use pwsh.'
                }
            } else {
                Write-Warning 'pwsh not installed. Some operations may require PowerShell Core.'
            }
        }
    }

    return $os
}
