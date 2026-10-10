<#
.SYNOPSIS
    Launch a local GGUF model on the RX 6700 XT (llama.cpp / Vulkan) and expose it to OpenCode.

.DESCRIPTION
    Fires up llama-server.exe from the local llama.cpp Vulkan build with sane
    defaults for this 12 GB card, waits until it answers /health, then prints the
    exact OpenCode model reference to pick.

    OpenCode reads ONE static provider ("local/auto") from
    ~/.config/opencode/opencode.jsonc. That provider points at
    http://127.0.0.1:<Port>/v1 and llama.cpp ignores the model id in requests,
    so switching models never requires editing OpenCode config again.

    Run with no arguments for an interactive menu.

.PARAMETER Model
    GGUF filename (or any unique part of it, or a full path). Omit to get a menu.

.PARAMETER Port
    Port to serve on. Must match the OpenCode provider (default 9931).

.PARAMETER Context
    Context window (tokens). Default 32768.

.PARAMETER Kv
    KV-cache quantization: q8_0 (default), q4_0 (saves VRAM), or f16.

.PARAMETER Thinking
    Reasoning handling. off (default, fast/tool-friendly), on, or auto.

.PARAMETER GpuLayers
    Layers to offload to the GPU. 99 = all (default).

.PARAMETER Parallel
    Concurrent request slots (default 1).

.PARAMETER LlamaDir
    Explicit llama.cpp build folder. Omit to auto-pick the newest under
    C:\Users\6700XT\llm\bin.

.PARAMETER Hidden
    Start the server window hidden/minimized instead of a visible console.

.PARAMETER NoStop
    Do not stop an existing llama-server before starting.

.PARAMETER List
    Only list the available models and exit.

.EXAMPLE
    .\Start-LocalLLM.ps1
    Interactive menu.

.EXAMPLE
    .\Start-LocalLLM.ps1 -Model Qwen3-8B
    Launch the 8B directly.

.EXAMPLE
    .\Start-LocalLLM.ps1 -Model Qwen3-8B -Context 16384 -Kv q4_0
    Tighter context, smaller KV cache.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Model,

    [int]$Port = 9931,
    [int]$Context = 32768,

    [ValidateSet('q8_0', 'q4_0', 'f16')]
    [string]$Kv = 'q8_0',

    [ValidateSet('off', 'on', 'auto')]
    [string]$Thinking = 'off',

    [int]$GpuLayers = 99,
    [int]$Parallel = 1,

    [string]$LlamaDir,
    [switch]$Hidden,
    [switch]$NoStop,
    [switch]$List
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
#  Paths
# ---------------------------------------------------------------------------
$LlmRoot  = 'C:\Users\6700XT\llm'
$ModelDir = Join-Path $LlmRoot 'models'

function Resolve-LlamaDir {
    param([string]$Preferred)
    if ($Preferred -and (Test-Path (Join-Path $Preferred 'llama-server.exe'))) {
        return (Resolve-Path $Preferred).Path
    }
    $bin = Join-Path $LlmRoot 'bin'
    $cand = Get-ChildItem $bin -Directory -Filter 'llama-*' -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'llama-server.exe') } |
        Sort-Object LastWriteTime -Descending
    if ($cand) { return $cand[0].FullName }
    return $null
}

function Write-Rule { param([string]$Text = '') Write-Host ('  ' + ('-' * 70)); if ($Text) { Write-Host $Text } }

# ---------------------------------------------------------------------------
#  Resolve runtime + models
# ---------------------------------------------------------------------------
$runDir = Resolve-LlamaDir -Preferred $LlamaDir
if (-not $runDir) {
    Write-Host "Could not find llama-server.exe under $LlmRoot\bin\llama-*." -ForegroundColor Red
    Write-Host 'Pass -LlamaDir <folder> or install a llama.cpp Vulkan build.' -ForegroundColor Red
    exit 1
}
$serverExe = Join-Path $runDir 'llama-server.exe'

if (-not (Test-Path $ModelDir)) {
    Write-Host "Model folder not found: $ModelDir" -ForegroundColor Red
    exit 1
}

$models = Get-ChildItem $ModelDir -Filter *.gguf -File -ErrorAction SilentlyContinue |
    Sort-Object Name
if (-not $models) {
    Write-Host "No .gguf files in $ModelDir" -ForegroundColor Red
    exit 1
}

if ($List) {
    Write-Host ''
    Write-Host "  Models in $ModelDir" -ForegroundColor Cyan
    Write-Rule
    $models | ForEach-Object {
        '{0,-45} {1,8:N2} GiB' -f $_.Name, ($_.Length / 1GB)
    }
    Write-Host ''
    exit 0
}

# ---------------------------------------------------------------------------
#  Pick a model
# ---------------------------------------------------------------------------
$selected = $null

if ($Model) {
    if (Test-Path $Model) {
        $selected = Get-Item $Model
    }
    else {
        $hits = $models | Where-Object { $_.Name -like "*$Model*" }
        if ($hits.Count -eq 1) { $selected = $hits[0] }
        elseif ($hits.Count -gt 1) {
            Write-Host "`n'$Model' matches several models:" -ForegroundColor Yellow
            $hits | ForEach-Object { Write-Host "  - $($_.Name)" }
            exit 1
        }
    }
    if (-not $selected) {
        Write-Host "No model matches '$Model' in $ModelDir" -ForegroundColor Red
        $models | ForEach-Object { Write-Host "  - $($_.Name)" }
        exit 1
    }
}
else {
    Write-Host ''
    Write-Host '  ==============================================================' -ForegroundColor Cyan
    Write-Host '   Local LLM launcher   -   RX 6700 XT (llama.cpp / Vulkan)'    -ForegroundColor Cyan
    Write-Host '  ==============================================================' -ForegroundColor Cyan
    Write-Host ''
    for ($i = 0; $i -lt $models.Count; $i++) {
        Write-Host ('   [{0}] {1,-45} {2,7:N2} GiB' -f ($i + 1), $models[$i].Name, ($models[$i].Length / 1GB))
    }
    Write-Host ''
    do {
        $answer = Read-Host "  Choose a model [1-$($models.Count)] (default 1)"
        if ([string]::IsNullOrWhiteSpace($answer)) { $answer = '1' }
        $idx = 0
    } while (-not [int]::TryParse($answer, [ref]$idx) -or $idx -lt 1 -or $idx -gt $models.Count)
    $selected = $models[$idx - 1]
}

# ---------------------------------------------------------------------------
#  Stop any previous server
# ---------------------------------------------------------------------------
if (-not $NoStop) {
    $existing = Get-Process llama-server -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "`n  Stopping $($existing.Count) existing llama-server process(es)..." -ForegroundColor DarkYellow
        $existing | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}

# ---------------------------------------------------------------------------
#  Build the launch arguments
# ---------------------------------------------------------------------------
$argList = New-Object System.Collections.Generic.List[string]
$argList.AddRange([string[]]@(
        '-m', $selected.FullName,
        '-c', "$Context",
        '-np', "$Parallel",
        '-ngl', "$GpuLayers",
        '--jinja',
        '--host', '127.0.0.1',
        '--port', "$Port"
    ))

if ($Kv -ne 'f16') {
    $argList.AddRange([string[]]@('-fa', 'on', '-ctk', $Kv, '-ctv', $Kv))
}
else {
    $argList.AddRange([string[]]@('-fa', 'on'))
}

switch ($Thinking) {
    'off' { $argList.AddRange([string[]]@('--reasoning', 'off')) }
    'on' { $argList.AddRange([string[]]@('--reasoning', 'on')) }
    'auto' { $argList.AddRange([string[]]@('--reasoning', 'auto')) }
}

# ---------------------------------------------------------------------------
#  Launch
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '  Launching local model' -ForegroundColor Green
Write-Rule
Write-Host ("   model      : {0}" -f $selected.Name)
Write-Host ("   size       : {0:N2} GiB" -f ($selected.Length / 1GB))
Write-Host ("   runtime    : {0}" -f $runDir)
Write-Host ("   context    : {0}   KV cache: {1}   parallel: {2}" -f $Context, $Kv, $Parallel)
Write-Host ("   offload    : -ngl {0}   flash-attn: on   thinking: {1}" -f $GpuLayers, $Thinking)
Write-Host ("   endpoint   : http://127.0.0.1:{0}/v1" -f $Port)
Write-Rule

$window = if ($Hidden) { 'Hidden' } else { 'Minimized' }
$proc = Start-Process -FilePath $serverExe -ArgumentList $argList.ToArray() -PassThru -WindowStyle $window

Write-Host '  Loading'
$ready = $false
for ($i = 0; $i -lt 300; $i++) {
    if ($proc.HasExited) { break }
    try {
        $h = Invoke-RestMethod "http://127.0.0.1:$Port/health" -TimeoutSec 2
        if ($h.status -eq 'ok') { $ready = $true; break }
    }
    catch { }
    Start-Sleep -Seconds 1
    if ($i % 5 -eq 4) { Write-Host '.' -NoNewline }
}

Write-Host ''
if (-not $ready) {
    Write-Host '  Server did not become healthy.' -ForegroundColor Red
    if ($proc.HasExited) { Write-Host ("  llama-server exited with code {0}." -f $proc.ExitCode) -ForegroundColor Red }
    exit 1
}

Write-Host ("  Ready in ~{0}s  (PID {1})" -f $i, $proc.Id) -ForegroundColor Green
Write-Host ''
Write-Host '  ----------------------------------------------------------------' -ForegroundColor DarkGray
Write-Host '   OpenCode:  /models  ->  "Local llama.cpp (RX 6700 XT)"' -ForegroundColor White
Write-Host '                          "Local model (auto)"     =  local/auto' -ForegroundColor White
Write-Host '   CLI     :  opencode run --model local/auto "your prompt"' -ForegroundColor DarkGray
Write-Host ("   API     :  http://127.0.0.1:{0}/v1   (model id: any)" -f $Port) -ForegroundColor DarkGray
Write-Host '   Stop    :  .\Stop-LocalLLM.ps1' -ForegroundColor DarkGray
Write-Host '  ----------------------------------------------------------------' -ForegroundColor DarkGray
Write-Host ''
