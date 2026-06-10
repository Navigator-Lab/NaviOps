# NaviOps — Documentation & Memory System

`docs/` is the single source of truth for project state — the persistent memory across sessions.

| File | Answers | Update cadence |
|------|---------|----------------|
| STATUS.md | *Where are we now?* phase, health, run/login | every session |
| CHANGELOG.md | *What's done?* dated, append-only | when work completes |
| TODO.md | *What's next?* prioritized backlog + checklists | when scope changes |
| DEFERRED.md | *What's parked, and why?* revisit triggers | when deferring |
| DECISIONS.md | *Why built this way?* decisions + rationale | when deciding |
| reports/ | EXP / PLAN / DEBUG / VERIFY / REVIEW / PERF / UX artifacts | per task |

## The "update docs" protocol ⭐
On *"update docs"* (or after any meaningful change):
1. CHANGELOG ← dated entry (what changed · files · verification result)
2. STATUS ← refresh current snapshot
3. TODO ← tick / add / re-prioritize
4. DEFERRED ← record parked items (why + revisit)
5. DECISIONS ← append new decisions (rationale + rejected alternatives)
6. Sync one-line state into agent `MEMORY.md`

Terse, factual, dated (absolute dates). Every "done" names its verification. A fresh session must
resume from `STATUS.md` with zero re-explanation.
