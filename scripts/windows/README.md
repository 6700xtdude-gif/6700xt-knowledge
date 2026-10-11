# Local LLM launcher scripts (Windows)

Manually fire up a local model on the **RX 6700 XT** (llama.cpp / Vulkan) and have **OpenCode**
connect to it — without ever editing OpenCode config again.

## How it works

- `llama-server.exe` serves **one** model on `http://127.0.0.1:9931` and **ignores the `model` field**
  in OpenAI-compatible requests. So OpenCode can use a single static provider (`local/auto`) that
  works for *whichever* GGUF you have loaded.
- You switch models by re-running `Start-LocalLLM.ps1`, not by touching
  `~/.config/opencode/opencode.jsonc`.

## Files

| File | Purpose |
|---|---|
| `Start-LocalLLM.ps1` | Interactive menu of `C:\Users\6700XT\llm\models\*.gguf`; launches one and waits for `/health`. |
| `Stop-LocalLLM.ps1` | Stops llama-server. |
| `Status-LocalLLM.ps1` | Shows the loaded model, context, quant, and endpoint. |
| `Start-LocalLLM.cmd` / `Stop-LocalLLM.cmd` | Double-click wrappers (use these for pinned shortcuts). |
| `Invoke-SmokeSuite.ps1` | Measurement harness: runs realistic, tool-required tasks through OpenCode and scores the model (see [Smoke suite](#smoke-suite--does-the-model-actually-work-as-an-agent)). |

## Everyday use

```powershell
# Menu (pick by number)
.\Start-LocalLLM.ps1

# Straight to a model (any unique part of the filename)
.\Start-LocalLLM.ps1 -Model Qwen3-8B

# Tighter VRAM if you need headroom
.\Start-LocalLLM.ps1 -Model Qwen3-8B -Context 16384 -Kv q4_0

# A model BIGGER than VRAM (hybrid GPU+CPU via --fit)
.\Start-LocalLLM.ps1 -Model Qwen3.8-27B -Fit -FitCtx 32384 -Kv q8_0

# Show the exact llama-server command without launching anything
.\Start-LocalLLM.ps1 -Model Qwen3.8-27B -Fit -FitCtx 32384 -DryRun

.\Status-LocalLLM.ps1
.\Stop-LocalLLM.ps1
```

Then in OpenCode: `/models` → **Local llama.cpp (RX 6700 XT)** → **Local model (auto)** (`local/auto`),
or from the CLI:

```powershell
opencode run --model local/auto "your prompt"
```

## Defaults chosen for the 12 GB card

| Flag | Value | Why |
|---|---|---|
| `-ngl 99` | all layers on GPU | 8B Q4 fits comfortably |
| `-c 32768` | 32K context | ~7.6 GB total at KV `q8_0`, ~4 GB free |
| `-ctk/-ctv q8_0` | 8-bit KV cache | small quality cost, big VRAM saving |
| `-fa on` | flash attention | enable; neutral for speed here |
| `--jinja` | model's chat template | required for OpenAI tool calls |
| `--reasoning off` | no thinking | Qwen3 otherwise spends hundreds of tokens thinking |

Pass `-Hidden` to suppress the server console, or `-NoStop` to leave an existing server running.

> Runtime folder is auto-detected: the newest `C:\Users\6700XT\llm\bin\llama-*` containing
> `llama-server.exe`. Override with `-LlamaDir <folder>`.

## Serving a model LARGER than 12 GB — `-Fit`

`-ngl 99` asks for **all** layers on the GPU. That is fine for a fully-offloadable model and fatal
for a 14 GB one. For a model bigger than VRAM, pass **`-Fit`**: the launcher omits `-ngl` (default
`auto`) and adds `--fit on`, so llama.cpp **measures free VRAM at load and picks the GPU layer
split**, keeping the rest in system RAM. `✅ Verified: 2026-10-10`

```powershell
# a 14.3 GB / 27B GGUF on a 12 GB card -> hybrid GPU+CPU
.\Start-LocalLLM.ps1 -Model Qwen3.8-27B -Fit -FitCtx 32384 -Kv q8_0 -NoContextShift
```

Which resolves to (check it yourself with `-DryRun`):

```
llama-server.exe -m ...\Qwen3.8-27B-UD-Q4_K_S.gguf -c 32768 -np 1 --jinja `
  --host 127.0.0.1 --port 9931 --fit on --fit-ctx 32384 --no-context-shift `
  -fa on -ctk q8_0 -ctv q8_0 --reasoning off
```

Measured here: **40/66 layers on GPU**, ≈10.3 GB VRAM + ≈6.1 GB RAM, **≈4 tok/s** decode,
180–250 tok/s prefill. Details:
[`../../log/2026-10-10-unsloth-studio-27b-hybrid-offload.md`](../../log/2026-10-10-unsloth-studio-27b-hybrid-offload.md).

### Switches

| Switch | Effect |
|---|---|
| `-Fit` | omit `-ngl`, add `--fit on` (auto GPU/CPU split for models > VRAM) |
| `-FitCtx N` | with `-Fit`, the **minimum** context `--fit` may settle on (llama.cpp floor 4096) |
| `-NoContextShift` | add `--no-context-shift` (never silently truncate context) |
| `-DryRun` | print the exact command and exit — **no** stop, **no** launch |
| `-NoStop` | don't kill an existing `llama-server` first |
| `-LlamaDir <dir>` | use a specific llama.cpp build (e.g. Unsloth's HIP build — see below) |

> ⚠️ **The launcher stops *any* process named `llama-server`** before starting — including one
> **Unsloth Studio** launched. And two 27B models do not fit in 12 GB, so don't run the standalone
> 27B while Studio is serving one. Close the Studio model first (or accept that `-Fit` run will stop
> it). Use `-DryRun` to inspect without stopping anything.

### Faithful-to-Unsloth variant

Studio served this exact model with its bundled **ROCm/HIP** llama.cpp build. To reuse *that* binary
instead of the local Vulkan build:

```powershell
.\Start-LocalLLM.ps1 -Model Qwen3.8-27B -Fit -FitCtx 32384 -Kv q8_0 `
  -LlamaDir "C:\Users\6700XT\.unsloth\llama.cpp\build\bin\Release"
```

## Smoke suite — does the model actually work as an agent?

`Invoke-SmokeSuite.ps1` drives a *served* model through **real, tool-required tasks** via
`opencode run --model <m> --agent build --auto --format json`, then reports per task: wall time,
steps, tool calls, **distinct** commands, **max repeat**, and the final text. Scoring is manual —
it is a *measurement harness*, not runtime scaffolding for the model.

```powershell
# serve something first (the launcher waits for /health)
.\Start-LocalLLM.ps1 -Model Qwen3-8B -Context 32768 -Kv q8_0 -Hidden

# all tasks, or a subset
.\Invoke-SmokeSuite.ps1 -Model local/auto
.\Invoke-SmokeSuite.ps1 -Model local/auto -Only T1,T4 -TimeoutSec 180
```

Results land in `%USERPROFILE%\llm\smoke\<timestamp>-<model>\` (`*.jsonl`, `summary.csv`,
`summary.json`). Between tasks it waits for the single llama.cpp slot to go idle, so a killed
runaway generation cannot poison the next task. For a worked run and the failure taxonomy
(analysis-paralysis, malformed-query loops, hallucinated verification), see
[`../../log/2026-10-10-agentic-smoke-suite.md`](../../log/2026-10-10-agentic-smoke-suite.md).
