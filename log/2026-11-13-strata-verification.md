# 2026-11-13 — Strata verification on AMD Radeon RX 6700 XT

**Machine:** 6700XT · Windows 10.0.26300 · AMD Radeon RX 6700 XT / vulkan / 6 cores / 64 GB

**Goal:** Verify Strata 0.2.13 running on `gfx1031` with Qwen3.6-35B-A3B-UD-Q4_K_XL model

> **Corrected 2026-11-13:** the decode figure and the `8080` port in this entry were both revised after
> the follow-up run. See [`2026-11-13-strata-mtp-sampling.md`](2026-11-13-strata-mtp-sampling.md).

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

# Check API status (the helper .bat's port; the app's own server uses the port in its run config):
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
- ✅ **Verified: 2026-11-13** [S13] Strata desktop host on `127.0.0.1:47831` while the app was starting; the app-launched inference server listens on port **18500**. **Corrected 2026-11-13:** the earlier `8080` here was the helper `.bat`'s port, not the app's. `[S25]`
- ✅ **Verified: 2026-11-13** [S20] ~18–20 tok/s decode on 11–23 K-token prompts, ~540–580 tok/s prompt, ~4.40 GiB VRAM on GPU, 18.75 GiB pinned host memory, 6 CPU threads, 11.7 s warm-up. **Corrected 2026-11-13:** that is the *no-draft* rate; a strictly greedy request drafts and reaches ~43 tok/s at a short context — see [`2026-11-13-strata-mtp-sampling.md`](2026-11-13-strata-mtp-sampling.md).
- ⚠️ **Desktop agent Harness restarted twice** with `the Harness process exited (code 1)` right after a
  compaction (`desktop-20261114-002730.log`). No user-visible failure; not filed. **Corrected 2026-11-13:**
  `harness.log` itself only holds one line, so the desktop log is the evidence, not the harness log.
- ⚠️ **Option mismatch**: Strata desktop passes `--vram-reserve-mib 1536` (and records `ui_reserve_applied:
  1536`), but the engine logs `ignoring --vram-reserve-mib 1536 (not an option of this engine)`. **Corrected
  2026-11-13:** tracked upstream as open [#5023](https://github.com/Niko1221/Strata/issues/5023).
- ⚠️ **MTP speculative decoding** shows `drafts accepted 0 of 0` even though `--mtp 2` was set. **Corrected
  2026-11-13:** not a broken engine — the model-card sampling makes the request non-greedy, and the q36
  engine drafts only for strictly greedy requests ([#3354](https://github.com/Niko1221/Strata/issues/3354)).
  Setting `temperature 0, presence_penalty 0, frequency_penalty 0, repetition_penalty 1` gives
  74–81 drafts of 96–106 and ~43 tok/s.

**Follow-ups:**
- [x] Investigate harness restarts → observed twice, both after a compaction; no user-visible failure, and
      child processes came straight back. Left unreported.
- [x] Explain the `--vram-reserve-mib` option mismatch → app records the reserve as applied, engine ignores
      it; already open upstream as #5023. No new issue needed.
- [x] Explain the MTP `0 of 0` drafts → model-card sampling gate; measured and written up in
      [`2026-11-13-strata-mtp-sampling.md`](2026-11-13-strata-mtp-sampling.md).
- [ ] Decide whether to add this machine's evidence to #5023 and #3354 (would comment, not open new issues).
- [ ] Test `--backend hip` vs the current native route to determine the optimal configuration
- [ ] Check if Strata supports a Vulkan backend for `gfx1031` (current path uses HIP rdn2)
- [ ] Compare against llama.cpp Vulkan on the same model

**Sources:**
- [S10]–[S21] in [`../sources.md`](../sources.md)
- Correction and the sampling measurement: [`2026-11-13-strata-mtp-sampling.md`](2026-11-13-strata-mtp-sampling.md), `[S22]`–`[S26]`
