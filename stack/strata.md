# Strata inference engine

**Verified:** 2026-10-10 · `📄 Documented`

[Strata](https://github.com/Niko1221/Strata) is a one-click local inference engine that targets
consumer hardware and runs large MoE models (notably **Qwen3.8-Flash-Next**) with an OpenAI- **and**
Anthropic-compatible API on **`127.0.0.1:8080`**. `[S9]`

## The 6700 XT story

- Strata maintains an explicit **`docs/OLDER_GPUS.md`** for older cards.
- That doc lists the **RX 6700 XT** on its **experimental HIP path**, invoked with
  **`--backend hip`**, described as **"unvalidated"** (issue **#524**). `[S9]`

> "Unvalidated" is Strata's word: the maintainers **do not own this card**, and (as of the doc) had a
> single daily reporter using it. Treat successes as fragile. `📄 Documented` `[S9]`

## Why it's interesting anyway

- It has a **one-click Windows/Linux installer** (no manual ROCm dance).
- It does **MoE expert offload** — routing only the active experts onto the GPU — which is how a
  small-VRAM card can run a much larger model. This is the same class of trick that let an earlier
  **1-bit Qwen Coder** run here "successfully but uselessly." `⚠️ Reported` (prior local attempt)
- Local API on `127.0.0.1:8080` means it can drop into the same stack as llama.cpp.

## Fit with this project

Strata is a candidate **runtime** alongside llama.cpp. The tradeoff is the same as ever:
convenience vs observability. If it runs Qwen3.8-Flash-Next on 12 GB here, that is a genuinely
valuable data point to record for other 6700 XT owners. `🧪 Untested here`

## To verify on this machine

- [ ] Install Strata, run with `--backend hip`, capture whether it validates on `gfx1031`.
- [ ] Record model, quant, VRAM use, tok/s, and stability over a long session.
- [ ] Compare against llama.cpp Vulkan on the same model.
