# OpenCode — driving local models on the 6700 XT

**Verified:** 2026-10-10 · `✅ Verified`

OpenCode is the agent harness this KB is maintained with. On this machine it is the **desktop app
v2.0.26**. To point it at a locally served model you define **one** custom provider whose endpoint is
the llama.cpp server, and then switch models by relaunching the server — **not** by editing config.
`[S11]`

## The trick: one static provider, any loaded model

llama.cpp serves a single loaded model and **ignores the `model` field** in OpenAI-compatible
requests. Verified here: sending a deliberately bogus id (`totally-bogus-model-xyz`) still returned
the loaded model and a correct completion. So a provider with a single `auto` model works for
**every** GGUF you load. `✅ Verified: 2026-10-10`

Config lives at `~/.config/opencode/opencode.jsonc` — on this machine that is
`C:\Users\6700XT\.config\opencode\opencode.jsonc`.

**V2 shape:** `providers` (plural) + `package` + `settings`. The V1 `provider`/`npm`/`options` form
still loads, but new config should use the V2 shape. `[S11]`

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "providers": {
    "local": {
      "name": "Local llama.cpp (RX 6700 XT)",
      "package": "@opencode/ai/providers/openai-compatible",
      "settings": { "baseURL": "http://127.0.0.1:9931/v1", "apiKey": "not-needed" },
      "models": {
        "auto": {
          "name": "Local model (auto)",
          "modelID": "local",
          "capabilities": { "tools": true, "input": ["text"], "output": ["text"] },
          "limit": { "context": 32768, "output": 8192 }
        }
      }
    }
  }
}
```

Select it with `/models` → **local/auto**, or on the CLI:
`opencode run --model local/auto "…"`. `✅ Verified: 2026-10-10`

**Why not the built-in discovery?** OpenCode auto-discovers **Ollama, LM Studio, and vLLM** only;
llama.cpp is not on that list, so it needs a custom provider with an explicit model entry. `[S11]`

## Tool calling and thinking

- Run llama.cpp with **`--jinja`** and OpenAI tool calls work (`finish_reason: tool_calls`, correct
  JSON arguments). This is what lets a local model actually drive OpenCode's tools.
  `✅ Verified: 2026-10-10`
- Qwen3 is a *thinking* model. Left alone it burned **205 tokens to answer "pong"** and **114** for a
  one-tool call. `--reasoning off` cuts those to **2** and **20** tokens and still emits clean tool
  calls. Use `--reasoning off` for agentic use; `--reasoning-budget N` bounds thinking instead.
  `✅ Verified: 2026-10-10`

## Launcher scripts

Windows launchers live in [`../scripts/windows/`](../scripts/windows/). They wrap `llama-server.exe`
with the 6700 XT defaults (`-ngl 99`, `-fa on`, KV `q8_0`, `--jinja`, `--reasoning off`), wait for
`/health`, and print the OpenCode model reference.

| Script | Purpose |
|---|---|
| `Start-LocalLLM.ps1` | menu of `…\llm\models\*.gguf`; launches one on `:9931` |
| `Stop-LocalLLM.ps1` | stops the server |
| `Status-LocalLLM.ps1` | shows loaded model, context, quant, endpoint |

## Connecting OpenCode to a served model — including a 27B

**There is nothing to configure.** The `local` provider already targets
`http://127.0.0.1:9931/v1`, and llama.cpp ignores the request `model` id, so **`local/auto` works for
whatever the launcher loaded** — 4B, 8B, or the 27B. Serve on the default port and it just connects.
`✅ Verified: 2026-10-10`

```powershell
# 1. serve (see scripts/windows/README.md); 9931 is the default and matches the provider
.\Start-LocalLLM.ps1 -Model Qwen3.8-27B -Fit -FitCtx 32384 -Kv q8_0 -NoContextShift
# 2. drive it
opencode run --model local/auto "list the .gguf files in C:\Users\6700XT\llm\models, largest first"
```

In the app: `/models` → **Local llama.cpp (RX 6700 XT)** → **Local model (auto)**.

### Tuning for a slow (~4 tok/s) model

The 27B is ~15× slower to decode than the 8B. Two knobs keep OpenCode from hanging:

- **`limit.output`** — the config default is `8192`. At 4 tok/s a full 8192-token answer is **~34
  minutes**. Drop it (e.g. `2048`) so a runaway generation is bounded. This is exactly the
  runaway-generation failure mode seen in [`../log/2026-10-10-agentic-smoke-suite.md`](../log/2026-10-10-agentic-smoke-suite.md).
- **`headerTimeout` / `chunkTimeout`** — already `300000` ms (5 min) in this machine's config, which
  is generous enough for the first token on a big prompt.

Also keep **`--reasoning off`** for agentic use (tool calls); the 27B still responds well without
thinking, and thinking multiplies the slow decode time.

### Keep the context consistent

The provider declares `limit.context: 32768`. Keep the server at or below that — e.g.
`-Context 32768` with `-Fit -FitCtx 32384` leaves the effective window ≥ 32384 and ≤ 32768, so
OpenCode will not over-fill the slot. If you raise `-Context`, raise `limit.context` to match.

## References

- `[S11]` OpenCode V2 documentation (config, providers, models).

## To verify on this machine

- [x] OpenCode reaches a local llama.cpp model as `local/auto`. — ✅ 2026-10-10
- [x] `--jinja` tool calls surface in OpenCode. — ✅ 2026-10-10
- [ ] Drive OpenCode with the **27B** via `-Fit` and time a real multi-step task end-to-end.
- [ ] How well an 8B local model completes a real multi-step agent task vs a hosted model.
