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
$arguments = @{
    Command = $Command
    Profile = $Profile
    DryRun = $DryRun
}
if ($PSBoundParameters.ContainsKey("Components")) {
    $arguments.Components = $Components
}
& (Join-Path $PSScriptRoot "bootstrap/windows.ps1") @arguments

