# Vulkan — the no-ROCm path

**Verified:** 2026-10-10 · `⚠️ Reported`

Vulkan is the **lowest-friction way to run inference on a 6700 XT** because it needs only the normal
AMD graphics driver — no ROCm, no `HSA_OVERRIDE_GFX_VERSION`, no WSL. `[S2]`

**Confirmed on this machine** with llama.cpp Vulkan build `b11541`:

```
$ llama-cli.exe --list-devices
Available devices:
  Vulkan0: AMD Radeon RX 6700 XT (12272 MiB, 11474 MiB free)
```

The card is detected over Vulkan with no ROCm installed, and it reports its true **~12 GB**
(12272 MiB). `✅ Verified: 2026-10-10`

Device capabilities reported by the Vulkan backend:

```
ggml_vulkan: 0 = AMD Radeon RX 6700 XT (AMD proprietary driver)
  | uma: 0 | fp16: 1 | bf16: 0 | fp4: 0 | warp size: 32 | matrix cores: none
```

Notes: **fp16 supported, bf16 not**; **Wave32**; **no matrix cores** (no WMMA) — this is why RDNA 2
without ROCm/composable-kernel paths leans on classic SIMD rather than tensor tiles. `✅ Verified: 2026-10-10`

## Who uses Vulkan on this card

- **llama.cpp** — builds with `-DGGML_VULKAN=ON`; widely used on RDNA 2.
- **LM Studio** — community reports show it frequently selecting the **Vulkan** engine on the
  6700 XT rather than ROCm. `⚠️ Reported`
- **Ollama** — has a Vulkan backend path on Windows.

## When to choose Vulkan vs HIP

| | Vulkan | HIP/ROCm |
|---|---|---|
| Setup friction | ✅ none beyond the driver | ⚠️ override / bundled runtime |
| Prompt processing (prefill) | decent | often faster |
| Decode (tok/s) | **22.61 t/s (27B IQ2_M)** · **16.78 t/s (35B MoE)** `[S29]` | typically better when kernels exist |
| Flash-attention support | ✅ Verified (`-fa on`, 64k context) | broader |
| Speculative decoding | ✅ Native MTP (`--spec-type draft-mtp`) | engine-dependent |
| Stability on `gfx1031` | ✅ 100% rock solid across builds | ⚠️ kernel-dependent |

> **Update (2026-11-14):** On modern `llama-server` (build 12374+ Vulkan), Vulkan fully supports **FlashAttention** (`-fa on`) and **Native Multi-Token Prediction (MTP) Speculation** (`--spec-type draft-mtp --spec-draft-n-max 2`).  
> Testing on RX 6700 XT 12 GB demonstrated:
> - **100% VRAM 27B (`Qwen3.8-27B-IQ2_M`):** **`22.61 tokens/sec`** steady state decode.
> - **Sparse MoE (`Qwen3.6-35B-A3B UD-Q4_K_XL`):** **`16.78 tokens/sec`** hybrid decode (16 layers VRAM, 25 in DDR4, 115 ms TTFT).
> `✅ Verified: 2026-11-14` `[S27]` `[S29]`. See [`../benchmarks/2026-11-14-afterburner-matrix.md`](../benchmarks/2026-11-14-afterburner-matrix.md).

## Quick check

```powershell
GPU-Z        # or AMD Software: look for Vulkan runtime
vulkaninfo   # if Vulkan SDK installed
```

See [`../recipes/vulkan-fallback.md`](../recipes/vulkan-fallback.md) for the llama.cpp build/run steps.
