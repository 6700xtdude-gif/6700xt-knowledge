<#
.SYNOPSIS
    Rename THIS computer through a UAC consent prompt (self-elevating).

.DESCRIPTION
    The interactive shell on this box runs with a *filtered* (unelevated)
    administrator token, so it cannot rename the computer SILENTLY. It CAN do it
    WITH CONSENT: this script re-launches itself with `Start-Process -Verb RunAs`,
    Windows shows the UAC prompt, YOU approve it, and the elevated copy runs
    `Rename-Computer`.

    Elevation here is a consent gate, not a wall. Nothing is bypassed or silenced
    - the Principal is the one who approves. A reboot is required for the new
    name to take effect (pass -Reboot to do it now, otherwise the command is
    printed for you to run when ready).

.PARAMETER NewName
    New computer name. 1-15 chars; letters, digits and hyphen only; not all
    digits; no leading or trailing hyphen.

.PARAMETER DryRun
    Validate and print what would happen, then exit. No elevation, no change.

.PARAMETER Reboot
    Explicit opt-in: reboot immediately after a successful rename.

.PARAMETER Elevated
    Internal. Set on the elevated re-launch; never pass this by hand.

.EXAMPLE
    .\Rename-ComputerElevated.ps1 -NewName MyBox -DryRun
    Show the plan without touching anything.

.EXAMPLE
    .\Rename-ComputerElevated.ps1 -NewName MyBox
    Rename now (you approve the UAC prompt); reboot by hand afterwards.

.EXAMPLE
    .\Rename-ComputerElevated.ps1 -NewName MyBox -Reboot
    Rename and reboot in one shot (UAC prompt, then Restart-Computer).

.NOTES
    Part of 6700xt-knowledge / scripts\windows. Requires an account in the local
    Administrators group and UAC enabled. Called by the OpenCode agent's shell
    tool just like any other script - the human still clicks the UAC prompt.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$NewName,

    [switch]$DryRun,
    [switch]$Reboot,

    # Internal: true when this process is the elevated re-launch.
    [switch]$Elevated
)

$ErrorActionPreference = 'Stop'

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-ComputerName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { throw 'NewName is required.' }
    if ($Name.Length -gt 15) { throw "Computer name '$Name' is too long (max 15 characters)." }
    if ($Name -notmatch '^[A-Za-z0-9-]+$') { throw "Computer name '$Name' may only contain letters, digits and hyphens." }
    if ($Name -match '^[0-9]+$') { throw "Computer name '$Name' cannot be all digits." }
    if ($Name.StartsWith('-') -or $Name.EndsWith('-')) { throw "Computer name '$Name' cannot start or end with a hyphen." }
}

$current = $env:COMPUTERNAME

if (-not $NewName) {
    if ($Elevated) { throw 'NewName is required.' }
    $NewName = Read-Host "  Current name is '$current'. New computer name"
}

Assert-ComputerName -Name $NewName

if ($NewName -ieq $current) {
    Write-Host "  Already named '$current'. Nothing to do." -ForegroundColor Yellow
    exit 0
}

Write-Host ''
Write-Host '  Rename computer' -ForegroundColor Cyan
Write-Host ("    from            : {0}" -f $current)
Write-Host ("    to              : {0}" -f $NewName)
Write-Host ("    elevated token  : {0}" -f (Test-Admin))
Write-Host ''

if ($DryRun) {
    Write-Host '  Dry run: no elevation, no change.' -ForegroundColor DarkYellow
    if (Test-Admin) {
        Write-Host ("  Would run: Rename-Computer -NewName {0} -Force" -f $NewName) -ForegroundColor DarkGray
    }
    else {
        Write-Host ("  Would self-elevate (UAC) then run: Rename-Computer -NewName {0} -Force" -f $NewName) -ForegroundColor DarkGray
    }
    Write-Host '  A reboot is then required for the name to take effect.' -ForegroundColor DarkGray
    exit 0
}

# ---- Self-elevate if needed (the consent gate) -------------------------------
if (-not (Test-Admin)) {
    Write-Host '  Requesting elevation - approve the UAC prompt...' -ForegroundColor DarkYellow
    $psExe = (Get-Process -Id $PID -ErrorAction SilentlyContinue).Path
    if (-not $psExe) { $psExe = 'powershell.exe' }

    $argList = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$PSCommandPath`"",
        '-NewName', "`"$NewName`"",
        '-Elevated'
    )
    if ($Reboot) { $argList += '-Reboot' }

    try {
        $p = Start-Process -FilePath $psExe -ArgumentList $argList -Verb RunAs -PassThru -Wait
    }
    catch {
        Write-Host '  Elevation was cancelled or denied. Nothing changed.' -ForegroundColor Red
        exit 1
    }
    exit $p.ExitCode
}

# ---- Elevated: do the rename --------------------------------------------------
Write-Host '  Elevated. Renaming...' -ForegroundColor Green
Rename-Computer -NewName $NewName -Force

Write-Host ''
Write-Host ("  OK: computer renamed to '{0}'." -f $NewName) -ForegroundColor Green
Write-Host ("  Name is still '{0}' until REBOOT." -f $env:COMPUTERNAME) -ForegroundColor Yellow

if ($Reboot) {
    Write-Host '  Rebooting now (-Reboot).' -ForegroundColor Yellow
    Restart-Computer -Force
}
else {
    Write-Host '  Reboot when ready:  Restart-Computer' -ForegroundColor DarkGray
}
