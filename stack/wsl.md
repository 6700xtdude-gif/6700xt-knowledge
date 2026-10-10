# WSL — status and relevance

**Verified:** 2026-10-10 · `📄 Documented` / `⚠️ Reported`

WSL is **not required** for this project (native Windows is preferred), but it remains relevant as a
fallback if a specific tool only ships Linux ROCm wheels. `[S10]`

## Recent changes that matter

- **WSL is now open source** (Microsoft). `⚠️ Reported`
- **WSL containers reached GA**, announced around **2026-09-29**, with `wslc.exe` / `container.exe`
  and a containerization push at Build 2026. `⚠️ Reported`
- Net effect: WSL is more capable than ever, but the ROCm story on Windows has also improved enough
  that native routing is now viable. See [`hip.md`](hip.md).

## When you'd still use WSL here

- A tool's **only** install path is Linux ROCm/PyTorch wheels with no native Windows equivalent.
- You want a reproducible Linux environment without reimaging.

## Guidance for this KB

Document WSL steps **only** when the native path fails, and always note the OS boundary. Do not make
WSL the default in recipes. `📄` (project convention)
