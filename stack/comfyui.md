# ComfyUI (image generation)

**Verified:** 2026-10-10 · `⚠️ Reported`

Included because the 6700 XT is a capable image-gen card and it's a common "does my GPU work?" test.
`[S8]`

## AMD ROCm support on Windows

- ComfyUI's **official AMD ROCm support on Windows** arrived via **ComfyUI Desktop v0.7.0+**
  (announced by ComfyUI). `📄 Documented` `[S8]`
- **But:** that official Windows ROCm path targets supported AMD cards; the **6700 XT (`gfx1031`) is
  not in the officially supported set**, so you may need community/override approaches. `⚠️ Reported`

## Practical paths on this card

1. **DirectML / Vulkan-ish builds** — historically the least painful 6000-series route.
2. **ROCm with `HSA_OVERRIDE_GFX_VERSION=10.3.0`** — may work, may produce artifacts.
3. **System memory offload** — with 12 GB VRAM, keep SDXL workflows modest; SD1.5 is comfortable.

## To verify on this machine

- [ ] Which ComfyUI Windows build runs on `gfx1031` with the least fuss?
- [ ] SD1.5 vs SDXL VRAM footprint and it/s.
