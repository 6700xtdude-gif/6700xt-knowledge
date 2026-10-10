# Linux — Arch / Omarchy on the 6700 XT

**Verified:** 2026-10-10 · `🧪 Planned` (no Linux data yet)

This project explicitly supports a future reimage to **Arch Linux / Omarchy**. The KB is designed to
be cloned onto that machine and extended there. This file is the landing zone for those trials.

## Why Linux changes the ROCm picture

- On Linux, ROCm support for RDNA 2 is generally **better and more mature** than on Windows, though
  `gfx1031` is still not always officially listed. Expect the same `HSA_OVERRIDE_GFX_VERSION=10.3.0`
  trick to appear in guides. `🧪 Untested here`
- Vulkan remains available and is often the fastest way to get running.

## Plan when reimaged

1. `git clone` this repo onto the Arch/Omarchy machine.
2. Confirm the card: `lspci | grep -i vga`, and `rocminfo | grep gfx` if ROCm installed.
3. Run the Vulkan recipe; then attempt ROCm (`export HSA_OVERRIDE_GFX_VERSION=10.3.0`).
4. Add a dated `log/` entry and promote findings back here and into `stack/`.
5. Open a PR from the Linux machine so both environments stay in one history.

## Open questions

- [ ] Is a Vulkan-only Arch setup sufficient, or is ROCm meaningfully faster for decode?
- [ ] Do Omarchy/Arch kernel + Mesa versions affect llama.cpp Vulkan performance?
- [ ] Does Unsloth run natively on Arch, or is it Windows/macOS-only?

## Sources

- Community reports of native Windows HIP as the alternative: `[S3]`
- ROCm Windows table (contrast): `[S1]`
