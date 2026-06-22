# Lesson 35 — IT Support Capstone

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (capstone variant) (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the integrative project for **IT Support Specialist / Desktop Support** — **own an IT-support
environment**: manage **users, permissions, devices, software, documentation, and incidents** end-to-end,
autonomously. Where the service-desk capstone (L34) proved you can work a queue, this proves you can **own
outcomes**. Pulls together Modules B, D, F, G (+ A, E, H).
**Primary artifact:** the capstone portfolio package — `docs/learning/capstones/35-it-support-project.md`.

> **How to use this capstone:** read §1–§4 (brief + integration), execute §5–§8 (run the environment),
> produce §9 (portfolio package), self-assess §10. A *project*, more autonomous than L34.

---

## §1 — Concept (the capstone brief)

You **own end-user IT for a team/site at Corp (corp.example)** — not just a queue, but **outcomes**. Over a
simulated period you will: **onboard and offboard** users end-to-end (L20 — AD + M365 + groups + mailbox +
device, scripted), manage **permissions and file-share access** (L07/L23, group-based/least-privilege),
manage the **device fleet** (L02/L24 — repairs, loaners, reimage) and **asset register** (L27), manage
**software** (L25 — catalog/approval/inventory) and **patching** (L26 — rings), maintain **documentation**
(L28 — runbooks/KB), and handle the **incidents** that arise (L24/L31 + a security event L29). You operate
**autonomously and safely** — respecting the danger zones (AD/GPO/M365/offboarding/patch — `navi.project.md`)
with `-WhatIf`/change discipline.

**This capstone proves:** you can own end-user IT for a team — identity lifecycle, access, devices,
software, docs, and incidents — i.e. you're hireable as an **IT Support Specialist / Desktop Support
Technician**.

---

## §2 — What it integrates (the lessons behind it)

| Capability | From |
|---|---|
| Onboarding/offboarding (AD+M365+device, scripted, staged) | L20 (+L11, L18) |
| Permissions & file-share access (group-based, least privilege) | L07, L23 |
| Device lifecycle: repair, loaner, reimage, asset register | L02, L24, L27 |
| Software (catalog/approval/inventory) + patching (rings) | L25, L26 |
| Documentation (runbooks/troubleshooting/KB) | L28 (+L15) |
| Incidents (endpoint + a major incident + a security event) | L24, L31, L29 |
| Change/danger-zone discipline | L17, L26, navi.project.md |

---

## §3 — Real-World framing

This is the IT Support Specialist / Desktop Support role: broader and more autonomous than the front desk.
"The new hire starts Monday — set them up" is yours end-to-end; so is "image these laptops," "build this
team's share," "deploy this software safely," and "this site's incident." Employers want evidence you can
**own these processes** consistently, safely, and with documentation — not just take a ticket. The
capstone's portfolio package is exactly that evidence.

---

## §4 — Demonstration (the standard to match)

The unit skills were demonstrated across Modules F–G (ENT-20 onboarding/offboarding, ENT-23 build-a-share,
ENT-24 endpoint/loaner, ENT-25 software governance, ENT-26 patch rings, ENT-27 asset reconcile). This
capstone is **owning them together, autonomously**, to that standard — scripted where automatable, group-
based + least-privilege for access, change-controlled for anything broad, documented throughout.

---

## §5 — The project (run the environment)

### Stage 1 — Identity lifecycle (L20)
- **Onboard** a batch of new hires (CSV-driven, `new_user_onboard.ps1`): AD account (right OU/naming),
  **role groups** (→ auto license/GPO/drives), mailbox (L11), device assigned + imaged + asset-tagged
  (L27), MFA + secure handoff. Produce the **onboarding runbook + handoff sheets**.
- **Offboard** a leaver (staged, `offboard_user.ps1`): disable + **revoke sessions**, preserve/transfer
  data (mailbox/OneDrive), reclaim license + device, wipe + re-stock (L27). Bonus: a **bad-terms** offboard
  (L20/ENT-20).

### Stage 2 — Access management (L07/L23)
- Build/maintain **file shares** group-based + least-privilege + ABE (L23); handle access requests/changes
  **by group** (L07); run a small **access review** (who has what — L27) and remediate any over-permission
  ("Everyone/Full Control") finding.

### Stage 3 — Device & software fleet (L02/L24/L25/L26/L27)
- Handle device incidents: a **slow/failing endpoint** (L24 — measure bottleneck → fix-vs-reimage +
  **loaner**), a **hardware** failure (L02). Manage **software** (catalog/approval + a non-standard request
  governed, L25) and run a **patch cycle** with **rings** (L26). Keep the **asset register** accurate (L27).

### Stage 4 — Incidents (L24/L31/L29)
- Handle an **endpoint major incident** (e.g. fleet bad-patch L26/ENT-26 run as IC, L31) and a **security
  event** (phishing/compromise L29) → contain + escalate. Produce the **incident report + RCA** (L31/L32).

### Stage 5 — Documentation (L28)
- Throughout, produce/maintain the **runbooks, troubleshooting guides, and KB** for everything you owned —
  to the quality checklist (L28). The environment should be runnable by the next tech from your docs.

---

## §6 — Ticket/Scenario Simulation

Drive the project from `docs/tickets/INDEX.md` (onboarding/offboarding REQs, access, hardware, software,
patch) plus the injected major incident + security event. The worked examples (ENT-20…ENT-30) are your
quality reference for the scripts, the share build, the loaner, the patch rollback, and the security
response.

---

## §7 — Service Desk / ITIL Perspective

This capstone exercises **service request fulfillment** (onboarding/offboarding/access/software — L17/L20),
**change enablement** (shares/patches/deployments — L26/L17, with danger-zone discipline), **incident +
problem** (L31/L32), **asset/configuration management** (L27), and **knowledge management** (L28) — the
IT-Support-Specialist slice of ITIL, owned end-to-end rather than ticket-by-ticket.

---

## §8 — Execution checklist

- [ ] Batch **onboarding** (scripted, group-based) + handoff sheets (L20)
- [ ] Staged **offboarding** (disable+revoke+transfer+reclaim+wipe), incl. a bad-terms case (L20)
- [ ] **File shares** built/maintained group-based + least-privilege + ABE (L23); access review (L27)
- [ ] **Device** incidents handled (slow/failing → fix-vs-reimage + loaner) + asset register accurate (L24/L02/L27)
- [ ] **Software** governed (catalog/approval/inventory) + a **patch cycle** with rings (L25/L26)
- [ ] One **major incident** (IC + report) + one **security event** (contain+escalate) + an **RCA** (L31/L29/L32)
- [ ] **Documentation** set (runbooks/troubleshooting/KB) to the quality checklist (L28)
- [ ] Danger-zone discipline throughout (`-WhatIf`, change control, lab-targeted)
- [ ] Portfolio package assembled (§9)

---

## §9 — GitHub Artifact (the capstone portfolio package)

Assemble in `docs/learning/capstones/35-it-support-project.md` (+ supporting files):
1. **Onboarding/offboarding** runbooks + the `new_user_onboard.ps1` / `offboard_user.ps1` scripts + handoff
   sheets (the centerpiece — L20).
2. **Access management** — the share design (group-based/least-priv/ABE) + the access-review result (L23/L27).
3. **Fleet** — device incident write-ups (fix-vs-reimage/loaner) + the **asset register** (L24/L02/L27).
4. **Software + patch** — the catalog/approval flow + a patch-cycle (rings) record (L25/L26).
5. **Incident + RCA** — the major-incident report + the security-incident note + an RCA (L31/L29/L32).
6. **Documentation set** — the runbooks/troubleshooting/KB you produced (L28).

The single strongest **IT Support Specialist** portfolio piece — "an IT environment I owned."

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Owned end-user IT for a simulated environment: scripted onboarding/offboarding
  (AD+M365+device), group-based least-privilege access and file shares, device fleet + asset management,
  governed software and ringed patching, and incident/RCA response — all documented in reusable runbooks
  and KB."*
- **Interview talking point:** **owning outcomes** (the new hire is set up Monday; the leaver leaves no
  access behind), **group-based least-privilege access**, the **fix-vs-reimage + loaner** judgment, **ringed
  patching**, and doing it all **safely** (danger zones, `-WhatIf`, change control). This is the
  "specialist, not just ticket-taker" story.
- **Serves:** IT Support Specialist · Desktop Support Technician.

---

## §11 — Certification Crossover Notes

Integrates **MD-102** (identity lifecycle, devices, apps, compliance), **MS-900** (M365/identity/licensing),
**CompTIA A+** (hardware/OS/software/security troubleshooting + procedures), and **ITIL 4** (request/change/
incident/problem/config/knowledge). Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** ownership means **outcomes + experience** — a smooth first day for a new hire, a loaner so
no one's stranded, documentation so the next tech can continue. You're judged on the whole experience, not
single tickets.

**🔒 Security:** this capstone is dense with security responsibility — **least-privilege** access (L07/L23),
**complete offboarding** (disable+revoke, L20), **governed software** + **app control** (L25), **patching**
(L26), **secure disposal** (L27), and handling a **security event** (L29). Doing all of it **safely**
(danger zones, change control) *is* the senior-tech differentiator and the bridge toward sysadmin/security.

---

## Quiz (Interview-Style, Graded) — capstone debrief

**Q1.** Walk me through how you onboarded a batch of new hires — what did you script and why group-based?
> **Your answer:**

**Q2.** How did you offboard a leaver safely, and what's the difference between disabling and fully securing
the account?
> **Your answer:**

**Q3.** How did you keep file-share access maintainable and least-privilege across the environment?
> **Your answer:**

**Q4.** Tell me about a device or patch incident you owned — fix-vs-reimage, loaner, or ring rollback.
> **Your answer:**

**Q5.** How did you keep this environment safe (danger zones) while still moving fast?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the capstone)* — Where did owning outcomes (vs tickets) change how you worked? · What did you
automate? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `IT support specialist responsibilities`
- `scripted onboarding offboarding AD M365 portfolio`
- `group based least privilege access review`
- `device fleet asset management lifecycle`
- `ringed patch deployment governed software`

**Going further**
- `junior sysadmin capstone` (L36) · `service desk capstone` (L34) · Modules F–G + L28/L31/L32

**Service / Security (Lens E):**
- 🤝 `owning outcomes new-hire experience`
- 🔒 `least privilege complete offboarding secure disposal` (→ NaviOpsSec)

---

## Capstone Status
- [ ] Onboarding/offboarding · access · fleet/asset · software/patch · incident+RCA · docs — all done
- [ ] Portfolio package assembled (`capstones/35-it-support-project.md`)
- [ ] Debrief quiz answered + professional-answer comparisons
- [ ] Reflection complete

When complete, run the Update Protocol, then move to **Lesson 36 — Junior SysAdmin Capstone**.

---

*Lesson 35 written by Navi · 2026-06-21 · full-depth (capstone). Integrates Modules B/D/F/G + A/E/H;
sources per the integrated lessons.*
