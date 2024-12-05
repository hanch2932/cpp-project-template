@echo off
chcp 65001
setlocal

SET "CURRENT_DIR=%~dp0"

echo.
pwsh -NoProfile -ExecutionPolicy Bypass -File "%CURRENT_DIR%\powershell\add-wt-profiles.ps1"

endlocal
pause
