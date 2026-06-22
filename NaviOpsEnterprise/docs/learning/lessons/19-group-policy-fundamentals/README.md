# Lesson 19 — Group Policy Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** how an org pushes settings to every Windows machine and user — **Group Policy**: GPOs,
linking/scope, **processing order (LSDOU)**, precedence, **security filtering**, and the #1 sysadmin
ticket "**this policy isn't applying**" (read with `gpresult` / `gpupdate`). Builds on AD/OUs (L18)
and explains the "why a setting won't stick" thread from L04.
**Primary artifact:** the "GPO not applying" troubleshooting guide + `scripts/gpresult_collect.ps1`.
**Lab:** DC01 (`infra/`).

> **How to use this lesson:** read §1–§7, do §8 (create + scope a GPO, read `gpresult`), produce §9,
> take the quiz, reflect. Then Lesson 20.

---

## §1 — Concept (Theory)

### What it is
**Group Policy** is AD's mechanism for centrally configuring **users and computers**. A **Group Policy
Object (GPO)** is a bundle of settings (security, drive maps, software, restrictions, configuration)
that you **link** to a site, the domain, or an **OU** (L18). Machines/users in that scope **apply** the
GPO at startup/logon and on a periodic refresh. It's how "every laptop gets BitLocker," "Finance gets
the F: drive mapped," and "no one can change the proxy" happen — without touching each PC.

### Why it matters for support
GPO is the answer to a whole class of mysteries: "my setting won't stick" (a GPO overrides it, L04),
"I'm missing my mapped drive" (a drive-map GPO didn't apply), "this restriction appeared" (a new GPO),
"it works for her but not me" (different OU/scope). At T2/Junior-SysAdmin you both **diagnose** GPO
problems and **create** policies — and a bad GPO can break logon for a whole org, so it's a danger
zone.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "my computer is locked down / a setting changed / my drive disappeared" — they
  don't know it's policy.
- **Level 2 — Technician:** GPOs are **settings linked to OUs/domain** that apply to the objects in
  scope; you read **what's applied** with `gpresult /r`, refresh with `gpupdate /force`, and check the
  GPO's **link, scope, and security filtering** to see why it did/didn't apply.
- **Level 3 — Engineer:** GPOs are stored in AD (**GPC**) + SYSVOL (**GPT**) and processed in **LSDOU**
  order (**L**ocal → **S**ite → **D**omain → **O**U, child OUs last) so the **last writer wins**
  (closest-to-the-object precedence), unless **Enforced** (overrides) or **Block Inheritance** is set;
  application is gated by **security filtering** (the user/computer must have *Read + Apply* — default
  Authenticated Users) and optional **WMI filters**; settings write to protected **registry** locations
  (L04). Computer settings apply at boot, user settings at logon, both refresh ~90 min. This is *why*
  precedence, scope, and filtering explain virtually every "didn't apply."

### Two Teaching Approaches (Lens B) — link, scope, precedence, filtering
**Approach 1 (technical):** a GPO only affects an object if (a) it's **linked** at or above the object's
location, (b) the object is **in scope** (the link's OU contains it), (c) the object passes **security
filtering** (Read+Apply) and any WMI filter, and (d) it **wins precedence** (LSDOU; closest OU wins
unless Enforced). Break any of those four and the setting "doesn't apply." Diagnose by checking each.

**Approach 2 (analogy):** GPO is a **company dress code distributed by org chart**. A policy posted at
the **company** level applies to everyone; a stricter **department** policy (closer to you) overrides
the general one (LSDOU/precedence); HR can mark a policy **mandatory** (Enforced) so a department can't
opt out, or a department can **opt out** of inherited policies (Block Inheritance); and a policy can be
limited to a **specific team** (security filtering). **Where it breaks down:** unlike a posted memo,
the rules combine and conflict by precise precedence — so "why am I following this rule?" is answered by
`gpresult`, the org's "show me every policy that applies to me."

### Visual (ASCII) — LSDOU processing & the four "did it apply?" gates
```
   PROCESSING ORDER (later overrides earlier — closest to object wins):
     Local ─▶ Site ─▶ Domain ─▶ OU(parent) ─▶ OU(child)        [Enforced links override this; Block Inheritance skips]
        (weakest)                              (strongest, normally)

   "DID THIS GPO APPLY?" — four gates (all must pass):
     1 LINKED at/above the object's OU?        2 object IN SCOPE (in that OU)?
     3 SECURITY FILTER: Read+Apply for it?     4 WINS PRECEDENCE (LSDOU/Enforced)?
   Read the verdict:  gpresult /r   (Applied vs Denied + reason)     Refresh:  gpupdate /force
```

---

## §2 — Tools & Commands

| Task | GUI (GPMC) | CLI / PowerShell |
|---|---|---|
| Manage GPOs | Group Policy Mgmt (`gpmc.msc`) | `Get-GPO -All` |
| What applies to a user/computer | GPMC → Group Policy Results | `gpresult /r` · `gpresult /h report.html` |
| Force a refresh | — | `gpupdate /force` |
| See a GPO's links & scope | GPMC → GPO → Scope tab | `Get-GPInheritance -Target "OU=Sales,…"` |
| Security filtering | GPO → Scope → Security Filtering | (GPMC) |
| Model "what would apply" | GPMC → Group Policy Modeling | — |
| Back up / restore a GPO | GPMC right-click | `Backup-GPO` / `Restore-GPO` |
| Create / link a GPO (⚠) | GPMC new + link | `New-GPO` · `New-GPLink` |

```powershell
gpresult /r                                   # applied + denied GPOs for the current user/computer + WHY
gpresult /h C:\temp\gpo.html                  # full HTML report (the best diagnostic view)
gpupdate /force                               # reapply policy now (don't wait ~90 min)
Get-GPInheritance -Target "OU=Sales,OU=Corp,DC=corp,DC=example"   # links + order + blocked?
Get-GPResultantSetOfPolicy -User corp\jdoe -Computer CLIENT01 -ReportType Html -Path rsop.html
```

> **Lab:** create/link/edit GPOs only in **DC01 / corp.example**, scoped to a **test OU** with a test
> account. Linking an untested GPO at the domain or a populated OU is a **danger zone** (can break logon
> org-wide) — confirm scope, test small, back up first (`navi.project.md`).

---

## §3 — Real-World Support Context & Use Cases

- **"It won't apply" is the signature ticket** — a mapped drive missing, a security setting absent, a
  restriction not in effect. `gpresult` + the four gates resolve it.
- **"A setting won't stick"** (from L04) → a GPO is overriding the local change; the user can't win
  against policy by design.
- **Scope/precedence bugs:** "works for her, not me" = different OU, security filtering, or a winning
  GPO; an over-broad link hits people it shouldn't.
- **Drive maps, printers, security baselines, software restrictions, BitLocker, the wallpaper/lock
  screen** — all commonly delivered by GPO.
- **The danger:** a bad GPO (e.g. a wrong security setting linked at the domain) can lock out logon for
  everyone — which is why GPO is change-controlled (L17/L26) and tested in a lab OU first.
- **Exam framing:** MD-102 (Windows config/management; Intune is the cloud analog), and the Microsoft
  AD admin path; A+ touches policy concepts.

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0211 (P3):** *"My F: drive (Finance share) isn't there anymore — it used to map
> automatically. — asmith, in Finance."*

1. **Know the mechanism:** the F: map is delivered by a **drive-map GPO** scoped to Finance — so this
   is "the GPO didn't apply," not a share problem (L23).
2. **Read what applied:** `gpresult /r` (or `/h`) on asmith's session → is the **"Finance Drive Maps"**
   GPO listed under **Applied** or **Denied** (and the reason)?
   - **Denied — security filtering / not in scope** → asmith isn't in the Finance group/OU the GPO
     targets (ties to L18 reorg!) → fix membership/OU.
   - **Not listed at all** → the link is broken/disabled or she's in the wrong OU.
   - **Applied but no drive** → the share/permission side (L23) or a script error.
3. **Refresh:** `gpupdate /force` then re-check — sometimes it's just a refresh-timing issue
   (policy applies at logon / ~90 min).
4. **Fix the failing gate:** correct group membership/OU (L18) or repair the GPO link/filtering; have
   her re-logon (drive maps run at logon).
5. **Verify:** F: maps; confirm with asmith.
6. **Document:** which gate failed (e.g. "removed from Finance group in the reorg → GPO security filter
   denied → re-added + re-logon").

The teaching point: **`gpresult` tells you Applied vs Denied + the reason** — then you fix the specific
gate (link / scope / filtering / precedence), not random guesses.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: a Group Policy isn't applying (or the wrong one is).**

### 1 · Symptoms
A mapped drive/printer missing · a security setting/restriction absent (or unexpectedly present) · "my
setting won't stick" · "works for them, not me" · a change you made to a GPO isn't taking effect.

### 2 · Possible Causes (most-likely first)
1. **Scope/membership**: object not in the GPO's OU or **security-filter** group (ties to L18).
2. **Refresh timing**: not applied yet (needs logon / `gpupdate`).
3. **Precedence**: another GPO **wins** (LSDOU / Enforced) and overrides it.
4. **Link disabled/Block Inheritance**: the GPO isn't reaching the OU.
5. **Filtering**: WMI filter excludes the machine; missing Read+Apply.
6. **Replication/SYSVOL**: GPO edit not replicated to the DC the client used.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | `gpresult /r` (or `/h`) — Applied vs Denied + reason | Denied (filter/scope) | fix group/OU membership (L18) |
| 2 | `gpupdate /force` + re-logon | applies now | it was refresh timing — done |
| 3 | GPMC Scope / `Get-GPInheritance` (precedence) | another GPO wins / Enforced | adjust precedence/Enforced |
| 4 | Link enabled? Block Inheritance set? | disabled/blocked | enable link / remove block |
| 5 | Security filtering (Read+Apply) / WMI filter | missing/excluded | fix filtering |
| 6 | Behavior differs by DC / recent edit | yes | SYSVOL/AD replication (escalate) |

### 4 · Resolution Steps
Correct OU/group membership or security filtering so the object is in scope; `gpupdate /force` +
re-logon; adjust precedence (link order / Enforced) so the intended GPO wins; enable the link / remove
Block Inheritance; fix/clear a WMI filter; allow/force replication. Always **test in a lab OU** before
changing a broadly-linked GPO.

### 5 · Escalation Criteria
Escalate to a senior AD admin / change management for: editing **domain-linked** or widely-scoped GPOs,
security-baseline changes, GPO **replication/SYSVOL** issues, and anything that could affect logon
broadly. A broadly-linked GPO change is a **Change** (L17/L26) with org-wide blast radius — never
ad-hoc. Attach: the `gpresult /h` report, the GPO link/scope/filtering, what you changed.

### 6 · Post-Incident Documentation
Ticket note (which gate failed + fix, with the `gpresult` evidence), GPO change recorded as a Change
(L26), KB/runbook for the recurring "GPO not applying" diagnostic, problem ticket if a structural cause
hit many (L32).

---

## §6 — Ticket Simulation

> **Ticket ENT-19 / INC (P2):** *"We pushed a new security GPO last night to tighten settings, and now
> a whole OU of users get an error at logon and some can't run a key business app. — IT change
> follow-up."* Channel: post-change incident.

**Triage:** a **recent GPO change** + **many users in one OU** failing right after → the new GPO is the
cause (a textbook **change-induced incident**, ties to L17/L26). Business-impacting → **P1/P2**.

**Worked resolution:**
1. **Correlate to the change:** the symptom started **after** the GPO push, scoped to the OU it was
   linked to → strong cause. (This is *why* changes are tracked, L17.)
2. **Confirm with `gpresult`:** on an affected user, `gpresult /h` → the new **"Security Hardening"**
   GPO is **Applied**; identify the specific setting breaking the app (e.g. an over-tight software
   restriction / removed permission / blocked port).
3. **Fast restore (incident priority = restore service):** the right move is to **roll back the change**
   — unlink (or disable the link of) the new GPO from the affected OU, or `Restore-GPO` to the prior
   version, then `gpupdate /force` + re-logon. (You backed it up before linking — danger-zone
   discipline.)
4. **Verify:** affected users log on cleanly and the app runs again.
5. **Re-do it safely (the lesson):** the GPO wasn't piloted — re-scope it to a **test OU** first,
   identify the offending setting, fix it, then re-deploy via change control to a **pilot ring** before
   the whole OU (L26).
6. **Problem/RCA (L32):** *why* did an untested GPO reach a populated OU? Tighten the change/GPO process.

**The professional ticket note:**
```
SUMMARY: New "Security Hardening" GPO linked to the Sales OU overnight broke logon + a business app for
the whole OU. Rolled back (unlinked GPO + Restore-GPO to prior) → service restored. Re-scoping to a test
OU + pilot before redeploy. RCA on the change process.
SYMPTOM: ~OU-wide logon error + app failure, started right after last night's GPO push.
DIAGNOSIS: gpresult /h on affected user → new GPO Applied; offending setting = over-tight software
restriction policy blocking the app.
CAUSE: untested security GPO linked directly to a populated OU (no pilot) — change-induced incident.
RESOLUTION (restore first): unlinked the GPO from Sales OU + Restore-GPO to prior version; gpupdate
/force + re-logon; logon + app verified.
FOLLOW-UP: re-test in a lab OU, fix the offending setting, redeploy via change control to a pilot ring
(L26); PROBLEM/RCA (L32) — no untested GPO to a populated OU; backups confirmed taken pre-change.
```

---

## §7 — Service Desk / ITIL Perspective

- **GPO sits squarely in change enablement** (L17/L26): a GPO link/edit is a **Change** with
  potentially org-wide blast radius — assess, pilot, schedule, **rollback** (backup the GPO first).
- **Change-induced incidents** are common here ("it broke after the GPO push") — the desk's clustered
  tickets after a change are the early signal; restore first (roll back), then fix properly.
- **Diagnosis at the desk, structure at the admin level:** T2 reads `gpresult` and fixes scope/
  membership; senior admins own GPO design, domain links, and replication.
- **Priority/risk:** a broadly-scoped GPO problem is high-impact (many users / logon) → P1/P2 + major
  incident handling (L31) if it hits a whole site.
- **Metric angle:** good GPO/change discipline (pilot rings, backups) prevents the most damaging
  self-inflicted outages.

---

## §8 — Practical Lab (build this yourself)

**Goal:** create and scope a GPO, then read `gpresult` to prove what applied and why — in a **test OU**.

### Lens C — Manual → Automation → Why
- **Manual:** create/link a GPO in GPMC; run `gpresult` on a client by hand.
- **Automated:** `gpresult_collect.ps1` gathers the RSoP/HTML report (and can collect from many
  machines) for fast, consistent "what applied + why" diagnosis; `Backup-GPO`/`Restore-GPO` script the
  safety net.
- **Why:** "did the policy apply and why not" recurs constantly; a script standardizes the evidence and
  scales the check; scripted backup/restore makes rollback reliable (the difference between a 5-minute
  recovery and an outage).

### Steps
1. **Lab + test OU:** in `corp.example`, create a **Test** OU with a test user/computer (never the
   populated OUs).
2. **Create a GPO:** `New-GPO "Lab Drive Map"` (or a simple wallpaper/setting); **link** it to the Test
   OU (`New-GPLink`); set security filtering to a test group.
3. **Apply + read:** on the test client, `gpupdate /force`, re-logon, then `gpresult /r` and
   `gpresult /h` — find your GPO under **Applied**.
4. **Break a gate on purpose:** remove the test user from the filter group → `gpresult` shows it
   **Denied** (reason: security filtering) — internalize the four gates.
5. **Precedence drill:** link a conflicting setting at a higher level and observe **LSDOU** decide; try
   **Enforced**.
6. **Safety:** `Backup-GPO` your test GPO; practice `Restore-GPO` (the rollback you'll rely on in §6).
7. **Write `scripts/gpresult_collect.ps1`** and the "GPO not applying" troubleshooting guide.

### Lens D — the raw artifact (gpresult tells you Applied vs Denied + why)
```
> gpresult /r   (excerpt)
   Applied Group Policy Objects
       Default Domain Policy
       Finance Drive Maps
   The following GPOs were not applied because they were filtered out
       Security Hardening (Sales)   Filtering: Denied (Security)   ← user lacks Read+Apply / not in filter group
       Lab Drive Map                Filtering: Denied (Security)
#   "Applied" vs "Denied + reason" is the whole diagnosis. Denied (Security) = scope/filter/membership
#   (fix in AD, L18). If it's "Applied" but the effect is missing → look past GPO (the share/script, L23).
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/gpo-not-applying.md` — the four-gate diagnostic + `gpresult`/`gpupdate`.
2. **Troubleshooting Guide:** `docs/troubleshooting/group-policy.md` — the full spine.
3. **Ticket Notes:** `docs/tickets/ENT-19-bad-gpo-rollback.md` — the worked ENT-19.
4. **KB Article:** `docs/kb/` — internal "Reading gpresult: Applied vs Denied (and the four gates)".
5. **Incident Report:** the change-induced GPO outage as an incident report + RCA (L31/L32).
6. **Portfolio Artifact:** §10 bullet + the LSDOU / four-gates / rollback talking points.
7. **Script:** `scripts/gpresult_collect.ps1` (+ backup/restore helper; `Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Managed Group Policy (GPMC + PowerShell): diagnosed 'policy not applying' via
  `gpresult` and the link/scope/filtering/precedence model, and recovered a change-induced GPO outage by
  rolling back to a backed-up GPO before re-deploying through a pilot ring."*
- **Interview talking point:** **LSDOU** processing + the **four gates** (linked/in-scope/filtered/
  precedence) for "why a GPO didn't apply," reading **`gpresult`** (Applied vs Denied + reason), and
  **rolling back a bad GPO** (backup first) — restore service, then re-deploy safely.
- **Serves:** Help Desk T2, IT Support, Junior SysAdmin.

---

## §11 — Certification Crossover Notes

- **MD-102:** Windows configuration/management (Group Policy + Intune as the cloud analog). The
  Microsoft AD admin path covers GPO deeply. **A+ (Core 2):** policy/management concepts. Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** GPO problems are invisible to users ("my drive's just gone") — explain that a central
policy delivers it and that you're fixing the policy/scope, and set expectations around the re-logon/
refresh.

**🔒 Security:** Group Policy **is** how security baselines are enforced (BitLocker, password policy,
restrictions, blocking risky settings) — respect that a setting "won't change" because **security
policy owns it** (don't help a user defeat a control). Conversely, GPO is an attacker target: a
malicious GPO can push settings/scripts fleet-wide (a known attack technique — NaviOpsSec domain), so
GPO **edit rights are privileged**, changes are change-controlled (L17/26), and **backups** enable both
rollback *and* tamper detection. Every GPO link/edit is a **danger zone**: test OU first, `-WhatIf`/
backup, never untested to a populated OU.

---

## Quiz (Interview-Style, Graded)

**Q1.** A user is missing a mapped drive that's delivered by GPO. What command tells you whether the GPO
applied, and what are the possible reasons it didn't?
> **Your answer:**

**Q2.** Explain LSDOU and what "the closest GPO wins" means for precedence.
> **Your answer:**

**Q3.** Name the four conditions that must all be true for a GPO to apply to a user/computer.
> **Your answer:**

**Q4.** **Scenario:** a security GPO pushed last night broke logon for an entire OU. What's your
*immediate* priority and action, and how should the GPO have been deployed?
> **Your answer:**

**Q5.** A user says a setting they keep changing reverts every time. What's the likely cause and how do
you confirm it?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `group policy LSDOU processing order precedence`
- `gpresult /r /h interpret applied denied`
- `gpo security filtering not applying`
- `gpupdate force refresh`
- `backup restore GPO rollback`

**Tools**
- `gpmc.msc Get-GPInheritance`
- `Get-GPResultantSetOfPolicy RSoP`

**Going further**
- `user provisioning and deprovisioning` (L20) · `patch management / change` (L26) ·
  `file shares and permissions` (L23) · `endpoint troubleshooting` (L24)

**Service / Security (Lens E):**
- 🤝 `explain central policy to users`, `re-logon for policy refresh`
- 🔒 `GPO security baseline enforcement`, `malicious GPO attack` (→ NaviOpsSec), `GPO change control`

---

## Lesson Status
- [ ] §8 lab completed (create/scope a GPO in a test OU + gpresult drills + backup/restore + script)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 20 — User Provisioning & Deprovisioning**.

---

*Lesson 19 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: Microsoft Group
Policy docs (processing/precedence, GPMC), MD-102 objectives.*
