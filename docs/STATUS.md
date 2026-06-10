# NaviOps — Status

**Updated:** 2026-06-10 · **Phase:** Day 0 — Bootstrap (repo scaffolded, no lessons started)

## Health
| Check | State |
|-------|-------|
| Repo scaffold (`.agent/`, `.claude/`, `docs/`) | ✅ copied from Navi v28 core |
| `navi.project.md` | ✅ in place |
| `docs/learning/` pedagogy stack | ✅ PROJECT_MISSION, CLAUDE_TEACHING_RULES, LEARNING_STATE |
| `.gitignore` + Gitleaks pre-commit | ✅ in place |
| Git | ✅ local repo, 1 commit, **not pushed** |
| First lesson | ⬜ not started |

## What's true right now
- This is a **fresh Navi project**: open Claude Code here, run `/navi <request>`.
- Pedagogy state (skills, milestones, infra/AWS state) lives in
  `docs/learning/LEARNING_STATE.md` — read it alongside this file.
- The Gate Rule (Concept → Real-World Use → Alternatives → Hands-On → Verification →
  Quiz → Reflection) governs every lesson — see `docs/learning/CLAUDE_TEACHING_RULES.md`.
- **Next action:** pick the first lesson topic (Linux filesystems/permissions is the
  natural Day 1 per `PROJECT_MISSION.md` roadmap) and run it through the Gate Rule into
  `docs/learning/lessons/01-<topic>/README.md`.

## RUN (local dev)
```bash
# In Claude Code, with this folder open:
/navi <plain-language request>
```

## Next / Deferred
See TODO.md · DEFERRED.md · `docs/learning/LEARNING_STATE.md`
