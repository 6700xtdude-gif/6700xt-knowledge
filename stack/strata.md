# Strata inference engine

**Verified:** 2026-11-13 · `✅ Verified`

[Strata](https://github.com/Niko1221/Strata) is a one-click local inference engine that targets
consumer hardware and runs large MoE models (notably **Qwen3.6-35B-A3B-UD-Q4_K_XL**) with an OpenAI- **and**
Anthropic-compatible API on **`127.0.0.1:8080`**. `[S9]`

> **Update 2026-11-13:** Strata is now **running** on this machine (desktop 0.2.13, engine 0.1.59-windows-x86_64-hip-rdna2 serving Qwen3.6-35B-A3B-UD-Q4_K_XL). See [`log/2026-11-13-strata-verification.md`](log/2026-11-13-strata-verification.md).

## The 6700 XT story

- Strata maintains an explicit **`docs/OLDER_GPUS.md`** for older cards.
- That doc **listed** the **RX 6700 XT** on its **experimental HIP path**, invoked with
  **`--backend hip`**, described as **"unvalidated"** (issue **#524**). `[S9]`
- We have now **validated** it: it runs on `gfx1031` here. `[S9]`

> "Unvalidated" is Strata's word: the maintainers **do not own this card**, and (as of the doc) had a
> single daily reporter using it. Treat successes as fragile. `✅ Verified` `[S9]` → updated 2026-11-13

## Why it's interesting anyway

- It has a **one-click Windows/Linux installer** (no manual ROCm dance).
- It does **MoE expert offload** — routing only the active experts onto the GPU — which is how a
  small-VRAM card can run a much larger model. This is the same class of trick that let an earlier
  **1-bit Qwen Coder** run here "successfully but uselessly." `⚠️ Reported` (prior local attempt)
- Local API on `127.0.0.1:8080` means it can drop into the same stack as llama.cpp.
- Running Qwen3.6-35B-A3B-UD-Q4_K_XL: ~4.4 GiB VRAM on GPU, ~18.75 GiB pinned host memory, ~18–20 tok/s decode, ~540–580 tok/s prompt. `✅ Verified: 2026-11-13`

## Fit with this project

Strata is a candidate **runtime** alongside llama.cpp. The tradeoff is the same as ever:
convenience vs observability. Running **Qwen3.6-35B-A3B-UD-Q4_K_XL** on 12 GB here is a genuinely
valuable data point to record for other 6700 XT owners. `✅ Verified: 2026-11-13`

## To verify on this machine

- [x] Install Strata, run with `--backend hip`, capture whether it validates on `gfx1031`. → **DONE 2026-11-13**: runs on `gfx1031` (engine 0.1.59-windows-x86_64-hip-rdna2).
- [x] Record model, quant, VRAM use, tok/s, and stability over a long session. → **DONE 2026-11-13**: Qwen3.6-35B-A3B-UD-Q4_K_XL, ~18–20 tok/s decode, ~540–580 tok/s prompt, 4.4 GiB VRAM, 18.75 GiB pinned host RAM, 6 CPU threads.
- [ ] Compare against llama.cpp Vulkan on the same model.
