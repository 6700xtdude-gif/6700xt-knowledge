@echo off
REM Double-click wrapper: launches Unsloth Studio elevated (UAC prompt).
REM The UAC prompt IS the consent gate - approve it and Studio's local LLM gets admin rights.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-UnslothElevated.ps1" %*
pause