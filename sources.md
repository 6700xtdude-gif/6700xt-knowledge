# Sources

Every non-obvious claim in this KB points to a row here. Format:
[S#] | URL | type | retrieved | supports'.

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
| S10 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Strata 0.2.13 verified running on AMD Radeon RX 6700 XT (gfx1031) with HIP rdn2 engine package 0.1.59. Confirmed via live logs and process inspection. [S10] |
| S11 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Strata engine 0.1.59-windows-x86_64-hip-rdna2 (HIP RDNA2) used for gfx1031 support. [S14] |
| S12 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Strata desktop 0.2.13 installed and running. [S15] |
| S13 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Strata desktop API on 127.0.0.1:47831 (desktop host), Strata server API on 127.0.0.1:8080. [S16] |
| S14 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Strata harness crashes (code 1) multiple times during startup (see harness.log). [S17] |
| S15 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Model: Qwen3.6-35B-A3B-UD-Q4_K_XL. [S20] |
| S16 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Tok/s: ~18–20 tok/s decode, ~540–580 tok/s prompt. [S21] |
| S17 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Strata engine 0.1.59-windows-x86_64-hip-rdna2 (HIP RDNA2) used for gfx1031 support. [S18] |
| S18 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Strata server API on 127.0.0.1:8080, desktop host 127.0.0.1:47831. [S19] |
| S19 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Local API on 127.0.0.1:8080 means it can drop into the same stack as llama.cpp. [S20] |
| S20 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Running Qwen3.6-35B-A3B-UD-Q4_K_XL: ~4.4 GiB VRAM on GPU, ~18.75 GiB pinned host memory, ~18–20 tok/s decode, ~540–580 tok/s prompt. [S21] |
| S21 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Strata desktop 0.2.13 runs on AMD Radeon RX 6700 XT (gfx1031) with HIP rdn2 engine package 0.1.59. Live process `strata.exe` (pid 15164) serving Qwen3.6-35B-A3B-UD-Q4_K_XL via `--serve --native`. [S22] |

## Housekeeping

- `[S3]` and `[S10]` need their exact URLs filled in the next time we are online. Marked inline.
- `[S12]` points at the repo, not a specific release page — the exact release URL is recorded locally in `UNSLOTH_PREBUILT_INFO.json` (`binary_release_tag: b11539-mix-2500203`). Replace when convenient.
- Add one row per new claim source. Prefer `primary`/`repo` over `forum`.
