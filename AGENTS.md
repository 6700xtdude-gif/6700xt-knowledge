# AGENTS.md — maintaining the 6700 XT Knowledge Base

You are working inside a **living, source-cited knowledge base** about running local LLMs on the
AMD Radeon RX 6700 XT (`gfx1031`, RDNA 2, 12 GB) across Windows, WSL, and Linux.

## Non-negotiable rules

1. **Date every claim.** When you add or change a factual statement, add or update a
   `Verified: YYYY-MM-DD` note. Today's date is available in your environment context.
2. **Cite the source.** Every non-obvious claim gets an entry in `sources.md` (URL, type,
   retrieved date, what it supports) and an inline link or `[S#]` reference.
3. **Label confidence.** Use exactly: `✅ Verified` (ran it here) · `📄 Documented` (vendor docs) ·
   `⚠️ Reported` (community) · `🧪 Untested` (guess).
4. **Flag staleness.** If a fact's `Verified` date is more than ~30 days old, mark it
   `⚠️ STALE — re-verify`.
5. **Never overwrite history silently.** Corrections go in the relevant file *and* as a dated entry
   in `log/`. If we previously believed something wrong, say so.
6. **Primary sources win.** AMD docs, maintainer repos, release notes > blog posts > forum posts.
7. **Separate "the card" from "the software stack."** Hardware specs are stable; software changes
   weekly. Don't mix them.

## Style

- Markdown, one topic per file, kebab-case filenames.
- Commands are fenced with the language and note the OS/shell (`powershell`, `bash`).
- Keep the summary tables in `README.md` and `index.md` in sync when statuses change.

## Adding an "avenue of self-exploration"

Create `log/YYYY-MM-DD-<slug>.md` using the template in `CONTRIBUTING.md`, capture the raw commands
and output, then promote verified findings into the relevant `stack/` file and update the dashboard
in `index.md`.
