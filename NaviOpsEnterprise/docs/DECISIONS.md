# DECISIONS — NaviOpsEnterprise (ADR-lite)

Locked decisions + rationale + rejected alternatives.

## D1 — One platform, lesson-per-folder, mirrors the siblings
**Decision:** NaviOpsEnterprise follows the exact NaviOps/NaviOpsNetwork/NaviOpsSec structure
(single repo, `docs/learning/lessons/NN-topic/README.md`, governance docs, alignment, capstones).
**Why:** proven, consistent across the four-platform bridge, transferable habits.
**Rejected:** a multi-repo or course-platform app — overkill, breaks the build-in-public portfolio.

## D2 — Lesson schema canonical in ONE file
**Decision:** the 12-section IT-Support schema lives only in `CLAUDE_TEACHING_RULES.md`; everything
else links to it. **Why:** single source of truth; no drift. **Rejected:** restating the schema in
README/ROADMAP.

## D3 — GUI-first, then PowerShell/CLI, then cloud admin center
**Decision:** teach the Windows GUI/console first (how a tech works on the floor), then the
PowerShell that scales, then the M365/Workspace admin center. **Why:** matches the actual day-one
job (Windows/M365-heavy), unlike the Linux-first siblings. **Rejected:** CLI-first (wrong for the
help-desk audience) and GUI-only (doesn't scale or impress).

## D4 — The diagnostic spine is mandatory (Hard Rule #4)
**Decision:** every troubleshooting topic (§5) carries Symptoms → Possible Causes → Diagnostic
Steps → Resolution Steps → Escalation Criteria → Post-Incident Documentation. **Why:** it *is* the
operational skill employers hire for. **Rejected:** ad-hoc "here's the fix" lessons.

## D5 — 6-artifact contract per lesson
**Decision:** Runbook, Troubleshooting Guide, Ticket Notes, KB Article, Incident Report, Portfolio
Artifact (+ script where automatable). **Why:** maps the spec's required outputs; builds the
portfolio as a byproduct. **Rejected:** lesson-only write-ups with no artifacts.

## D6 — Phased build, full depth per delivered lesson
**Decision:** build the foundation first, then lessons in waves; "no placeholder/unfinished"
applies per *delivered* lesson, not "all 36 at once." **Why:** 15k+ lines at the sibling quality
bar can't be one turn; quality per lesson beats a thin sweep. **Rejected:** stubbing all 36
shallowly (violates the spec's "no unfinished lessons").

## D7 — Global libraries in addition to per-lesson examples
**Decision:** `docs/tickets/` (100+ ticket library) and `docs/kb/` (the named KB set) exist as
standalone reference collections; lessons also produce their own ticket-sim + KB as worked
teaching examples. **Why:** the spec lists both; they serve different purposes (reference vs
teaching). **Rejected:** only per-lesson tickets (misses the "100+ ticket library" deliverable).

## D8 — Public-repo discipline, lab-only, placeholder identities
**Decision:** `corp.example`, RFC 1918, placeholder users/assets; no real tenant/employer/PII data.
**Why:** this ships to GitHub as a portfolio; same rule as all sibling platforms. **Rejected:**
realistic-but-real data (legal/ethical/privacy risk).
