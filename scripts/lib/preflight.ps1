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

    if (-not (Test-RequiredCommand -CommandName 'git')) {
        throw 'git is required but not found on PATH.'
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

    return $os
}
