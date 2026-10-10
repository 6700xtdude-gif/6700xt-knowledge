# 2026-10-10 — Wiring OpenCode to a local llama.cpp model (no config edits per model)

**Machine:** SANDBOX · Windows 11 Pro · RX 6700 XT `gfx1031` (driver `32.0.21045.5002`) · **no ROCm** ·
OpenCode Desktop **v2.0.26** · llama.cpp `b11541` Vulkan
**Goal:** Drive a locally served GGUF from OpenCode without hand-adding every model to OpenCode's config.
**Result:** ✅ works — one static provider `local/auto` reaches whatever is loaded on `:9931`; tool
calls and thinking suppression verified.

## Context

We can serve 4B/8B Q4 models on the card (see [`../benchmarks/2026-10-10-baseline.md`](../benchmarks/2026-10-10-baseline.md)),
but OpenCode lists models from its config, and adding a new provider/model entry for every GGUF we try
is exactly the kind of busywork this KB exists to eliminate. The question: can OpenCode connect to
"whatever happens to be running on localhost" with a **single** provider definition?

## Steps

```powershell
# 1. serve the 8B (Vulkan)
llama-server.exe -m Qwen3-8B-Q4_K_M.gguf -c 32768 -np 1 -ngl 99 -fa on `
  -ctk q8_0 -ctv q8_0 --jinja --reasoning off --host 127.0.0.1 --port 9931

# 2. does llama.cpp care about the requested model id?
curl http://127.0.0.1:9931/v1/chat/completions -d '{"model":"totally-bogus-model-xyz", ...}'

# 3. one static OpenCode provider (~/.config/opencode/opencode.jsonc) -> baseURL :9931/v1
# 4. verify OpenCode sees it, then use it end-to-end
opencode models
opencode run --model local/auto "Reply with exactly the single word: pong"
```

## Output

```
# /v1/chat/completions with a bogus model id
served_model = C:\Users\6700XT\llm\models\Qwen3-8B-Q4_K_M.gguf
content      = pong                # <-- id ignored, still served the loaded model

# tool-call probe (with --jinja), Qwen3 thinking off
finish_reason : tool_calls
tool_calls    : {"function":{"name":"get_weather","arguments":"{\"location\": \"Paris\"}"}}
completion_tk : 20

# thinking experiment
baseline (no flag)     -> reasoning_present True   completion_tokens 135
--reasoning-budget 0   -> reasoning_present False  completion_tokens   5
--reasoning off        -> reasoning_present False  completion_tokens   2

# OpenCode
$ opencode models | Select-String local
local/auto
$ opencode run --model local/auto "Reply with exactly the single word: pong"
pong
```

## Findings

- llama.cpp **ignores the request `model` field** — a bogus id returned the loaded model and answered
  correctly. One OpenCode provider therefore serves *any* loaded GGUF. `Verified: 2026-10-10`
- OpenCode **V2** config uses `providers` + `package: "@opencode/ai/providers/openai-compatible"` +
  `settings.baseURL`; model field shape is `capabilities`/`limit`. `Verified: 2026-10-10` `[S11]`
- OpenCode auto-discovers **Ollama / LM Studio / vLLM** only — llama.cpp needs a custom provider. `[S11]`
- `--jinja` gives working **OpenAI tool calls** on the 6700 XT (`finish_reason: tool_calls`).
  `Verified: 2026-10-10`
- Qwen3 **thinking** cost 135–205 tokens for trivial answers; `--reasoning off` drops it to 2–20 and
  keeps tool calls. `Verified: 2026-10-10`
- End-to-end `opencode run --model local/auto` returned a correct one-word answer. `Verified: 2026-10-10`

## Follow-ups

- [ ] Run a real multi-step agent task on the 8B and rate it (where does it break first?).
- [ ] Compare the same prompt on `--reasoning-budget 512` vs `off`.
- [ ] Port the launcher scripts to Linux/Omarchy (`llama-server` + a shell equivalent).
