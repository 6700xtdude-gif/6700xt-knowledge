# Index — 6700 XT Knowledge Base

Start here. Each topic links to its file and shows when it was last verified.

## Verification dashboard

| File | Topic | Last verified | Confidence |
|---|---|---|---|
| [`hardware/6700xt.md`](hardware/6700xt.md) | Card specs (`gfx1031`, 12 GB) | 2026-10-10 | 📄 |
| [`stack/rocm-windows.md`](stack/rocm-windows.md) | ROCm/HIP on Windows | 2026-07-31 | 📄 |
| [`stack/vulkan.md`](stack/vulkan.md) | Vulkan path | 2026-10-10 | ⚠️ |
| [`stack/hip.md`](stack/hip.md) | Native HIP, no WSL | 2026-10-10 | ⚠️ |
| [`stack/llama-cpp.md`](stack/llama-cpp.md) | llama.cpp / `llama serve` | 2026-10-10 | 📄 |
| [`stack/unsloth.md`](stack/unsloth.md) | Unsloth training | 2026-10-10 | 📄 |
| [`stack/lmstudio.md`](stack/lmstudio.md) | LM Studio | 2026-10-10 | ⚠️ |
| [`stack/ollama.md`](stack/ollama.md) | Ollama | 2026-10-10 | ⚠️ |
| [`stack/comfyui.md`](stack/comfyui.md) | ComfyUI (image) | 2026-10-10 | ⚠️ |
| [`stack/strata.md`](stack/strata.md) | Strata inference engine | 2026-10-10 | 📄 |
| [`models/what-fits-12gb.md`](models/what-fits-12gb.md) | Model/quant sizing | 2026-10-10 | 🧪 |

## The one-paragraph summary

ROCm does **not** officially support the 6700 XT (`gfx1031`) on Windows — even as of the
2026-07-31 HIP SDK table — so ROCm paths still need `HSA_OVERRIDE_GFX_VERSION=10.3.0`. But you
increasingly don't need ROCm: **Vulkan** (llama.cpp, LM Studio) works out of the box, and engines
like **Strata** ship their own HIP kernels for `gfx1031`. Everything else is fast-moving — see the
dashboard above and re-verify anything older than ~30 days.

## Open questions / to verify next

- [ ] Does Unsloth Desktop actually detect and train on `gfx1031` on *this* machine?
- [ ] Vulkan vs HIP decode tok/s for a 7-8B Q4 model (measure and record).
- [ ] Is `HSA_OVERRIDE_GFX_VERSION` still required on ROCm 7.15+ for `gfx1031`, or auto-detected?
- [ ] Does the native Windows HIP `vLLM + ROCm 7.15` recipe actually run here?

## Conventions

- Dates are `YYYY-MM-DD`.
- Confidence tags: ✅ Verified · 📄 Documented · ⚠️ Reported · 🧪 Untested.
- Every non-obvious claim links to an entry in [`sources.md`](sources.md).
