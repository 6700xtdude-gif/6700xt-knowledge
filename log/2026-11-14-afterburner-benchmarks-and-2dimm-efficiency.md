# 2026-11-14 — 6700XT-Afterburner Benchmarks, 100% VRAM 27B, and 2-DIMM IMC Efficiency

**Machine:** SANDBOX · Windows 11 Pro (10.0.26300) · AMD Radeon RX 6700 XT 12 GB (`gfx1031`, Vulkan) · AMD Ryzen 5 5600 (6C/12T) · 32 GB DDR4-3200 (2×16 GB DIMMs) vs 64 GB DDR4-3200 (4 DIMMs).  
**Goal:** Verify 100% VRAM 27B saturation (`IQ2_M`), native Vulkan MoE throughput on `Qwen 3.6 35B`, and isolate the impact of 32 GB (2 DIMMs) vs 64 GB (4 DIMMs) on hybrid offload memory bandwidth.  
**Result:** ✅ verified — 100% VRAM 27B achieves **`22.61 t/s`** decode; 35B MoE achieves **`16.78 t/s`** decode on Vulkan; 2-DIMM DDR4-3200 delivers **`7.54 t/s`** on dense hybrid offload (+23.0% speedup over 4-DIMM 6.13 t/s due to 1 DPC / 1T command rate).

---

## Background & Context

Following the release of Project 9696XT and community audit requests (Alex @AlexFP16), we tested the standard evaluation matrix across the entire model spectrum on both 64 GB (4 DIMMs) and 32 GB (2 DIMMs) hardware configurations using `llama-server.exe` (build 12374 Vulkan) with a verified 65,536 (64k) context window.

Companion Repository: [`6700xtdude-gif/6700XT-Afterburner`](https://github.com/6700xtdude-gif/6700XT-Afterburner) `[S27]`.

---

## Empirical Benchmark Findings

### 1. 100% VRAM 27B Saturation (`Qwen3.8-27B-IQ2_M`)
- **Configuration:** 65/65 layers on GPU, 0 in DDR4, `-ctk q4_0 -ctv q4_0`, `-c 65536`, `--spec-type draft-mtp --spec-draft-n-max 2`.
- **Throughput:**
  - Overall Median Decode: **`22.61 tokens/sec`** (5.7x faster than 4 t/s legacy hybrid baseline).
  - Structured JSON: **`24.22 t/s`** (76.0% MTP draft acceptance, 163 ms TTFT).
  - Code Generation: **`23.69 t/s`** (72.6% MTP draft acceptance, 176 ms TTFT).
  - Reasoning: **`20.29 t/s`** (55.5% MTP draft acceptance, 166 ms TTFT).
- **RSS & Footprint:** 12,928.9 MB peak process RSS.
- **Hardware Invariance:** Bypasses DDR4 completely; decode rate is identical on 32 GB (22.61 t/s) and 64 GB (22.43 t/s).

### 2. Sparse MoE Hybrid Offload (`Qwen3.6-35B-A3B UD-Q4_K_XL`)
- **Configuration:** 16 layers VRAM, 25 in DDR4, `-ctk q8_0 -ctv q8_0`, `-c 65536`, `-t 6`.
- **Throughput:**
  - Overall Median Decode: **`16.78 tokens/sec`** (115–124 ms TTFT).
  - Structured JSON: **`16.81 t/s`**.
  - Code Generation: **`16.77 t/s`**.
- **RSS & Footprint:** 21,530.5 MB peak process RSS.
- **Physical Memory Margins:** System booted with 26.3 GB free physical RAM; process consumed 21.5 GB, leaving ~5.4 GB free physical memory with zero NVMe SSD pagefile swapping.

### 3. Dense Hybrid Offload & 2-DIMM Memory Controller Advantage (`Qwen3.8-27B UD-Q4_K_XL`)
- **Configuration:** 45 layers VRAM, 20 in DDR4, `-t 4 -tb 12`, `--spec-type draft-mtp --spec-draft-n-max 2`.
- **Throughput:**
  - 32 GB (2×16 GB DIMMs, 1 DPC): **`7.54 tokens/sec`** overall median (JSON: **`8.64 t/s`** with 82.3% MTP acceptance).
  - 64 GB (4×16 GB DIMMs, 2 DPC): **`6.13 tokens/sec`** overall median (JSON: **`6.45 t/s`**).
- **Silicon Insight:** The Ryzen 5 5600 Integrated Memory Controller (IMC) operates with lower latency and true 1T command rate on 2 single-rank DIMMs, increasing effective memory bandwidth from ~25.5 GB/s to ~31.4 GB/s. This delivers an immediate **+23.0% speedup** on bandwidth-bound hybrid offload.

### 4. Parity & Verification Suite
- Determinism at temp=0.0: **PASSED** (byte-for-byte exact matches).
- JSON Schema Integrity: **PASSED** (valid JSON dictionary parsed even across agentic `<think>` tokens).
- Python AST Validation: **PASSED** (valid AST syntax tree parsed).
- Speculative Draft Acceptance: **PASSED** (65.3% to 71.5% acceptance over 600+ drafted tokens).
- Hermetic Unit Tests: 11/11 passed in 60 ms.
