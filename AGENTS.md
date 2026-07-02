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
  **Sole exception:** the report-reveal below — it *opens* the file you just wrote in the editor and
  changes nothing on disk, so it is allowed (and required) even in REPORT-ONLY modes.
- No auto-spend / no auto-send: never run paid APIs, live messaging, deploys, `git push`, or
  instance starts unprompted — surface the command for the user to run.
- HITL: risky / multi-file / irreversible work STOPS after PLAN for explicit approval before
  execution. Fast-path (act directly) only for low-risk, reversible, single-file changes.
- Back up before overwrite; confirm destructive/irreversible actions first.

## Routing
Map the user's words to intent + tier per `navi.md` §1/§3; print mode + tier + protocols on the boot
line. Reports go under `docs/reports/`, never the repo root.

## Reveal reports in the IDE (Always On — every mode, every agent)
Whenever you write a report file under `docs/reports/` — **any** mode (EXP · PLAN · DEBUG · VERIFY ·
REVIEW · ENUM · MENTOR), whether the mode was triggered explicitly or auto-detected — reveal it in
the editor as your **last step**, so the human sees it in view instead of a bare path:

```sh
.agent/bin/navi-reveal.sh "<abs-or-repo-path-to-the-report-you-just-wrote>"
```

- Run it **once**, after the file (and any INDEX row) is written. Pass the report path you just saved.
- **Best-effort / non-fatal** — the script self-resolves the Antigravity IDE CLI and exits 0 if none
  is found; never let it block or fail the task.
- This opens *your own* artifact (`-r`, current window) and mutates nothing — it is the allowed
  exception to REPORT-ONLY above, not a violation of it.
- This is not tied to typing "mentor"/"enum": if a report was produced, reveal it.
