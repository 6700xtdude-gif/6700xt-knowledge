# Strata inference engine

**Verified:** 2026-11-13 · `✅ Verified`

[Strata](https://github.com/Niko1221/Strata) is a one-click local inference engine that targets
consumer hardware and runs large MoE models (notably **Qwen3.6-35B-A3B-UD-Q4_K_XL**) with an OpenAI- **and**
Anthropic-compatible API. `[S9]`

The port depends on how it was started: the desktop app writes a run config and serves on the `port` in it
(`18500` here, `✅ Verified: 2026-11-13` `[S25]`), while the helper `run-qwen36-ud-q4_k_xl.bat` passes
`--port 8080`. Do not assume `8080` when the app started the engine.

> **Update 2026-11-13:** Strata is now **running** on this machine (desktop 0.2.13, engine 0.1.59-windows-x86_64-hip-rdna2 serving Qwen3.6-35B-A3B-UD-Q4_K_XL). See [`log/2026-11-13-strata-verification.md`](../log/2026-11-13-strata-verification.md). Why `--mtp 2` still logged `0 of 0`: [`log/2026-11-13-strata-mtp-sampling.md`](../log/2026-11-13-strata-mtp-sampling.md).

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
- A local OpenAI-compatible API means it can drop into the same stack as llama.cpp. (Port varies; see above.)
- Running Qwen3.6-35B-A3B-UD-Q4_K_XL: ~4.4 GiB VRAM on GPU, ~18.75 GiB pinned host memory, ~540–580 tok/s prompt. `✅ Verified: 2026-11-13`
- Decode is **two numbers, not one**: ~22–28 tok/s for a request that names no sampling, ~42–44 tok/s for a
  strictly greedy one (drafts accepted 74–81 of 96–106). `✅ Verified: 2026-11-13` `[S24]`

## MTP only drafts on a strictly greedy request

The engine is started with `--mtp 2`, the log says `MTP block loaded`, and the warm-up runs "a speculative
step". Every served request that does not name its own sampling still logs `drafts accepted 0 of 0`, because
the server fills in the model card's sampling (`temperature 1.0`, `presence_penalty 1.5`, …) and the q36
engine drafts only when `needs_logits()` is false — that is, `temperature 0`, `repeat 1`, `freq 0`,
`present 0`. `[S22]` `[S23]`

Measured here on `gfx1031`, four interleaved pairs, 128 generated tokens each: `[S24]`

| request | decode | drafts |
|---|---|---|
| no sampling fields | 22.6 / 25.5 / 27.5 / 27.1 tok/s | 0 of 0 |
| `temperature 0, top_p 1.0, presence_penalty 0, frequency_penalty 0, repetition_penalty 1` | 42.2 / 43.6 / 42.4 / 42.8 tok/s | 81/96, 78/102, 78/98, 74/106 |

So MTP is worth roughly **1.7×** decode here, and the default path silently leaves it on the table. This is
tracked upstream as #3354 (open, with an opt-in `STRATA_Q36_MTP_SAMPLED` in #3773); this machine's numbers
were added to that thread on 2026-11-13. It is not specific to this card. `[S22]` `[S23]`

Practical consequence: the ~18–20 tok/s every earlier note quoted was the **no-draft** rate. A client that
wants the faster path must send the four greedy fields explicitly; leaving them out does **not** mean "off".


## `--vram-reserve-mib` is recorded as applied but ignored

The app passes `--vram-reserve-mib 1536` for this run and its run config says `"ui_reserve_applied": 1536`,
so the UI believes a 1.5 GiB reserve is held for the compositor and the vision reader. `[S25]` The q36 engine
drops the flag with `ignoring --vram-reserve-mib 1536 (not an option of this engine)` and never applies it.
`✅ Verified: 2026-11-13` `[S26]`

That is upstream #5023 (open; evidence from this machine added 2026-11-13): the fix asked for is to refuse the
flag before start instead of looking like it was applied. It matters here because the reserve is what keeps the desktop
and `strata-vision` from pushing the engine into an OOM; the engine was still reporting 3.37 GiB free and
served normally, so no crash was seen — but the setting is a no-op. `[S26]`

## Fit with this project

Strata is a candidate **runtime** alongside llama.cpp. The tradeoff is the same as ever:
convenience vs observability. Running **Qwen3.6-35B-A3B-UD-Q4_K_XL** on 12 GB here is a genuinely
valuable data point to record for other 6700 XT owners. `✅ Verified: 2026-11-13`

## To verify on this machine

- [x] Install Strata, run with `--backend hip`, capture whether it validates on `gfx1031`. → **DONE 2026-11-13**: runs on `gfx1031` (engine 0.1.59-windows-x86_64-hip-rdna2).
- [x] Record model, quant, VRAM use, tok/s, and stability over a long session. → **DONE 2026-11-13**: Qwen3.6-35B-A3B-UD-Q4_K_XL, ~540–580 tok/s prompt, 4.4 GiB VRAM, 18.75 GiB pinned host RAM, 6 CPU threads.
- [x] Find out why `--mtp 2` reported `0 of 0` drafts. → **DONE 2026-11-13**: model-card sampling on non-greedy requests; ~26 → ~43 tok/s with strict greedy. See [`../log/2026-11-13-strata-mtp-sampling.md`](../log/2026-11-13-strata-mtp-sampling.md).
- [ ] Confirm the ~43 tok/s greedy rate holds on a long (1–2 K token) generation, not just 128 tokens.
- [ ] Check whether a run-config `sampling` block (the #3354 workaround) makes the app's own chat path greedy.
- [ ] Compare against llama.cpp Vulkan on the same model.
