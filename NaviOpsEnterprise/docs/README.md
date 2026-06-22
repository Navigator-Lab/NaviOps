# docs/ — Living Memory & Artifacts (NaviOpsEnterprise)

This folder is the project's **living memory** (state) and **generated artifacts** (the work).

## Living memory (read these first on a fresh session)
- **`STATUS.md`** — where we are now (phase, health, run/login).
- **`learning/LEARNING_STATE.md`** — pedagogy/progress state (next lesson, lab state).
- `CHANGELOG.md` — dated, append-only history (each entry names its verification).
- `TODO.md` — prioritized backlog.
- `DECISIONS.md` — locked decisions + rationale.
- `DEFERRED.md` — parked items + revisit triggers.

## The pedagogy layer
- `learning/` — mission, the 12-section schema, roadmap, lessons, alignment, capstones, playbooks,
  career guides. Start at `learning/ROADMAP.md`.

## Operational artifacts (what every lesson produces)
- `runbooks/` — step-by-step "when this ticket comes in, do X".
- `troubleshooting/` — symptom → cause → fix decision guides.
- `kb/` — end-user-facing knowledge base articles.
- `tickets/` — the realistic ticket library (target 100+).
- `templates/` — ticket / KB / runbook / troubleshooting / incident-report / RCA templates.
- `reports/{EXP,PLAN}/` — Navi reports.

## The "update docs" protocol (after any meaningful change / on "update docs")
1. `CHANGELOG.md` ← dated entry (what changed · files · verification result).
2. `STATUS.md` ← refresh the snapshot.
3. `TODO.md` ← tick done / add / re-prioritize.
4. `DEFERRED.md` ← record anything parked (why + when to revisit).
5. `DECISIONS.md` ← append new decisions (rationale + rejected alternatives).
6. `learning/LEARNING_STATE.md` ← lesson/skill progress.
7. Sync the one-line state into agent memory (`MEMORY.md`).

Keep entries terse and factual. A fresh session must resume from `STATUS.md` +
`learning/LEARNING_STATE.md` with zero re-explanation.
