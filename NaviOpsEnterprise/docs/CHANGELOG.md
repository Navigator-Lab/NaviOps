# CHANGELOG — NaviOpsEnterprise

Dated, append-only. Each entry names its verification.

## 2026-06-21 — Completeness pass ("nothing missed" for a fresh learner)
- **Published the remaining named KB articles** (platform reference content, spec-required): KB-0004 Wi-Fi,
  KB-0005 email/Outlook, KB-0006 printer, KB-0007 shared-folder, KB-0008 software, KB-0009 Remote Desktop,
  KB-0010 Microsoft 365 — completing the **full 10-article named set**; updated `docs/kb/INDEX.md` (all ✅ +
  linked).
- **Added learner-workspace guides** to `docs/runbooks/`, `docs/troubleshooting/`, `scripts/` — each a
  "what you produce here" README mapping every lesson's §9 deliverable + naming + standards (so the empty
  workspace is self-explanatory). Deliberately **did not** pre-write the runbooks/troubleshooting/ticket-
  notes/scripts — producing those IS the curriculum (the 6-artifact contract).
- **Verified link integrity:** scanned all internal markdown links (excl. `.agent`) — **zero broken**.
- **Result:** a fresh learner can start at Lesson 01 and proceed to 36 + capstones with no dangling
  references and all reference content present. Not committed (user-directed; commit/push stays manual).

## 2026-06-21 — Module I (Capstones: lessons 34–36) — ✅ v1 COMPLETE
- **Authored full-depth (capstone variant):** 34 Service Desk Capstone (run a 50-ticket queue + major
  incident + security event + KBs + metrics report) · 35 IT Support Capstone (own users/permissions/devices/
  software/docs/incidents end-to-end) · 36 Junior SysAdmin Capstone (provision/accounts/incidents/backups/
  reports, safely under change control — the graduation project).
- **Added:** `docs/learning/capstones/README.md` (index), `docs/learning/CAPSTONE-GUIDE.md`,
  `docs/learning/playbooks/DOCUMENTATION-PLAYBOOK.md`; README "Start here" updated (capstone guide + docs
  playbook + capstones link).
- **Milestone:** **NaviOpsEnterprise v1 is complete** — all 36 lessons (9 modules) + 3 capstones authored
  full-depth, on the proven sibling-platform standard. Covers the full arc: Help Desk T1/T2 → IT Support →
  Desktop Support → Junior SysAdmin → Infrastructure Support, with portfolio artifacts throughout.
- **Updated:** `LEARNING_STATE.md` (34–36 ✅, v1 complete), `STATUS.md`, this CHANGELOG, agent memory.
- **Verification:** 39 lesson/capstone READMEs present (01–36); all governance/guides/playbooks/templates/
  libraries/lab in place; internal links resolve. ~17k lines authored (excl. `.agent`). Pending only:
  optional KB/ticket backfill + the user-triggered `git` commit.

## 2026-06-21 — Module H (Operations Discipline: lessons 28–33)
- **Authored full-depth (12-section):** 28 Documentation & Knowledge Bases · 29 Security Awareness for IT
  Support · 30 Backup & Recovery Fundamentals · 31 Incident Management · 32 Root Cause Analysis ·
  33 Jira Service Management.
- **Worked sims:** ENT-28 (KB-rot fix) · ENT-29 (account-takeover containment, INC-0701) · ENT-30
  (ransomware recovery from clean offline backup, INC-0706) · ENT-31 (run a major incident as IC, INC-0811)
  · ENT-32 (RCA on the fleet bad-patch, PRB-0002) · ENT-33 (JSM configuration improvement).
- **Significance:** Module H is the maturity/operations layer — consolidates the 🔒 security thread (L29),
  the do-no-harm/data-first thread (L30), and the P1-handling from every prior module into incident (L31) +
  RCA (L32), then operationalizes the whole curriculum in JSM (L33). Strong NaviOpsSec bridge (L29/L30/L31/L32).
- **Updated:** `LEARNING_STATE.md` (28–33 ✅, current=34, skills), `STATUS.md`, this CHANGELOG.
- **Verification:** 6 lesson READMEs (~400–500+ lines each) created; cross-links resolve; LEARNING_STATE
  table consistent. Remaining: capstones 34–36 → v1 complete.

## 2026-06-21 — Module G (Windows Server & Endpoints: lessons 22–27)
- **Authored full-depth (12-section):** 22 Windows Server Fundamentals · 23 File Shares & Permissions ·
  24 Endpoint Troubleshooting · 25 Software Installation & Management · 26 Patch Management ·
  27 Asset Management.
- **Worked ticket sims:** ENT-22 (DC disk-full major incident) · ENT-23 (build a team share, group-based) ·
  ENT-24 (BSOD/failing-disk, deadline + loaner) · ENT-25 (non-standard app request governance) ·
  ENT-26 (fleet bad-patch rollback major incident) · ENT-27 (asset audit reconcile).
  Scripts referenced: server_health, share_audit, endpoint_triage, software_inventory, patch_status,
  asset_collect + the asset-register template.
- **Significance:** Module G is the full server/endpoint sysadmin layer (Junior SysAdmin / Infra Support).
- **Updated:** `LEARNING_STATE.md` (22–27 ✅, current=28, skills), `STATUS.md`, this CHANGELOG.
- **Verification:** 6 lesson READMEs (~400+ lines each) created; cross-links resolve; LEARNING_STATE
  table consistent. Next: Module H (28–33), then capstones (34–36).

## 2026-06-21 — Module F (Identity & Directory: lessons 18–21) + lab notes
- **Authored full-depth (12-section):** 18 Active Directory Fundamentals · 19 Group Policy Fundamentals ·
  20 User Provisioning & Deprovisioning · 21 Password Resets & Account Recovery.
- **Lab:** `infra/README.md` — build notes for DC01 (AD DS/DNS/DHCP, corp.example), FS01 (file server),
  CLIENT01, and the M365 dev-tenant model; safety/danger-zone checklist.
- **Worked ticket sims:** ENT-18 (reorg access loss) · ENT-19 (bad-GPO rollback) · ENT-20 (bad-terms
  offboarding) · ENT-21 (repeated lockout via Event 4740). Scripts referenced: aduc_query,
  gpresult_collect, new_user_onboard, offboard_user, reset_password, unlock_account.
- **Significance:** Module F is the Junior-SysAdmin pivot (the onboarding script + offboarding =
  the portfolio centerpieces).
- **Updated:** `LEARNING_STATE.md` (18–21 ✅, current=22, skills), `STATUS.md`, this CHANGELOG.
- **Verification:** 4 lesson READMEs (~400+ lines each) + infra notes created; cross-links resolve;
  LEARNING_STATE table consistent. Next: Module G (22–27).

## 2026-06-21 — Lesson wave 3 (Modules D + E: lessons 10–17)
- **Authored full-depth (12-section):** 10 Printers & Peripherals · 11 Microsoft 365 Fundamentals ·
  12 Google Workspace Administration · 13 Email Troubleshooting · 14 Browser & Web Troubleshooting ·
  15 Ticketing Systems Fundamentals · 16 Help-Desk Workflows · 17 ITIL Fundamentals. Each carries the
  diagnostic spine, a worked ticket sim (ENT-10…17), lab, quiz, and the 6-artifact contract (scripts/
  tools referenced: spooler_reset, m365_user_report, mailbox_report, plus the browser-isolation method,
  ticket/canned-response templates, shift-handover template, and the ITIL classification runbook).
- **Modules complete:** A–E (the full service-desk-ready core; covers Help Desk T1/T2 hireable skills).
- **Updated:** `LEARNING_STATE.md` (10–17 ✅, current=18, skills), `STATUS.md`, this CHANGELOG.
- **Verification:** all 8 lesson READMEs created (~300–400+ lines each, matching sibling depth); internal
  cross-links resolve; LEARNING_STATE table consistent. Next: Module F (18–21, lab stack online).

## 2026-06-21 — Lesson wave 2 (Modules B + C: lessons 04–09)
- **Authored full-depth (12-section):** 04 Windows Fundamentals · 05 Linux Fundamentals for Support ·
  06 Filesystems & Storage · 07 User Accounts & Permissions · 08 Networking Fundamentals ·
  09 DNS, DHCP & Connectivity. Each carries the diagnostic spine, a worked ticket sim (ENT-04…09),
  lab, quiz, and the 6-artifact contract (scripts referenced: windows_triage, linux_triage,
  disk_cleanup, whoami_access, net_triage, check_dns).
- **Updated:** `LEARNING_STATE.md` (04–09 ✅, current=10, skills), `STATUS.md`, this CHANGELOG.
- **Verification:** all 6 lesson READMEs created (~250+ lines each, matching sibling depth); internal
  cross-links resolve; LEARNING_STATE lesson table consistent. Next: wave 3 (10–17).

## 2026-06-21 — Platform bootstrap (foundation + first lesson wave)
- **Scaffolded** the repo: `.agent/` (Navi v28, copied from NaviOpsSec), `docs/learning/…`,
  `docs/{runbooks,troubleshooting,kb,tickets,templates,reports}`, `scripts/`, `infra/`, LICENSE.
- **Project Law:** `navi.project.md` — Windows/M365/AD-first, 6-artifact contract, diagnostic-spine
  Hard Rule, danger zones (AD/GPO/M365/offboarding/patch/backup).
- **Pedagogy layer:** `CLAUDE_TEACHING_RULES.md` (12-section IT-Support schema + 5 Integration
  Lenses), `ROADMAP.md` (36 lessons / 9 modules), `PROJECT_MISSION.md`, `LEARNING_STATE.md`.
- **Front door:** `README.md`.
- **Guides:** `alignment/ROLE-MAPPING.md`, `alignment/CERTIFICATION-MAPPING.md`,
  `INTERVIEW-PREP.md`, `PORTFOLIO-GUIDE.md`, `LINKEDIN-GUIDE.md`, `SYSADMIN-PATH.md`,
  `playbooks/HELPDESK-PLAYBOOK.md`, `playbooks/IT-SUPPORT-PLAYBOOK.md`.
- **Templates:** ticket-note, KB-article, runbook, troubleshooting-guide, incident-report, RCA.
- **Lessons:** 01 (IT Fundamentals), 02 (Computer Hardware), 03 (OS Fundamentals) — full 12-section.
- **Libraries:** `docs/tickets/INDEX.md` + first tickets; `docs/kb/INDEX.md` + first KB articles.
- **Verification:** all files created; structure matches sibling-platform layout; internal links
  resolve to created paths. Pending: `git init`, then grow lessons 04–36 in waves.
