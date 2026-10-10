# Sources

Every non-obvious claim in this KB points to a row here. Format:
`[S#] | URL | type | retrieved | supports`.

Types: `primary` (vendor/maintainer), `repo`, `news`, `forum`.

| ID | URL | Type | Retrieved | Supports |
|---|---|---|---|---|
| S1 | https://rocm.docs.amd.com/projects/install-on-windows/en/latest/reference/system-requirements.html | primary | 2026-07-31 | RX 6700 XT (`gfx1031`) **not** in the supported ROCm/HIP table (Runtime ❌ / HIP SDK ❌); RDNA 3/4 supported |
| S2 | https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md | repo | 2026-10-10 | llama.cpp backends incl. Vulkan (and HIP) build options |
| S3 | Community forum thread (native Windows ROCm 7.15 + vLLM, RX 6000, no WSL) | forum | 2026-10-10 | Reported ~62 tok/s decode; ROCm 7.14 needs Adrenalin 26.6.4+; **exact URL to be captured on next visit** |
| S4 | https://github.com/ggml-org/llama.cpp | repo | 2026-10-10 | Server docs, flags (`-c`, `--cache-type-k/-v`, `--flash-attn`, `-ngl`, `--jinja`); unified `llama` binary vs `llama-server.exe` (discussion #23875) |
| S5 | https://docs.unsloth.ai/ (and Unsloth Desktop / Studio) | primary | 2026-10-10 | RDNA 2 / `gfx1031` "Full" support on Windows; auto-installs ROCm; Tauri + uv; `sk-unsloth-` keys; OpenAI + Anthropic APIs; `--disable-tools`; OpenCode integration; base URL `http://localhost:8888/v1/` |
| S6 | https://lmstudio.ai/ | primary | 2026-10-10 | Multi-runtime (Vulkan vs ROCm/HIP); backend selection visible |
| S7 | https://ollama.com/ | primary | 2026-10-10 | Ollama Windows install; Vulkan path |
| S8 | https://blog.comfy.org/ (ComfyUI AMD ROCm on Windows, Desktop v0.7.0+) | primary/news | 2026-10-10 | Official Windows ROCm support; 6700 XT not in officially supported set |
| S9 | https://github.com/Niko1221/Strata · https://github.com/Niko1221/Strata/blob/main/docs/OLDER_GPUS.md | repo | 2026-10-10 | RX 6700 XT experimental HIP path `--backend hip`, "unvalidated" (#524); API on `127.0.0.1:8080`; MoE expert offload |
| S10 | Microsoft WSL / Windows Blogs (WSL open source; WSL containers GA ~2026-09-29) | primary/news | 2026-10-10 | WSL open source; `wslc.exe`/`container.exe`; containerization push; **exact URL to be captured** |
| S11 | https://opencode.ai/v2/docs/ (config, providers, models, migrate-v1) | primary | 2026-10-10 | OpenCode **V2** uses `providers` + `package` + `settings`; model shape `capabilities`/`limit`; auto-discovers Ollama/LM Studio/vLLM only; `opencode.jsonc` at `~/.config/opencode/` |

## Housekeeping

- `[S3]` and `[S10]` need their exact URLs filled in the next time we are online. Marked inline.
- Add one row per new claim source. Prefer `primary`/`repo` over `forum`.
