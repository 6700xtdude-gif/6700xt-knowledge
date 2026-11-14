# 2026-11-13 — Why Strata's MTP drafts were 0 of 0 (and the ~1.7× we left on the table)

**Machine:** 6700XT · Windows 10.0.26300 · AMD Radeon RX 6700 XT (`gfx1031`, 12 GB) / 6 cores / 64 GB

**Goal:** Explain `drafts accepted 0 of 0` in the Strata engine log while `--mtp 2` was set, and measure
whether the fix upstream describes (a strictly greedy request) actually produces drafts here.

**Result:** ✅ explained and measured. The engine drafts only for a strictly greedy request; the server
fills in the model card's sampling (`temperature 1.0`, `presence_penalty 1.5`) when a request names none.
On this card, the same prompt goes from **~26 tok/s to ~43 tok/s** with the four greedy fields set.

**Context:** The 2026-11-13 verification log recorded `drafts accepted 0 of 0` as an open anomaly and
listed "report it upstream" as a follow-up. Reading the upstream issue tracker first showed it is already
tracked (#3354, open) and was closed once as not-an-engine-bug (#5609), with the gate named in the source.
So the anomaly was ours to test, not to file.

**Steps:**

```powershell
# The app's server is not on 8080. Find the port and the key in the run config it wrote:
Get-Content 'C:\Users\6700XT\.strata\data\native-instances\59f33a13-5ac4-4c2c-87cf-385c85ceb4f4.json' -Raw

# Health check (the app's server requires the key from that config):
$cfg = Get-Content 'C:\Users\6700XT\.strata\data\native-instances\59f33a13-5ac4-4c2c-87cf-385c85ceb4f4.json' -Raw | ConvertFrom-Json
$h = @{ Authorization = "Bearer $($cfg.api_key)" }
Invoke-RestMethod -Uri 'http://127.0.0.1:18500/v1/models' -Headers $h   # -> qwen36-ud-q4_k_xl, qwen3.6-35b-a3b-ud-q4_k_xl

# A: request that names no sampling   B: the same with strict greedy fields
$bodyA = @{ model='qwen36-ud-q4_k_xl'; messages=@(@{role='user';content='Write one paragraph about the number 6700 and graphics cards.'}); max_tokens=128 } | ConvertTo-Json -Depth 5
$bodyB = @{ model='qwen36-ud-q4_k_xl'; messages=@(@{role='user';content='Write one paragraph about the number 6700 and graphics cards.'}); max_tokens=128; temperature=0; top_p=1.0; presence_penalty=0; frequency_penalty=0; repetition_penalty=1 } | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri 'http://127.0.0.1:18500/v1/chat/completions' -Method Post -Headers $h -Body $bodyA
Invoke-RestMethod -Uri 'http://127.0.0.1:18500/v1/chat/completions' -Method Post -Headers $h -Body $bodyB

# Then read what the engine logged for each request:
Get-Content 'C:\Users\6700XT\AppData\Local\Strata\install\strata-qwen36-ud-q4_k_xl.log' -Tail 10
```

**Output (raw, four interleaved pairs; A then B each round, 128 generated tokens):**

```
strata serve: session 0: prompt 25 tokens = 0 reused + 25 read in 468 ms (53.4 tok/s), 128 generated in 5669 ms (22.6 tok/s), drafts accepted 0 of 0 (length)
strata serve: session 0: prompt 25 tokens = 0 reused + 25 read in 318 ms (78.5 tok/s), 128 generated in 3031 ms (42.2 tok/s), drafts accepted 81 of 96 (length)
strata serve: session 0: prompt 22 tokens = 0 reused + 22 read in 380 ms (57.9 tok/s), 128 generated in 5011 ms (25.5 tok/s), drafts accepted 0 of 0 (length)
strata serve: session 0: prompt 22 tokens = 0 reused + 22 read in 257 ms (85.6 tok/s), 128 generated in 2936 ms (43.6 tok/s), drafts accepted 78 of 102 (length)
strata serve: session 0: prompt 19 tokens = 0 reused + 19 read in 217 ms (87.4 tok/s), 128 generated in 4657 ms (27.5 tok/s), drafts accepted 0 of 0 (length)
strata serve: session 0: prompt 19 tokens = 0 reused + 19 read in 233 ms (81.6 tok/s), 128 generated in 3018 ms (42.4 tok/s), drafts accepted 78 of 98 (length)
strata serve: session 0: prompt 22 tokens = 0 reused + 22 read in 273 ms (80.6 tok/s), 128 generated in 4728 ms (27.1 tok/s), drafts accepted 0 of 0 (length)
strata serve: session 0: prompt 22 tokens = 0 reused + 22 read in 238 ms (92.6 tok/s), 128 generated in 2989 ms (42.8 tok/s), drafts accepted 74 of 106 (length)
```

**Findings:**

- ✅ **Verified: 2026-11-13** `[S24]` Default request: 22.6 / 25.5 / 27.5 / 27.1 tok/s, `drafts accepted 0 of 0`.
- ✅ **Verified: 2026-11-13** `[S24]` Strict greedy request: 42.2 / 43.6 / 42.4 / 42.8 tok/s, 74–81 drafts
  accepted of 96–106 offered (72–84 %).
- ✅ **Verified: 2026-11-13** The same model, engine, context and prompt shape differ by **~1.7×** decode on
  this card with nothing but four sampling fields. `[S24]`
- 📄 **Documented** `[S22]` `[S23]` Cause: `needs_logits()` is true whenever `temperature > 0`, `repeat != 1`,
  `freq != 0` or `present != 0`; the q36 engine drafts only when it is false. The server applies the model
  card's sampling when the request names none, so a plain OpenAI request never drafts.
- ✅ **Verified: 2026-11-13** `[S25]` The app-launched server listens on **18500**, from its run config — not
  8080. The earlier claim of 8080 holds only for the helper `.bat`, which passes `--port 8080`.
- ⚠️ **Reported** `[S22]` An opt-in `STRATA_Q36_MTP_SAMPLED=1` (#3773) makes sampled requests draft too; not
  tested here.
- ⚠️ The first prompt of a session was not cached (`0 reused`), so these are cold short-prompt numbers. The
  ~43 tok/s figure is decode only and 128 tokens long.

**What this corrects:** the earlier ~18–20 tok/s figure was the **no-draft** rate on 11–23 K-token prompts.
Long prompts still cost the prefill; decode is ~26 tok/s by default and ~43 tok/s greedy at a short context.
Do not quote "18–20 tok/s" as Strata's ceiling on this card.

**Follow-ups:**

- [x] Explain `drafts accepted 0 of 0` → model-card sampling; already tracked upstream (#3354).
- [ ] Confirm ~43 tok/s on a 1–2 K token generation (drafts may decay as the window grows).
- [ ] Test whether putting a `sampling` block in the app's run config makes the app's own chat path greedy,
      which is the documented workaround in #3354.
- [ ] Do **not** file a new MTP issue: #3354 covers it and #5609 was closed with the same cause. If anything,
      add this Windows/`gfx1031` data point to #3354.

**Sources:** `[S22]`–`[S26]` in [`../sources.md`](../sources.md)
