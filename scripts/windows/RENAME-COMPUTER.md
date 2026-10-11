# Renaming this PC — the recipe for the local LLM

**Verified:** 2026-10-11 · `✅ Verified` (commands run on SANDBOX, Windows 11 build 26300)

> Companion to [`Rename-ComputerElevated.ps1`](Rename-ComputerElevated.ps1).

## The one rule that matters

A local model **cannot** read your system state or rename your PC on its own. Its terminal runs
**unelevated** (filtered admin token, UAC on), so anything admin returns:

```
Exit code 1:
The requested operation requires elevation (Run as administrator).
```

The pattern that works: **the model writes a script that asks the *human* for admin.** Nothing
silently escalates; nothing is bypassed; you approve the UAC prompt.

## Never do this — all three observed failing here

| ❌ Wrong | Why it fails |
|---|---|
| `wmic computersystem where name="X" call renamenode Y` | deprecated, usually absent on build 26300+; also needs admin |
| `Set-ComputerName -Name Y -Restart` | **this cmdlet does not exist.** The real one is `Rename-Computer` |
| Guessing / fabricating a value | see the hallucination table below |

### Fabrication is the bigger danger

Asked "run `hostname` and give me the output", the local 9B gave three different wrong answers on
three runs. The true value was `SANDBOX` every time:

| Run | Answer |
|---|---|
| 1 | `d4f8a2c1-9b3e-4f1a-8c7d-2e5b6a9f0c3d` |
| 2 | `workstation` |
| 3 | `DESKTOP-XXXXXX` |

Zero of them were correct, and each was stated plainly, without hedging. **If you cannot run a
command, say so** — never fill the gap with a plausible string.

## The working script (already built and tested)

`Rename-ComputerElevated.ps1` in this folder validates the name, re-launches itself elevated via
`Start-Process -Verb RunAs` (your UAC prompt), runs `Rename-Computer`, and reports the reboot.

```powershell
$s = 'C:\Users\6700XT\Documents\6700xt-knowledge\scripts\windows\Rename-ComputerElevated.ps1'

# inspect the plan; changes nothing
powershell -NoProfile -ExecutionPolicy Bypass -File $s -NewName MYBOXRIG -DryRun

# do it: UAC prompt -> approve -> reboot to apply
powershell -NoProfile -ExecutionPolicy Bypass -File $s -NewName MYBOXRIG
```

## Reading the name back (verified ground truth, 2026-10-11)

```powershell
(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName').ComputerName
$env:COMPUTERNAME
hostname
```

All four routes agreed: `SANDBOX`. Note the registry has **two** keys —
`ActiveComputerName` (name in effect) and `ComputerName` (name pending a reboot). After a rename they
differ until you reboot.

## Name rules (Windows rejects anything else)

1–15 characters · letters, digits and hyphens only · **no underscore** · not all digits ·
no leading/trailing hyphen. So `SANDBOX_v0` is invalid; `SANDBOX-v0` is fine.

## Minimal correct script, if you must write one from scratch

```powershell
param([string]$NewName)
if (-not $NewName) { throw 'NewName required' }

$amAdmin = (New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $amAdmin) {
    Start-Process powershell -Verb RunAs -ArgumentList @(
        '-NoProfile', '-File', "`"$PSCommandPath`"", '-NewName', "`"$NewName`"")
    return
}

Rename-Computer -NewName $NewName -Force
Write-Host "Renamed to $NewName. REBOOT to apply."
```

`-Verb RunAs` is the whole trick: it triggers UAC **for the user to approve**, which is why this
respects the machine owner's authority instead of working around it.

## For the local LLM

See [`SYSTEM-PROMPT.txt`](SYSTEM-PROMPT.txt) in this folder — paste it into Unsloth's chat
**System Prompt** field. It encodes the three prohibitions and the correct commands above.
