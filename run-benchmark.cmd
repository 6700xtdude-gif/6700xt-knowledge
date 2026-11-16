@echo off
title AMD Radeon RX 6700 XT - Community Benchmark Runner
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\run-benchmark.ps1"
echo.
pause
