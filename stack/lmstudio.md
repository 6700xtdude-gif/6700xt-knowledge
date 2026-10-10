# LM Studio

**Verified:** 2026-10-10 · `⚠️ Reported`

LM Studio is the easiest GUI to sanity-check the 6700 XT, and it is a good fallback/reference point.
`[S6]`

## Engine behavior on this card

- LM Studio ships multiple runtimes (llama.cpp Vulkan, llama.cpp ROCm/HIP, and others).
- On the RX 6700 XT, community reports frequently show it selecting the **Vulkan** engine, which
  sidesteps the ROCm support gap. `⚠️ Reported`
- A ROCm/HIP runtime can sometimes be forced, but expect the `gfx1031` caveats.

## How to read its output

- The **runtime / backend** is shown in the model-load panel and in the server logs. Note which one
  it picks — that alone tells you whether ROCm is "working" on your card.
- Check the **GGUF** vs **MLX** distinction (MLX is Apple-only; irrelevant here).

## Why keep it around

- Fast way to answer "is this card healthy for inference?" before building anything.
- Its picks (Vulkan vs ROCm) corroborate what we see in llama.cpp.
- Easy **local server** toggle if you want a quick OpenAI-compatible endpoint for experiments.

## To verify on this machine

- [ ] Install LM Studio, load a 7–8B Q4 GGUF, record which backend it chooses and the tok/s.
- [ ] Compare against standalone llama.cpp Vulkan on the same model.
