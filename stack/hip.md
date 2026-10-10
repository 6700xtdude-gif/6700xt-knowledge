# Native HIP (no WSL) on Windows

**Verified:** 2026-10-10 · `⚠️ Reported`

The most interesting recent development for RX 6000 owners is **native Windows HIP working without
WSL**. Historically the advice was "install ROCm inside WSL2"; that requirement appears to be
weakening. `[S3]`

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

- [ ] Install ROCm 7.15 on this machine, run `rocminfo`, confirm `gfx1031` is enumerated.
- [ ] (Re)test with and without `HSA_OVERRIDE_GFX_VERSION`.
- [ ] Serve a 7–8B GGUF/model via vLLM and record tok/s vs Vulkan.

See also [`rocm-windows.md`](rocm-windows.md) and [`../recipes/hip-override.md`](../recipes/hip-override.md).
