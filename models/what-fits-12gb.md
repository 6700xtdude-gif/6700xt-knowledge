# What fits in 12 GB — model & quant sizing

**Verified:** 2026-10-10 · `🧪 Untested` (heuristics; confirm with the measured baseline)

12 GB VRAM is the governing constraint for the RX 6700 XT. Everything here is a *starting* estimate;
real numbers depend on context length, KV-cache precision, and the engine.

## Rough VRAM budget (weights only)

`params × bits/8` bytes, plus KV cache + overhead:

| Model size | Q8_0 | Q4_K_M | Fits 12 GB? |
|---|---|---|---|
| 3–4 B | ~4–5 GB | ~2.5–3 GB | ✅ very comfortable |
| 7–8 B | ~8–9 GB | ~4.5–5.5 GB | ✅ at Q4; keep context modest |
| 12–14 B | ~13–15 GB | ~7–8 GB | ⚠️ tight at Q4, low context |
| 27–30 B+ dense | — | ~14 GB (Q4_K_S) | ⚠️ **fits only with hybrid CPU offload** — see measured 27B below |
| MoE (e.g. Qwen3.8-Flash-Next) | — | — | ⚠️ possible via **expert offload** |

## The two levers that change everything

1. **Context length** — KV cache grows with context *and* is paid per layer. `-c 8192` is cheap;
   `-c 32768` can eat several GB.
2. **KV-cache precision** — `--cache-type-k q8_0 --cache-type-v q8_0` roughly halves KV memory vs
   f16, and `q4_0` halves it again for a little more quality loss. This is the single best knob on a
   12 GB card. See [`../stack/llama-cpp.md`](../stack/llama-cpp.md).

## Recommended ladder for this project

| Stage | Model class | Quant | Why |
|---|---|---|---|
| Smoke test | 1–3 B | Q4_K_M / Q8_0 | prove the stack works, fast iteration |
| Main assistant | **3–4 B** | Q4_K_M / Q8_0 | first fine-tune tier; comfortable |
| Daily driver | 7–8 B | Q4_K_M | best quality that still fits |
| Stretch | MoE / 12–14 B | Q4 + offload | only if expert offload works well |

**First fine-tune target: 3–4 B.** QLoRA at that size fits 12 GB with room for a real context.

## Speed expectations (order of magnitude, to be replaced by real numbers)

- 3–4 B Q4: tens of tok/s — interactive.
- 7–8 B Q4: roughly one to two dozen tok/s — usable.
- Anything offloaded to system RAM: expect a large drop.

## Measured on this machine (2026-10-10)

llama.cpp `b11541` **Vulkan**, `-ngl 99` (both Qwen3, Q4_K_M):

| Model | decode | 32K ctx VRAM (q8_0 KV) |
|---|---|---|
| **4B** | ~92–97 t/s | ~6.1 GB total |
| **8B** | ~60–63 t/s | ~7.6 GB total |

- **8B Q4 fully offloads** and peaks at ~7.6 GB at 32K — ~4 GB headroom on 12 GB.
- KV `q4_0` saves **~1.1 GB** vs q8_0 at 32K, for ~3–4% less decode speed.

Full detail: [`../benchmarks/2026-10-10-baseline.md`](../benchmarks/2026-10-10-baseline.md).

### A 27 B on 12 GB — measured, via `--fit` hybrid offload (2026-10-10)

A **Qwen3.8-27B** (`UD-Q4_K_S`, 27.32 B params, **14.30 GB** file) served by Unsloth Studio's bundled
ROCm/HIP llama.cpp `b11539` **does run** — by splitting the model across VRAM *and* system RAM with
`--fit on` (auto-offload). 32,512-token unified context, KV `q8_0`, GQA (`n_head_kv 4`), hybrid
attention+recurrent arch (`qwen35`).

| | |
|---|---:|
| Layers on GPU | **40 / 66** |
| VRAM: weights + KV + state + compute | ≈ **10.3 GB** (of 12.3 GB) |
| System RAM: remainder of weights + state | ≈ **6.1 GB** |
| **Prefill** | **180–250 tok/s** |
| **Decode** | **≈ 4.0 tok/s** (~250 ms/token) |

**Read:** a 27B *can* be made to run on this card, but the CPU-resident 26 layers make decode
**~15× slower** than a fully-offloaded 8B Q4 (63 tok/s). Usable for reading a streaming answer; painful
for long agent turns. `Verified: 2026-10-10`

**Reproduce it locally** (the model is hardlinked into `llm\models`, so it appears in the menu):

```powershell
# the key switch: --fit on picks the GPU/CPU split instead of -ngl 99
.\Start-LocalLLM.ps1 -Model Qwen3.8-27B -Fit -FitCtx 32384 -Kv q8_0 -NoContextShift
# inspect the exact command first, launching nothing:
.\Start-LocalLLM.ps1 -Model Qwen3.8-27B -Fit -FitCtx 32384 -DryRun
```

See [`../scripts/windows/README.md`](../scripts/windows/README.md) (launcher) and
[`../stack/opencode.md`](../stack/opencode.md) (driving it from OpenCode).

**Reproduced standalone** on the local **Vulkan** build: same **40/66** split (`llama-fit-params` →
`-ngl 40`), **9.8 GB VRAM**, **4.65 tok/s** decode, and OpenCode `local/auto` works — including tool calls.
`✅ Verified: 2026-10-10` See [`../log/2026-10-10-local-27b-offload-opencode.md`](../log/2026-10-10-local-27b-offload-opencode.md).

Full detail: [`../log/2026-10-10-unsloth-studio-27b-hybrid-offload.md`](../log/2026-10-10-unsloth-studio-27b-hybrid-offload.md).

## Still to measure

- [ ] 12–14B Q4 at low context (the "tight" tier) — where does it start spilling to CPU?
- [ ] 27B with a smaller quant (Q3_K_XL) — does the whole model land on the GPU, and at what tok/s?
- [ ] Decode *floor*: what fraction of the ~4 tok/s is CPU layers vs PCIe transfer vs the 248K vocab projection?
