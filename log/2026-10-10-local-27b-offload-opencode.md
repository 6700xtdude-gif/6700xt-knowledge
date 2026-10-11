# 2026-10-10 — Reproduce the 27B hybrid offload locally + drive it from OpenCode

**Machine:** SANDBOX · Windows 11 Pro · RX 6700 XT `gfx1031` (driver `32.0.21045.5002`) · **no ROCm** (Vulkan path)
· llama.cpp `b11541` **Vulkan** · OpenCode **v2.0.26**
**Goal:** Reproduce [`the Unsloth 27B result`](2026-10-10-unsloth-studio-27b-hybrid-offload.md) **outside** Unsloth
Studio — our own standalone build — and connect OpenCode to it.
**Result:** ✅ works — the local Vulkan build picks the **same 40/66-layer split**, decodes at **4.65 tok/s**, and
OpenCode's `local/auto` returns `pong` and emits valid tool calls.

## Context

The sibling log measured a 14.3 GB / 27 B model on this 12 GB card, but *inside* Unsloth Studio's bundled
**HIP** build. Two open questions:

1. Does our **standalone Vulkan** llama.cpp reproduce it?
2. Can we point **OpenCode** at it with no config surgery?

It also surfaced a launcher gap: `Start-LocalLLM.ps1` hardcoded `-ngl 99` (all layers on GPU), which cannot
serve a model larger than VRAM. That is now fixed with a `-Fit` path.

## Steps

```powershell
# 1. make the 27B discoverable to the launcher (hardlink = zero extra disk, same volume)
New-Item -ItemType HardLink -Path C:\Users\6700XT\llm\models\Qwen3.8-27B-UD-Q4_K_S.gguf `
  -Target C:\Users\6700XT\.cache\huggingface\hub\models--unsloth--Qwen3.8-27B-GGUF\snapshots\4ca720788d1e01f1bff70c033e0d0028fd02e502\Qwen3.8-27B-UD-Q4_K_S.gguf

# 2. predict the GPU/CPU split WITHOUT loading the model
& C:\Users\6700XT\llm\bin\llama-b11541-vulkan\llama-fit-params.exe `
  -m C:\Users\6700XT\llm\models\Qwen3.8-27B-UD-Q4_K_S.gguf `
  -c 32384 -np 1 --fit on --fit-ctx 32384 -fa on -ctk q8_0 -ctv q8_0

# 3. serve it (new -Fit path: omits -ngl, adds --fit on)
C:\Users\6700XT\Documents\6700xt-knowledge\scripts\windows\Start-LocalLLM.cmd -Model Qwen3.8-27B -Fit -FitCtx 32384 -Kv q8_0 -NoContextShift -Hidden

# 4. drive it from OpenCode (no config change)
opencode-cli.exe run --model local/auto "Reply with exactly one word: pong"
```

(Caution: the launcher stops **any** process named `llama-server` — including Studio's. Stop the Studio model
first; two 27Bs do not fit in 12 GB.)

## Output

`llama-fit-params.exe` printed the fitted args — **the same split as the HIP run**:

```
-c 32384 -ngl 40
```

Launcher:

```
model      : Qwen3.8-27B-UD-Q4_K_S.gguf   (14.30 GiB)
runtime    : C:\Users\6700XT\llm\bin\llama-b11541-vulkan
offload    : --fit on (ctx >= 32384)   KV: q8_0   parallel: 1
Ready in ~12s  (PID 15704)   endpoint http://127.0.0.1:9931/v1
```

Measured:

| Metric | Unsloth HIP (sibling log) | Local Vulkan (this run) |
|---|---|---|
| GPU layer split | 40 / 66 | **40 / 66** (`-ngl 40`) |
| VRAM held | ~10.3 GB | **9,780.9 MB dedicated** + 1,479.7 MB shared |
| Context | 32,512 | 32,768 |
| **Decode** | ~4.0 tok/s | **4.65 tok/s** (215 ms/token) |

OpenCode round-trip:

```
> build · auto
pong
```

Tool calling (direct API, `--jinja`): `finish_reason: tool_calls`, function `shell`, valid JSON args, decode 4.30 tok/s.

## Findings

- **The local Vulkan build reproduces the HIP split exactly — `-ngl 40` of 66 layers.**
  `llama-fit-params.exe` predicts it without loading the model. `✅ Verified: 2026-10-10`
- **Decode 4.65 tok/s (Vulkan) ≥ ~4.0 tok/s (HIP).** For a bandwidth/PCIe-bound hybrid split, the backend is
  not the bottleneck. `✅ Verified: 2026-10-10`
- **OpenCode needs no config change.** Its `local` provider already targets `http://127.0.0.1:9931/v1`, and
  llama.cpp ignores the request `model` id, so `local/auto` serves the 27B. `✅ Verified: 2026-10-10`
- **The 27B drives OpenCode's tools.** `--jinja` yielded `finish_reason: tool_calls` with correct JSON
  arguments. `✅ Verified: 2026-10-10`
- **`llama-fit-params.exe` is a cheap pre-flight** for `--fit` — no weights loaded, prints the chosen `-ngl`
  and `-c`. `✅ Verified: 2026-10-10`
- **The launcher gained `-Fit` / `-FitCtx` / `-NoContextShift` / `-DryRun`.** `-DryRun` prints the exact
  command and touches nothing. `✅ Verified: 2026-10-10`
- **Prefill on short prompts is not comparable** to the 180–250 tok/s seen under HIP (that was on 8 K-token
  prompts); this run's prompts were tiny, so no prefill number is claimed. `🧪`

## Follow-ups

- [ ] Time a real OpenCode **multi-step** task on the 27B at 4.65 tok/s (how long is a tool loop?).
- [ ] Cold vs warm model load time (this was ~12 s warm cache).
- [ ] Same model under the Unsloth HIP binary via `-LlamaDir` for a like-for-like backend A/B.
