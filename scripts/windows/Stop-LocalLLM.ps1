<#
.SYNOPSIS
    Stop the local llama.cpp server.

.DESCRIPTION
    Kills llama-server process(es). With -Port, only the process listening on
    that port is stopped; otherwise every llama-server is stopped.

.EXAMPLE
    .\Stop-LocalLLM.ps1
.EXAMPLE
    .\Stop-LocalLLM.ps1 -Port 9931
#>
[CmdletBinding()]
param(
    [int]$Port
)

$ErrorActionPreference = 'SilentlyContinue'

$targets = @()
if ($Port) {
    $conns = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    foreach ($c in $conns) {
        $p = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
        if ($p) { $targets += $p }
    }
    if (-not $targets) { Write-Host "Nothing listening on port $Port."; exit 0 }
}
else {
    $targets = @(Get-Process llama-server -ErrorAction SilentlyContinue)
    if (-not $targets) { Write-Host 'No llama-server is running.'; exit 0 }
}

foreach ($p in ($targets | Sort-Object Id -Unique)) {
    Write-Host ("Stopping {0} (PID {1})..." -f $p.ProcessName, $p.Id) -ForegroundColor DarkYellow
    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
}
Write-Host 'Done.' -ForegroundColor Green
