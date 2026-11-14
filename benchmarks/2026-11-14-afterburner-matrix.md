# Empirical Benchmark Matrix — 2026-11-14 (RX 6700 XT Afterburner)

**Status:** ✅ measured on bare-metal hardware.  
**Platform:** Windows 11 Pro, AMD Ryzen 5 5600 (6C/12T), AMD Radeon RX 6700 XT 12 GB (`gfx1031`, 96 MB Infinity Cache), 32 GB DDR4-3200 (2×16 GB DIMMs, 1 DPC).  
**Runtime:** `llama-server.exe` (build 12374 Vulkan), 65,536 (64k) Context Window.  
**Test Suite:** Standardized 3-round interleaved evaluation matrix with warm-up cycles (`bench/bench_head_to_head.py`).  
**Companion Project:** [`6700xtdude-gif/6700XT-Afterburner`](https://github.com/6700xtdude-gif/6700XT-Afterburner) `[S27]`.

---

## 1. Comparative Architectural Matrix (32 GB vs. 64 GB Host RAM)

| Model & Quant Regime | Offload Strategy | Host RAM Config | Overall Median Decode | Structured JSON | Python Code | Peak RSS | Key Silicon Bottleneck |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **Qwen 3.8 27B IQ2_M**<br>(Sub-3-bit Importance Matrix) | **65 / 65 Layers on GPU**<br>MTP Speculation ($K=2$) | 32 GB (2 DIMMs) | **`22.61 t/s`** | **24.22 t/s**<br>(76.0% accept) | **23.69 t/s**<br>(72.6% accept) | 12,929 MB | **Zero DDR4 Traffic.** Pure GDDR6 + 96MB Infinity Cache speed. |
| **Qwen 3.8 27B IQ2_M** | 65 / 65 Layers on GPU<br>MTP Speculation ($K=2$) | 64 GB (4 DIMMs) | **`22.43 t/s`** | 23.70 t/s | 23.06 t/s | 12,156 MB | Identical throughput (~22.6 vs 22.4 t/s). VRAM-resident models bypass DDR4. |
| **Qwen 3.6 35B A3B UD-Q4_K_XL**<br>(Sparse MoE, 3B active) | 16 GPU / 25 DDR4<br>Sparse routing (8/256) | 32 GB (2 DIMMs) | **`16.78 t/s`** | **16.81 t/s**<br>(120.9 ms TTFT) | **16.77 t/s**<br>(1209 ms TTFT) | 21,531 MB | **Sparse Expert Advantage.** Reads ~3.5 GB active parameters/tok; zero SSD paging. |
| **Qwen 3.6 35B A3B UD-Q4_K_XL** | 16 GPU / 25 DDR4<br>Sparse routing (8/256) | 64 GB (4 DIMMs) | **`16.39 t/s`** | 16.47 t/s | 16.47 t/s | 21,469 MB | High capacity margin; steady ~16.4 t/s across all rounds. |
| **Qwen 3.8 27B UD-Q4_K_XL**<br>(Dense Hybrid Offload) | 45 GPU / 20 DDR4<br>MTP Speculation ($K=2$, `tb=12`) | **32 GB (2 DIMMs)** | **`7.54 t/s`** | **8.64 t/s**<br>(82.3% accept) | **7.59 t/s**<br>(66.2% accept) | 20,935 MB | **2-DIMM IMC Advantage (+23.0% speedup).** 1 DPC / 1T command rate reduces DDR4 latency. |
| **Qwen 3.8 27B UD-Q4_K_XL** | 45 GPU / 20 DDR4<br>MTP Speculation ($K=2$, `tb=12`) | 64 GB (4 DIMMs) | **`6.13 t/s`** | 6.45 t/s | 6.15 t/s | 22,098 MB | **The DDR4 Cliff.** Streams 27B weights every token through 32 GiB/s DDR4 bus. |

---

## 2. Dual-Engine Speculative Decoding Matrix (JEV + 96 MB Infinity Cache)

Pinning ultra-compact draft engines inside the RX 6700 XT's 96 MB on-die Infinity Cache (>1 TB/s) accelerates full-VRAM verifier models:

| Verifier Model | Drafter Model | Speculation Setup | Standalone Baseline | Speculative Decode | Speedup ($\alpha$) |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **Qwen 2.5 Coder 7B Q4_K_M** | 0.5B Instruct Q4_0 | Dual-Engine ($K=2$) | 71.7 t/s | **95.3 t/s (JSON)**<br>**85.3 t/s (Code)** | **1.33x** (JSON)<br>**1.17x** (Code) |
| **Qwen 2.5 Coder 14B Q4_K_M** | 0.5B Instruct Q4_0 | Dual-Engine ($K=3$) | 37.4 t/s | **62.3 t/s (JSON)**<br>**60.9 t/s (Code)** | **1.67x** (JSON)<br>**1.62x** (Code) |

---

## 3. Key Empirical Discoveries

1. **The 2-DIMM Memory Controller Advantage:**
   - The Ryzen 5 5600 Integrated Memory Controller (IMC) operates significantly more efficiently when driving 2 single-rank DIMMs (1 DPC, 1T command rate) compared to 4 DIMMs (2 DPC).
   - This delivers an immediate **+23.0% speedup (6.13 t/s $\rightarrow$ 7.54 t/s)** on hybrid offload decode where the CPU must stream model weights across DDR4 on every single token.
2. **Working Set Boundaries on 32 GB RAM:**
   - A clean 32 GB Windows 11 host (with ~26.3 GB free memory at boot) provides sufficient headroom to run large hybrid models (`Qwen 3.6 35B` at 21.5 GB RSS, `Qwen 3.8 27B` at 20.9 GB RSS) completely in physical memory with **zero NVMe SSD disk thrashing**.
3. **100% VRAM Saturation:**
   - Sizing large models down to `IQ2_M` eliminates DDR4 dependence entirely, achieving **22.61 tokens/sec** with 160–170 ms TTFT.
