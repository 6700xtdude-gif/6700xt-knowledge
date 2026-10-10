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

> **Default port:** the long-standing llama-server default is **`8080`**. The current server README
> shows a different default listen address — **verify with `llama serve --help`** on your build
> rather than trusting either number. `🧪 Untested here`

## Flags that matter for observability

The whole point of running standalone is seeing and controlling these:

| Flag | Controls |
|---|---|
| `-c <n>` | **context window** |
| `--cache-type-k q8_0\|q4_0` | **KV-cache K** precision |
| `--cache-type-v q8_0\|q4_0` | **KV-cache V** precision (note: some builds require K set too) |
| `--flash-attn` | flash attention on/off |
| `-ngl <n>` / `--n-gpu-layers` | layers offloaded to GPU |
| `--jinja` | use the model's chat template (important for tool calling) |
| `--no-context-shift` | stop silent context truncation |
| `--verbose` | log what the runtime actually did |

KV cache quantization (`q8_0`, `q4_0`) is how you trade a little quality for a lot of VRAM and
context headroom on a 12 GB card. Test both 8-bit and 4-bit and log the difference.

## Serving to the local stack

- Standalone server → listen on `localhost:<port>`, expose the OpenAI-compatible
  `/v1/chat/completions` endpoint.
- If an upstream tool (like Unsloth) is also injecting its own tools, run llama.cpp with the model's
  own tool-calling **disabled** so the outer agent's tools work. See [`unsloth.md`](unsloth.md).

## References

- Repo + server docs: `[S4]`
- Backend build options (Vulkan/HIP): `[S4]`

## To verify on this machine

- [ ] Which style is present after install (`llama` vs `llama-server.exe`).
- [ ] Actual default port (`--help`).
- [ ] Whether `--cache-type-v q4_0` is accepted without also quantizing K.
