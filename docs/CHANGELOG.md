# Changelog

Dated, append-only. Newest first. Every entry names its verification.

## 2026-06-11
- **Lesson schema extended with 4 Integration Lenses** (Three-Level Depth,
  Double-Explanation, Bash Automation, C/Systems Tie-In), merging `01.md`'s 7 rules
  into `docs/learning/CLAUDE_TEACHING_RULES.md` (new Top-Level Rule 11 + Integration
  Lenses section, Steps 1/4/6 annotated). Backed by an EXP with 5 WebSearch sources
  (Bloom's Taxonomy, C-via-Linux-internals curricula, Feynman/dual-coding,
  scenario-based assessment) — `docs/reports/EXP/EXP_REPORT_2026-06-11_Lesson-Schema-Integration-Lenses.md`.
  Updated `PROJECT_MISSION.md` (new Systems Programming/C row) and
  `LEARNING_STATE.md` (new C/Linux Internals skill area + knowledge section).
  Retrofitted Lesson 01 (apartment-keys analogy, `stat()`/`st_mode` syscall tie-in,
  setuid-audit automation note) and Lesson 02 (save-game/photo-album analogy,
  `.git/objects` content-addressable-store tie-in, `git-health-check.sh` automation
  note) with all 4 lenses. Logged D10. `01.md` removed (content fully absorbed).
  · **Verify:** `grep -c "^### Step" docs/learning/CLAUDE_TEACHING_RULES.md` → 8;
  `grep -c "^### Lens" docs/learning/CLAUDE_TEACHING_RULES.md` → 4; `01.md` no longer
  present at repo root.

## 2026-06-10
- **Career & infrastructure strategy** delivered as an EXP + PLAN
  (`docs/reports/EXP/EXP_REPORT_2026-06-10_NaviOps-Career-Strategy.md`,
  `docs/reports/PLAN/PLAN_2026-06-10_Backup-Migration-and-30-90-Roadmap.md`): OS recommendation
  (AlmaLinux/Rocky + Ubuntu), VM-first migration with 3-2-1 backup, home-lab architecture,
  NaviOps technical architecture, skills-gap analysis, hiring-market ranking, interview/portfolio
  strategy, cert strategy, and a 30/90-day roadmap. Grounded in 5 WebSearches (RHEL≈43% server
  share, AWS Free-Tier 2025 overhaul, RHCSA ROI, entry-Linux market). Logged D6–D9.
  · **Verify:** both report files exist under `docs/reports/{EXP,PLAN}`; `docs/DECISIONS.md` has D6–D9.
- Bootstrapped NaviOps from Navi v28 core (`.agent/`, `.claude/`, `docs/` templates) +
  generated `docs/learning/` pedagogy stack (PROJECT_MISSION, CLAUDE_TEACHING_RULES,
  LEARNING_STATE) from the original 001-004.md bootstrap prompts (archived in
  `docs/learning/prompts/`). Added `.gitignore` + Gitleaks pre-commit hook.
  · **Verify:** `git log --oneline` shows 1 commit; `find` confirms full skeleton present.
- Completed **Lesson 01 — Linux Filesystems & Permissions**
  (`docs/learning/lessons/01-linux-filesystems-permissions/README.md`): all 8 Gate
  Rule steps, including graded quiz (5/8 fully correct, 3/8 with professional-answer
  corrections) and Search Keywords section.
  · **Verify:** lesson file has Step 1–8 sections, Lesson Status all checked.
- Extended the **Gate Rule to 8 steps** in `CLAUDE_TEACHING_RULES.md`: Step 6 (Quiz) now
  requires Claude to write a "Professional Answer" comparison under each learner
  answer; new Step 8 requires a "Search Keywords For Further Understanding" section.
  Updated cross-references in `PROJECT_MISSION.md` and `docs/DECISIONS.md` (D4).
  · **Verify:** `grep -c "^### Step" docs/learning/CLAUDE_TEACHING_RULES.md` → 8.
- WebSearch research (navi-research subagent, 13 sources) confirmed Git/GitHub,
  Ansible, GitHub Actions/CI, Terraform/IaC, and secrets management are baseline
  2025-2026 junior Linux SysAdmin/DevOps expectations. Added these to
  `PROJECT_MISSION.md`'s skills table, milestones, and Junior DoD; logged as D5 in
  `docs/DECISIONS.md`. Git/GitHub Fundamentals is now Lesson 02.
  · **Verify:** `docs/learning/PROJECT_MISSION.md` skills table includes "Git & GitHub"
  row; `docs/DECISIONS.md` has D5.
