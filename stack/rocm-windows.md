# ROCm / HIP on Windows — official status

**Verified:** 2026-07-31 (AMD support table) · `📄 Documented`
**⚠️ Re-verify after ~2026-08-31** — AMD updates this table roughly monthly.

## The headline

AMD's own **Windows ROCm/HIP SDK system-requirements table** does **not** list the RX 6700 XT
(`gfx1031`) as supported. In that table the RX 6700 XT row shows:

| Runtime | HIP SDK |
|---|---|
| ❌ | ❌ |

Official Windows ROCm support landed for **RDNA 3 (RX 7000)** and **RDNA 4 (RX 9000)**, not RDNA 2.
The 6000-series rows remain unsupported. `[S1]`

## The workaround everyone uses

Override the reported GFX version so ROCm treats the card as the closest supported RDNA 2 part:

```powershell
$env:HSA_OVERRIDE_GFX_VERSION = "10.3.0"
```

> `10.3.0` targets `gfx1030`. The 6700 XT is `gfx1031`; the override is "close enough" for most
> kernels but is **not** officially blessed and can silently misbehave. `⚠️ Reported`

Details and per-tool usage: [`hip.md`](hip.md) and [`../recipes/hip-override.md`](../recipes/hip-override.md).

## What actually ships

- **HIP SDK** independently supports some consumer cards on Windows; the 6700 XT is not on the
  supported list. `[S1]`
- Third-party redistribution is the practical route on Windows: **Unsloth** bundles ROCm for
  RDNA 2 (see [`unsloth.md`](unsloth.md)), and hand-built wheels exist for PyTorch-ROCm.

## Driver coupling

- ROCm **7.14** reportedly requires **Adrenalin 26.6.4 or newer** on Windows. `⚠️ Reported`
- Newer ROCm (7.15+) is reported to work on RX 6000 with **no WSL required** — see [`hip.md`](hip.md).

## What to watch

1. Does AMD add RDNA 2 to the Windows support table? Check the URL in `[S1]`.
2. Does `HSA_OVERRIDE_GFX_VERSION` become unnecessary as detection improves?
3. Native-Windows (no-WSL) HIP is the most likely path to stop caring about the override entirely.
