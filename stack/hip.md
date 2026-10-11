# Native HIP (no WSL) on Windows

**Verified:** 2026-10-10 · `✅ Verified` (one real HIP run on `gfx1031`) · `⚠️ Reported` (vLLM path below)

The most interesting recent development for RX 6000 owners is **native Windows HIP working without
WSL**. Historically the advice was "install ROCm inside WSL2"; that requirement appears to be
weakening. `[S3]`

## ✅ Confirmed here: Unsloth's bundled ROCm build runs on `gfx1031`, no WSL

On 2026-10-10 we found Unsloth Studio serving a 27 B model through its own prebuilt llama.cpp built
for **ROCm**, and the device line at load was unambiguous:

```
ggml_cuda_init: found 1 ROCm devices (Total VRAM: 12272 MiB):
  Device 0: AMD Radeon RX 6700 XT, gfx1031 (0x1031), VMM: no, Wave Size: 32, VRAM: 12272 MiB
```

- Asset: `app-b11539-mix-2500203-windows-x64-rocm-gfx103X.zip` (`gfx103X` → `gfx1030/1031/1032/1034`).
- **ROCm runtime 7.14**, **no WSL**, and **no `HSA_OVERRIDE_GFX_VERSION`** in the launch command —
  the kernels loaded and 40 layers offloaded to the GPU. `✅ Verified: 2026-10-10`

This is the strongest evidence we have so far that "`gfx1031` is unsupported by AMD" (see
[`rocm-windows.md`](rocm-windows.md)) is a *support-matrix* statement, not a *capability* statement.
`[S12]` Full write-up: [`../log/2026-10-10-unsloth-studio-27b-hybrid-offload.md`](../log/2026-10-10-unsloth-studio-27b-hybrid-offload.md).

## Reported working setup

- **ROCm 7.15** on Windows 11, **no WSL2**.
- **vLLM** serving a model on the 6700 XT, reported ~**62 tok/s** decode on the test model. `[S3]`
- Earlier ROCm 7.14 was also reported working with **Adrenalin 26.6.4+**. `[S3]`

> These are community reports (forum thread), not vendor docs. Reproduce before trusting the
> numbers. `⚠️ Reported`

## The `HSA_OVERRIDE_GFX_VERSION` question

Most guides still set:

```powershell
$env:HSA_OVERRIDE_GFX_VERSION = "10.3.0"
```

Whether it is still *required* on 7.15 for `gfx1031` is an **open question** — add it if kernels fail
to load, remove it if they load natively. `🧪 Untested`

## Why this matters for the project

If native HIP is reliable, we can:

1. Drop the WSL dependency entirely (matches this project's native-Windows preference).
2. Serve vLLM directly to the local stack on `localhost:xxxx`.
3. Train with Unsloth using the same runtime instead of juggling WSL.

## To verify next

- [x] See HIP actually execute on `gfx1031` on Windows — **done** via Unsloth's bundled ROCm 7.14 build (no WSL, no `HSA_OVERRIDE`). `✅ 2026-10-10`
- [ ] Stand up ROCm 7.15 *ourselves* (not Unsloth's bundle) and run `rocminfo`; confirm `gfx1031` is enumerated.
- [ ] (Re)test with and without `HSA_OVERRIDE_GFX_VERSION` on a self-built binary.
- [ ] Serve a 7–8B model via vLLM (HIP) and record tok/s vs Vulkan — isolate the engine from the model size.

See also [`rocm-windows.md`](rocm-windows.md) and [`../recipes/hip-override.md`](../recipes/hip-override.md).
