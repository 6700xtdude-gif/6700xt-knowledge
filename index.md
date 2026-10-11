# Index — 6700 XT Knowledge Base

Start here. Each topic links to its file and shows when it was last verified.

## Verification dashboard

| File | Topic | Last verified | Confidence |
|---|---|---|---|
| [`hardware/6700xt.md`](hardware/6700xt.md) | Card specs (`gfx1031`, 12 GB) | 2026-10-10 | 📄 |
| [`stack/rocm-windows.md`](stack/rocm-windows.md) | ROCm/HIP on Windows | 2026-07-31 | 📄 |
| [`stack/vulkan.md`](stack/vulkan.md) | Vulkan path | 2026-10-10 | ✅ |
| [`stack/hip.md`](stack/hip.md) | Native HIP, no WSL | 2026-10-10 | ✅ |
| [`stack/llama-cpp.md`](stack/llama-cpp.md) | llama.cpp / `llama serve` | 2026-10-10 | ✅ |
| [`stack/unsloth.md`](stack/unsloth.md) | Unsloth (train + bundled ROCm serving) | 2026-10-10 | ✅ |
| [`stack/lmstudio.md`](stack/lmstudio.md) | LM Studio | 2026-10-10 | ⚠️ |
| [`stack/ollama.md`](stack/ollama.md) | Ollama | 2026-10-10 | ⚠️ |
| [`stack/comfyui.md`](stack/comfyui.md) | ComfyUI (image) | 2026-10-10 | ⚠️ |
| [`stack/strata.md`](stack/strata.md) | Strata inference engine | 2026-10-10 | 📄 |
| [`stack/opencode.md`](stack/opencode.md) | OpenCode → local model (`local/auto`) | 2026-10-10 | ✅ |
| [`benchmarks/2026-10-10-baseline.md`](benchmarks/2026-10-10-baseline.md) | Vulkan baseline: 4B + 8B (measured) | 2026-10-10 | ✅ |
| [`log/2026-10-10-unsloth-studio-27b-hybrid-offload.md`](log/2026-10-10-unsloth-studio-27b-hybrid-offload.md) | **27 B on 12 GB via `--fit` + HIP (measured)** | 2026-10-10 | ✅ |
| [`log/2026-10-10-local-27b-offload-opencode.md`](log/2026-10-10-local-27b-offload-opencode.md) | **27 B reproduced locally (Vulkan) + OpenCode** | 2026-10-10 | ✅ |
| [`models/what-fits-12gb.md`](models/what-fits-12gb.md) | Model/quant sizing | 2026-10-10 | ⚠️ |

## The one-paragraph summary

ROCm does **not** officially support the 6700 XT (`gfx1031`) on Windows — even as of the
2026-07-31 HIP SDK table — so ROCm paths still need `HSA_OVERRIDE_GFX_VERSION=10.3.0`. But you
increasingly don't need ROCm: **Vulkan** (llama.cpp, LM Studio) works out of the box, and engines
like **Strata** ship their own HIP kernels for `gfx1031`. And "unsupported" is a *support-matrix*
statement, not a *capability* one: **Unsloth's bundled ROCm 7.14 llama.cpp build ran on `gfx1031`
here on 2026-10-10 with no WSL and no `HSA_OVERRIDE`** (a 14.3 GB / 27 B model, hybrid-offloaded to
~4 tok/s). Everything else is fast-moving — see the dashboard above and re-verify anything older than
~30 days.

## Open questions / to verify next

- [ ] Does Unsloth Desktop **train** (tiny QLoRA) on `gfx1031`? — *inference is now proven (see the 27B log); training is still open.*
- [ ] Vulkan vs HIP decode tok/s **for the same model** (isolate the backend from model size).
- [ ] Is `HSA_OVERRIDE_GFX_VERSION` still required on ROCm 7.15+ for `gfx1031`, or auto-detected?
- [ ] Does the native Windows HIP `vLLM + ROCm 7.15` recipe actually run here?

## Conventions

- Dates are `YYYY-MM-DD`.
- Confidence tags: ✅ Verified · 📄 Documented · ⚠️ Reported · 🧪 Untested.
- Every non-obvious claim links to an entry in [`sources.md`](sources.md).
