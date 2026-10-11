<#
.SYNOPSIS
    Launch Unsloth Studio with an ELEVATED token, so the local LLM it hosts can do admin work.

.DESCRIPTION
    WHY THIS EXISTS
    --------------
    On this machine the account `6700XT` IS in BUILTIN\Administrators, but the ordinary
    interactive shell runs with a *UAC-filtered* token (integrity = Medium, admin SIDs set to
    "deny only"). That is why an unelevated local LLM could not rename the PC or write HKLM.

    The fix is not a bypass and not an exploit. It is the ordinary Windows pattern: **launch the
    app from an elevated parent.** Everything it spawns inherits the High-integrity token --
    including the llama-server process and any shell the model drives.

    THE CONSENT GATE
    ----------------
    This script calls `Start-Process -Verb RunAs`. Windows shows ONE UAC prompt.
    The Principal clicks it. That click IS the authorisation. Nothing is silenced, no policy is
    edited, no credential is stored, no scheduled task is abused.

    Consequence to accept: while Studio runs elevated, the local model has real administrative
    authority over this machine. That is the point -- but it means the model should still be
    told (see SYSTEM-PROMPT.txt) to never reboot without asking, and never fabricate values.

.PARAMETER StudioPath
    Full path to unsloth-studio.exe. Auto-detected if omitted.

.PARAMETER DryRun
    Print the plan and the elevation path, then exit. Touches nothing.

.PARAMETER Model
    Optional. Passed through to Studio on the command line, if Studio supports it.

.PARAMETER Elevated
    Internal. Set on the elevated re-launch; never pass by hand.

.EXAMPLE
    .\Start-UnslothElevated.ps1 -DryRun
    Show what would happen, elevate nothing.

.EXAMPLE
    .\Start-UnslothElevated.ps1
    Launch Studio elevated. Approve the UAC prompt when it appears.

.NOTES
    Part of 6700xt-knowledge / scripts\windows.
    Verified: 2026-10-11 on SANDBOX (Windows 11 build 26300).
#>
[CmdletBinding()]
param(
    [string]$StudioPath,
    [switch]$DryRun,
    [string]$Model,
    [switch]$Elevated
)

$ErrorActionPreference = 'Stop'

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-Integrity {
    # Medium / High / System -- read from the token's integrity SID label.
    # GetTokenInformation reports it directly; fall back to scanning group SIDs.
    try {
        Add-Type -Namespace Win -Name Native -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("advapi32.dll", SetLastError = true)]
public static extern bool OpenProcessToken(System.IntPtr h, uint acc, out System.IntPtr tok);
[System.Runtime.InteropServices.DllImport("advapi32.dll", SetLastError = true)]
public static extern bool GetTokenInformation(System.IntPtr tok, int cls, System.IntPtr info, int len, out int ret);
[System.Runtime.InteropServices.DllImport("advapi32.dll", SetLastError = true)]
public static extern bool CloseHandle(System.IntPtr h);
'@ -ErrorAction SilentlyContinue

        $acc = 0x0008   # TOKEN_QUERY
        $cls = 25       # TokenIntegrityLevel
        $tok = [IntPtr]::Zero
        if ([Win.Native]::OpenProcessToken([System.Diagnostics.Process]::GetCurrentProcess().Handle, $acc, [ref]$tok)) {
            $need = 0
            [void][Win.Native]::GetTokenInformation($tok, $cls, [IntPtr]::Zero, 0, [ref]$need)
            if ($need -gt 0) {
                $buf = [Runtime.InteropServices.Marshal]::AllocHGlobal($need)
                try {
                    if ([Win.Native]::GetTokenInformation($tok, $cls, $buf, $need, [ref]$need)) {
                        $sidPtr = [Runtime.InteropServices.Marshal]::ReadIntPtr($buf)
                        $sid = New-Object Security.Principal.SecurityIdentifier($sidPtr)
                        $rid = $sid.Value            # e.g. S-1-16-12288
                        switch ($rid) {
                            'S-1-16-8192'  { return 'Medium' }
                            'S-1-16-12288' { return 'High'   }
                            'S-1-16-16384' { return 'System' }
                            default        { return "Level $($rid -replace '^S-1-16-','')" }
                        }
                    }
                } finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($buf) }
            }
            [void][Win.Native]::CloseHandle($tok)
        }
    } catch { }

    # Fallback: scan the token's group SIDs for an integrity label.
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        foreach ($g in $id.Groups) {
            $sid = $g.Value
            if ($sid -match '^S-1-16-(\d+)$') {
                switch ($Matches[1]) {
                    '8192'  { return 'Medium' }
                    '12288' { return 'High'   }
                    '16384' { return 'System' }
                    default { return "Level $($Matches[1])" }
                }
            }
        }
    } catch { }
    return 'unknown'
}

function Resolve-Studio {
    param([string]$Explicit)
    if ($Explicit) {
        if (-not (Test-Path -LiteralPath $Explicit)) {
            throw "StudioPath not found: $Explicit"
        }
        return $Explicit
    }
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Unsloth Studio (Desktop)\unsloth-studio.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Unsloth Studio\unsloth Studio.exe'),
        (Join-Path $env:LOCALAPPDATA 'unsloth-studio.exe')
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return $c }
    }
    throw 'Could not locate unsloth-studio.exe. Pass -StudioPath <full path>.'
}

# ---- Report current state -----------------------------------------------------
Write-Host ''
Write-Host '  Unsloth Studio - elevated launch' -ForegroundColor Cyan
Write-Host ("    this process   : {0}" -f $env:USERNAME)
Write-Host ("    admin role     : {0}" -f (Test-Admin))
Write-Host ("    integrity      : {0}" -f (Get-Integrity))
Write-Host ("    already elevated: {0}" -f $Elevated.IsPresent)
Write-Host ''

if ($DryRun) {
    $path = Resolve-Studio -Explicit $StudioPath
    Write-Host '  Dry run - nothing was launched or changed.' -ForegroundColor DarkYellow
    Write-Host ''
    Write-Host '  Would do:' -ForegroundColor DarkGray
    Write-Host ("    1. Start-Process -FilePath '{0}' -Verb RunAs" -f $path) -ForegroundColor DarkGray
    if ($Model) {
        Write-Host ("       (with -ArgumentList '{0}')" -f $Model) -ForegroundColor DarkGray
    }
    Write-Host '    2. YOU approve the UAC prompt. That click is the authorisation.' -ForegroundColor DarkGray
    Write-Host '    3. Studio + llama-server + the local model inherit the High token.' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  Result: the local LLM can then run admin commands directly, with no' -ForegroundColor DarkGray
    Write-Host '  second UAC prompt, because its process tree is already elevated.' -ForegroundColor DarkGray
    exit 0
}

# ---- Self-elevate (the consent gate) ------------------------------------------
if (-not (Test-Admin)) {
    $path = Resolve-Studio -Explicit $StudioPath

    Write-Host '  Requesting elevation - approve the UAC prompt...' -ForegroundColor DarkYellow
    $psExe = (Get-Process -Id $PID -ErrorAction SilentlyContinue).Path
    if (-not $psExe) { $psExe = 'powershell.exe' }

    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-Elevated')
    if ($Model)    { $argList += @('-Model', "`"$Model`"") }
    $argList += @('-StudioPath', "`"$path`"")

    try {
        Start-Process -FilePath $psExe -ArgumentList $argList -Verb RunAs -ErrorAction Stop | Out-Null
        Write-Host '  Elevation granted. Handing off to the elevated launcher.' -ForegroundColor Green
        Write-Host '  (This unelevated window may close. Studio opens in its own.)' -ForegroundColor DarkGray
        exit 0
    }
    catch {
        Write-Host '  Elevation was cancelled or denied. Studio was NOT launched.' -ForegroundColor Red
        Write-Host '  Nothing changed. You can run it unelevated if you prefer.' -ForegroundColor DarkGray
        exit 1
    }
}

# ---- Elevated: launch Studio --------------------------------------------------
Write-Host '  Elevated. Launching Unsloth Studio...' -ForegroundColor Green
$path = Resolve-Studio -Explicit $StudioPath
Write-Host ("    exe    : {0}" -f $path)
if ($Model) { Write-Host ("    model  : {0}" -f $Model) }
Write-Host ''

$startArgs = @{}
if ($Model) { $startArgs['ArgumentList'] = $Model }

try {
    $p = Start-Process -FilePath $path @startArgs -PassThru -ErrorAction Stop
    Write-Host ("    launched PID {0}" -f $p.Id) -ForegroundColor Green
}
catch {
    Write-Host ("    FAILED to launch: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '  The local LLM inside Studio now runs ELEVATED.' -ForegroundColor Green
Write-Host '  It can rename this PC, write HKLM, and manage services without a' -ForegroundColor DarkGray
Write-Host '  further prompt - because this process tree already holds the token.' -ForegroundColor DarkGray
Write-Host ''
Write-Host '  Paste SYSTEM-PROMPT.txt into Studio'"'"'s System Prompt field so the model' -ForegroundColor DarkGray
Write-Host '  knows it is elevated and does not fabricate system values.' -ForegroundColor DarkGray
Write-Host ''
Write-Host '  Close Studio to drop the elevated token.' -ForegroundColor DarkGray