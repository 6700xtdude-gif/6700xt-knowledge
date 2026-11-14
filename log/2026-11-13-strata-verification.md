# 2026-11-13 — Strata verification on AMD Radeon RX 6700 XT

**Machine:** 6700XT · Windows 10.0.26300 · AMD Radeon RX 6700 XT / vulkan / 6 cores / 64 GB

**Goal:** Verify Strata 0.2.13 running on `gfx1031` with Qwen3.6-35B-A3B-UD-Q4_K_XL model

**Result:** ✅ works — Strata desktop 0.2.13 running Strata engine 0.1.59-windows-x86_64-hip-rdna2, serving Qwen3.6-35B-A3B-UD-Q4_K_XL via `--serve --native`, API on 127.0.0.1:8080

**Context:** Strata previously documented RX 6700 XT as experimental HIP path (`--backend hip`, "unvalidated", #524). We installed Strata desktop 0.2.13 and confirmed the engine runs on this hardware. The engine loaded and served the 35B MoE model with ~18–20 tok/s decode and ~540–580 tok/s prompt throughput.

**Steps:**
```powershell
# Install Strata desktop 0.2.13
# Run Strata desktop (see run-qwen36-ud-q4_k_xl.bat)
# Confirm Strata is running:
Get-Process | Where-Object { $_.Name -match 'strata' }

# Check engine logs:
Get-Content -Path 'C:\Users\6700XT\AppData\Local\Strata\install\strata-qwen36-ud-q4_k_xl.log' -Tail 40

# Check API status:
curl http://127.0.0.1:8080/api/v1/models
```

**Output (trimmed):**
```
[strata] 2026-11-13 19:51:45 engine started: ...0.1.59-windows-x86_64-hip-rdna2\strata.exe --serve --native ...Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf --max-context 32768 --prefill auto --mtp 2 --vision --pool-workers 5 --vram-reserve-mib 1536
strata-q36: ignoring --vram-reserve-mib 1536 (not an option of this engine)
strata: Windows budgets 11474 of this card's 12272 MiB for this process; free VRAM is counted within that
strata-q36: hybrid experts: 20 of 256 per layer in VRAM (1.46 GiB), all 18.75 GiB in pinned host memory
strata serve: session 0: prompt 11424 tokens = 11424 read in 19477 ms (586.5 tok/s), 81 generated in 4435 ms (18.3 tok/s)
```

**Findings:**
- ✅ **Verified: 2026-11-13** [S21] Strata desktop 0.2.13 runs on AMD Radeon RX 6700 XT (`gfx1031`) with HIP rdn2 engine package 0.1.59.
- ✅ **Verified: 2026-11-13** [S15] Engine 0.1.59-windows-x86_64-hip-rdna2 successfully loaded and served Qwen3.6-35B-A3B-UD-Q4_K_XL via `--serve --native`.
- ✅ **Verified: 2026-11-13** [S13] Strata desktop API on `127.0.0.1:47831` (desktop host), Strata server API on `127.0.0.1:8080`.
- ✅ **Verified: 2026-11-13** [S20] ~18–20 tok/s decode, ~540–580 tok/s prompt, ~4.40 GiB VRAM on GPU, 18.75 GiB pinned host memory, 6 CPU threads, 11.7 s warm-up.
- ⚠️ **Strata harness crashes** (exit code 1) multiple times during startup (see `.strata\data\agent\harness.log`).
- ⚠️ **Option mismatch**: Strata desktop passes `--vram-reserve-mib 1536`, but the engine logs `ignoring --vram-reserve-mib 1536 (not an option of this engine)`.
- ⚠️ **MTP speculative decoding** shows `drafts accepted 0 of 0` even though `--mtp 2` was set.

**Follow-ups:**
- [ ] Investigate harness crashes (exit code 1) and agent configuration
- [ ] Report the `--vram-reserve-mib` option mismatch and the MTP `0 of 0` drafts issue to the Strata repo
- [ ] Test `--backend hip` vs the current native route to determine the optimal configuration
- [ ] Check if Strata supports a Vulkan backend for `gfx1031` (current path uses HIP rdn2)
- [ ] Compare against llama.cpp Vulkan on the same model

**Sources:**
- [S10]–[S21] in [`../sources.md`](../sources.md)
