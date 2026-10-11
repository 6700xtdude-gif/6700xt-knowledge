# MINUTES — The Compact Body

**Record of:** the governing body for this machine's human/AI collaboration
**Constitution:** [`COMPACT.md`](COMPACT.md) · **Sources:** this file
**Location rule:** all records live in this KB, versioned and pushed (Compact Art. IV)

---

## Session 1 — Design of the Compact

**Date:** 2026-10-10 23:09 → 2026-10-11 01:57
**Session record:** `ses_ed6d94785ffem90XBcUDhUD7j9` — "Project landscape and status overview"
**Quorum:** present (Principal). **Chair:** Agent (Parliamentarian & Clerk, non-voting).
**Minutes status at time of writing:** *no minutes were filed for this session.* The record below
was reconstructed on 2026-10-11 from the session database after the fact. See the honesty note.

### Objective
Design a governing constitution for the collaboration between the Principal and the Agent over
their local AI and computing tools, using **Robert's Rules of Order** as the procedural backbone,
grounded in Adam Smith, Bayesian decision theory, the U.S. Constitution and Tenth Amendment, and
the Federalist/Anti-Federalist Papers.

### Requirements established
- The **Principal / owner** holds sovereignty. The **Agent** is a *contractor with enumerated,
  revocable authority* — never a co-sovereign.
- The primary risk to prevent above all: **being misled.** Truth & Evidence is the centerpiece.
- Goals: **sovereignty, durable capability, a method others can adopt, sharper judgment.**
  (The Principal explicitly did *not* select "energy back / save time.")
- Scope: the Principal's **local AI and computing tools** — not their whole life or finances.
- Form: a **full constitution** — formal articles plus recorded minutes, with a high bar to amend.
- The Agent serves as **parliamentarian**: formulate plans, present them, await approval.

### Decisions taken
| # | Decision |
|---|---|
| D-1 | Assembly = Principal, with Agent and 6700XT as **non-voting seats**. |
| D-2 | **Quorum exists whenever the Principal is present.** The Principal is the sole voting member. |
| D-3 | Agent + GPU acting alone = "scheduled task" / operations only — reversible, pre-authorized — **never policy.** |
| D-4 | KB scripts are canonical; duplicate `llm\scripts` deleted; clutter archived, not deleted. |
| D-5 | Design philosophy: structural checks not trust (Madison); reserved powers (Tenth Amendment); do not rely on benevolence (Smith); confidence scaled to stakes (Bayesian). |

### Proposed but NOT ratified at this session
An **8-article Compact** was drafted and presented (I. Truth & Evidence · II. Reserved Powers &
Delegation · III. Sovereignty & Portability · IV. Compounding & Continuity · V. Teaching &
Judgment · VI. Motions/Voting/Minutes · VII. Rights of the Principal · VIII. Amendment). It was
**never approved**; two questions were left unanswered:
1. **Provisional Window** — whether the first 30 days allow amendment by simple majority.
2. **Record location** — where `COMPACT.md` / `MINUTES.md` should live.

### Work completed this session
- Project landscape surveyed and reported.
- Tidy-up executed and verified: KB ledger updated, commit `59599a0` pushed, tag `v0.1`.
- Duplicate `llm\scripts` deleted after hash-verifying contents identical; pointer README created.
- Clutter archived to `Documents\_archive` and `Downloads\_installers`. **Nothing deleted.**
- Launcher re-verified via `-DryRun`.
- Research homework completed (Smith, Bayes, Tenth Amendment, Federalist 51, Brutus No. 1).
- Five vision-eliciting questions asked and answered.

### Substantive findings recorded (all independently re-verified 2026-10-11)
- **Elevation is a consent gate, not a prohibition.** The account is in `BUILTIN\Administrators`;
  the ordinary shell token is merely UAC-filtered (Medium integrity). The Agent had been reciting
  a false absolute rule, which it corrected in `~/.config/opencode/AGENTS.md`.
- **The local model fabricates system values.** Asked for the hostname three times it answered: a
  random UUID, `workstation`, `DESKTOP-XXXXXX`. Truth was `SANDBOX` all three times. This is the
  empirical basis for Article I.
- **The local model cannot rename the PC from an unelevated shell** — but it *can* be given an
  elevated token by launching its host elevated (resolved in Session 2 below).

### Honesty note (Art. I)
These minutes were **reconstructed after the fact**, not recorded live. The original session left
no filed minutes; its only durable trace was an automatic compaction summary inside OpenCode's
session database. If that database is lost, the original record is lost. That gap is precisely
what Article IV (Compounding & Continuity) exists to prevent, and it is why this file exists now.

---

## Session 2 — Elevation of the local LLM

**Date:** 2026-10-11
**Session record:** `ses_ed63fe2ebffeQdOm6hXGjuF7lk` — "Review Markdown files across folders"
**Quorum:** present (Principal). **Motion carried by the Principal as sole voting member.**

### New business
The Principal directed that the **local LLM be able to run elevated**, and that the backlog be
packed up and recorded.

### Motion as put
> "Make it so local llm can run elevated … all in favor say AYE … the AYES have it, motion passes.
> Motion to accept last meeting minutes and new business."

**Disposition:** **Carried.** The Principal is the sole voting member and was present, so quorum was
satisfied. Recorded here by the Clerk.

### Also accepted
**Motion to accept the Session 1 minutes** — carried; those minutes are recorded above.

### Action taken
1. **New:** `scripts/windows/Start-UnslothElevated.ps1` (+ `.cmd`) — self-elevating launcher that
   starts Unsloth Studio with a High-integrity token via `Start-Process -Verb RunAs`.
2. **Updated:** `scripts/windows/SYSTEM-PROMPT.txt` — replaced the "you run UNELEVATED and cannot
   do admin work" opening with **rule 0**, which makes the model *test its own elevation* rather
   than assume either way, and re-states that elevation grants authority, **not knowledge**.
3. **New:** `COMPACT.md` — the 8 articles, ratified.
4. **New:** this file.

### Verified at time of writing
| Check | Result |
|---|---|
| `Start-UnslothElevated.ps1` parses | ✅ 0 parser errors |
| `-DryRun` executes | ✅ detects Studio at `%LOCALAPPDATA%\Unsloth Studio (Desktop)\unsloth-studio.exe` |
| Integrity reporting | ✅ reads `Medium` unelevated (matches `whoami /groups`) |
| Script elevates nothing in `-DryRun` | ✅ confirmed |

### Deliberately NOT done, and why
- **No UAC bypass.** Elevation is requested through the standard consent prompt. The Principal
  approves. Suppressing or auto-answering that prompt would convert a consent gate into a
  privilege-escalation hole, which is contrary to Article II.
- **No silent auto-elevation.** There is no scheduled task, no service, and no registry tweak that
  grants elevation without a human click.
- **The computer was not renamed.** That remains the Principal's decision under Article VII, and
  requires a reboot.

### Standing risk to record (Art. I, Art. II)
While Studio runs elevated, the local model holds **real administrative authority over this
machine**. That is the intended effect. It also means Article I is load-bearing: the model
demonstrably fabricates system values. Elevation increases what a wrong answer can *do*. The
mitigation is rule 0 and rule 1 of `SYSTEM-PROMPT.txt`, plus the Principal's right to audit.

### Open items carried forward
- [ ] Record location — **resolved**: this KB, versioned and pushed (`COMPACT.md`, `MINUTES.md`).
- [ ] Provisional Window — **resolved** in Article VIII: first 30 days, simple majority.
- [ ] Commit and push the outstanding work (`c5db6b4`, plus the new files).
- [ ] Decide the new computer name (still `SANDBOX`); a reboot is required to apply it.