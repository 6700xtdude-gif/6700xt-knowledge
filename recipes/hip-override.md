# Recipe — HIP on `gfx1031` with `HSA_OVERRIDE_GFX_VERSION`

**Verified:** 2026-10-10 · `⚠️ Reported`

Use this only when you specifically need a ROCm/HIP runtime (e.g. PyTorch-ROCm, some vLLM builds).
Prefer Vulkan otherwise — see [`../stack/vulkan.md`](../stack/vulkan.md).

## The override

ROCm does not officially support `gfx1031` (see [`../stack/rocm-windows.md`](../stack/rocm-windows.md)),
so you pretend the card is `gfx1030`:

```powershell
# current session
$env:HSA_OVERRIDE_GFX_VERSION = "10.3.0"
```

```powershell
# persistent for your user
[Environment]::SetEnvironmentVariable("HSA_OVERRIDE_GFX_VERSION","10.3.0","User")
```

```bash
# Linux / Omarchy
export HSA_OVERRIDE_GFX_VERSION=10.3.0
```

## Verify ROCm sees the card

```powershell
rocminfo | Select-String 'gfx'
```

You want to see `gfx1030` (the overridden identity) and no fatal HIP errors.

## Cautions

- The override makes the runtime *believe* it's a different part; some kernels will miscompute or
  crash. If you see NaNs, garbage output, or hard crashes, drop the override or drop to Vulkan.
- Whether it is still needed on ROCm 7.15+ is an **open question**. Try without it first. `🧪 Untested`

## Related

- Native HIP (no WSL): [`../stack/hip.md`](../stack/hip.md)
- ROCm 7.14 ↔ Adrenalin 26.6.4 coupling: [`../stack/rocm-windows.md`](../stack/rocm-windows.md)
