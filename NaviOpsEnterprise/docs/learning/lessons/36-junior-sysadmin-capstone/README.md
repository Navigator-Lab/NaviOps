# Lesson 36 — Junior SysAdmin Capstone

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (capstone variant) (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the final, most senior integrative project — **operate as a Junior System Administrator**:
**provision systems, manage accounts, handle incidents, perform backups, and write reports** — owning the
**infrastructure** layer (AD/GPO, servers, shares, patching, backups) safely and with change discipline.
The graduation project of NaviOpsEnterprise and the launch point into the sibling platforms.
**Primary artifact:** the capstone portfolio package — `docs/learning/capstones/36-junior-sysadmin-project.md`.

> **How to use this capstone:** read §1–§4 (brief + integration), execute §5–§8 (run the ops), produce §9
> (portfolio package), self-assess §10. The most autonomous, infrastructure-focused project.

---

## §1 — Concept (the capstone brief)

You **operate the infrastructure for Corp (corp.example)** as a Junior SysAdmin. Over a simulated period
you will: **provision systems** (stand up/configure a server + roles — L22, the lab DC01/FS01),
**manage accounts** at the directory level (AD users/groups/OUs + GPO — L18/L19, scripted), **handle
incidents** including a **server/DC outage** and a **security incident** run as IC with RCA (L22/L31/L29/
L32), **perform backups** and prove recovery (L30 — 3-2-1, restore test, a ransomware-recovery scenario),
and **write reports** (health, patch compliance, asset, incident/RCA, and a status report for leadership).
You operate **safely** — every infrastructure change is **change-controlled** with `-WhatIf`/snapshots/
rollback (L17/L26, danger zones), because at this level a mistake affects everyone.

**This capstone proves:** you can keep core infrastructure (directory, servers, shares, patching, backups)
healthy, handle infrastructure incidents, and report on it — i.e. you're hireable as a **Junior System
Administrator / Infrastructure Support Engineer**, and ready for the sibling platforms.

---

## §2 — What it integrates (the lessons behind it)

| Capability | From |
|---|---|
| Provision systems: server roles, remote admin, health | L22 (+L05 Linux, L09 DNS/DHCP) |
| Manage accounts/directory: AD, GPO, provisioning (scripted) | L18, L19, L20, L21 |
| File/print services + access (group-based/least-priv) | L23, L07, L10 |
| Patching at scale (rings) + software + assets | L26, L25, L27 |
| Backups + recovery (3-2-1, restore test, ransomware) | L30 |
| Incidents (server/DC outage + security) run as IC + RCA | L22, L31, L29, L32 |
| Reporting (health/patch/asset/incident/status) | L16, L22, L26, L27, L31, L32 |
| Change/danger-zone discipline (the senior differentiator) | L17, L26, navi.project.md |

---

## §3 — Real-World framing

This is the Junior SysAdmin / Infrastructure Support role: you own the **servers, directory, services,
patching, and backups** that everyone else depends on. A mistake here is a *company-wide* event, so the job
is as much about **safe, change-controlled operation + good reporting** as raw technical skill. Employers
want evidence you can provision, manage identity at scale, keep services healthy, recover from disaster, and
**report to leadership** — and do it **without breaking the org**. This capstone is that evidence, and the
bridge into **NaviOps** (Linux/SysAdmin), **NaviOpsNetwork** (NOC), and **NaviOpsSec** (security).

---

## §4 — Demonstration (the standard to match)

The unit skills were demonstrated across Modules F–H (ENT-18 AD, ENT-19 GPO rollback, ENT-20 provisioning,
ENT-22 DC disk-full MI, ENT-26 patch rollback, ENT-30 ransomware recovery, ENT-31 IC, ENT-32 RCA). This
capstone is **operating them together as a junior sysadmin**, autonomously and **safely** (change control,
`-WhatIf`, snapshots, rollback) — to that standard — plus the **reporting** that the role requires.

---

## §5 — The project (run infrastructure operations)

### Stage 1 — Provision systems (L22 + L09/L18)
- Stand up / configure the lab infrastructure (`infra/` — DC01 with AD DS/DNS/DHCP, FS01 file services);
  verify roles + health (`server_health.ps1`, L22). Confirm DNS/DHCP work (L09). Build the OU/group
  structure (L18).

### Stage 2 — Manage accounts at scale (L18/L19/L20/L21)
- Provision users/groups via **PowerShell** (CSV → `new_user_onboard.ps1`, L20); apply/troubleshoot a
  **GPO** (L19 — and demonstrate a **backup + rollback** of a GPO, ENT-19); handle resets/lockouts incl. an
  **Event-4740 source hunt** (L21). Run an **access review** (L07/L27).

### Stage 3 — Services, patching, assets (L23/L26/L25/L27)
- Maintain **file/print services** (L23/L10, group-based/least-priv); run a **patch cycle with rings**
  (L26) incl. a **rollback** of a bad patch; keep **software** governed (L25) and the **asset register**
  accurate (L27).

### Stage 4 — Backups & recovery (L30) — the safety net
- Implement/verify **3-2-1** backups (incl. an **offline/immutable** copy); **perform a restore test** (the
  key habit — prove it works, not just that it ran); run a **ransomware-recovery** scenario (L30/ENT-30 —
  restore a share from a clean offline backup). State **RPO/RTO**.

### Stage 5 — Incidents as IC + RCA (L22/L31/L29/L32)
- Handle a **server/DC outage** (e.g. DC disk-full L22/ENT-22) as **Incident Commander** (L31): declare,
  comms, restore, timeline → **RCA** (L32) with preventive actions (monitoring/standard) implemented as
  **changes** (L26). Handle a **security incident** (L29) — contain + escalate.

### Stage 6 — Write reports (the sysadmin-differentiator)
- Produce a **report set**: server **health** report (L22), **patch-compliance** report (L26), **asset**
  report (L27), the **incident report + RCA** (L31/L32), and a **status report for leadership** (what's
  healthy, what's at risk, what changed, what's planned). Clear, accurate, decision-useful.

---

## §6 — Ticket/Scenario Simulation

Drive from `docs/tickets/INDEX.md` (server/share/account/patch/backup REQs+INCs) + the lab (`infra/`) +
the injected DC outage, bad patch, and ransomware/security scenarios. The worked examples (ENT-18…ENT-33)
are your quality reference for the scripts, the GPO rollback, the IC runs, the backups, and the RCAs.

---

## §7 — Service Desk / ITIL Perspective

This capstone owns the infrastructure-facing ITIL practices: **service request fulfillment** (provisioning),
**change enablement** (every infra change — patches, GPO, services — assessed/piloted/rollback, L17/L26),
**incident + major incident** (L31), **problem/RCA** (L32), **service configuration** (asset/CMDB, L27),
**service continuity** (backups/recovery, L30), and **reporting** for continual improvement (L16). The
through-line is **safe change** — the junior-sysadmin discipline.

---

## §8 — Execution checklist

- [ ] **Provisioned** systems: server roles + health verified; DNS/DHCP; OU/group structure (L22/L09/L18)
- [ ] **Accounts at scale**: PowerShell provisioning; GPO apply + **backup/rollback**; reset/4740 hunt; access review (L18–21/L07/L27)
- [ ] **Services/patch/assets**: shares (group-based); **patch ring + rollback**; software governed; asset register (L23/L26/L25/L27)
- [ ] **Backups**: 3-2-1 (+offline); **restore TEST**; ransomware-recovery scenario; RPO/RTO stated (L30)
- [ ] **Incidents**: a server/DC outage run as **IC** + **RCA**; a security incident contained (L22/L31/L32/L29)
- [ ] **Reports**: health · patch-compliance · asset · incident+RCA · **leadership status report**
- [ ] **Safe operation** throughout: change control, `-WhatIf`, snapshots, rollback (L17/L26, danger zones)
- [ ] Portfolio package assembled (§9)

---

## §9 — GitHub Artifact (the capstone portfolio package)

Assemble in `docs/learning/capstones/36-junior-sysadmin-project.md` (+ supporting files):
1. **Provisioning** — the server/role + directory build (with `server_health.ps1`, AD/GPO scripts) (L22/L18/L19).
2. **Account management** — scripted provisioning + the GPO backup/rollback + access review (L20/L19/L27).
3. **Services/patch/assets** — share design, the patch-ring cycle (+rollback), the asset register (L23/L26/L27).
4. **Backups & recovery** — the 3-2-1 design, the **restore-test result**, and the ransomware-recovery write-up (L30).
5. **Incident + RCA** — the server-outage incident report (IC) + the RCA with implemented preventive
   actions + the security-incident note (L31/L32/L29).
6. **Report set** — health, patch-compliance, asset, and the **leadership status report** (the sysadmin
   differentiator).

The single strongest **Junior SysAdmin** portfolio piece — "infrastructure operations I ran, safely, with
reports."

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Operated core infrastructure as a junior sysadmin: provisioned servers/roles and
  directory (AD/GPO, PowerShell), ran ringed patching with rollback, implemented 3-2-1 backups with verified
  restores and ransomware recovery, commanded a server outage with RCA-driven prevention, and produced
  health/patch/asset and leadership status reports — all under change control."*
- **Interview talking point:** **safe infrastructure operation** (change control, snapshots, `-WhatIf`,
  rollback — "I keep services up *and* don't break the org"), **backups you've actually test-restored**,
  **commanding a server incident + RCA**, and **reporting to leadership**. This is the "junior sysadmin,
  ready to grow" story — and the launch into NaviOps/NaviOpsNetwork/NaviOpsSec.
- **Serves:** Junior System Administrator · Infrastructure Support Engineer (graduation).

---

## §11 — Certification Crossover Notes

Integrates the **Microsoft server-admin path** (AD/GPO/servers), **MD-102/MS-900** (identity/endpoint/M365),
**CompTIA A+/Network+** (the underlying hardware/OS/network), and **ITIL 4** (change/incident/problem/
continuity/config). The natural next certs: Microsoft server/identity, Network+ → **NaviOpsNetwork**,
Security+ → **NaviOpsSec**, Linux+ → **NaviOps**. Detail in `alignment/CERTIFICATION-MAPPING.md` +
`SYSADMIN-PATH.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** at the infrastructure level, "service" is **reliability + communication** — keeping the
services everyone depends on healthy, and reporting clearly (especially to leadership during/after
incidents). Reports are how a sysadmin demonstrates value and earns trust.

**🔒 Security:** this capstone is dense with security ownership — AD is the **crown jewels** (least
privilege, protect admin groups — L18), GPO enforces **security baselines** (L19), patching closes
**vulnerabilities** (L26), backups are the **ransomware defense** (offline/immutable — L30), and you handle
a **security incident** (L29). Operating it all **safely** (change control, `-WhatIf`, rollback, snapshots)
is the senior differentiator — and the on-ramp to **NaviOpsSec** (security operations) and the rest of the
bridge.

---

## Quiz (Interview-Style, Graded) — capstone debrief

**Q1.** Walk me through provisioning a server + directory and how you verified it was healthy.
> **Your answer:**

**Q2.** How do you operate on infrastructure safely — what's your change/rollback discipline?
> **Your answer:**

**Q3.** Tell me about your backup strategy — and how you *proved* you could recover (incl. from ransomware).
> **Your answer:**

**Q4.** Describe a server/DC outage you commanded and the RCA-driven prevention you implemented.
> **Your answer:**

**Q5.** What would you put in a status report to leadership about the infrastructure you run?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the capstone — and the platform)* — You've gone from zero to junior sysadmin. What's strongest in
your portfolio? · Where will you go next (NaviOps / NaviOpsNetwork / NaviOpsSec)? · What would you do
differently?

---

## Search Keywords For Further Understanding

**Core**
- `junior system administrator responsibilities`
- `provision windows server active directory powershell`
- `infrastructure change management rollback snapshot`
- `3-2-1 backup restore test ransomware recovery`
- `sysadmin status report leadership`

**Going further**
- **NaviOps** (Linux/SysAdmin) · **NaviOpsNetwork** (NOC) · **NaviOpsSec** (Security Ops) —
  `SYSADMIN-PATH.md` for the route

**Service / Security (Lens E):**
- 🤝 `infrastructure reliability + leadership reporting`
- 🔒 `safe change control`, `AD crown jewels`, `offline backup ransomware defense` (→ NaviOpsSec)

---

## Capstone Status
- [ ] Provisioning · accounts · services/patch/assets · backups+restore-test · incident+RCA · reports — all done
- [ ] Portfolio package assembled (`capstones/36-junior-sysadmin-project.md`)
- [ ] Debrief quiz answered + professional-answer comparisons
- [ ] Reflection complete — **platform v1 finished** 🎓

**Congratulations — you've completed NaviOpsEnterprise.** From zero to **Help Desk → IT Support → Desktop
Support → Junior SysAdmin → Infrastructure Support**, with a portfolio that proves it. Next: pick a sibling
platform (`SYSADMIN-PATH.md`) to go deeper — **NaviOps** (Linux), **NaviOpsNetwork** (NOC), or
**NaviOpsSec** (Security).

---

*Lesson 36 written by Navi · 2026-06-21 · full-depth (capstone — graduation). Integrates Modules F–H + the
whole platform; sources per the integrated lessons; next steps in `SYSADMIN-PATH.md`.*
