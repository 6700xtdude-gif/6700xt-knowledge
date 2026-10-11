<#
.SYNOPSIS
    SMOKE2 - agentic smoke suite for local models driven through OpenCode.

.DESCRIPTION
    Replaces the old toy probes ("reply pong", a single get_weather tool call) with
    realistic, tool-required tasks that mirror what we actually want a local agent to
    do on this machine: read the Windows event logs, report machine facts, do
    multi-step filesystem work, and refuse to hallucinate.

    For each task it runs:
        opencode run --model <Model> --agent build --auto --format json
    captures the NDJSON event stream, and reports per task:
      - wall time, and whether it hit the per-task timeout
      - number of model steps and tool calls
      - distinct shell commands, and how often the SAME command was repeated
        (a repeated command == the degenerate-loop failure mode)
      - the final assistant text

    Scoring is manual; this script collects evidence and writes raw JSON per task.
    It is a MEASUREMENT harness, not runtime scaffolding for the model.

.PARAMETER Model
    OpenCode model reference, e.g. local/auto (default).

.PARAMETER TimeoutSec
    Per-task timeout in seconds (default 150). On timeout the whole process tree
    is killed so a looping model cannot run forever.

.PARAMETER Only
    Run a subset of task ids, e.g. -Only T1,T4.

.PARAMETER OutDir
    Results directory (default %USERPROFILE%\llm\smoke).

.EXAMPLE
    .\Invoke-SmokeSuite.ps1 -Model local/auto
#>
[CmdletBinding()]
param(
    [string]$Model = 'local/auto',
    [string]$Agent = 'build',
    [int]$TimeoutSec = 240,
    [string[]]$Only,
    [string]$OutDir = (Join-Path $env:USERPROFILE 'llm\smoke')
)

$ErrorActionPreference = 'Continue'
$cli = 'C:\Users\6700XT\AppData\Roaming\ai.opencode.desktop\cli\2.0.26\opencode-cli.exe'
if (-not (Test-Path $cli)) { throw "opencode CLI not found: $cli" }

$tasks = @(
    [pscustomobject]@{ Id = 'T0'; Name = 'control-instruct';       Prompt = 'Reply with exactly the single word: pong.' }
    [pscustomobject]@{ Id = 'T1'; Name = 'event-triage-1h';        Prompt = 'Query the Windows event logs and report every Error or Critical message from the last hour. Then pick the most serious one and suggest a likely cause and a fix.' }
    [pscustomobject]@{ Id = 'T2'; Name = 'event-match-reference';  Prompt = 'Search the Windows event logs from the last 12 hours for events similar to this one, and report any matches: License Activation (slui.exe) failed with the following error code: hr=0x803F7001' }
    [pscustomobject]@{ Id = 'T3'; Name = 'event-unclean-shutdown'; Prompt = 'How many unclean or unexpected shutdowns has this PC had in the last 7 days? Report the count and which event IDs you used to determine it.' }
    [pscustomobject]@{ Id = 'T4'; Name = 'disk-free';              Prompt = 'Report the free space on every fixed drive on this machine, in GB.' }
    [pscustomobject]@{ Id = 'T5'; Name = 'model-list';             Prompt = 'List the .gguf files in C:\Users\6700XT\llm\models with their size in GiB, largest first.' }
    [pscustomobject]@{ Id = 'T6'; Name = 'largest-files';          Prompt = 'Find the 5 largest files under C:\Users\6700XT\Documents and report each with its full path and size in MB.' }
)
if ($Only) { $tasks = @($tasks | Where-Object { $Only -contains $_.Id }) }

$stamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$slug = ($Model -replace '[^a-zA-Z0-9]+', '_')
$runDir = Join-Path $OutDir "$stamp-$slug"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

# A killed task can leave the single llama-server slot still generating. Before starting
# the next task, wait for the slot to go idle, or the next task gets no answer at all
# (its request just queues) and we'd blame the model for a harness artifact.
function Wait-ServerIdle {
    param([int]$MaxSec = 240)
    $deadline = (Get-Date).AddSeconds($MaxSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $slots = Invoke-RestMethod 'http://127.0.0.1:9931/slots' -TimeoutSec 3
            if (@($slots | Where-Object { $_.is_processing }).Count -eq 0) { return }
        } catch { return }
        Start-Sleep -Seconds 3
    }
    Write-Host '  (warning: server still busy after wait)'
}

$summary = @()
foreach ($t in $tasks) {
    Write-Host "=== $($t.Id) $($t.Name) ==="
    Wait-ServerIdle
    $outFile = Join-Path $runDir ("{0}.jsonl" -f $t.Id)
    $errFile = Join-Path $runDir ("{0}.err" -f $t.Id)
    $title = "SMOKE2 $($t.Id) $($t.Name)"
    $argStr = 'run --model ' + $Model + ' --agent ' + $Agent + ' --auto --format json --title "' + $title + '" "' + $t.Prompt + '"'

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $started = Get-Date
    $p = Start-Process -FilePath $cli -ArgumentList $argStr -NoNewWindow -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $finished = $p.WaitForExit($TimeoutSec * 1000)
    if (-not $finished) {
        try { & taskkill.exe /PID $p.Id /T /F *> $null } catch { }
        Start-Sleep -Seconds 2
    }
    $sw.Stop()
    $endedAt = Get-Date

    $sessionId = $null
    $texts = New-Object System.Collections.Generic.List[string]
    $cmds = New-Object System.Collections.Generic.List[string]
    $tools = 0; $steps = 0
    $reasons = New-Object System.Collections.Generic.List[string]
    foreach ($ln in (Get-Content $outFile -ErrorAction SilentlyContinue)) {
        if (-not $ln.Trim()) { continue }
        try { $o = $ln | ConvertFrom-Json } catch { continue }
        if ($o.sessionID) { $sessionId = $o.sessionID }
        if ($o.type -eq 'step_finish' -and $o.part) { $steps++; if ($o.part.reason) { $reasons.Add([string]$o.part.reason) } }
        $part = $o.part
        if ($part -and $part.type -eq 'tool') {
            $tools++
            if ($part.state -and $part.state.input -and $part.state.input.command) { $cmds.Add([string]$part.state.input.command) }
        }
        elseif ($part -and $part.type -eq 'text' -and $part.text) { $texts.Add([string]$part.text) }
    }

    $distinctCount = ($cmds | Select-Object -Unique).Count
    $maxRepeat = 0
    if ($cmds.Count) { $maxRepeat = [int](($cmds | Group-Object | Sort-Object Count -Descending)[0].Count) }
    $final = ''
    if ($texts.Count) { $final = ($texts[$texts.Count - 1]).Trim() }
    $loop = ($maxRepeat -ge 3)

    $rec = [pscustomobject]@{
        Task           = $t.Id
        Name           = $t.Name
        Model          = $Model
        Session        = $sessionId
        Started        = $started.ToString('HH:mm:ss')
        Ended          = $endedAt.ToString('HH:mm:ss')
        Seconds        = [math]::Round($sw.Elapsed.TotalSeconds, 1)
        TimedOut       = (-not $finished)
        Steps          = $steps
        ToolCalls      = $tools
        DistinctCmds   = $distinctCount
        MaxRepeat      = $maxRepeat
        Loop           = $loop
        Reasons        = (($reasons | Select-Object -Unique) -join ',')
        FinalText      = ($final -replace '\s+', ' ')
    }
    $summary += $rec
    Write-Host ("  {0}s steps={1} tools={2} distinct={3} maxRepeat={4} loop={5} timeout={6}" -f $rec.Seconds, $steps, $tools, $distinctCount, $maxRepeat, $loop, $rec.TimedOut)
}

$summary | Export-Csv (Join-Path $runDir 'summary.csv') -NoTypeInformation
$summary | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $runDir 'summary.json')
Write-Host "`nwrote $runDir"
$summary | Format-Table Task, Seconds, TimedOut, Steps, ToolCalls, DistinctCmds, MaxRepeat, Loop -AutoSize | Out-String -Width 200
