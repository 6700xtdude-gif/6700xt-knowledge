# Recipe — native Windows, no WSL

**Verified:** 2026-10-10 · `⚠️ Reported`

Goal: run local inference on the 6700 XT using **native Windows tooling only** (no WSL), per this
project's preference.

## Recommended order

1. **Graphics driver first.** Install the current AMD Adrenalin driver. Many problems are just drivers.
   - `Verified: 2026-10-10` this machine reports driver `32.0.21045.5002`.
2. **Try Vulkan before ROCm.** It needs nothing extra and works on `gfx1031`.
   - LM Studio is the fastest sanity check — see [`../stack/lmstudio.md`](../stack/lmstudio.md).
   - Then build/run llama.cpp Vulkan: [`vulkan-fallback.md`](vulkan-fallback.md).
3. **Only then, try native HIP** (ROCm 7.15+, reportedly no WSL needed):
   - [`../stack/hip.md`](../stack/hip.md) and [`hip-override.md`](hip-override.md).
4. **For training**, use Unsloth (bundles its own ROCm): [`../stack/unsloth.md`](../stack/unsloth.md).

## Sanity checks

```powershell
# Card present + driver version
Get-CimInstance Win32_VideoController | Where-Object Name -match 'Radeon' |
  Select-Object Name, DriverVersion, AdapterRAM

# If ROCm installed
rocminfo | Select-String 'gfx'
```

## Why not WSL (for this project)

The user explicitly wants native Windows. Everything needed now has a native path: Vulkan for
inference, Unsloth-bundled ROCm for training, and reported native HIP for vLLM. Keep WSL in the
back pocket only if a specific tool *requires* it.

## Related

- ROCm status: [`../stack/rocm-windows.md`](../stack/rocm-windows.md)
- Vulkan: [`../stack/vulkan.md`](../stack/vulkan.md)
