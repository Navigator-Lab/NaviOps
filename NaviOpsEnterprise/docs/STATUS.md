# STATUS — NaviOpsEnterprise

> Where the project is *right now*. Read this first (with `docs/learning/LEARNING_STATE.md`) on
> every fresh session. Refresh after meaningful change.

- **Phase:** ✅ **v1 COMPLETE** — all 36 lessons (9 modules) + 3 capstones authored full-depth.
- **Health:** 🟢 green — full platform: scaffolding, governance, schema, all guides/playbooks, lessons
  01–36, capstones, `infra/` lab notes, ticket + KB libraries.
- **Run/login:** open this folder in Claude Code → `/navi <request>`. Lab build notes in `infra/README.md`.

## Snapshot
- **Navi core** (`.agent/`) copied unmodified from NaviOpsSec (v28).
- **Project Law** (`navi.project.md`) written: Windows/M365/AD-first, 6-artifact contract,
  diagnostic-spine Hard Rule, danger zones for AD/GPO/M365/offboarding.
- **Pedagogy layer** complete: `CLAUDE_TEACHING_RULES.md` (12-section IT-Support schema),
  `ROADMAP.md` (36 lessons), `PROJECT_MISSION.md`, `LEARNING_STATE.md`.
- **Guides** complete: ROLE-MAPPING, CERTIFICATION-MAPPING, INTERVIEW-PREP, PORTFOLIO-GUIDE,
  LINKEDIN-GUIDE, SYSADMIN-PATH, HELPDESK-PLAYBOOK, IT-SUPPORT-PLAYBOOK.
- **Lessons authored:** 01–36 (full 12-section) + 3 capstones. **Curriculum complete.**
- **Libraries:** `docs/tickets/` (103 defined; ENT-01/02/03 standalone files; ENT-04–33 worked inline in
  their lessons) and `docs/kb/` (**all 10 named articles KB-0001…0010 published** + KB-0101 example).
- **Learner workspace ready:** `docs/runbooks/`, `docs/troubleshooting/`, `scripts/` each have a "what you
  produce here" guide (the per-lesson §9 deliverables — intentionally empty for the learner to build).
- **Link integrity:** all internal markdown links resolve (verified). Nothing dangling for a fresh learner.
- **Lab:** `infra/README.md` build notes (DC01 AD/DNS/DHCP, FS01 file server, CLIENT01, M365 dev-tenant).

## Next actions (v1 done — these are optional enhancements)
1. (Optional) Backfill the remaining standalone KB/ticket files; per-milestone PORTFOLIO.md roll-ups.
2. (Optional) **Commit** when the operator asks (git init done; commit/push is user-triggered).
3. The operator now studies/executes lessons 01→36 in order; update LEARNING_STATE as they progress.

## Links
- Pedagogy state: `docs/learning/LEARNING_STATE.md`
- What/where: `docs/learning/ROADMAP.md` · How taught: `docs/learning/CLAUDE_TEACHING_RULES.md`
