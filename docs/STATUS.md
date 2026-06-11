# NaviOps — Status

**Updated:** 2026-06-11 · **Phase:** Day 1 — Lessons 01–02 retrofitted with the extended lesson schema (D10); Lesson 02 quiz/reflection still pending

## Health
| Check | State |
|-------|-------|
| Repo scaffold (`.agent/`, `.claude/`, `docs/`) | ✅ copied from Navi v28 core |
| `navi.project.md` | ✅ in place |
| `docs/learning/` pedagogy stack | ✅ PROJECT_MISSION, CLAUDE_TEACHING_RULES, LEARNING_STATE |
| `.gitignore` + Gitleaks pre-commit | ✅ in place |
| Git | ✅ local repo, 1 commit, **not pushed** |
| First lesson | ✅ Lesson 01 complete (all 8 Gate Rule steps, graded quiz) |

## What's true right now
- This is a **fresh Navi project**: open Claude Code here, run `/navi <request>`.
- Pedagogy state (skills, milestones, infra/AWS state) lives in
  `docs/learning/LEARNING_STATE.md` — read it alongside this file.
- The Gate Rule is now **8 steps**: Concept → Real-World Use → Alternatives → Hands-On
  → Verification → Quiz (graded, with Claude's professional-answer comparisons) →
  Reflection → Search Keywords For Further Understanding — see
  `docs/learning/CLAUDE_TEACHING_RULES.md`.
- **Schema extended (2026-06-11, D10):** 4 cross-cutting **Integration Lenses**
  (Three-Level Depth, Double-Explanation, Bash Automation, C/Systems Tie-In) now fire
  inside Steps 1 & 4 — merged from `01.md` (now removed). Lessons 01 and 02 retrofitted
  with all 4 lenses. See
  `docs/reports/EXP/EXP_REPORT_2026-06-11_Lesson-Schema-Integration-Lenses.md`.
- The roadmap (`docs/learning/PROJECT_MISSION.md`) was expanded (D5) with **Git &
  GitHub**, Ansible, GitHub Actions/CI, and Terraform/IaC — confirmed via WebSearch as
  baseline 2025-2026 junior SysAdmin/DevOps expectations.
- **Strategy locked (2026-06-10):** OS = AlmaLinux 9 (or Rocky) + Ubuntu LTS secondary;
  migration = VM-first hybrid (host never wiped); Docker Wk3, AWS Wk5–8 (6-mo Free-Plan
  clock), K8s deferred, RHCSA ~Day 75–120 skills-first; first-role target = Linux Support
  → Junior SysAdmin. Full reasoning + 30/90-day roadmap in
  `docs/reports/EXP/EXP_REPORT_2026-06-10_NaviOps-Career-Strategy.md` and
  `docs/reports/PLAN/PLAN_2026-06-10_Backup-Migration-and-30-90-Roadmap.md` (decisions D6–D9).
- **Hardware confirmed (2026-06-10):** Dell E6540 16 GB is the **only** laptop → VM-first is the
  only safe path; run VMs **headless** (1 always-on, 2 for networking labs, avoid 3). Apply-trigger
  roadmap M0–M4 added to the PLAN — start applying for Linux **Support** roles at ~Day 14, in waves.
- **Next action:** run **Phase A (3-2-1 backup + verify)** from the PLAN, then start
  **Lesson 02 — Git & GitHub Fundamentals** (`docs/learning/LEARNING_STATE.md` → "Next
  Lesson"). Hands-on task uses this NaviOps repo (branch + small change + PR + first push).

## RUN (local dev)
```bash
# In Claude Code, with this folder open:
/navi <plain-language request>
```

## Next / Deferred
See TODO.md · DEFERRED.md · `docs/learning/LEARNING_STATE.md`
