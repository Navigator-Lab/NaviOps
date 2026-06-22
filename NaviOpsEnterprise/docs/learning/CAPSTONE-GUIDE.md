# Capstone Guide — NaviOpsEnterprise

How to run the three capstones (Lessons 34–36) and assemble each into a portfolio package that gets you
interviews. The capstones are where the curriculum stops being lessons and becomes **evidence you can do
the job**.

## Why capstones matter most
Recruiters skim certs; hiring managers want **proof of operational ability**. A capstone package — "a
service desk I ran," "an IT environment I owned," "infrastructure operations I ran safely with reports" —
is the most persuasive thing in your portfolio because it shows **integration under realistic conditions**,
not isolated facts.

## The three (and when to do them)
- **L34 Service Desk** — after Modules A–E (the Help Desk core). Run a 50-ticket queue + major incident +
  security event + KBs + metrics report.
- **L35 IT Support** — after Module F–G. Own users/permissions/devices/software/docs/incidents end-to-end.
- **L36 Junior SysAdmin** — after Module H. Operate infrastructure (provision/accounts/incidents/backups/
  reports), safely, under change control. The graduation project.

Do them in order; each is more autonomous than the last.

## How to run a capstone
1. **Read the brief** (the lesson's §1–§5) and the **execution checklist** (§8).
2. **Set up** what you need: the ticket library (`docs/tickets/INDEX.md`) for L34; the lab (`infra/`) +
   scripts for L35/L36; placeholder identities (`LEARNING_STATE.md`).
3. **Execute the stages** — work it like the real role, to the standard the worked examples (ENT-01…ENT-33)
   set. Use the templates (`docs/templates/`) for every artifact.
4. **Inject the scenarios** — the major incident (L31), the security event (L29), the backup/ransomware
   recovery (L30), the patch rollback (L26) — don't skip the hard parts; they're the differentiators.
5. **Operate safely** (L35/L36): danger-zone discipline — `-WhatIf`, snapshots, change control, lab-targeted
   (`navi.project.md`).
6. **Assemble the package** (the lesson's §9) into `docs/learning/capstones/NN-…-project.md` + supporting
   files. **Sanitize** (placeholders only — HR#1).
7. **Debrief** — answer the capstone quiz to a professional standard; write the reflection.

## What a great package contains (general)
- The **work itself** (tickets/scripts/configs/runbooks) — real artifacts, in your voice.
- The **hard scenarios** handled (incident report + RCA, security containment, restore test).
- A **report** (metrics for L34; the report set for L36) — shows you understand the *business*.
- A short **reflection** ("what I'd improve") — shows continual-improvement thinking (L16).

## Turning a capstone into interview gold
- **Pin it** in your GitHub + link it from your resume/LinkedIn (`PORTFOLIO-GUIDE.md`, `LINKEDIN-GUIDE.md`).
- **Rehearse the walkthrough** (the lesson's §10 talking point + the debrief quiz, `INTERVIEW-PREP.md`):
  be able to narrate running the desk / owning the environment / operating infra end-to-end.
- **Lead with the hard part** — the major incident you commanded, the offboarding you secured, the restore
  you proved — that's what separates you.

## Honesty rule (all platforms)
Capstones are **simulated/lab** — label them as such ("hands-on lab/personal project"). They're true (you
did the work, it's in the repo) and demonstrable — never imply production experience. Lying disqualifies;
"I built this lab to prove I can do the job" is respected.

## After the capstones
You're hireable across Help Desk → Junior SysAdmin. To go deeper, pick a sibling platform
(`SYSADMIN-PATH.md`): **NaviOps** (Linux/SysAdmin), **NaviOpsNetwork** (NOC), **NaviOpsSec** (Security Ops).
