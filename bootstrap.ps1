[CmdletBinding()]
param(
    [ValidateSet("install", "update", "check")]
    [string]$Command = "install",
    [ValidateSet("windows", "wsl", "all")]
    [string]$Target = "all",
    [ValidateSet("common", "personal")]
    [string]$Profile = "common",
    [string]$Components,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$arguments = @{
    Command = $Command
    Target = $Target
    Profile = $Profile
    DryRun = $DryRun
}
if ($PSBoundParameters.ContainsKey("Components")) {
    $arguments.Components = $Components
}
& (Join-Path $PSScriptRoot "bootstrap/windows.ps1") @arguments

