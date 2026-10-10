# Recipe — llama.cpp with the Vulkan backend

**Verified:** 2026-10-10 · `🧪 Untested` (steps are the standard llama.cpp Vulkan build; confirm locally)

## Build (if building from source)

```powershell
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
cmake -B build -DGGML_VULKAN=ON
cmake --build build --config Release
```

Or download a **prebuilt Vulkan release** for Windows from the releases page. `[S4]`

## Run a model

```powershell
# unified binary style
.\llama serve -m .\models\Qwen3-4B-Q4_K_M.gguf `
  -c 8192 `
  --cache-type-k q8_0 --cache-type-v q8_0 `
  --flash-attn `
  -ngl 999 `
  --jinja --no-context-shift --verbose
```

```powershell
# classic style (if that's what you have)
.\llama-server.exe -m .\models\Qwen3-4B-Q4_K_M.gguf `
  -c 8192 --cache-type-k q8_0 --cache-type-v q8_0 --flash-attn -ngl 999 --jinja
```

> **Port:** verify the default with `--help`; the long-standing default was `8080`.
> `🧪 Untested here`

## What to watch in the log

- GPU detection / Vulkan device name.
- Which layers were offloaded (`-ngl`).
- Prompt-eval and decode tok/s at the end of a request.
- Whether `--cache-type-v q4_0` is accepted standalone.

## Then

- Fill in [`../benchmarks/2026-10-10-baseline.md`](../benchmarks/2026-10-10-baseline.md).
- Compare with a HIP run once [`hip-override.md`](hip-override.md) is verified.
