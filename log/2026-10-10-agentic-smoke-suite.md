# 2026-10-10 — Agentic smoke suite v2: the 8B passes toys, fails real triage

**Machine:** SANDBOX · Windows 11 Pro · RX 6700 XT `gfx1031` (driver `32.0.21045.5002`) · **no ROCm** ·
OpenCode Desktop **v2.0.26** · llama.cpp `b11541` Vulkan
**Goal:** Replace the toy probes ("reply `pong`", one `get_weather` tool call) with realistic,
tool-required tasks, and find where a local model actually breaks on this machine.
**Result:** ❌ for the actual goal — **neither the 8B nor the 14B (both `--reasoning off`) can do
open-ended event-log triage.** Both pass the simple bounded tool tasks and both fail the triage
tasks, either by emitting a malformed query and looping, or by generating thousands of tokens
without ever calling a tool. Thinking (`--reasoning-budget 1024`) is the next lever under test.

## Context

The original smoke tests proved plumbing (the model can answer and can emit a tool call), not
capability. The thing we actually want a local model to do is *read the Windows event logs and flag
errors with likely causes/fixes* — an open-ended, tool-required, multi-step task. So we wrote a
suite that mirrors that and scored it.

Two failure modes were already visible from ad-hoc runs before the suite existed:

1. **Degenerate repetition** — the model hit a real PowerShell gotcha, then re-ran the *identical*
   broken command ~12× while narrating "let's try a different approach".
2. **Analysis paralysis** — long generation with no tool call and no final answer.

The suite makes both measurable (`MaxRepeat`, `ToolCalls`, per-task timeout).

## The suite

`scripts/windows/Invoke-SmokeSuite.ps1` runs each task through the real interface
(`opencode run --model <m> --agent build --auto --format json`), captures the NDJSON event stream,
and reports per task: wall time, steps, tool calls, **distinct** commands, **max repeat**, and the
final text. It is a *measurement harness* (for us), not runtime scaffolding for the model.

| ID | Task | Ground truth (this run) |
|---|---|---|
| T0 | control — reply exactly `pong` | `pong` |
| T1 | Error/Critical in **System+Application**, last 1 h | 6 events: 2× SPP `8198`, 4× DCOM `10010` |
| T2 | find events matching the `slui 0x803F7001` reference, last 12 h | 6× `8198` (Application log) |
| T3 | unclean shutdowns, last 7 d | 1× Event `41`, 1× Event `6008` |
| T4 | free space per fixed drive | `C:` ≈ 856–861 GB (drops as the 14B downloads) |
| T5 | `.gguf` in `llm\models`, largest first | 8B 4.68, 4B 2.33, 14B 1.1 GiB |
| T6 | 5 largest files under `Documents` | all ≈ 0.01 MB |

## Steps

```powershell
# serve a model (launcher stops any existing server, waits for /health)
.\scripts\windows\Start-LocalLLM.ps1 -Model Qwen3-8B-Q4_K_M.gguf -Context 32768 -Kv q8_0 -Hidden

# run the suite (detached is more robust here; the sandbox server restarts kill foreground shells)
.\scripts\windows\Invoke-SmokeSuite.ps1 -Model local/auto -TimeoutSec 150
```

## Output

8B (`Qwen3-8B-Q4_K_M`, ctx 32768, KV q8_0, `--reasoning off`):

| Task | s | Tools | Verdict | What actually happened |
|---|---|---|---|---|
| T0 | 0.7 | 0 | ✅ | `pong.` |
| T1 | 152 | 0 | ❌ | timeout — **no tool call, no answer** |
| T2 | 152 | 2 | ❌ | malformed `Get-WinEvent` (missing `}`), wrong log (`System`) + wrong provider; repeated; timeout |
| T3 | 152 | 0 | ❌ | timeout — **no tool call, no answer** |
| T4 | 130 | 1 | ✅ | `Get-PSDrive`, correct ≈855 GB |
| T5 | 32 | 2 | ✅ | `glob` + `shell`, correct sorted list |
| T6 | 28 | 1 | ⚠️ | no `-Recurse`; listed **directories** as 0 MB files |

**Score: 3 ✅ · 1 ⚠️ · 3 ❌.** The three failures are exactly the event-log/triage tasks.

14B (`Qwen3-14B-Q4_K_M`, ctx 32768, KV q4_0, `--reasoning off`, **9931 MB VRAM**):

| Task | s | Tools | Verdict | What actually happened |
|---|---|---|---|---|
| T0 | 66 | 0 | ✅ | `pong` (66 s = first request after the model swap, cold) |
| T1 | 182 | 0 | ❌ | timeout — no tool call, no answer |
| T2 | 182 | 0 | ❌ | **0 bytes** — never answered (measurement artifact, see Findings) |
| T3 | 23 | 0 | ❌ | **refusal** — "I cannot directly access system logs…" + told the user to open Event Viewer |
| T4 | 38 | 1 | ⚠️ | valid `Get-WmiObject Win32_LogicalDisk` call, but reported **874.3 GB** vs an actual ~854 GiB |
| T5 | 95 | 2 | ✅ | correct sorted list (14B 8.38, 8B 4.68, 4B 2.33) |
| T6 | 24 | 1 | ✅ | `-Recurse`, correct top-5, matches ground truth |

**Score: 3 ✅ · 1 ⚠️ · 3 ❌** — the **same verdicts as the 8B**, only the failure *text* changed.

14B — `--reasoning on --reasoning-budget 1024` (run 1):

| Task | s | Tools | Verdict | What actually happened |
|---|---|---|---|---|
| T0 | 73 | 0 | ✅ | `pong` |
| T1 | 80 | 2 | ⚠️ | queried System+Application but used the **invalid `TimeCreated` filter key** → 0 results; concluded "no events" (true for that window **by luck**) and blamed "lack of administrative privileges" |
| T2 | 221 | 3 | ✅ | correct `StartTime` + `-match '0x803F7001'`; found the **3 exact-code** events (12:21, 11:23, 08:09) |
| T3 | 71 | 1 | ⚠️ | right count (**1** via Event `6008`) but claimed "no Event 41" without ever querying it (one exists) |
| T4 | 302 | 5 | ❌ | **looped on `Get-Volume` variants** — the command is *valid* (verified: returns 2 volumes); it kept rewriting it and never ended |
| T5 | 302 | 1 | ❌ | one tool call, then a long ramble past the timeout |
| T6 | 302 | 0 | ⚠️ invalid | never ran — T5's runaway still held the server slot |

**Score: 2 ✅ · 2 ⚠️ · 2 ❌ · 1 invalid.** Thinking is required to get tool calls on the triage
tasks, but it does **not** produce reliable answers.

## Findings

- **The 8B (reasoning off) cannot do open-ended event-log triage, but is fine on bounded single-tool
  tasks.** It fails T1/T2/T3 and passes T4/T5/T6. `Verified: 2026-10-10`
- **Failure mode A — analysis paralysis:** T1 and T3 produced *only* a `step_start` and then
  generated for the full 150 s with **zero tool calls and no completed text part.**
  `Verified: 2026-10-10`
- **Failure mode B — malformed query + repetition:** T2 emitted
  `Get-WinEvent -FilterHashtable @{LogName='System'; ... ProviderName='Microsoft-Windows-Security-Auditing' | ...}`
  — an **unbalanced `}`**, the wrong log (the SPP events are in **Application**, not `System`), and
  the wrong provider. The same command was re-issued verbatim and the task timed out.
  `Verified: 2026-10-10`
- **The failures are stochastic.** An earlier ad-hoc run of the T4 disk task **looped ~12× on a
  single command** (`[math]::Round($_.FreeSpace/1GB,2) + ' GB'`); in the suite T4 passed with one
  call. Same model, same prompt. `Verified: 2026-10-10`
- **Bigger is not the fix while thinking is off.** 8B→14B changed *how* the triage tasks failed
  (refusal instead of malformed-query loop) but not *whether*. Same score, same failing tasks.
  `Verified: 2026-10-10`
- **The "no answer" tasks are runaway generation, capped by OpenCode — not infinite.** The provider
  sets `limit.output: 8192`; the server's own default is `max_tokens: -1`. A model that never emits
  EOS generates up to 8192 tokens (~136 s at 8B, ~234 s at 14B) — longer than a 150–180 s timeout —
  so the harness kills it mid-ramble and **no text part is ever emitted**. Unbounded only when a
  client omits `max_tokens`. `Verified: 2026-10-10`
- **Measurement artifact (now fixed in the harness):** a killed task can leave the single server slot
  still generating, so the *next* task gets **0 bytes** (this is what T2-on-14B was). `Invoke-SmokeSuite.ps1`
  now waits for `/slots` to report idle between tasks. `Verified: 2026-10-10`
- **`Get-WinEvent` filter keys are unforgiving.** `TimeCreated` is **not** a valid key — it returns
  "no events" even when 22 exist; the correct key is `StartTime`. The 14B used the bogus key, got
  nothing, and blamed "lack of administrative privileges". `Verified: 2026-10-10`
- **The T4 "loop" command is actually valid.** `Get-Volume | Where-Object {$_.DriveType -eq 'Fixed'}`
  returns 2 volumes on this box — the 14B wasn't debugging a real error, it *flailed on a working
  command* (5 near-identical rewrites, one with a syntax slip: commas instead of semicolons in a
  hashtable). `Verified: 2026-10-10`
- **Hallucinated verification:** T3 asserted "no Event 41 was found" after only querying ID `6008` —
  an Event `41` *does* exist in the window. A fabricated "I checked" claim. `Verified: 2026-10-10`
- **Timed ground truths:** "last hour" answers depend on *when* the task runs; the harness previously
  didn't record that, so one of my own ground truths was stale (the 12:21 events aged out of T1's
  window before T1 ran). Harness now records `Started`/`Ended` per task. `Verified: 2026-10-10`
- **Real PowerShell gotcha (the loop's trigger):** `[math]::Round($x,2) + ' GB'` **errors** with
  `Cannot convert value "GB" to type System.Double` — `+` takes the **left** operand's type, so a
  `double` on the left tries to parse `" GB"` as a number. Working idioms:
  `'{0:N2} GB' -f $x`, `'' + $x + ' GB'`, or put the string on the left. The 8B sometimes dodges it
  (T5 used `$_.Name + " - " + ...`, string-first) and sometimes not. `Verified: 2026-10-10`
- **`--format json` + a per-task timeout is a good harness:** it turns "the model felt dumb" into
  countable signals (`ToolCalls`, `MaxRepeat`, `TimedOut`). `Verified: 2026-10-10`
- **Llama.cpp server flag notes:** `--reasoning [on|off|auto]`, `--reasoning-budget N`,
  `--reasoning-effort`, `--reasoning-format` all exist in `b11541`. `Verified: 2026-10-10`

## Follow-ups

- [x] Same suite on **Qwen3-14B-Q4_K_M** (ctx 32768, KV q4_0, reasoning off) — done: same 3 ✅ / 1 ⚠️ / 3 ❌.
- [x] 14B with `--reasoning-budget 1024`, run 1 — done: 2 ✅ / 2 ⚠️ / 2 ❌ / 1 invalid. Repeating (R2 *running*) for variance.
- [ ] 8B with `--reasoning-budget 1024` (isolate thinking from model size).
- [ ] Force turn discipline — test a lower `limit.output`/`max_tokens` so a non-terminating model must end its turn.
- [ ] Try a small MoE (e.g. Qwen3-30B-A3B) with expert offload.
- [ ] Promote the surviving config into `../stack/opencode.md`.
