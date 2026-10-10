# Unsloth on the RX 6700 XT (`gfx1031`)

**Verified:** 2026-10-10 · `📄 Documented`

Unsloth is used in this project **only for training/export**, not as the inference runtime (we prefer
standalone llama.cpp for observability). `[S5]`

## Support claim

Unsloth's own documentation lists **RDNA 2 / `gfx1031` (RX 6700 XT) as "Full" support on Windows**
and claims it **auto-installs ROCm** for you — i.e. it does not make you satisfy AMD's official
support matrix. `[S5]`

> This is a **vendor claim**, and it runs counter to AMD's own unsupported status for `gfx1031`.
> It is the single most important thing to verify on this machine. `⚠️ Reported`

## What the app is

- **Unsloth Desktop / Studio** is a **Tauri** desktop app.
- It provisions a **uv-managed Python environment** for training dependencies.
- It **bundles its own llama.cpp** builds (including ROCm prebuilts) rather than using yours.
- Default install / history location: `C:\Users\<user>\.unsloth\studio`. `Verified: 2026-10-10` (path)

## Serving and OpenCode

- Unsloth can serve a model over **two API shapes on one port**: OpenAI-style
  (`/v1/chat/completions`) **and** Anthropic-style (`/v1/messages`), using **`sk-unsloth-` keys**.
- `unsloth start opencode` wires OpenCode to that local server.
- Custom-provider base URL for OpenCode: **`http://localhost:8888/v1/`** (verify the port in the app).
- When driving OpenCode, start the server with **`--disable-tools`** so the model doesn't try to use
  its own tools and fight OpenCode's. `📄 Documented` `[S5]`

## The observability gap (why we still use llama.cpp)

Unsloth's built-in server abstracts away the exact llama.cpp flags (context, KV-cache bits,
flash-attn). For this project's requirement — "see how the model launches" — export the trained model
to **GGUF** and serve it with standalone llama.cpp where every flag is visible. See
[`llama-cpp.md`](llama-cpp.md).

## Training tier for 12 GB

Start at **3–4B** (very comfortable on 12 GB). See [`../models/what-fits-12gb.md`](../models/what-fits-12gb.md).

## To verify on this machine

- [ ] Does Unsloth Desktop detect `gfx1031` and complete a tiny QLoRA run?
- [ ] Which ROCm version does it install, and does it work without `HSA_OVERRIDE_GFX_VERSION`?
- [ ] Does its GGUF export load in standalone llama.cpp unchanged?
