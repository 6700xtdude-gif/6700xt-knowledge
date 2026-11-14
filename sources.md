# Sources

Every non-obvious claim in this KB points to a row here. Format:
[S#] | URL | type | retrieved | supports'.

Types: `primary` (vendor/maintainer), `repo`, `news`, `forum`. Local artifacts on this machine
(engine logs, run configs) are `primary`: they are the first-party record of what actually ran.

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
| S10 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Strata 0.2.13 verified running on AMD Radeon RX 6700 XT (gfx1031) with HIP rdn2 engine package 0.1.59; confirmed via live logs and process inspection |
| S11 | https://github.com/Niko1221/Strata | repo | 2026-11-13 | Engine package `0.1.59-windows-x86_64-hip-rdna2` (HIP RDNA2) is the one installed for `gfx1031` |
| S12 | https://github.com/Niko1221/Strata/releases | repo | 2026-11-13 | Strata desktop 0.2.13 is the installed app version (`components/.updates/state.json`) |
| S13 | local `.strata\data\native-instances\59f33a13-5ac4-4c2c-87cf-385c85ceb4f4.json` | primary | 2026-11-13 | Run config for the live instance: `arch qwen35moe`, `backend hip`, port `18500`, api key present, `--mtp 2 --vision --pool-workers 5 --vram-reserve-mib 1536` |
| S14 | local `C:\Users\6700XT\.strata\data\agent\` | primary | 2026-11-13 | The desktop agent Harness (0.2.1-alpha.3) restarted twice with `the Harness process exited (code 1)` after a compaction; no user-visible failure was seen. Not yet reported |
| S15 | local `C:\Users\6700XT\Documents\Strata\models\qwen36-UD-Q4_K_XL\` | primary | 2026-11-13 | Model on disk: `Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf` (753 tensors) + `mmproj-F16.gguf` |
| S16 | local `...\install\strata-qwen36-ud-q4_k_xl.log` | primary | 2026-11-13 | Startup: 4.40 GiB on the GPU in 2.5 s, 20 of 256 experts per layer in VRAM (1.46 GiB), all 18.75 GiB in pinned host memory, 6 CPU threads, warm-up 3.4 s |
| S17 | local `...\install\strata-qwen36-ud-q4_k_xl.log` | primary | 2026-11-13 | Prompt throughput 494–590 tok/s over ~70 requests at 11–23 K token prompts, 32 K context |
| S18 | local `...\install\strata-qwen36-ud-q4_k_xl.log` | primary | 2026-11-13 | `Windows budgets 11474 of this card's 12272 MiB for this process` — the WDDM budget the engine counts against |
| S19 | local `...\install\run-qwen36-ud-q4_k_xl.bat` | primary | 2026-11-13 | The helper starts `serve/server.py --port 8080 --open`; that is where the `8080` figure comes from |
| S20 | local `...\install\strata-qwen36-ud-q4_k_xl.log` | primary | 2026-11-13 | ~70 served requests, every one `drafts accepted 0 of 0` while the log also says `MTP block loaded` |
| S21 | local `...\install\strata-qwen36-ud-q4_k_xl.log` + `Get-Process` | primary | 2026-11-13 | Live process `strata.exe --serve --native ... --mtp 2 --vision`, `strata-vision.exe` (CPU, 6 threads), `strata-desktop.exe`; engine working set ~41.7 GB |
| S22 | https://github.com/Niko1221/Strata/issues/3354 | repo | 2026-11-13 | Root cause of `drafts accepted 0 of 0`: the server fills in model-card sampling (`temperature 1.0`, `presence_penalty 1.5`) when a request names none, and the q36 engine drafts only for a strictly greedy request. Open; opt-in `STRATA_Q36_MTP_SAMPLED=1` in #3773; workaround is a `sampling` block in the run config |
| S23 | https://github.com/Niko1221/Strata/issues/5609 | repo | 2026-11-13 | Closed as not an engine bug; states the gate as `mtp_d > 0 && !smp.needs_logits() && !adm`, with `needs_logits()` true for temperature > 0, repeat != 1, freq != 0 or present != 0 (`src/qwen35/q36_engine.cu`, `include/strata/qwen35/sampling.hpp`) |
| S24 | local `...\install\strata-qwen36-ud-q4_k_xl.log` (new lines, 2026-11-13 20:3x) | primary | 2026-11-13 | Live 4-pair interleaved measurement on gfx1031, 128 generated tokens each: 22.6 / 25.5 / 27.5 / 27.1 tok/s with `0 of 0` drafts, then 42.2 / 43.6 / 42.4 / 42.8 tok/s with 81/96, 78/102, 78/98, 74/106 drafts accepted |
| S25 | local `.strata\data\native-instances\59f33a13-5ac4-4c2c-87cf-385c85ceb4f4.json` | primary | 2026-11-13 | The app-launched server uses port `18500` (`port` field; the python process is `serve.server ... --port 18500`), so `8080` is not the app's port. Also records `vram_reserve_mib: 1536` and `ui_reserve_applied: 1536` |
| S26 | https://github.com/Niko1221/Strata/issues/5023 + local engine log | repo | 2026-11-13 | The q36 engine prints `ignoring --vram-reserve-mib 1536 (not an option of this engine)` while the app records the reserve as applied. Open, no comments; the ask is to refuse the flag before start. Static check: `src/qwen35/q36_engine.cu` (~line 3809) prints the `ignoring ... (not an option of this engine)` line |

## Housekeeping

- `[S3]` needs its exact URL filled in the next time we are online. Marked inline.
- `[S12]` points at the repo, not a specific release page — the exact release URL is recorded locally in `UNSLOTH_PREBUILT_INFO.json` (`binary_release_tag: b11539-mix-2500203`). Replace when convenient.
- Rows S13–S21 and S24–S25 are local artifacts; they are evidence of what this machine did on
  2026-11-13, not of upstream behaviour. If the install is removed they cannot be re-read.
- Add one row per new claim source. Prefer `primary`/`repo` over `forum`.
