[CmdletBinding()]
param(
    [switch]$CheckOnly,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$NtpServer = "ntp.jst.mfeed.ad.jp"
$NtpPeer = "$NtpServer,0x8"
$ParametersPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
$current = Get-ItemProperty -LiteralPath $ParametersPath

if ($current.NtpServer -eq $NtpPeer -and $current.Type -eq "NTP") {
    Write-Host "[ntp] configured: $NtpServer"
    return
}

if ($CheckOnly) {
    Write-Error "NTP drift: server=$($current.NtpServer) type=$($current.Type) expected=$NtpPeer"
    return
}

if ($DryRun) {
    Write-Host "[dry-run] w32tm /config /manualpeerlist:$NtpPeer /syncfromflags:manual /update"
    Write-Host "[dry-run] restart Windows Time and resync"
    return
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Configuring NTP requires an elevated PowerShell session."
}

& w32tm /config "/manualpeerlist:$NtpPeer" /syncfromflags:manual /update
if ($LASTEXITCODE -ne 0) { throw "w32tm configuration failed (exit $LASTEXITCODE)" }

Restart-Service -Name w32time
& w32tm /resync
if ($LASTEXITCODE -ne 0) { throw "w32tm resync failed (exit $LASTEXITCODE)" }

Write-Host "[ntp] configured: $NtpServer"

