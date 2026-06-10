# Changelog

Dated, append-only. Newest first. Every entry names its verification.

## 2026-06-10
- Bootstrapped NaviOps from Navi v28 core (`.agent/`, `.claude/`, `docs/` templates) +
  generated `docs/learning/` pedagogy stack (PROJECT_MISSION, CLAUDE_TEACHING_RULES,
  LEARNING_STATE) from the original 001-004.md bootstrap prompts (archived in
  `docs/learning/prompts/`). Added `.gitignore` + Gitleaks pre-commit hook.
  · **Verify:** `git log --oneline` shows 1 commit; `find` confirms full skeleton present.
