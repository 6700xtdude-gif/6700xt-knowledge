@echo off
rem Double-click launcher for the local llama.cpp model menu.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-LocalLLM.ps1" %*
