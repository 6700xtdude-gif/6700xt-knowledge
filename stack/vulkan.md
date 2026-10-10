# Vulkan — the no-ROCm path

**Verified:** 2026-10-10 · `⚠️ Reported`

Vulkan is the **lowest-friction way to run inference on a 6700 XT** because it needs only the normal
AMD graphics driver — no ROCm, no `HSA_OVERRIDE_GFX_VERSION`, no WSL. `[S2]`

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
| Decode (tok/s) | good | typically better when it works |
| Flash-attention support | varies | broader |
| Stability on `gfx1031` | ✅ stable | ⚠️ kernel-dependent |

> Rule of thumb: **start on Vulkan to get running today**, then benchmark HIP if you want the last
> 10–30% of throughput. Record both. `🧪 Untested here — benchmark pending`

## Quick check

```powershell
GPU-Z        # or AMD Software: look for Vulkan runtime
vulkaninfo   # if Vulkan SDK installed
```

See [`../recipes/vulkan-fallback.md`](../recipes/vulkan-fallback.md) for the llama.cpp build/run steps.
