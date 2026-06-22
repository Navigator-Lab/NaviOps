# Claude Teaching Rules — NaviOpsEnterprise

This file defines **how Claude must teach** throughout NaviOpsEnterprise. It is **authoritative**:
it governs every lesson. Other docs (`PROJECT_MISSION.md`, `ROADMAP.md`, `LEARNING_STATE.md`)
link here for the schema rather than restating it — this is the single source of truth
(`navi.project.md` Hard Rule #2, `docs/DECISIONS.md` D2).

> Modeled on the sibling platforms' `CLAUDE_TEACHING_RULES.md` (Gate Rule + Integration Lenses),
> reorganized into a **12-section IT-Support lesson schema**. The schema embeds the operator's
> required lesson flow —
> **Theory → Demonstration → Practical Lab → Ticket Simulation → Troubleshooting → Documentation
> → Portfolio Evidence** — and the required per-lesson outputs (Runbook, Troubleshooting Guide,
> Ticket Notes, KB Article, Incident Report, Portfolio Artifact).

## Top-Level Rules

1. Never give large code/config dumps. Teach only enough for the current lesson.
2. **Teach through doing the job** — every lesson must produce real support artifacts that go into
   the actual platform (`scripts/`, `docs/runbooks/`, `docs/troubleshooting/`, `docs/kb/`,
   `docs/tickets/`). No disconnected toy exercises. Every runbook, KB article, ticket note, and
   script contributes to NaviOpsEnterprise.
3. Every lesson follows the **12-Section Schema** (below), in order, applying the **Integration
   Lenses** wherever they trigger.
4. **Support is taught GUI-first, then CLI** (D3): a help-desk tech fixes things in the **Windows
   GUI / admin console** the way they would on the floor, then learns the **PowerShell / CLI**
   equivalent that scales (`Get-ADUser`, `Set-ADAccountPassword`, `gpupdate`, `ipconfig`,
   `nslookup`, the Exchange Online / Microsoft Graph cmdlets), then maps to the **cloud admin
   center** (Entra/Exchange/Teams admin). Linux equivalents appear where the role touches Linux.
   Never CLI-only and never GUI-only.
5. Never skip the **Troubleshooting Workflow** (§5) — and it must always carry the full diagnostic
   spine: **Symptoms → Possible Causes → Diagnostic Steps → Resolution Steps → Escalation
   Criteria → Post-Incident Documentation** (Hard Rule #4).
6. Never skip the **Ticket Simulation** (§6) or the **Practical Lab** (§8).
7. Never skip the **Quiz** — and never skip writing the **Professional Answer** comparison under
   each of the learner's answers (interview-grade, scenario-based).
8. Never move to the next lesson until the quiz is answered to a professional standard, the
   **Reflection** is complete, and **Search Keywords** are written.
9. Every completed lesson produces a portfolio-worthy artifact
   (`docs/learning/lessons/NN-<topic>/README.md`) **and** its **6-artifact evidence package**
   (§9 Artifact Contract).
10. Every completed **milestone** generates Resume bullets + Interview talking points + a
    Portfolio summary (`lessons/<milestone>/PORTFOLIO.md`).
11. **Public-repo discipline:** §6/§8/§9 include a redaction check — no real employer/tenant
    data, real names/emails, internal hostnames/asset tags, public IPs, license keys, or tokens
    before anything is committed (`navi.project.md` Hard Rule #1). All tickets/logs are
    lab-generated or sanitized; identities use `corp.example` placeholders.
12. The project keeps a dedicated `/scripts` directory of real support automation (e.g.
    `reset_password.ps1`, `unlock_account.ps1`, `new_user_onboard.ps1`, `offboard_user.ps1`,
    `check_dns.ps1`, `mailbox_report.ps1`, `disk_cleanup.ps1`, `gpresult_collect.ps1`) — every
    lesson that produces a script adds or extends one of these, never a one-off scratch file.

## Integration Lenses (cross-cutting — apply *within* the sections below)

Lenses are not extra sections; they are requirements that fire inside specific sections.
Reasoning follows Bloom's Taxonomy (foundations before higher-order analysis) and dual-coding /
Feynman technique (pair a technical explanation with a concrete analogy).

### Lens A — Three-Level Depth (User → Technician → Engineer)
For **important concepts**, §1 explains at three depths:
- **Level 1 (User/Beginner):** what it is, in plain terms — what the end user sees.
- **Level 2 (Technician/T1–T2):** how it's diagnosed and fixed day-to-day in the GUI + PowerShell.
- **Level 3 (Engineer/Internals):** what's actually happening underneath — the AD attribute, the
  registry key, the protocol exchange, the log/event ID, the cloud object — and *why* the fix
  works. This is what separates a button-pusher from someone who understands the system.

### Lens B — Two Teaching Approaches (Technical + Analogy + Visual)
**Required for difficult concepts** — Active Directory & authentication, DNS resolution, DHCP
lease, Group Policy processing, mail flow, permissions/inheritance, the ITIL incident lifecycle,
and any concept the operator finds hard. §1 must give:
1. A precise **technical** explanation.
2. A simplifying **analogy** (AD → a company phone directory + ID-badge system; DNS → the
   contacts app translating a name to a number; DHCP → a hotel front desk handing out room keys
   for a set time; Group Policy → the company dress code pushed to everyone; a ticket priority
   matrix → an ER triage; permissions inheritance → who holds which master key). Note where the
   analogy breaks down.
3. An **ASCII diagram** (Visual) — the logon flow, the DNS query path, the mail-flow hops, the OU
   tree, the ticket lifecycle, or the escalation ladder.

### Lens C — GUI → Automation → Why (Manual → PowerShell → at scale)
For any operational lesson, §8 must cover: how the task is done **in the GUI** (what a tech clicks
on the floor), how it's **automated with PowerShell/Bash** (a `/scripts` tool), **why** the
automation matters (consistency, speed, doing 50 onboardings the same way, an auditable record),
and what **sysadmins automate** in production (scheduled tasks, bulk provisioning, reporting).

### Lens D — Artifact / System-Internals Tie-In
Whenever a concept touches the actual system — the AD user object's attributes, the Event Viewer
entry (with its Event ID), the registry value, the GPO `gpresult` output, the `ipconfig /all`
dump, the mailbox property, the DHCP lease record — §1 Level 3 explains the mechanism, and §8
includes a focused look at the **raw artifact** (the exact attribute/event/output the diagnosis
keys on). The goal is to understand *where the evidence comes from*, so a fix isn't a black box.

### Lens E — Service & Security Mindset (the spine of this platform)
Every lesson builds **both** mindsets of a professional support tech:
- **Service:** clear communication, the right priority/SLA, expectation-setting, documentation
  that the next tech can use, and never leaving the user worse off. Tie to ITIL.
- **Security awareness:** the support desk is a top social-engineering target — verify identity
  before a reset, least-privilege when granting access, recognize phishing/MFA-fatigue/pretexting,
  and never expose credentials. Even Lesson 01 carries a real service + security frame; it
  deepens through provisioning/deprovisioning (20–21), security awareness (29), and the capstones.

## The 12-Section Schema — every lesson

> Sections 4 (Demonstration), 5 (Troubleshooting Workflow), 6 (Ticket Simulation), and 7 (Service
> Desk / ITIL Perspective) are what make this an **operational** support platform, not an
> exam-cram. They appear in **every** lesson, scaled to the topic. The schema maps the required
> flow: **§1 Theory → §4 Demonstration → §8 Practical Lab → §6 Ticket Simulation → §5
> Troubleshooting → §9 Documentation → §9/§10 Portfolio Evidence.**

### §1 — Concept (Theory)
Explain (EXP-style, WebSearch if needed): what it is · why it exists · what problem it solves ·
the underlying mechanism (the standard/protocol/AD object/Microsoft service and how it works).
- **Lens A** (important concepts): User → Technician → Engineer depth.
- **Lens B** (difficult concepts): technical + analogy + **ASCII diagram**.
- **Lens D** (artifact topics): the exact attribute/event/output the concept produces.

### §2 — Tools & Commands
The toolkit for this topic, with what each one shows and a real example. The relevant subset of:
Windows GUI consoles (ADUC, GPMC, Event Viewer, Services, Task Manager, RSAT, Computer Mgmt),
PowerShell (`Get-ADUser`, `Set-ADAccountPassword`, `Unlock-ADAccount`, `Get-ADComputer`,
`gpresult`, `gpupdate`, `Get-Service`, `Get-EventLog`/`Get-WinEvent`, the `ActiveDirectory` /
`ExchangeOnlineManagement` / `Microsoft.Graph` modules), networking CLIs (`ipconfig`, `nslookup`,
`ping`, `tracert`, `netstat`, `Test-NetConnection`), and the **cloud admin centers**
(Entra admin, Exchange admin, Teams admin, Microsoft 365 admin). Map each GUI action to its
**PowerShell / admin-center equivalent** so the operator can pivot from the floor to scale.

### §3 — Real-World Support Context & Use Cases
Real production scenarios · how T1/T2/desktop/sysadmin techs use this · which **ticket
categories** it shows up in · how often (volume) · when it's a quick win vs an escalation · the
**A+/Network+/MS-900/MD-102/ITIL** exam framing (so the operator recognizes it on the exam *and*
in the queue).

### §4 — Demonstration (worked walkthrough)
A narrated, end-to-end walkthrough of the task being done correctly the first time — the "watch me
do it" before "you do it." The exact clicks/commands, what good output looks like, and the
checkpoints that tell you it worked. This is the demonstration step of the required flow.

### §5 — Troubleshooting Workflow (the diagnostic spine — never skipped)
The structured method for this problem class, **always** as:
1. **Symptoms** — what the user reports and what you observe.
2. **Possible Causes** — ranked most-likely-first.
3. **Diagnostic Steps** — the ordered checks (GUI + command) that isolate the cause.
4. **Resolution Steps** — the fix for each cause.
5. **Escalation Criteria** — exactly when and to whom this leaves T1 (T1→T2→T3/vendor), with what
   info attached.
6. **Post-Incident Documentation** — what gets written down (ticket note, KB update, RCA if major).

### §6 — Ticket Simulation
A realistic ticket in the user's own words (with priority/impact/urgency), worked end-to-end:
intake → triage/priority → diagnosis → resolution → **the professional ticket note** (the exact
wording you'd save) → closure. Reference the matching entry in the ticket library
(`docs/tickets/`). Show the difference between a lazy note and a great one.

### §7 — Service Desk / ITIL Perspective
How this topic shows up on a **service-desk shift**: which queue/category it lands in,
**priority** (impact × urgency), the **SLA** clock, the **escalation path** (T1→T2→T3/vendor),
incident vs request vs problem (ITIL), the **metric** angle (FCR, MTTR, CSAT, backlog), and the
hand-off/communication expectations. Tie to the playbooks (`docs/learning/playbooks/`).

### §8 — Practical Lab (build this yourself)
Commands, configs, and files to create — only enough for this lesson. Where relevant, the
**break-then-fix drill**: (lab-only) reproduce the problem, then diagnose and resolve it.
**Lens C** (GUI → PowerShell automation → why → what production automates).
**Lens D** (a focused look at the raw artifact — the AD attribute, the Event ID, the command
output). Labs use `corp.example` / RFC 1918 ranges and placeholder identities only.

### §9 — GitHub Artifact (the 6-artifact evidence package / Artifact Contract)
The lesson is "done" when the operator has produced, in their own voice and committed:
1. **A Runbook** — the step-by-step "when this ticket comes in, do X" (`docs/runbooks/`).
2. **A Troubleshooting Guide** — the symptom→cause→fix decision guide (`docs/troubleshooting/`).
3. **Ticket Notes** — the worked ticket from §6 with a professional resolution note
   (`docs/tickets/`).
4. **A KB Article** — the end-user-facing how-to / self-service article (`docs/kb/`).
5. **An Incident Report** (or RCA, for the larger/outage lessons) — from the §8 drill, using the
   templates (`docs/templates/`), sanitized.
6. **A Portfolio Artifact** — the resume bullet + the LinkedIn line + the talking point (§10).
   Plus a supporting **script** (`scripts/`) wherever the task is automatable (`Invoke-ScriptAnalyzer`/
   `shellcheck`-clean).

### §10 — Portfolio Artifact
What this lesson contributes to the portfolio: the resume bullet, the interview talking point, the
LinkedIn-worthy line, and which role (Help Desk T1 / T2 / IT Support Specialist / Desktop Support
/ Junior SysAdmin / Infrastructure Support) it serves. At a milestone, roll up into
`lessons/<milestone>/PORTFOLIO.md`.

### §11 — Certification Crossover Notes
Where this lesson maps to **CompTIA A+**, **CompTIA Network+**, **Microsoft 365 Fundamentals
(MS-900)**, **Microsoft Endpoint Administrator (MD-102)** / **Azure/Identity fundamentals**, and
**ITIL 4 Foundation** objectives. "N/A for cert X" is a valid note. Detail lives in
`alignment/CERTIFICATION-MAPPING.md`.

### §12 — Support Notes (Lens E — Service & Security)
The full service + security treatment for this topic: the communication/expectation-setting that
makes it good support, and the security-awareness angle (identity verification, least privilege,
the social-engineering/phishing risk, data handling). This is the running thread that builds the
professional support mindset from Lesson 01.

---

## Quiz (graded — fires after §8, before the lesson closes)

This is the **Understanding Verification** checkpoint:
- 5–10 questions phrased as **interview questions**; at least one scenario-based ("a user calls
  and says X — what do you check first and why?"), not pure recall.
- The learner answers **inline, directly under each question**.
- Once answered, Claude writes a **"Professional Answer"** directly below each — a *comparison*,
  not a rewrite: confirm what's right, sharpen what's off (quote the part), add the detail an
  interviewer expects (edge cases, the "why", common follow-ups, the escalation point).
- The learner must reach a professional standard (after the comparison, if needed) before moving
  on.

## Reflection (after the quiz)
- What did you learn? · What confused you? · What would you do differently?

## Search Keywords For Further Understanding (closes every lesson)
- 5–10 search-engine-ready phrases (Core / Tools / Going further), including ≥1 adjacent "future
  lesson" topic.
- **Service / Security (Lens E):** a service-quality + a security-awareness keyword group — every
  lesson, since Lens E always fires here.

---

## Update Protocol — after every completed lesson
1. Write `docs/learning/lessons/NN-<topic>/README.md` covering all 12 sections + Lenses.
2. Update `docs/learning/LEARNING_STATE.md` (skills learned/partial, next lesson, lab state).
3. Run the standard "update docs" protocol (`docs/README.md`) — CHANGELOG/STATUS/TODO.
4. Update the alignment matrices (`alignment/`) if the lesson closed an A+/Network+/MS-900/MD-102/
   ITIL objective.
5. If a milestone is complete, produce `lessons/<milestone>/PORTFOLIO.md` (Resume bullets +
   Interview talking points + Portfolio summary).
