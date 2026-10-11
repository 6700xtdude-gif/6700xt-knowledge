# 2026-10-10 — A 27B runs on 12 GB: Unsloth Studio's HIP build + `--fit` hybrid offload

**Machine:** SANDBOX · Windows 11 Pro · RX 6700 XT `gfx1031` (driver `32.0.21045.5002`) · **ROCm 7.14 runtime bundled by Unsloth**
· llama.cpp `b11539` (`b11539-mix-2500203`, commit `1cdd47c`) **ROCm/HIP** build, served by Unsloth Studio
**Goal:** Explain how a running Unsloth Studio session is serving a **27 B** GGUF on a **12 GB** card, and measure whether the response speed is acceptable.
**Result:** ✅ works — 14.30 GB model runs via **automatic hybrid offload** (`--fit on`): **40/66 layers on GPU**, the rest on CPU/RAM. Decode ≈ **4.0 tok/s**, prefill ≈ **180–250 tok/s**.

## Context

A live Unsloth Studio session was already generating against a local server on this box. Two questions:

1. The card has 12 GB VRAM; the model file is 14.30 GB. How does it fit at all?
2. Is the ~4 tok/s the user reports actually acceptable, and what is the mechanism?

Prior assumption we were testing: `stack/unsloth.md` says the app "abstracts away the exact llama.cpp
flags" (an *observability gap*) and that Unsloth uses **Vulkan**. **Both turned out to be wrong for the
serving path** — see Findings. Also note the KB's earlier assumption that HIP is awkward on `gfx1031`:
Unsloth ships a **prebuilt ROCm build for `gfx103X` that includes `gfx1031`**, and it is installed and
running here.

## Steps

```powershell
# 1. find the running server (it was NOT on 8888 or 9931)
Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -ge 9000 } |
  Select-Object LocalPort,OwningProcess,@{n='Proc';e={(Get-Process -Id $_.OwningProcess).ProcessName}}
Get-Process llama-server | Select-Object Id,@{n='WS_MB';e={[math]::Round($_.WorkingSet64/1MB,1)}},StartTime

# 2. recover the FULL launch command (the "observability gap" is not real)
(Get-CimInstance Win32_Process -Filter "ProcessId=16188").CommandLine

# 3. the app bundles a prebuilt ROCm llama.cpp — read its provenance manifest
Get-Content C:\Users\6700XT\.unsloth\llama.cpp\UNSLOTH_PREBUILT_INFO.json -Raw | ConvertFrom-Json |
  Select-Object release_tag,asset,backend,gfx_target,mapped_targets,source_commit_short,installed_at_utc

# 4. query the server (it is API-key gated)
$k = (Get-Content C:\Users\6700XT\.unsloth\studio\auth\llama_api_key_0a99f40030df4e36 -Raw).Trim()
$h = @{ Authorization = "Bearer $k" }
(Invoke-WebRequest http://127.0.0.1:58551/props   -Headers $h -UseBasicParsing).Content
(Invoke-WebRequest http://127.0.0.1:58551/slots   -Headers $h -UseBasicParsing).Content
(Invoke-WebRequest http://127.0.0.1:58551/metrics -Headers $h -UseBasicParsing).Content

# 5. read the app's own verbosity-4 llama-server log for the memory plan
Get-Content C:\Users\6700XT\.unsloth\studio\logs\llama-server\llama-*-port-58551-try0.log |
  Select-String 'fit|offload|KV|buffer|n_layer'

# 6. VRAM actually held by the process
(Get-Counter "\GPU Process Memory(pid_16188*)\Dedicated Usage").CounterSamples |
  Select-Object Path,@{n='MB';e={[math]::Round($_.CookedValue/1MB,1)}}
```

## Output

**Launch command (recovered verbatim):**

```
C:\Users\6700XT\.unsloth\llama.cpp\build\bin\Release\llama-server.exe
  -m ...\models--unsloth--Qwen3.8-27B-GGUF\snapshots\4ca720788...\Qwen3.8-27B-UD-Q4_K_S.gguf
  --port 58551 --parallel 4 --flash-attn on --no-context-shift -c 32384
  --alias unsloth/Qwen3.8-27B-GGUF --fit on --metrics
  --slot-save-path C:\Users\6700XT\.unsloth\studio\cache\llama-slots --kv-unified
  --fit-ctx 32384 --jinja --verbosity 4 --cache-type-k q8_0 --cache-type-v q8_0
  --spec-type none --reasoning on --chat-template-kwargs "{\"preserve_thinking\": true}"
  --api-key-file C:\Users\6700XT\.unsloth\studio\auth\llama_api_key_0a99f40030df4e36
  --ctx-checkpoints 2 --load-mode none --no-mmproj-auto
```

**Provenance (`UNSLOTH_PREBUILT_INFO.json`):**

| Field | Value |
|---|---|
| published_repo | `unslothai/llama.cpp` |
| release_tag | `b11539-mix-2500203` |
| asset | `app-b11539-mix-2500203-windows-x64-rocm-gfx103X.zip` |
| backend | `rocm` |
| gfx_target | `gfx103X` → mapped: `gfx1030`, **`gfx1031`**, `gfx1032`, `gfx1034` |
| source_commit | `1cdd47c403d51390d85872bf3e1e50c5ca3ccae9` |
| host_profile | `has_rocm: true`, `rocm_runtime: [7, 14]`, `rocm_gfx_targets: [gfx1030, gfx1031]` |
| installed_at_utc | `2026-10-10T22:04:45Z` |

Backend selection in the app installer log: `gpu_branch=rocm`, `torch_index_family=rocm`.
Device line at load: `ggml_cuda_init: found 1 ROCm devices (Total VRAM: 12272 MiB)` → `ROCm0 ... gfx1031 (0x1031), VMM: no, Wave Size: 32`.

**The `--fit on` memory plan (from the app's own log):**

```
common_init_: fitting params to device memory ...
common_params_fit_impl: projected to use 15717 MiB of device memory vs. 11508 MiB of free device memory
common_params_fit_impl: cannot meet free memory target of 1024 MiB, need to reduce device memory by 5232 MiB
common_params_fit_impl: context size set by user to 32384 -> no change
common_params_fit_impl:   - ROCm0 (AMD Radeon RX 6700 XT): 40 layers, 10274 MiB used, 1234 MiB free
load_tensors: offloading output layer to GPU
load_tensors: offloading 39 repeating layers to GPU
load_tensors: offloaded 40/66 layers to GPU
load_tensors:        ROCm0 model buffer size =  8914.42 MiB
load_tensors:    ROCm_Host model buffer size =  5387.08 MiB
llama_kv_cache:        CPU KV buffer size =   404.81 MiB
llama_kv_cache:      ROCm0 KV buffer size =   674.69 MiB
llama_memory_recurrent:        CPU RS buffer size =   249.38 MiB   # hybrid/SSM state
llama_memory_recurrent:      ROCm0 RS buffer size =   349.12 MiB
sched_reserve:      ROCm0 compute buffer size =   335.97 MiB
```

**Resident memory:**

| Component | VRAM (ROCm0) | System RAM |
|---|---:|---:|
| Model weights | 8,914 MiB | 5,387 MiB |
| KV cache (q8_0, 32.5K ctx) | 675 MiB | 405 MiB |
| Recurrent state | 349 MiB | 249 MiB |
| Compute buffers | 336 MiB | 73 MiB |
| **Total** | **≈10.3 GB** | **≈6.1 GB** |

Measured adapter dedicated usage for the process: **10,787 MiB** (of 12,272 MiB). RAM working set `llama-server`: **6,783 MB**.

**Throughput** — from the app's own `print_timing` lines and a direct probe (`/v1/chat/completions`):

| Phase | Rate | Source |
|---|---:|---|
| Prefill (prompt eval) | 180–250 tok/s | log, 8.3K-token prompts |
| Decode (steady) | **4.0 tok/s** (≈250 ms/token) | log, repeated across tasks |
| Decode (two requests at once) | ~2.9 tok/s | our probe overlapped the live session |

The model is `arch = qwen35`, 27.32 B params, `n_layer 64` (`n_layer_all 65`), `n_head 24` / `n_head_kv 4`
(GQA), `n_ff 17408`, **`n_vocab 248320`** (huge). File `Qwen3.8-27B-UD-Q4_K_S.gguf` = **14.30 GB** (~4.2 bits/param).

## Findings

- **A 14.30 GB 27 B model runs on the 12 GB card via llama.cpp `--fit on` automatic partial offload.**
  40/66 layers go to VRAM, 26 stay on the CPU; the split is chosen at load by measuring free device
  memory (`projected 15717 MiB vs 11508 MiB free` → back off). `✅ Verified: 2026-10-10`
- **Weights split 8,914 MiB VRAM + 5,387 MiB RAM** — i.e. ~62% of the model is on the GPU.
  `✅ Verified: 2026-10-10`
- **Unsloth Studio serves with a prebuilt ROCm/HIP llama.cpp, NOT Vulkan** — this corrects
  [`stack/unsloth.md`](../stack/unsloth.md). Build `b11539-mix-2500203` from `unslothai/llama.cpp`,
  asset `...windows-x64-rocm-gfx103X.zip`, backend `rocm`, `gfx103X` mapped to `gfx1030/1031/1032/1034`.
  `✅ Verified: 2026-10-10`
- **HIP works on `gfx1031` on Windows with no WSL and (in this run) no `HSA_OVERRIDE_GFX_VERSION`.**
  The bundled runtime is **ROCm 7.14**; kernels loaded natively and 40 layers offloaded.
  This is real evidence for the vendor claim in `[S5]`, for *inference* at least.
  `✅ Verified: 2026-10-10`
- **The "observability gap" is false.** The full llama.cpp flag set is recoverable from
  `Win32_Process.CommandLine`, and the app writes verbosity-4 `llama-server` logs under
  `C:\Users\6700XT\.unsloth\studio\logs\llama-server\`. What you *can't* easily do is *edit* the flags
  from inside the app. `✅ Verified: 2026-10-10`
- **The serving port is dynamic, not `8888`.** Observed distinct ports across runs: `57025`, `58374`,
  `58551`, `59079`, `60088`, `62498`. `[S5]`'s `8888` is a default, not a constant.
  `✅ Verified: 2026-10-10`
- **The server is API-key gated** (`--api-key-file ...\studio\auth\llama_api_key_*.txt`); requests need
  `Authorization: Bearer <key>`. `/props`, `/slots`, `/metrics` all work with it.
  `✅ Verified: 2026-10-10`
- **The model is a hybrid attention + recurrent architecture** (`qwen35`): a `llama_memory_recurrent`
  state exists alongside the KV cache, and the log warns it may *force full prompt re-processing*
  because of "hybrid/recurrent memory". Combined with GQA (`n_head_kv 4`) this keeps per-token state
  small. `✅ Verified: 2026-10-10`
- **Decode ≈ 4.0 tok/s is the honest price of the split.** Every token runs 26 CPU-resident layers and
  crosses PCIe each step; the card reports `VMM: no`. A 500-token answer is ~2 minutes.
  Prefill is fine (180–250 tok/s). `✅ Verified: 2026-10-10`
- **The Unsloth llama.cpp "mix" build is modular:** `llama-server.exe` is only ~25 KB and loads
  `llama-server-impl.dll` (~9.2 MB); `ggml-hip.dll` is ~184 MB and pulls `amdhip64_7.dll`, `rocblas.dll`,
  `libhipblaslt.dll`. `--fit` logic lives in `llama-fit-params-impl.dll`. `✅ Verified: 2026-10-10`

## Follow-ups

- [ ] Does the same hybrid offload hold if the model is swapped to a smaller quant (Q3_K_XL) — does the whole 27B land on the GPU, and at what tok/s?
- [ ] Repeat with `--parallel 1` (single slot) and a cold, non-overlapped run for a clean decode number.
- [ ] Does Unsloth Desktop **train** on `gfx1031` (the original open question), now that we know its bundled ROCm 7.14 inference works?
- [ ] Compare this HIP 27B decode against the same model forced onto Vulkan via the standalone `C:\Users\6700XT\llm` rig.
- [ ] Capture the exact `--fit` documentation URL to replace the repo-level reference in `sources.md`.
