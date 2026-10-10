<#
.SYNOPSIS
    Show what local model is currently served (and how OpenCode should reach it).

.EXAMPLE
    .\Status-LocalLLM.ps1
#>
[CmdletBinding()]
param(
    [int]$Port = 9931
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host ''
Write-Host '  Local LLM status' -ForegroundColor Cyan
Write-Host ('  ' + ('-' * 60))

$procs = @(Get-Process llama-server -ErrorAction SilentlyContinue)
if (-not $procs) {
    Write-Host '  No llama-server process is running.' -ForegroundColor DarkYellow
    Write-Host '  Start one with .\Start-LocalLLM.ps1'
    Write-Host ''
    exit 0
}

foreach ($p in $procs) {
    Write-Host ("  PID {0,-7} started {1}" -f $p.Id, $p.StartTime)
}

$healthy = $false
try {
    $h = Invoke-RestMethod "http://127.0.0.1:$Port/health" -TimeoutSec 3
    $healthy = ($h.status -eq 'ok')
}
catch { }

if (-not $healthy) {
    Write-Host "  Port $Port is not answering /health." -ForegroundColor DarkYellow
    Write-Host ''
    exit 0
}

try {
    $m = (Invoke-RestMethod "http://127.0.0.1:$Port/v1/models" -TimeoutSec 5).data
    if ($m -is [array]) { $m = $m[0] }
    $meta = $m.meta
    Write-Host ''
    Write-Host ("  model      : {0}" -f (Split-Path $m.id -Leaf))
    if ($meta) {
        Write-Host ("  context    : {0}  (trained {1})" -f $meta.n_ctx, $meta.n_ctx_train)
        Write-Host ("  params     : {0:N2} B   quant: {1}" -f ($meta.n_params / 1e9), $meta.ftype)
    }
}
catch {
    Write-Host '  /v1/models not available.' -ForegroundColor DarkYellow
}

Write-Host ("  endpoint   : http://127.0.0.1:{0}/v1" -f $Port)
Write-Host '  OpenCode   : local/auto' -ForegroundColor Green
Write-Host ''
