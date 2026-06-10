# Decisions (ADR-lite)

Locked decisions + rationale. Append; don't rewrite history.

## D1 — NaviOps is a separate repo from Navi
**2026-06-10.** NaviOps is project-specific (AWS, CCNA, personal career roadmap), which
would violate Navi's own Hard Rule #1 (project-agnostic `.agent/`) if merged into the
Navi repo. NaviOps copies Navi's `.agent/` core unmodified and adds its own
`navi.project.md` + `docs/learning/`. *Rejected:* a `naviops/` subfolder inside
`Navigator-Lab/Navi`.

## D2 — Gate Rule lives in exactly one file
**2026-06-10.** `docs/learning/CLAUDE_TEACHING_RULES.md` is the single source of truth
for the 7-step Gate Rule. `PROJECT_MISSION.md` links to it instead of restating it, to
avoid drift between the two (the original 001/004 prompts both contained the full rule).
*Rejected:* duplicating the Gate Rule in both files.

## D3 — `LEARNING_STATE.md` uses placeholders for all infra/AWS facts
**2026-06-10.** Since NaviOps ships to a public repo and will accumulate 30+ days of
real infrastructure work, `LEARNING_STATE.md`'s "Current Infrastructure"/"Current AWS
State" sections mandate placeholders (`<ACCOUNT_ID>`, `10.0.x.x`, `<INSTANCE_ID>`) from
day 1, backed by a Gitleaks pre-commit hook. *Rejected:* redacting retroactively before
each push (error-prone over a long-running repo).
