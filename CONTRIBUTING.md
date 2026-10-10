# Contributing

This is a **living experiment**. The whole point is to capture what we learn on real 6700 XT
hardware before it evaporates, and to share it with other owners.

## Adding an "avenue of self-exploration"

When we try a new technique, technology, tool, or version change, we treat it as an experiment:

1. **Create a dated log**: `log/YYYY-MM-DD-<slug>.md`. Use the template below.
2. **Capture raw evidence**: exact commands, versions, and outputs. Paste real output, not a summary.
3. **Record a result**: works / fails / partial, plus numbers (tok/s, VRAM, temps).
4. **Promote verified findings** into the relevant `stack/` (or `hardware/`, `models/`, `recipes/`)
   file, with a `Verified:` date and a confidence tag.
5. **Update the dashboard** in `index.md` and the summary table in `README.md`.
6. **Add sources** to `sources.md`.

> If we had to look it up twice, it belongs here.

## Log template

```markdown
# YYYY-MM-DD — <short title>

**Machine:** <hostname> · <OS/version> · <GPU/driver> · <ROCm/version if any>
**Goal:** what we were trying to prove
**Result:** ✅ works / ⚠️ partial / ❌ fails — one line

## Context
Why this matters, what we expected, prior assumptions we are testing.

## Steps
```powershell
# exact commands
```

## Output
```
# key output (trimmed but real)
```

## Findings
- Fact. `Verified: YYYY-MM-DD` `[S#]`

## Follow-ups
- [ ] next thing to test
```

## Source discipline

`sources.md` rows: `| [S#] | URL | primary/repo/news/forum | retrieved YYYY-MM-DD | what it supports |`.

## OS coverage

Windows, WSL, and Linux are all first-class. When documenting a step, say which OS it applies to and
where behavior differs. **Arch / Omarchy Linux** findings are explicitly welcome — the goal is that
the KB can be cloned onto a reimaged machine and extended there.

## License

By contributing you agree your contributions are licensed under the repo's [MIT license](LICENSE).
