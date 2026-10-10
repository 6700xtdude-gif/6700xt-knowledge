# Local LLM launcher scripts (Windows)

Manually fire up a local model on the **RX 6700 XT** (llama.cpp / Vulkan) and have **OpenCode**
connect to it — without ever editing OpenCode config again.

## How it works

- `llama-server.exe` serves **one** model on `http://127.0.0.1:9931` and **ignores the `model` field**
  in OpenAI-compatible requests. So OpenCode can use a single static provider (`local/auto`) that
  works for *whichever* GGUF you have loaded.
- You switch models by re-running `Start-LocalLLM.ps1`, not by touching
  `~/.config/opencode/opencode.jsonc`.

## Files

| File | Purpose |
|---|---|
| `Start-LocalLLM.ps1` | Interactive menu of `C:\Users\6700XT\llm\models\*.gguf`; launches one and waits for `/health`. |
| `Stop-LocalLLM.ps1` | Stops llama-server. |
| `Status-LocalLLM.ps1` | Shows the loaded model, context, quant, and endpoint. |
| `Start-LocalLLM.cmd` / `Stop-LocalLLM.cmd` | Double-click wrappers (use these for pinned shortcuts). |

## Everyday use

```powershell
# Menu (pick by number)
.\Start-LocalLLM.ps1

# Straight to a model (any unique part of the filename)
.\Start-LocalLLM.ps1 -Model Qwen3-8B

# Tighter VRAM if you need headroom
.\Start-LocalLLM.ps1 -Model Qwen3-8B -Context 16384 -Kv q4_0

.\Status-LocalLLM.ps1
.\Stop-LocalLLM.ps1
```

Then in OpenCode: `/models` → **Local llama.cpp (RX 6700 XT)** → **Local model (auto)** (`local/auto`),
or from the CLI:

```powershell
opencode run --model local/auto "your prompt"
```

## Defaults chosen for the 12 GB card

| Flag | Value | Why |
|---|---|---|
| `-ngl 99` | all layers on GPU | 8B Q4 fits comfortably |
| `-c 32768` | 32K context | ~7.6 GB total at KV `q8_0`, ~4 GB free |
| `-ctk/-ctv q8_0` | 8-bit KV cache | small quality cost, big VRAM saving |
| `-fa on` | flash attention | enable; neutral for speed here |
| `--jinja` | model's chat template | required for OpenAI tool calls |
| `--reasoning off` | no thinking | Qwen3 otherwise spends hundreds of tokens thinking |

Pass `-Hidden` to suppress the server console, or `-NoStop` to leave an existing server running.

> Runtime folder is auto-detected: the newest `C:\Users\6700XT\llm\bin\llama-*` containing
> `llama-server.exe`. Override with `-LlamaDir <folder>`.
