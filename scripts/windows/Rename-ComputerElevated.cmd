@echo off
rem Double-click wrapper for Rename-ComputerElevated.ps1.
rem Prompts for the new name; you approve the UAC consent prompt.
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Rename-ComputerElevated.ps1" %*
echo.
pause
