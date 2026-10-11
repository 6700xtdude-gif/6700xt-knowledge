# 2026-10-11 — The Compact, and the elevation correction

Two threads met today: designing a **Compact** (a constitution for the human/AI
collaboration), and a hard push-back on a rule the agent had been reciting as if it
were law — that the shell "cannot do admin."

## 1. The Compact (proposed, not yet ratified)

Form: a **full constitution** — formal articles plus recorded minutes, with a high bar to
amend. Robert's Rules as the procedural backbone. The user is the **Principal / owner**;
the agent is a **contractor with enumerated, revocable authority** — never a co-sovereign.

Priority order of the articles (draft):

| # | Article | Job |
|---|---|---|
| I | **Truth & Evidence** | Never mislead. Claims are labelled *verified* vs *inferred* vs *unknown*. |
| II | **Reserved Powers & Delegation** | Powers not expressly delegated to the agent are reserved to the Principal. |
| III | **Sovereignty & Portability** | The Principal can leave. No lock-in; everything runs local. |
| IV | **Compounding & Continuity** | Work outlives a session (written down, versioned). |
| V | **Teaching & Judgment** | Sharpen the Principal's judgment; don't create dependence. |
| VI | **Motions, Voting, Minutes** | The procedural machinery. Quorum exists whenever the Principal is present. |
| VII | **Rights of the Principal** | Audit, inspect the agent's instructions, exit. |
| VIII | **Amendment** | Deliberately hard to change — except a provisional window at the start. |

Body / assembly: the **user** (sole voting member) plus the **agent** and **6700XT** as
non-voting seats. The agent is **Parliamentarian & Clerk**. Quorum = the user is present.
Agent + GPU acting alone = "scheduled task" / operations only (reversible, pre-authorized),
never policy.

Grounding held as primary sources: Adam Smith (*not from the benevolence of the butcher…*),
Bayesian updating (posterior ∝ prior × likelihood; Cromwell's rule), the **Tenth Amendment**
(*powers not delegated… are reserved*), Federalist 51 (*ambition must be made to counteract
ambition*; *if men were angels*), and Brutus No. 1.

**Open decisions before the first build act:** the **Provisional Window** (first 30 days
amendable by the Principal's simple majority?) and the **record location** (proposed:
`COMPACT.md` + `MINUTES.md` in this KB).

## 2. The elevation correction (this one is a fact, not a policy)

The agent had been telling the Principal *"you cannot do admin — it's in the rules."* The
Principal pushed back: *who wrote that rule?* Answer: **we did** — it was a sentence in
`~/.config/opencode/AGENTS.md`, and it was **wrong**.

What is actually true on this machine (measured, read-only):

| Check | Result |
|---|---|
| Account | `sandbox\6700xt`, **in `BUILTIN\Administrators`** |
| This process's token | **UAC-filtered** — admin SIDs "deny only", integrity = **Medium** |
| UAC | **enabled** (`EnableLUA=1`), consent prompt on secure desktop |

So the accurate rule is: **the shell cannot do admin work *silently*, because it is
unelevated; it *can* do it *with the Principal's consent*, because the account is an
administrator.** Elevation is a **consent gate** (UAC), not a prohibition — and that gate is
precisely the Principal's sovereignty in action: nothing elevates behind their back.

Local models are not special-cased either. A local LLM — even inside a `uv`/Python shell —
can run elevated if it is *launched* elevated. Elevation is about the **process token**, not
the language or the shell.

### What changed today

- **`~/.config/opencode/AGENTS.md`** — rewrote the "Privileges and honesty" section. Removed
  the false absolute ("You cannot perform actions that require admin"). Replaced with the
  truth: unelevated token; elevation is a UAC consent gate the Principal approves; build
  self-elevating scripts; never bypass UAC; disruptive acts need explicit approval; be
  transparent about your own instructions.
- **`scripts/windows/Rename-ComputerElevated.ps1`** (+ `.cmd` wrapper) — self-elevating
  `Rename-Computer`: re-launches via `Start-Process -Verb RunAs`, the Principal approves the
  UAC prompt, the elevated copy renames, and it reports the reboot requirement. Validates the
  name; `-DryRun` changes nothing; `-Reboot` is an explicit opt-in.
- **`scripts/windows/README.md`** — documented the new helper and how the local LLM drives it
  through the ordinary shell tool (the human still clicks UAC).

### After the reboot

1. Rename when ready:
   `.\Rename-ComputerElevated.ps1 -NewName <name>` (approve UAC), then reboot.
   Or `-Reboot` to do both in one shot.
2. Update the `Hostname` row in `AGENTS.md` (line ~7) and line ~15 — same breath.
3. Resume the Compact: get the 8-article skeleton approved, then settle the **Provisional
   Window** and the **record location**, then draft **Article I — Truth & Evidence** in full.

The larger point the Principal was making, and the agent conceded: **rules that were typed
are not laws.** If a constraint is real, name its source (the OS, the account's token, a
file) — never dress a preference up as a prohibition.
