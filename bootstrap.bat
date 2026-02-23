@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

where pwsh >nul 2>nul
if errorlevel 1 (
  echo [ERROR] PowerShell 7 ^(pwsh^) is required.
  echo Install from: https://learn.microsoft.com/powershell/scripting/install/installing-powershell
  exit /b 1
)

pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\bootstrap.ps1" %*
exit /b %ERRORLEVEL%
