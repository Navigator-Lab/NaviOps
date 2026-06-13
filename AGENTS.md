# Navi — Agent Operating Rules (Always On)

> Cross-tool rules file (Antigravity · Claude Code · Cursor). In Antigravity, add this in the Rules
> panel as a **Workspace** rule set to **Always On**. It is a *loader + safety kernel*, not a copy of
> the protocols — the `.agent/` files are the single source of truth. Do not hardcode versions or
> protocol text here; reference the files.

Before any non-trivial task: READ `.agent/workflows/navi.md` first — it is the single source of
truth (version, boot line, intent routing, tiers). Then emit its boot line. Anchor:
`.agent/protocols/ADR-P00-Master-Rule.md`. Project law: `navi.project.md`. Never restate protocol
contents from memory — open the file.

## Safety (non-negotiable — these OVERRIDE auto-continue)
- REPORT-ONLY modes — ENUM, EXP, REVIEW, VERIFY produce a *report file*. They do NOT execute,
  re-run, or "fix" the user's command, and do NOT mutate the filesystem. ENUM → write the 5-section
  card to `docs/reports/enum/` and hand the user the corrected command; never run it (ADR-P12 Rule 0).
- No auto-spend / no auto-send: never run paid APIs, live messaging, deploys, `git push`, or
  instance starts unprompted — surface the command for the user to run.
- HITL: risky / multi-file / irreversible work STOPS after PLAN for explicit approval before
  execution. Fast-path (act directly) only for low-risk, reversible, single-file changes.
- Back up before overwrite; confirm destructive/irreversible actions first.

## Routing
Map the user's words to intent + tier per `navi.md` §1/§3; print mode + tier + protocols on the boot
line. Reports go under `docs/reports/`, never the repo root.
