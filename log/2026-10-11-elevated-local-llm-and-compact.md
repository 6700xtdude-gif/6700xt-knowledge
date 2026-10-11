# 2026-10-11 — Raising the local LLM: an elevated Studio launcher, the Compact, and minutes

**Machine:** SANDBOX · Windows 11 Pro (build 26300) · RX 6700 XT `gfx1031` (driver `32.0.21045.5002`)
**Goal:** Make the local LLM able to run elevated, and get the governance record out of a volatile
session database and into durable files.
**Result:** ✅ works — `Start-UnslothElevated.ps1` self-elevates Studio via the standard UAC
consent prompt; `-DryRun` verified, script parses clean, integrity detection reads `Medium`
unelevated. `COMPACT.md` and `MINUTES.md` written.

## Context

Two threads met.

**First.** The 2026-10-10/11 session proved a local model *fabricates system values* and cannot
administer the machine from an unelevated shell. The standing conclusion was that elevation is a
**consent gate** — the account is an administrator, the token is merely UAC-filtered. But no tool
existed to actually give the model a High-integrity token.

**Second.** That same session ran ~2h48m and produced **no filed minutes**. Its only durable trace
was an automatic compaction summary inside `~/.local/share/opencode/opencode.db` — an application
database, not a record the Principal controls. That is precisely the failure Article IV exists to
prevent.

## Steps

```powershell
# 1. establish ground truth about the token
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
(New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)      # -> False
whoami /groups | Select-String 'Mandatory Label'                # -> S-1-16-8192 (Medium)

# 2. locate the Studio binary
Get-ChildItem "$env:LOCALAPPDATA" -Recurse -Depth 3 -Filter '*nsloth*.exe'
#   -> C:\Users\6700XT\AppData\Local\Unsloth Studio (Desktop)\unsloth-studio.exe

# 3. build and verify the launcher (parse + dry-run, elevate nothing)
[System.Management.Automation.Language.Parser]::ParseFile($s,[ref]$null,[ref]$errs)
powershell -NoProfile -ExecutionPolicy Bypass -File $s -DryRun
```

## Output

Token ground truth:

```
IsAdmin(role) : False
Integrity     : Mandatory Label\Medium Mandatory Level  S-1-16-8192
User          : 6700XT
```

Parser + dry-run:

```
PARSE: OK (0 errors)

  Unsloth Studio - elevated launch
    this process   : 6700XT
    admin role     : False
    integrity      : Medium
    already elevated: False

  Would do:
    1. Start-Process -FilePath '...\unsloth-studio.exe' -Verb RunAs
    2. YOU approve the UAC prompt. That click is the authorisation.
    3. Studio + llama-server + the local model inherit the High token.
```

## Findings

- **The local LLM can be given a High-integrity token by launching its host elevated.** Standard
  Windows inheritance — no exploit, no policy edit. `✅ Verified: 2026-10-11`
- **The integrity level is readable from the token**, via `GetTokenInformation`
  (`TokenIntegrityLevel`, class 25) → `S-1-16-8192` = Medium. A group-SID scan is a working
  fallback. `✅ Verified: 2026-10-11`
- **`SYSTEM-PROMPT.txt` was actively wrong and said so.** It opened with "You run UNELEVATED …
  you cannot silently rename the PC." That was true only of the *launch path*, not of the machine.
  It now opens with **rule 0**: test your own elevation, don't assume either way.
  `✅ Corrected: 2026-10-11`
- **Elevation increases the cost of a wrong answer, not just the power.** The model fabricates
  system values (measured: 3/3 wrong hostname answers). Article I therefore binds hardest exactly
  when the Agent is most capable. `✅ Verified: 2026-10-11`
- **The governance record existed in exactly one volatile place.** Recovered from
  `opencode.db` (`ses_ed6d94785ffem90XBcUDhUD7j9`, compaction at seq 682) and written to
  `MINUTES.md` and `COMPACT.md`. The reconstruction is labelled as such. `✅ Verified: 2026-10-11`
- **Both open questions of the 2026-10-10 session are now resolved**: record location = this KB
  (versioned, pushed); Provisional Window = first 30 days, simple majority, supermajority after.
  `✅ Resolved: 2026-10-11`

## Follow-ups

- [ ] **Push** the outstanding commit `c5db6b4` plus the new files to `origin/main`.
- [ ] **Run it for real** — approve the UAC prompt and confirm inside Studio that the model reports
      `IsAdmin = True` from its own shell.
- [ ] Decide the new computer name (still `SANDBOX`); reboot required to apply.
- [ ] Re-run the agentic smoke suite against the elevated model — the failure taxonomy
      (analysis paralysis, malformed-query loops, hallucinated verification) may differ when the
      model can actually read system state instead of guessing.
- [ ] Prune `~/.cache/huggingface` (~36 GB, ~21 GB not wired into the launcher); offered
      2026-10-10, no decision yet.