# Lesson 18 — Active Directory Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the directory that underpins the corporate Windows world — **Active Directory**: domains,
**OUs**, users, groups, the **logon/authentication** flow, and the two ways you'll work it (the
**ADUC** console + **PowerShell**). This is the foundation of provisioning (L20), resets (L21), GPO
(L19), and file access (L07/L23) — and the first true Junior-SysAdmin skill.
**Primary artifact:** `scripts/aduc_query.ps1` + the AD account-lookup runbook. **Lab:** DC01
(`infra/`).

> **How to use this lesson:** read §1–§7, do §8 (query + understand AD in the lab), produce §9, take
> the quiz, reflect. Then Lesson 19.

---

## §1 — Concept (Theory)

### What it is
**Active Directory (AD DS)** is Microsoft's on-prem **directory service** — the central database of an
organization's **users, computers, groups, and policies**, hosted on **domain controllers (DCs)**. It
provides **authentication** (proving who you are when you log on) and **authorization** structure (via
group membership, L07), and it's organized into a **domain** (`corp.example`), subdivided into
**Organizational Units (OUs)** that hold objects and anchor **Group Policy** (L19). Most corporate
Windows logons, file shares, and email identities trace back to AD (and, in the cloud, its sibling
**Entra ID**, L11).

### Why it matters for support
The moment you move past pure help desk, AD is your daily tool: you look up accounts, check group
memberships ("why can't they access X?", L07), reset/unlock (L21), onboard/offboard (L20), and read
why a logon failed. Understanding AD's structure makes every identity ticket precise instead of
guesswork.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "my company username and password" — they log into Windows and email with it.
- **Level 2 — Technician:** AD is a **tree of OUs containing user/computer/group objects** on the
  domain controllers; you find an account (ADUC / `Get-ADUser`), check which **OU** it's in and which
  **groups** it's in, and see its status (enabled? locked? password expired?).
- **Level 3 — Engineer:** AD is an **LDAP directory** with a **schema** of object classes/attributes;
  authentication uses **Kerberos** (tickets) / NTLM; objects have a unique **SID** (the basis of the
  access token, L07) and a **distinguishedName** (`CN=Jane Doe,OU=Sales,OU=Corp,DC=corp,DC=example`);
  DCs **replicate** the database between each other; **OUs** are the unit of delegation + GPO scope
  (L19). This is *why* a group change needs a re-logon (new token), why an account's OU determines its
  policy, and why "replication delay" can explain inconsistent behavior.

### Two Teaching Approaches (Lens B) — domain, OU, object, group
**Approach 1 (technical):** a **domain** is a security/administrative boundary with its own directory
on DCs; **OUs** are containers that organize objects and to which **GPOs** link and admin rights are
**delegated**; **objects** are users/computers/groups (each with attributes + a SID);
**groups** bundle users to assign access/rights by role. Authentication is centralized at the DC;
authorization is decided at resources by group SIDs in the token (L07).

**Approach 2 (analogy):** AD is a **large company's HR + security system in one building**. The
**domain** is the company; **OUs** are the **departments/floors** (you can set floor-specific rules and
let a floor manager run their floor — GPO + delegation); a **user object** is an **employee's HR record
+ ID badge**; **groups** are **team rosters** that grant access to specific rooms (L07); the **domain
controller** is the **security desk** that checks your badge at login (authentication). **Where it
breaks down:** unlike a single building, there can be several security desks (DCs) that must stay in
sync (**replication**) — so a change made at one desk may take a moment to appear at another.

### Visual (ASCII) — the AD structure & logon flow
```
   DOMAIN: corp.example   (on Domain Controllers: DC01 …)   ← authentication (Kerberos)
   └─ OU=Corp
       ├─ OU=Departments
       │    ├─ OU=Sales      → [user] jdoe   (SID, DN=CN=jdoe,OU=Sales,…)  member of: Sales, Projects
       │    └─ OU=Finance    → [user] asmith                               member of: Finance
       ├─ OU=Groups          → [group] Finance, Projects, IT-Admins
       └─ OU=Computers       → [computer] CLIENT01, LT-0427

   LOGON: user → DC checks credentials (Kerberos ticket) → token built {user SID + group SIDs} →
          access to resources decided by those SIDs (L07).  OU determines which GPOs apply (L19).
```

---

## §2 — Tools & Commands

| Task | GUI (ADUC etc.) | PowerShell (`ActiveDirectory` module) |
|---|---|---|
| Find a user | ADUC (`dsa.msc`) → Find | `Get-ADUser jdoe -Properties *` |
| User's groups | ADUC → Member Of tab | `Get-ADPrincipalGroupMembership jdoe` |
| Group's members | ADUC → group → Members | `Get-ADGroupMember Finance` |
| Account status (locked/enabled/expiry) | ADUC → Account tab | `Get-ADUser jdoe -Properties LockedOut,Enabled,PasswordExpired,PasswordLastSet` |
| Find a computer | ADUC → Computers | `Get-ADComputer CLIENT01` |
| Which OU is it in | ADUC location | `(Get-ADUser jdoe).DistinguishedName` |
| Move an object (⚠) | ADUC drag/Move | `Move-ADObject` |
| Reset/unlock (L21) | ADUC right-click | `Set-ADAccountPassword` / `Unlock-ADAccount` |

```powershell
Get-ADUser jdoe -Properties Enabled,LockedOut,PasswordExpired,MemberOf,Department,Manager |
  Select Name,Enabled,LockedOut,PasswordExpired,Department
Get-ADPrincipalGroupMembership jdoe | Select Name           # the groups behind their access (L07)
Get-ADGroupMember Finance | Select Name                      # who's in the Finance group
Search-ADAccount -LockedOut                                  # all locked accounts right now (L21)
```

> **Lab:** target **DC01 / corp.example** (`infra/`). All write ops (`Set-`/`Move-`/`Remove-`) are
> **danger zones** — run with `-WhatIf` first; never against a live domain (`navi.project.md`).

---

## §3 — Real-World Support Context & Use Cases

- **The identity backbone:** almost every "can't access / can't log in / who is this user" ticket is
  answered in AD. It's the T2/IT-Support/Junior-SysAdmin workhorse.
- **Group membership = access** (L07): "why can they/can't they reach X?" → check `Get-ADPrincipalGroup
  Membership`. Grant by group, never per-user ACL.
- **Account status reads:** **locked** (L21 — too many bad tries), **disabled** (offboarded/suspended,
  L20), **password expired** (L01) — each is a different fix; AD tells you which.
- **OU placement matters:** an object's OU decides its **GPOs** (L19) and delegated admin — a user in
  the wrong OU gets the wrong policy.
- **Hybrid reality:** most orgs sync AD ↔ **Entra ID** (L11) so the same identity works on-prem and in
  M365; a change on-prem syncs to the cloud (and vice-versa in cloud-first shops).
- **Exam framing:** MS-900/MD-102 (identity, Entra), and the broader Microsoft identity/AD admin path;
  A+ touches domain vs workgroup + account concepts.

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0114 (P2):** *"I can log into my computer fine, but I can't get into email or the
> Finance share. — asmith."* (Account exists; *something* about it is wrong.)

1. **Find the account:** `Get-ADUser asmith -Properties Enabled,LockedOut,PasswordExpired,MemberOf` —
   read its real state, don't assume.
2. **Status:** Enabled = True, LockedOut = False, PasswordExpired = False → **auth is fine** (matches
   "logs into Windows OK"). So it's **authorization/membership**, not the account.
3. **Group membership:** `Get-ADPrincipalGroupMembership asmith` → the **Finance** group is present but
   the mail-enabled / licensing group is **missing** (or, in hybrid, the cloud license — L11). For the
   share specifically, confirm **Finance** group really grants it (L07/L23).
4. **OU check:** `(Get-ADUser asmith).DistinguishedName` — is she in the expected OU? A wrong-OU move
   can strip group-based access or GPO (L19).
5. **Resolve the gap:** add the missing group (the right way — L07/L20) and/or fix licensing (L11);
   have her **re-logon** (token refresh, L07).
6. **Document:** note the exact group/OU gap and the re-logon requirement.

The teaching point: **read the account's real attributes first** — enabled/locked/expired vs group
membership vs OU each route to a different fix; AD shows you which.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: AD account / logon / membership issues.**

### 1 · Symptoms
Can't log on at all · logs into Windows but not email/shares · "account locked/disabled" · access lost
after a move/reorg · inconsistent behavior on different machines · new account "doesn't work yet."

### 2 · Possible Causes (most-likely first)
1. **Account state**: locked (L21), disabled (L20), password expired (L01).
2. **Group membership** missing/changed → authorization gap (L07).
3. **Wrong OU** → wrong GPO (L19) / lost delegated access.
4. **Stale token** — membership changed, no re-logon (L07).
5. **Replication delay** — change made on one DC not yet on another.
6. **Hybrid sync** — on-prem change not yet synced to Entra (L11).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | `Get-ADUser -Properties Enabled,LockedOut,PasswordExpired` | locked/disabled/expired | unlock/enable/reset (L21/L20) |
| 2 | `Get-ADPrincipalGroupMembership` | missing group | add via group (L07/L20) + re-logon |
| 3 | `(Get-ADUser).DistinguishedName` (OU) | wrong OU | move back (approved) → fixes GPO/access |
| 4 | Re-logged in since change? | no | sign out/in (stale token) |
| 5 | Behavior differs by time/DC | yes | replication delay — wait/force `repadmin` (escalate) |
| 6 | Hybrid: synced to Entra? | no | wait/force sync or fix on the correct side (L11) |

### 4 · Resolution Steps
Unlock/enable/reset the account (L21/L20); add the correct **group** (least privilege, L07) + re-logon;
move the object back to the correct **OU** (with approval — affects GPO, L19); allow/force replication
or hybrid sync; for hybrid, change on the **authoritative** side (on-prem AD in synced orgs).

### 5 · Escalation Criteria
Escalate to a senior AD admin for: replication problems (`repadmin`/`dcdiag`), schema/forest-level
issues, FSMO/DC health, trust relationships, and bulk/structural OU changes. Write ops on a **live**
domain that you're not authorized for stop at the boundary (danger zone). Attach: `Get-ADUser`
properties, group membership, DN/OU, what you tried.

### 6 · Post-Incident Documentation
Ticket note (account state + group/OU fix + re-logon), access records (who's in what — feeds L27),
KB for recurring patterns, problem ticket if a reorg/OU move stranded many (L32).

---

## §6 — Ticket Simulation

> **Ticket ENT-18 / INC-0107 (P2):** *"After the department reorg yesterday, half my team can't access
> the Projects share anymore. — team lead, ~6 users incl. jdoe."* Channel: ticket.

**Triage:** **multiple** users, all **after a reorg** (an OU/group change) → a **structural** AD cause,
not 6 separate problems. Business-impacting → **P2** (P1 if it blocks a whole function).

**Worked resolution:**
1. **Find the pattern:** `Get-ADPrincipalGroupMembership jdoe` (a representative) → the **Projects**
   group is **missing**; check another affected user → same. So the reorg removed the team from the
   group (or moved them to an OU whose membership rules differ).
2. **Confirm the cause:** the reorg **moved** the team to a new OU; if Projects access was granted via a
   group tied to the *old* OU (or a dynamic rule / a GPO-mapped drive), the move stripped it.
3. **Verify authorization:** the team **should** still have Projects access (lead confirms) — so this is
   a reorg side-effect to **fix**, not a deliberate removal (don't blindly re-grant without confirming,
   L07).
4. **Resolve at the structural level:** re-add the team to the **Projects** group (bulk —
   `Add-ADGroupMember Projects -Members (Get-ADUser -Filter ...)`), or correct the OU/group mapping so
   membership is restored correctly; have users **re-logon** (token).
5. **Verify:** representative users can reach `\\FS01\Projects` again (L23).
6. **Prevent (problem, L32):** reorg/OU moves should preserve role-group membership — feed this into the
   provisioning/move process (L20) so future reorgs don't strip access.

**The professional ticket note:**
```
SUMMARY: Dept reorg moved a team to a new OU and dropped them from the Projects security group →
~6 users lost \\FS01\Projects access. Confirmed still authorized; bulk-re-added to Projects group;
re-logon restored access. Raised a Problem to make OU moves preserve role-group membership.
SYMPTOM: ~6 users "Access denied" to Projects share after yesterday's reorg.
DIAGNOSIS: Get-ADPrincipalGroupMembership (jdoe + 1 other) → Projects group missing; cause = OU move
during reorg stripped the group-based access.
CAUSE: reorg OU move removed role-group membership (structural, not per-user).
RESOLUTION: lead re-approved; bulk Add-ADGroupMember Projects; users signed out/in; verified share
access (L23).
FOLLOW-UP: PROBLEM (L32) — OU-move/offboarding process must preserve role groups; update provisioning
runbook (L20). KB on "access lost after a reorg".
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Account/Access (Identity). Single = **Incident**; a reorg stranding many = an **Incident
  cluster → Problem** (L32); structural changes are **Changes** (L17/L26).
- **AD is where identity incidents are diagnosed and resolved** — the desk reads it; senior admins own
  its structure (replication, schema, DC health).
- **Group-based, least-privilege access** (L07) is the standard AD enforces; "grant by group" is both
  good practice and what makes bulk fixes (like the reorg) possible.
- **Hybrid awareness:** in AD↔Entra synced orgs, know which side is authoritative so you change the
  right one (L11) — a frequent source of "I fixed it but it reverted."
- **Metric/risk angle:** AD is critical infrastructure — careless writes affect many people; this is why
  it's a danger zone with `-WhatIf` discipline and change control.

---

## §8 — Practical Lab (build this yourself)

**Goal:** stand up (or use) the lab AD, and become fluent at *reading* AD with ADUC + PowerShell. (Read
first; writes come in L20/L21.)

### Lens C — Manual → Automation → Why
- **Manual:** click through ADUC to find a user, their groups, their OU.
- **Automated:** `aduc_query.ps1` returns a user's status (enabled/locked/expired), groups, OU, manager,
  and last logon in one shot — and can run for many users (audits, L27).
- **Why:** "what's the state of this account and what does it have access to?" is the most-repeated
  identity question; a script answers it instantly and feeds provisioning/access reviews. ADUC is fine
  for one user; PowerShell scales to the fleet.

### Steps
1. **Lab:** build DC01 / `corp.example` per `infra/README.md` (or use an existing lab) with the seed OUs,
   users (`jdoe`, `asmith`), and groups (`Finance`, `Projects`).
2. **Read with ADUC:** find `jdoe`, view the Account tab (status), Member Of (groups), and note the OU.
3. **Read with PowerShell:** run the §2 block — `Get-ADUser`, `Get-ADPrincipalGroupMembership`,
   `Get-ADGroupMember`, `Search-ADAccount -LockedOut`.
4. **Map access:** for `jdoe`, list her groups and tie one to a share (L07/L23) — "this group grants
   this access."
5. **DN/OU awareness:** print `(Get-ADUser jdoe).DistinguishedName`; understand how OU → GPO (preview
   L19).
6. **Write `scripts/aduc_query.ps1`** (status + groups + OU + manager + lastLogon) and the
   account-lookup runbook.

### Lens D — the raw artifact (the account attributes that route every fix)
```
> Get-ADUser asmith -Properties Enabled,LockedOut,PasswordExpired,MemberOf | fl Name,Enabled,LockedOut,PasswordExpired
   Name           : asmith
   Enabled        : True          ← not disabled (offboarding would set False, L20)
   LockedOut      : False         ← not locked (too-many-tries would set True, L21)
   PasswordExpired: False         ← not expired (the L01 expiry ticket)
   MemberOf       : {CN=Finance,…}  ← has Finance, MISSING the mail/Projects group → it's AUTHZ (L07), not auth
#   These four attributes + group membership tell you EXACTLY which fix applies. Read them first.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/ad-account-lookup.md` — find an account, read status/groups/OU, decide
   the fix.
2. **Troubleshooting Guide:** `docs/troubleshooting/ad-account-logon.md` — the full spine.
3. **Ticket Notes:** `docs/tickets/ENT-18-reorg-access-loss.md` — the worked ENT-18.
4. **KB Article:** `docs/kb/` — internal "Reading an AD account: enabled/locked/expired/groups/OU"
   reference for T1→T2.
5. **Incident Report:** the reorg access-loss as a mini incident report + the Problem (L32).
6. **Portfolio Artifact:** §10 bullet + the account-attributes / group-based-access talking points.
7. **Script:** `scripts/aduc_query.ps1` (`Invoke-ScriptAnalyzer`-clean; read-only).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Administered Active Directory (ADUC + PowerShell `ActiveDirectory` module):
  built an account-audit script (status, group membership, OU, last logon) and resolved a reorg-driven
  group-membership access incident affecting multiple users."*
- **Interview talking point:** the **AD structure** (domain → OU → object/group), reading the **account
  attributes** (enabled/locked/expired) vs **group membership** vs **OU** to route a fix, and
  **group-based least-privilege** access — plus why a membership change needs a **re-logon**.
- **Serves:** Help Desk T2, IT Support, Junior SysAdmin (the first true sysadmin skill).

---

## §11 — Certification Crossover Notes

- **MS-900 / MD-102:** identity, Entra ID (the cloud sibling), hybrid identity. The deep on-prem AD path
  is Microsoft's identity/server admin certs. **A+ (Core 2):** domain vs workgroup, account basics.
  Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** identity problems block people entirely (no logon = no work) — diagnose precisely
(don't reset everything hopefully), confirm the user's real need, and explain the re-logon step so
they're not surprised access "didn't work" immediately.

**🔒 Security:** AD is the **crown jewels** — compromising it compromises everything. Apply **least
privilege** (group-based, L07; few admins), **never make users Domain Admins**, protect privileged
groups (Domain/Enterprise Admins), and watch for security-relevant changes (unexpected new accounts,
group additions to admin groups — these are classic attacker moves, the NaviOpsSec domain). Every AD
**write is a danger zone** (`navi.project.md`): `-WhatIf` first, target the lab, and treat live-domain
changes with change control (L17). Disabled (not deleted) is the safe offboarding default (L20).

---

## Quiz (Interview-Style, Graded)

**Q1.** What is an OU, and name two things that an object's OU determines.
> **Your answer:**

**Q2.** A user logs into Windows fine but can't access email or a file share. What does that tell you,
and what do you check in AD?
> **Your answer:**

**Q3.** What's the difference between an account being *locked*, *disabled*, and *password expired* —
and how do you tell which it is?
> **Your answer:**

**Q4.** **Scenario:** after a department reorg, several users on a team lose access to a shared folder.
What's the likely cause, how do you confirm it, and how do you fix it for all of them?
> **Your answer:**

**Q5.** Why does adding a user to a group often not take effect until they log off and back on?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `active directory domain OU users groups explained`
- `Get-ADUser Get-ADPrincipalGroupMembership PowerShell`
- `AD account locked vs disabled vs expired`
- `active directory kerberos logon SID token`
- `AD replication delay troubleshooting`

**Tools**
- `ADUC dsa.msc find user`
- `Search-ADAccount -LockedOut`

**Going further**
- `group policy fundamentals` (L19) · `user provisioning and deprovisioning` (L20) ·
  `password resets` (L21) · `file shares and permissions` (L23) · `entra ID hybrid` (L11)

**Service / Security (Lens E):**
- 🤝 `explain re-logon for group changes`, `precise identity diagnosis`
- 🔒 `least privilege AD`, `protect domain admins`, `AD as attacker target` (→ NaviOpsSec)

---

## Lesson Status
- [ ] §8 lab completed (DC01 lab + ADUC/PowerShell read drills + aduc_query.ps1 + runbook)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 19 — Group Policy Fundamentals**.

---

*Lesson 18 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: Microsoft AD DS
docs, `ActiveDirectory` PowerShell module, MS-900/MD-102 identity objectives.*
