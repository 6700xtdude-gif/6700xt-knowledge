# llama.cpp — and the `llama serve` vs `llama-server.exe` question

**Verified:** 2026-10-10 · `📄 Documented`

llama.cpp is the observable, controllable runtime this project prefers over vendor black boxes.
On the 6700 XT, build or download it with a **Vulkan** backend; a **HIP/ROCm** backend is possible
but carries the usual `gfx1031` caveats. `[S4]`

## Two launch styles exist (this trips people up)

The project is migrating from one-binary-per-tool toward a **single unified binary** (`llama`,
formerly/alongside `llama.app`) with **subcommands** — e.g. `llama serve`. `[S4]`

| Style | Invocation | Notes |
|---|---|---|
| **Unified** (new) | `llama serve -m model.gguf ...` | subcommand form; the direction of travel |
| **Classic** (still shipped) | `llama-server.exe -m model.gguf ...` | still present and valid |

Both currently exist. Don't assume docs from 2024 describe what you have. Check `--help`.

Confirmed on this machine with build **`b11541`** (version `0.6.0-dev`, commit `f2918cabb`,
Clang 20.1.8, Windows x86_64): the unified binary ships and exposes subcommands
`serve`, `cli`, `download`, `version`, `licenses`, `help`, **and** classic `llama-server.exe` is
still present. `✅ Verified: 2026-10-10`

> **Default port: `9931`.** Confirmed via `llama-server.exe --help` on build `b11541` — the old
> `8080` default is gone here. `✅ Verified: 2026-10-10`

## Flags that matter for observability

The whole point of running standalone is seeing and controlling these:

| Flag | Controls |
|---|---|
| `-c <n>` | **context window** |
| `--cache-type-k q8_0\|q4_0` | **KV-cache K** precision |
| `--cache-type-v q8_0\|q4_0` | **KV-cache V** precision (note: some builds require K set too) |
| `--flash-attn` | flash attention on/off |
| `-ngl <n>` / `--n-gpu-layers` | layers offloaded to GPU |
| `--fit on\|off` | **auto-fit to device memory** — picks the GPU layer count for you (`--fit-ctx <n>` caps the context it may pick). Essential for models larger than VRAM. |
| `--jinja` | use the model's chat template (important for tool calling) |
| `--no-context-shift` | stop silent context truncation |
| `--verbose` | log what the runtime actually did |

KV cache quantization (`q8_0`, `q4_0`) is how you trade a little quality for a lot of VRAM and
context headroom on a 12 GB card. Test both 8-bit and 4-bit and log the difference.

## `--fit` — serving a model larger than VRAM

`--fit on` (with an optional `--fit-ctx <n>` ceiling) makes llama.cpp **measure free device memory at
load and choose the GPU layer count itself**, keeping the remainder of the weights in system RAM. It
prints the whole decision at `--verbosity 4`, e.g. on this box:

```
projected to use 15717 MiB of device memory vs. 11508 MiB of free device memory
cannot meet free memory target of 1024 MiB, need to reduce device memory by 5232 MiB
  - ROCm0 (AMD Radeon RX 6700 XT): 40 layers, 10274 MiB used, 1234 MiB free
load_tensors: offloaded 40/66 layers to GPU
```

Result: a **14.3 GB / 27 B** GGUF runs on 12 GB (≈10.3 GB VRAM + ≈6.1 GB RAM) at **~4 tok/s** decode.
This is the modern replacement for hand-tuning `-ngl`. `✅ Verified: 2026-10-10` — see
[`../log/2026-10-10-unsloth-studio-27b-hybrid-offload.md`](../log/2026-10-10-unsloth-studio-27b-hybrid-offload.md).

> **Unsloth's "mix" build is modular.** `llama-server.exe` is a ~25 KB shim; the code lives in
> `llama-server-impl.dll` / `llama-common.dll`, and `llama-fit-params-impl.dll` implements `--fit`.
> Don't be fooled by the tiny `.exe` size. `✅ Verified: 2026-10-10`

## Serving to the local stack

- Standalone server → listen on `localhost:<port>`, expose the OpenAI-compatible
  `/v1/chat/completions` endpoint.
- If an upstream tool (like Unsloth) is also injecting its own tools, run llama.cpp with the model's
  own tool-calling **disabled** so the outer agent's tools work. See [`unsloth.md`](unsloth.md).

## OpenAI endpoint quirks (verified here)

- **The request `model` field is ignored.** Sending `model: "totally-bogus-model-xyz"` still returned
  the loaded model and a correct completion. This is what lets one static OpenCode provider serve
  *any* loaded GGUF — see [`opencode.md`](opencode.md). `✅ Verified: 2026-10-10`
- **`--jinja` enables OpenAI tool calls** (`finish_reason: tool_calls` with correct JSON arguments).
  `✅ Verified: 2026-10-10`
- **Thinking models need corralling.** Qwen3 spent 135–205 tokens reasoning about trivial prompts;
  `--reasoning off` cut that to 2 (`--reasoning-budget 0` to 5) while keeping tool calls.
  `✅ Verified: 2026-10-10`

## References

- Repo + server docs: `[S4]`
- Backend build options (Vulkan/HIP): `[S4]`
- Driving it from OpenCode: [`opencode.md`](opencode.md)

## To verify on this machine

- [x] Which style is present after install (`llama` vs `llama-server.exe`). — **Both**, build `b11541`.
- [x] Actual default port (`--help`). — **`9931`**.
- [ ] Whether `--cache-type-v q4_0` is accepted without also quantizing K.
