@echo off
rem Double-click launcher to stop the local llama.cpp server.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Stop-LocalLLM.ps1" %*
