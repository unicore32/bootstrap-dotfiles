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
& (Join-Path $PSScriptRoot "bootstrap/windows.ps1") `
    -Command $Command -Target $Target -Profile $Profile -DryRun:$DryRun

