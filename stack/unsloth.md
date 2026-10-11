# Unsloth on the RX 6700 XT (`gfx1031`)

**Verified:** 2026-10-10 · `✅ Verified` (bundled backend, serving, ports, logs) · `📄 Documented` (training claim)

Unsloth's intended use in this project is **training/export**. In practice the Studio app *also* serves
models, and — contrary to an earlier assumption here — **that serving path is fully observable** (see
below). We still prefer standalone llama.cpp when we want to control every flag. `[S5]`

## Support claim

Unsloth's own documentation lists **RDNA 2 / `gfx1031` (RX 6700 XT) as "Full" support on Windows**
and claims it **auto-installs ROCm** for you — i.e. it does not make you satisfy AMD's official
support matrix. `[S5]`

> This is a **vendor claim**, and it runs counter to AMD's own unsupported status for `gfx1031`.
> **We have now verified the inference half of it:** Unsloth installed a ROCm `gfx103X` build and it
> offloaded to the 6700 XT (see below). The **training** half (a QLoRA run) is still unverified.
> `✅ Verified: 2026-10-10` (inference) · `📄 Documented` (training claim)

## What the app is

- **Unsloth Desktop / Studio** is a **Tauri** desktop app.
- It provisions a **uv-managed Python environment** for training dependencies.
- It **bundles its own llama.cpp** builds (including ROCm prebuilts) rather than using yours.
- Default install / history location: `C:\Users\<user>\.unsloth\studio`. `Verified: 2026-10-10` (path)

### The bundled backend is ROCm/HIP, not Vulkan `✅`

The installer selects a GPU branch (`gpu_branch=rocm`, `torch_index_family=rocm`) and downloads a
matching prebuilt llama.cpp. On this machine that resolved to an **official Unsloth ROCm build for
`gfx103X` that includes `gfx1031`** — the provenance is recorded by the app itself in
`C:\Users\<user>\.unsloth\llama.cpp\UNSLOTH_PREBUILT_INFO.json`:

| Field | Value (this machine, 2026-10-10) |
|---|---|
| repo / release | `unslothai/llama.cpp` · `b11539-mix-2500203` (build `b11539`, commit `1cdd47c`) |
| asset | `app-b11539-mix-2500203-windows-x64-rocm-gfx103X.zip` |
| backend | `rocm` |
| gfx_target | `gfx103X` → `gfx1030`, **`gfx1031`**, `gfx1032`, `gfx1034` |
| host ROCm runtime | `7.14` |

The build is **modular**: `llama-server.exe` (~25 KB) loads `llama-server-impl.dll` (~9.2 MB), and
`ggml-hip.dll` (~184 MB) pulls in `amdhip64_7.dll`, `rocblas.dll`, `libhipblaslt.dll`. `✅ Verified: 2026-10-10` `[S12]`

## Serving and OpenCode

- Unsloth can serve a model over **two API shapes on one port**: OpenAI-style
  (`/v1/chat/completions`) **and** Anthropic-style (`/v1/messages`), using **`sk-unsloth-` keys**.
- `unsloth start opencode` wires OpenCode to that local server.
- Custom-provider base URL for OpenCode was documented as **`http://localhost:8888/v1/`** — but the
  **actual port is dynamic per launch.** `[S5]` Observed distinct ports on this box across runs:
  `57025 · 58374 · 58551 · 59079 · 60088 · 62498`. Read the live port from the app or from
  `Get-NetTCPConnection` / the process command line; don't hard-code `8888`. `✅ Verified: 2026-10-10`
- The served endpoint is **API-key gated**: the server is launched with
  `--api-key-file ...\studio\auth\llama_api_key_<id>.txt`, so clients must send
  `Authorization: Bearer <key>`. With the key, `/props`, `/slots`, and `/metrics` all respond.
  `✅ Verified: 2026-10-10`
- When driving OpenCode, start the server with **`--disable-tools`** so the model doesn't try to use
  its own tools and fight OpenCode's. `📄 Documented` `[S5]`

## Observability — better than we claimed

An earlier version of this file said the Studio server "abstracts away the exact llama.cpp flags."
**That is not true.** The full flag set is recoverable and the app writes verbose logs. `✅ Verified: 2026-10-10`

- The launch command is visible verbatim:
  ```powershell
  (Get-CimInstance Win32_Process -Filter "ProcessId=<pid>").CommandLine
  ```
- The app runs the server at `--verbosity 4` and saves per-launch logs to
  `C:\Users\<user>\.unsloth\studio\logs\llama-server\llama-<id>-port-<port>-try0.log` — including the
  `--fit` memory plan, layer-offload counts, KV/compute buffer sizes, and per-task timings.
- What you **can't** easily do is *edit* the flags from inside the app.

A worked example (a 27 B model on this 12 GB card) is in
[`../log/2026-10-10-unsloth-studio-27b-hybrid-offload.md`](../log/2026-10-10-unsloth-studio-27b-hybrid-offload.md).

## Training tier for 12 GB

Start at **3–4B** (very comfortable on 12 GB). See [`../models/what-fits-12gb.md`](../models/what-fits-12gb.md).

## To verify on this machine

- [x] Does Unsloth Desktop detect `gfx1031`? — **Yes:** it installed a ROCm `gfx103X` llama.cpp build and offloaded 40 layers to the 6700 XT. `✅ 2026-10-10`
- [x] Which ROCm version does it install, and does it work without `HSA_OVERRIDE_GFX_VERSION`? — **ROCm 7.14 runtime; no `HSA_OVERRIDE` set in the launch command, and kernels loaded.** `✅ 2026-10-10`
- [ ] Does Unsloth Desktop complete a tiny **QLoRA training** run on `gfx1031`? (inference is now proven; training is still open)
- [ ] Does its GGUF export load in standalone llama.cpp unchanged?
