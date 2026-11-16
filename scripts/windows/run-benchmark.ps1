<#
.SYNOPSIS
    Standardized 6700 XT Community Benchmark Runner
.DESCRIPTION
    Runs reproducible inference benchmarks on AMD Radeon RX 6700 XT (gfx1031)
    and formats the results for submission to the 6700xt-knowledge repository.
#>

[CmdletBinding()]
param(
    [string]$ServerUrl = "http://127.0.0.1:8080",
    [int]$Seed = 6700,
    [float]$Temperature = 0.6
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Red
Write-Host "  AMD Radeon RX 6700 XT Community Inference Benchmark" -ForegroundColor White
Write-Host "  Repo: https://github.com/6700xtdude-gif/6700xt-knowledge" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Red
Write-Host ""

# 1. Hardware Fingerprinting
Write-Host "[1/4] Detecting Hardware Baseline..." -ForegroundColor Cyan
$gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "*6700 XT*" } | Select-Object -First 1
if (-not $gpu) {
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
}

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$dimms = Get-CimInstance Win32_PhysicalMemory
$totalRamGB = [math]::Round(($dimms | Measure-Object -Property Capacity -Sum).Sum / 1GB, 1)
$dimmCount = ($dimms | Measure-Object).Count
$os = (Get-CimInstance Win32_OperatingSystem).Caption

$gpuName = if ($gpu) { $gpu.Name } else { "AMD Radeon RX 6700 XT 12GB" }
$driverVer = if ($gpu) { $gpu.DriverVersion } else { "Unknown" }
$cpuName = if ($cpu) { $cpu.Name.Trim() } else { "AMD Ryzen" }

Write-Host "  GPU: $gpuName (Driver: $driverVer)" -ForegroundColor Green
Write-Host "  CPU: $cpuName" -ForegroundColor Green
Write-Host "  RAM: $totalRamGB GB ($dimmCount-DIMM configuration)" -ForegroundColor Green
Write-Host "  OS:  $os" -ForegroundColor Green
Write-Host ""

# 2. Server Status Verification
Write-Host "[2/4] Connecting to Local Inference Engine ($ServerUrl)..." -ForegroundColor Cyan
try {
    $props = Invoke-RestMethod -Uri "$ServerUrl/props" -TimeoutSec 3 -ErrorAction Stop
    $modelAlias = $props.model_alias
    $ctx = $props.default_generation_settings.n_ctx
    Write-Host "  Active Model: $modelAlias" -ForegroundColor Green
    Write-Host "  KV Context:   $ctx tokens" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Cannot connect to $ServerUrl." -ForegroundColor Red
    Write-Host "  Please ensure llama-server.exe is running on port 8080." -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 3. Running Benchmark Prompts
Write-Host "[3/4] Executing Standardized Prompts (Seed $Seed)..." -ForegroundColor Cyan

$testPrompts = @(
    @{
        Name = "Burst Generation (Short)"
        Prompt = "Explain the architecture of AMD Infinity Cache and how it accelerates GPU memory bandwidth in 3 paragraphs."
        MaxTokens = 256
    },
    @{
        Name = "Reasoning & Logic Trace"
        Prompt = "Solve this step by step: A train leaves station A at 60 mph. Two hours later, a second train leaves station A on a parallel track at 90 mph. Exactly how many miles from station A does the second train overtake the first train?"
        MaxTokens = 400
    }
)

$results = @()

foreach ($test in $testPrompts) {
    Write-Host "  Testing: $($test.Name)..." -NoNewline
    $body = @{
        prompt = $test.Prompt
        n_predict = $test.MaxTokens
        temperature = $Temperature
        seed = $Seed
        stream = $false
    } | ConvertTo-Json

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $res = Invoke-RestMethod -Uri "$ServerUrl/completion" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 60
        $sw.Stop()

        $durationSec = [math]::Round($sw.Elapsed.TotalSeconds, 2)
        $tokensOut = $res.tokens_predicted
        $tps = if ($durationSec -gt 0 -and $tokensOut) { [math]::Round($tokensOut / $durationSec, 2) } else { "N/A" }

        Write-Host " Done! ($tokensOut tokens @ $tps t/s in ${durationSec}s)" -ForegroundColor Green
        $results += [PSCustomObject]@{
            Test = $test.Name
            Tokens = $tokensOut
            Speed = $tps
            Duration = $durationSec
        }
    } catch {
        Write-Host " Failed! ($($_.Exception.Message))" -ForegroundColor Red
    }
}

Write-Host ""

# 4. Generate Community Markdown Table
Write-Host "[4/4] Generating Community Benchmark Submission..." -ForegroundColor Cyan

$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$avgSpeed = ($results | Measure-Object -Property Speed -Average).Average
$avgSpeedStr = if ($avgSpeed) { [math]::Round($avgSpeed, 1) } else { "N/A" }

$md = @"
### Community Benchmark: AMD Radeon RX 6700 XT
**Submitted:** $timestamp  
**Hardware Baseline:**
- **GPU:** $gpuName (Driver: `$driverVer`)
- **CPU:** $cpuName
- **System Memory:** $totalRamGB GB ($dimmCount-DIMM)
- **Model:** `$modelAlias` (Context: $ctx, Seed: $Seed, Temp: $Temperature)

| Benchmark Test | Output Tokens | Duration (s) | Decode Velocity (t/s) |
|---|---|---|---|
"@

foreach ($r in $results) {
    $md += "`n| $($r.Test) | $($r.Tokens) | $($r.Duration)s | **$($r.Speed) t/s** |"
}

$md += @"


**Summary:** Average throughput **$avgSpeedStr t/s** on Vulkan backend.
"@

# Copy to clipboard
Set-Clipboard -Value $md
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  SUCCESS! Benchmark Markdown copied to your Clipboard." -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To submit your results:" -ForegroundColor Yellow
Write-Host "1. Paste (Ctrl + V) into GitHub Issues or Discussions." -ForegroundColor Yellow
Write-Host "2. URL: https://github.com/6700xtdude-gif/6700xt-knowledge/issues" -ForegroundColor Cyan
Write-Host ""
