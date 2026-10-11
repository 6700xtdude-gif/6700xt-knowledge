# 6700 XT Knowledge Base

A living, source-cited knowledge base for running **local LLMs and GPU compute on the
AMD Radeon RX 6700 XT** (`gfx1031`, RDNA 2, 12 GB) — on **Windows, WSL, and Linux**, with and
without ROCm.

Maintained by **6700XTDude** and the OpenCode agent as a *living experiment* on real
bare-metal hardware, not a static wiki.

> **Status:** v0.1 — seeded 2026-10-10 from a fresh Windows 11 install on a bare-metal SANDBOX
> (Ryzen 5 5600 / RX 6700 XT / 32 GB RAM / 1 TB NVMe).

## Why this exists

Running modern models on a 6700 XT is possible, but the documentation is scattered, contradictory,
and changes every few weeks. Official ROCm support, driver requirements, and per-tool behavior move
faster than any model's training data. This repo records **what is true now**, **when it was
verified**, and **where it came from** — so we stop re-deriving the same facts and so other
6700 XT owners benefit.

## Core principles

1. **Every claim is dated.** Facts carry a `Verified:` date. Anything older than ~30 days is marked
   `⚠️ STALE — re-verify`.
2. **Primary sources first.** AMD's own docs, maintainer repos, and release notes outrank forum posts.
3. **Labeled confidence.** Use the tags below on every non-obvious claim.
4. **Reproducible.** Commands are copy-pasteable, with OS and shell noted.
5. **OS-agnostic.** Windows, WSL, and Linux (including Arch / Omarchy) live side by side.

Confidence tags:

| Tag | Meaning |
|---|---|
| ✅ **Verified** | I ran it on this machine and saw it work |
| 📄 **Documented** | Stated in the vendor's / maintainer's own docs |
| ⚠️ **Reported** | Community reports; not yet reproduced here |
| 🧪 **Untested** | Inference or guess — flagged as such |

## The 6700 XT today (summary)

| Topic | Status | Confidence | Verified |
|---|---|---|---|
| AMD ROCm/HIP SDK on Windows | ❌ **Officially unsupported** (`gfx1031`) | 📄 | 2026-07-31 |
| `HSA_OVERRIDE_GFX_VERSION=10.3.0` | Still the common ROCm workaround | ⚠️ | 2026-10-10 |
| Vulkan (llama.cpp / LM Studio) | Works, no ROCm needed | ✅ | 2026-10-10 |
| Native Windows HIP (no WSL) | **Runs on `gfx1031`** via Unsloth's bundled ROCm 7.14 — no `HSA_OVERRIDE` needed | ✅ | 2026-10-10 |
| Unsloth on `gfx1031` | Bundled **ROCm/HIP** llama.cpp serves (inference proven); training unverified | ✅ / 📄 | 2026-10-10 |
| A **27 B** model on 12 GB | Runs via `--fit` hybrid offload — **≈4 tok/s** decode, ≈10.3 GB VRAM + ≈6.1 GB RAM | ✅ | 2026-10-10 |
| Strata (Qwen3.8-Flash-Next) | Runs via `--backend hip`, unvalidated | 📄 | 2026-10-10 |
| A local model as an *agent* (8B / 14B) | Passes bounded tasks, **fails open-ended event-log triage** | ✅ | 2026-10-10 |

Full detail in [`stack/`](stack/); provenance in [`sources.md`](sources.md).

## Repo map

```
6700xt-knowledge/
├── COMPACT.md                 # the constitution — 8 articles, ratified 2026-10-11
├── MINUTES.md                 # session minutes (the sitting record)
├── index.md                  # map + "last verified" dashboard
├── hardware/6700xt.md        # the card: gfx1031, 12 GB, no CUDA
├── stack/                    # one file per software component
│   ├── rocm-windows.md       # official status + HSA override
│   ├── vulkan.md             # the no-ROCm path
│   ├── hip.md                # native HIP paths
│   ├── llama-cpp.md          # llama serve vs llama-server.exe
│   ├── opencode.md           # drive local models from OpenCode (local/auto)
│   ├── unsloth.md            # train + bundled ROCm/HIP serving
│   ├── lmstudio.md
│   ├── ollama.md
│   ├── comfyui.md
│   └── strata.md
├── models/what-fits-12gb.md  # quant -> VRAM -> speed on 12 GB
├── recipes/                  # copy-paste setups
│   ├── native-windows-no-wsl.md
│   ├── vulkan-fallback.md
│   └── hip-override.md
├── scripts/windows/          # local-model launcher + elevation tools + OpenCode wiring
├── benchmarks/               # measured results (per machine)
├── log/                      # dated session logs
├── sources.md                # every URL + type + retrieved date
└── CONTRIBUTING.md
```

## Governance — read this first

This repo is more than technical notes. It is the **record of a working relationship**, governed by
a written constitution:

- [`COMPACT.md`](COMPACT.md) — 8 articles. The centerpiece is **Truth & Evidence**: never
  mislead, never fabricate a value, name the source of every constraint. Article II reserves
  un-delegated powers to the Principal and forbids silent elevation.
- [`MINUTES.md`](MINUTES.md) — the sitting record. Motions, dispositions, and honest labels on
  reconstructed history.

**Principal:** 6700XT (sole voting member) · **Agent:** Parliamentarian & Clerk (non-voting) ·
**6700XT GPU:** seat (non-voting) · **Quorum:** whenever the Principal is present.

> *Rules that were merely typed are not laws.* If a constraint is real, this project names its
> source — the OS, the account's token, a file — rather than dressing a preference as a prohibition.

## Using it with OpenCode

The repo ships an [`AGENTS.md`](AGENTS.md) and a skill
([`.opencode/skills/6700xt-expert/`](.opencode/skills/6700xt-expert/SKILL.md)) so that an OpenCode
agent reads this KB *before* answering 6700 XT / local-LLM questions, checks dates, and cites
sources. Clone the repo and open it in OpenCode — the rules travel with it.

OpenCode can also **run a local model itself**: see [`stack/opencode.md`](stack/opencode.md) and
[`scripts/windows/`](scripts/windows/) for a single static provider (`local/auto`) that connects to
whatever `llama-server` has loaded — no config edits per model.

## Contributing an "avenue of self-exploration"

Every new technique, tool, or version change gets its own dated entry. See
[`CONTRIBUTING.md`](CONTRIBUTING.md) for the format. Rule of thumb:

> If we had to look it up twice, it belongs here.

## Disclaimer

Independent community project. Not affiliated with AMD, Qwen, Unsloth, Strata, LM Studio, Ollama,
ComfyUI, Microsoft, or llama.cpp. Verify anything destructive before running it.

## License

[MIT](LICENSE).
