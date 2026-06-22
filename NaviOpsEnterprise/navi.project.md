# navi.project.md — NaviOpsEnterprise

> Navi loads this right after project detection as its **Project Law**. Navi's core
> (`.agent/`) stays project-agnostic; everything specific to *NaviOpsEnterprise* (the IT
> Operations / Help Desk / Service Desk / Junior SysAdmin academy being built and the learning
> journey behind it) lives here.
>
> Sibling projects (same philosophy, same documentation system, same quality bar):
> - **NaviOps** (`/home/sys-ctl/NaviOps`) — the Linux/DevOps/SysAdmin platform.
> - **NaviOpsNetwork** (`/home/sys-ctl/NaviOpsNetwork`) — the Networking/NOC platform.
> - **NaviOpsSec** (`/home/sys-ctl/NaviOpsSec`) — the Security Operations (Blue Team) platform.
>
> NaviOpsEnterprise is the **fourth platform** and the **front door** of the whole bridge: it
> takes a complete beginner to **Help Desk Tier 1 → Help Desk Tier 2 → IT Support Specialist →
> Desktop Support Technician → Junior System Administrator → Infrastructure Support Engineer**.
> This is an **IT Operations / End-User-Support** platform — real tickets, real troubleshooting,
> real documentation. Not a theory course.

## Identity
- **name**: NaviOpsEnterprise
- **one-liner**: A project-based, operations-focused **IT Support / Service Desk / Junior
  SysAdmin** learning platform built in public on the Navi framework, taking the operator from
  zero to **Help Desk T1/T2 → IT Support Specialist → Desktop Support → Junior SysAdmin →
  Infrastructure Support Engineer** by handling real tickets and producing real documentation.
- **stack**: Windows (client + Server) · Active Directory & Group Policy · Microsoft 365
  (Entra ID/Exchange Online/Teams/OneDrive/SharePoint) · Google Workspace · networking
  fundamentals (DNS/DHCP/TCP-IP) · Linux fundamentals for support · ticketing & ITSM
  (Jira Service Management, ServiceNow & Zendesk concepts) · ITIL 4 service management ·
  endpoint/desktop support · printers & peripherals · backup & recovery · patch & asset
  management · incident management & RCA. PowerShell + Bash are the automation languages.
  `.agent/` is the Navi core, copied unmodified from the sibling platforms.

## Commands
- **install**: _(none global — tools are introduced per lesson: RSAT/AD tools, the M365/Entra
  admin centers, a ticketing sandbox, PowerShell modules `ActiveDirectory`/`ExchangeOnlineManagement`/
  `Microsoft.Graph`, a Windows Server lab VM, a Linux VM)_
- **test**: _(none yet — add per-lesson checks under `scripts/`: PowerShell `Invoke-ScriptAnalyzer`,
  `bash -n`/`shellcheck` for any Bash, and "does the runbook actually resolve the ticket" dry-runs)_
- **run / dev**: open Claude Code here → `/navi <request>`
- **build**: _(n/a until the first lab stack under `infra/` — e.g. an AD domain controller VM)_
- **lint / typecheck**: `Invoke-ScriptAnalyzer scripts/*.ps1` (PowerShell) · `shellcheck scripts/*.sh` (Bash)

## Layout
- **entrypoint**: `.agent/workflows/navi.md` (Navi v28 core, copied from the sibling platforms)
- **pedagogy layer**: `docs/learning/` — `PROJECT_MISSION.md` (constitution),
  `CLAUDE_TEACHING_RULES.md` (the canonical **12-section IT-Support lesson schema** + Integration
  Lenses — single source of truth), `ROADMAP.md` (36-lesson map + support career stages),
  `LEARNING_STATE.md` (living progress tracker), `alignment/` (A+/Network+/MS-900/MD-102/ITIL +
  role mappings), `capstones/` (the 3 capstone projects), `playbooks/` (HELPDESK / IT-SUPPORT /
  SYSADMIN playbooks), the career guides (`INTERVIEW-PREP.md`, `PORTFOLIO-GUIDE.md`,
  `LINKEDIN-GUIDE.md`, `SYSADMIN-PATH.md`), `prompts/` (bootstrap archive),
  `lessons/NN-topic/README.md` (one per completed lesson, schema output)
- **memory + reports**: `docs/` (STATUS/CHANGELOG/TODO/DECISIONS/DEFERRED + `docs/reports/`)
- **operational artifacts**: `docs/runbooks/` (step-by-step "when X, do Y"),
  `docs/troubleshooting/` (symptom→cause→fix guides), `docs/kb/` (end-user-facing KB articles),
  `docs/tickets/` (the realistic ticket library, 100+), `docs/templates/` (ticket / KB / runbook /
  incident-report / RCA templates), `scripts/` (PowerShell + Bash support automation),
  `infra/` (lab build definitions: AD domain, M365 dev-tenant notes, client images)
- **config / env**: real secrets never committed — see Hard Rules below

## Hard Rules ("Schema Lock") — what Navi must never violate here
1. **Public-repo discipline (this repo ships to GitHub as a portfolio piece).** No real
   employer/tenant data, real user names or emails, internal hostnames/asset tags, public IPs,
   license keys, API tokens, tenant IDs, or KB content lifted verbatim from an employer is ever
   committed. Use `corp.example` / `*.corp.example`, RFC 1918 ranges, and the placeholder
   identities in `LEARNING_STATE.md` (e.g. `jdoe@corp.example`, asset `LT-0427`). All tickets,
   logs, and screenshots are **lab-generated or sanitized**.
2. **Lesson schema is canonical in ONE file**: `docs/learning/CLAUDE_TEACHING_RULES.md`
   (the 12-section IT-Support schema + Integration Lenses). Every lesson follows it; other docs
   link to it rather than restating it.
3. **Every lesson produces real operational evidence** — the **6-artifact contract**: a
   **Runbook**, a **Troubleshooting Guide**, **Ticket Notes** (a worked ticket), a **KB Article**
   (end-user-facing), an **Incident Report** (or RCA, for the bigger lessons), and a **Portfolio
   Artifact**. Plus a supporting **script** (PowerShell/Bash) where the task is automatable.
   No disconnected toy exercises — everything lands in `scripts/`, `docs/runbooks/`,
   `docs/troubleshooting/`, `docs/kb/`, `docs/tickets/`.
4. **Every troubleshooting topic carries the full diagnostic spine**: **Symptoms → Possible
   Causes → Diagnostic Steps → Resolution Steps → Escalation Criteria → Post-Incident
   Documentation.** This is non-negotiable in §5 of every lesson — it is what makes the platform
   operational rather than theoretical.
5. **`docs/learning/LEARNING_STATE.md` is updated after every lesson/milestone** — a fresh
   session resumes teaching from it with zero re-explanation.
6. **No auto-spend / no auto-send** (P00, inherited): never modify a live directory/tenant, send
   mail as a user, reset a real account, deploy GPO to a production OU, `git push`, or spin up
   paid cloud resources without the operator explicitly approving that specific command.

## Danger Zones (confirm before touching)
- **Active Directory write operations** (`Remove-ADUser`, `Set-ADUser`, disabling/deleting
  accounts, moving objects between OUs, resetting passwords) — only against the **lab domain**;
  destructive AD ops on a live domain can lock out real people. Confirm + target the lab.
- **Group Policy** linked at the domain or a populated OU — a bad GPO can break logon for an
  entire org. Test in a lab OU with a test account first; never link untested policy broadly.
- **Microsoft 365 / Entra admin actions** (license removal, mailbox deletion, conditional-access
  changes, bulk operations via Graph/Exchange Online) — irreversible bulk changes affect real
  users. Lab/dev-tenant only; confirm scope.
- **Deprovisioning / offboarding** (disable account, revoke sessions, convert mailbox, wipe
  device) — staged and reversible-where-possible; one wrong target offboards the wrong person.
- **Patch deployment / software push** to a fleet — can break endpoints at scale; pilot ring first.
- **Backup/restore operations** — a restore can overwrite good data; confirm source/target.
- **Editing `.agent/`** (Navi core) — keep in sync with the sibling platforms; project-specific
  content belongs in `docs/learning/` or this file, not `.agent/`.

## Notes
- **Windows-first, then cross-platform.** Unlike the Linux-first siblings, the day-one job here is
  predominantly **Windows + Microsoft 365 + Active Directory**, so concepts are taught from the
  Windows GUI **and** PowerShell first, then mapped to the cloud admin centers (Entra/Exchange)
  and to Linux where the role touches it (Lesson 05). The operator must be able to fix a problem
  in the **GUI** (what a tech does on the floor) *and* in **PowerShell** (what scales) — that's
  the platform's signature.
- **The ticket is the unit of work.** Every troubleshooting lesson is framed as a real ticket:
  symptom in the user's words → triage/priority → diagnosis → resolution → documentation →
  closure. The operator graduates able to *work a queue*, not just recite facts.
- **MENTOR (P11) teaching depth in NaviOpsEnterprise**: when MENTOR answers a command/tool
  question (e.g. "what does `gpupdate /force` do", "is `Get-ADUser -Filter` the right way",
  "how should I word this ticket note"), it composes this project's teaching schema as its depth —
  the **12-section IT-Support lesson schema** (`CLAUDE_TEACHING_RULES.md`) + **Integration
  Lenses** (Two-Approach explanation, GUI↔CLI automation, Troubleshooting spine, Ticket/ITIL
  lens, Security-awareness). So command mentoring matches the lesson pedagogy.
- A fresh session resumes from `docs/STATUS.md` (project/code state) **and**
  `docs/learning/LEARNING_STATE.md` (pedagogy/progress state) — read both first.
- **The bridge**: NaviOpsEnterprise (IT support / service desk) → NaviOps (Linux/SysAdmin) →
  NaviOpsNetwork (networking/NOC) → NaviOpsSec (security ops) form one career path:
  Help Desk → IT Support → Junior SysAdmin → NOC/Infra → Security Analyst. This platform is the
  **on-ramp**. See `docs/learning/alignment/ROLE-MAPPING.md`.
- Origin of this project: built per the operator's `1.md` spec to extend the NaviOps /
  NaviOpsNetwork / NaviOpsSec standards into an end-user IT Support & Service Desk academy.
