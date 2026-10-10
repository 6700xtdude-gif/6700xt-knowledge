# Ollama

**Verified:** 2026-10-10 · `⚠️ Reported`

Ollama is a convenient "it just runs" option and increasingly ships a **Vulkan** path on Windows,
which is relevant because the 6700 XT can use Vulkan without ROCm. `[S7]`

## On the 6700 XT

- Ollama's GPU discovery may or may not enumerate the card depending on backend and driver.
- Vulkan backend support is the interesting path here; where it's active, no ROCm override is needed.
- If it silently falls back to CPU, you'll see it in the server log (`no compatible GPUs found`) and
  in the load-time `... layers` message.

## Trade-off vs standalone llama.cpp

| | Ollama | standalone llama.cpp |
|---|---|---|
| Ease | ✅ very | ⚠️ manual |
| Flag/observability control | ⚠️ limited | ✅ full |
| KV-cache / flash-attn tuning | ⚠️ limited | ✅ full |

Use Ollama for convenience; use llama.cpp when you need to *see and control* the launch. See
[`llama-cpp.md`](llama-cpp.md).

## To verify on this machine

- [ ] Does Ollama enumerate the 6700 XT (GPU vs CPU)? Which backend?
- [ ] `ollama serve` logs — capture the detection lines.
