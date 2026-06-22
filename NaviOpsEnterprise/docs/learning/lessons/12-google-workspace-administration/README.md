# Lesson 12 — Google Workspace Administration

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the other major cloud workspace — **Google Workspace**: the **Admin console**, users /
groups / **Organizational Units (OUs)**, **Gmail / Drive / Calendar / Meet** support, license/SKU
assignment, and the **M365 ↔ Workspace map** so a tech can support either. Many orgs run Workspace;
some run both.
**Primary artifact:** a Workspace user-management runbook + a Workspace↔M365 reference.

> **How to use this lesson:** read §1–§7, do §8 (explore the Admin console in a trial/dev domain),
> produce §9, take the quiz, reflect. Then Lesson 13.

---

## §1 — Concept (Theory)

### What it is
**Google Workspace** is Google's cloud productivity suite: **Gmail** (mail), **Drive** (files, incl.
**Shared drives**), **Calendar**, **Meet** (meetings), **Docs/Sheets/Slides**, and **Chat**, all tied
to a **Google identity** managed in the **Admin console** (admin.google.com). Admins organize users
into an **OU tree** (which is how policies/settings cascade), put them in **groups** (for email lists
and access), and assign **licenses (SKUs)** like Business Starter/Standard/Plus or Enterprise.

### Why it matters for support
If your employer runs Workspace instead of (or alongside) M365, every "email/files/meeting/sign-in"
ticket lives here. The concepts are nearly identical to M365 — identity, license, permissions — but the
*surfaces and names* differ. A tech who knows the **map** supports both worlds without relearning the
logic.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "I can't get into Gmail / share this Drive file / join the Meet."
- **Level 2 — Technician:** in the **Admin console**, find the user, check they're **active** and
  **licensed**, confirm group membership and Drive sharing settings, reset password / re-do 2-Step
  Verification.
- **Level 3 — Engineer:** policy in Workspace flows down the **OU tree** (settings applied to an OU
  cascade to users in it — the Group-Policy analog); **groups** drive both mailing and access;
  **Shared drives** own files at the *team* level (not a person), so a leaver's files don't vanish;
  **2-Step Verification** + **context-aware access** are the MFA/Conditional-Access analogs; the
  **Directory API / GAM** automate at scale. This is *why* moving a user between OUs changes their
  settings, and why Shared drives matter for offboarding (L20).

### Two Teaching Approaches (Lens B) — Workspace mirrors M365
**Approach 1 (technical):** Workspace and M365 are the same three-layer model — **identity** (Google
account / Entra), **entitlement** (Workspace SKU / M365 license), **content access** (Drive sharing &
Shared drives / SharePoint & OneDrive permissions) — administered from a central console with OUs/groups
(Workspace) or groups/admin-centers (M365). Learn the logic once; swap the vocabulary.

**Approach 2 (analogy):** if M365 is one **gym chain**, Workspace is a **competing chain** with the
same facilities under different names — the membership card (account), the tier (license), and the
team rooms (shared storage) all exist; only the signage and the front-desk layout differ. **Where it
breaks down:** the details aren't 1:1 — e.g. Workspace's **OU tree** is the policy unit (more like AD
OUs + GPO), whereas M365 leans on **groups** for most things; don't assume identical behavior, just
identical *concepts*.

### Visual (ASCII) — Workspace structure + the M365 map
```
   GOOGLE WORKSPACE                                  ↔  MICROSOFT 365
   Admin console (admin.google.com)                  ↔  M365 / Entra admin centers
   OU tree (settings cascade down)                   ↔  AD OUs + Group Policy / Entra groups
   Groups (mail + access)                            ↔  Distribution / security groups
   License SKU (Business Standard…)                  ↔  License (E3 / Business Premium)
   Gmail · Drive · Shared drives · Calendar · Meet   ↔  Exchange · OneDrive · SharePoint · Calendar · Teams
   2-Step Verification · context-aware access        ↔  MFA · Conditional Access
```

---

## §2 — Tools & Commands

| Where | What it administers |
|---|---|
| **Admin console** (admin.google.com) | users, OUs, groups, licenses, security, app settings |
| Directory → Users | create/suspend/reset, license, group/OU membership |
| Directory → Org units (OUs) | policy/settings scope (move a user to change settings) |
| Directory → Groups | mailing lists + access groups |
| Apps → Google Workspace | per-service settings (Gmail routing, Drive sharing) |
| Security → Authentication | 2-Step Verification, password policy, context-aware access |
| Reports / Audit logs | sign-in, admin, Drive activity (security/forensics) |
| **GAM** (open-source CLI) / Admin SDK | automation at scale (the PowerShell-equivalent) |

```text
# Conceptual GAM examples (the automation layer, run from an admin workstation):
gam info user jdoe@corp.example                 # account status, OU, groups, licenses
gam update user jdoe@corp.example suspended on   # suspend (offboarding step, L20)
gam print users fields primaryEmail,suspended,orgUnitPath > users.csv   # audit/report
```

> Lab note: use a **Workspace trial/dev domain** with placeholder users — never a production tenant
> (`navi.project.md` HR#1; bulk GAM ops + suspensions are a danger zone — confirm scope).

---

## §3 — Real-World Support Context & Use Cases

- **Workspace-first shops:** startups, education, and many SMBs run Workspace — the entire end-user
  queue (mail/files/meet/sign-in) is here.
- **Dual-suite orgs:** some run both (e.g. M365 for some teams, Workspace for others, or migrating
  between them) — you support both and the interop quirks.
- **Shared drives vs My Drive:** "the leaver took all our files" happens when files live in a person's
  **My Drive**; **Shared drives** (team-owned) prevent it — a key offboarding/data-governance lesson
  (L20).
- **2-Step Verification:** the MFA analog — new phone / lost key re-enrollment mirrors L11/L21.
- **Sharing settings:** "can't share externally" / "link sharing off" are *policy* (OU-level), not
  bugs — the Conditional-Access-style "control working" recognition.
- **Exam framing:** Workspace has its own Google admin certs; A+/MS-900 reference cloud productivity
  concepts generally — the transferable identity/license/permission model is the takeaway.

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0411-G (P3):** *"Our new contractor can sign in but can't see the team's project files
> in Drive. — request from the team lead, contractor = rkhan@corp.example."*

1. **Identity OK?** Admin console → `rkhan` is **active** and **licensed** (sign-in works, so identity
   is fine) → it's an **access/permissions** problem, not auth.
2. **Where do the files live?** The team's project files are in a **Shared drive** (good practice). Is
   `rkhan` a **member** of that Shared drive (or of the group that's a member)?  → **Not a member.**
3. **Authorization check:** is the contractor approved for that project's data? (Team lead requested →
   confirm scope; contractors often get **limited** roles.)
4. **Grant by group/role:** add `rkhan` to the **group** that has access to the Shared drive (least
   privilege — Viewer/Contributor as appropriate), not as a one-off individual share.
5. **Verify:** `rkhan` now sees the Shared drive and the files at the right access level.
6. **Document:** note the group + role + approver; fold contractor access into the onboarding pattern.

The teaching point: it's the **same logic as M365/L07** — identity is fine, the gap is *content access*,
fixed via **group membership at least privilege** — only the surface (Shared drive) is Google-flavored.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: a Google Workspace service/access isn't working for a user.**

### 1 · Symptoms
Can't sign in to Gmail/Workspace · 2-Step prompt issues · "no Gmail"/can't send · can't see/share a
Drive file or Shared drive · can't join Meet · "sharing is disabled" · suspended-account message.

### 2 · Possible Causes (most-likely first)
1. **License/SKU** missing (no Gmail/feature).
2. **Account suspended** or sign-in blocked.
3. **2-Step Verification** not registered / new device.
4. **Access/permissions**: not a member of the Shared drive/group; file shared to wrong scope.
5. **OU-level policy**: external sharing off, app disabled for that OU (intended control).
6. **Client/cache**: signed into the wrong Google account (multi-login), browser cache (L14).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Admin console: account active? | suspended | reinstate (if appropriate) |
| 2 | License/SKU assigned? | missing | assign (entitlement approved) |
| 3 | 2-Step Verification state | none/old device | re-enroll (L21-style) |
| 4 | Shared drive / group membership | not a member | add via group (least priv) |
| 5 | OU policy (sharing/app enabled?) | disabled for OU | it's policy — explain or move OU (approved) |
| 6 | Which Google account is signed in? | wrong/multi-login | sign into the correct account (L14) |

### 4 · Resolution Steps
Assign the SKU; reinstate the account (if it was wrongly suspended); re-enroll 2-Step; add to the
Shared-drive **group** at the right role; if it's an **OU policy** doing its job, explain it (or move
the user to the correct OU *with approval*); fix multi-login / clear browser state (L14).

### 5 · Escalation Criteria
Escalate to the Workspace admin / Google support for: OU policy/sharing-policy changes, domain mail
routing, license procurement, suspected security events (Reports/audit log anomalies, external auto-
forward — L29), or GAM/API automation. Attach: account status, license, group/OU path, audit-log
entry. **Bulk** GAM ops + suspensions = danger zone (confirm scope).

### 6 · Post-Incident Documentation
Ticket note (license/access/2SV + fix), KB (Workspace self-help), onboarding/offboarding runbook
update (L20 — Shared-drive membership, suspend-not-delete), security escalation as needed.

---

## §6 — Ticket Simulation

> **Ticket ENT-12 / INC-0110 (P2):** *"An employee left last Friday — but their manager says all the
> team's documents have disappeared from Drive! — urgent, leaver = tjones@corp.example."*

**Triage:** "leaver took the files" = files lived in the **leaver's My Drive**, and offboarding
**suspended/deleted** the account → the team lost access to *their own* documents. Business-impacting,
multi-user → **P2** (data-availability).

**Worked resolution (do-no-harm + governance):**
1. **Don't delete anything further.** A suspended account's Drive still exists; a deleted one may be in
   the recovery window — act before it lapses.
2. **Confirm the cause:** the project docs were in **tjones' My Drive**, shared ad-hoc — not in a
   **Shared drive** — so suspension removed the team's access.
3. **Recover access (the right Google tool):** **transfer ownership** of tjones' Drive data to the
   manager (Admin console → user → *Transfer data*/Drive transfer), or restore from the recovery
   window, putting the documents under a team-owned **Shared drive**.
4. **Verify:** manager confirms the documents are back and now team-owned.
5. **Fix the root cause (the real lesson):** project files belong in a **Shared drive** (team-owned) so
   a future leaver never takes them — update the **offboarding runbook** (L20) to include a Drive
   ownership-transfer step and the data-governance standard.

**The professional ticket note:**
```
SUMMARY: Team "lost" project docs because they lived in a leaver's My Drive and offboarding suspended
the account. Transferred the leaver's Drive data to the manager and moved the docs into a team Shared
drive. No data lost. Updated offboarding to prevent recurrence.
SYMPTOM: team documents "disappeared" from Drive after an employee left.
DIAGNOSIS: docs were in tjones' personal My Drive (ad-hoc shared), not a Shared drive → account
suspension removed access.
CAUSE: data-governance gap (team files owned by an individual, not a Shared drive) + standard
offboarding suspension.
RESOLUTION: Admin console Drive data transfer to the manager; relocated docs into a team Shared drive;
verified access.
FOLLOW-UP: offboarding runbook (L20) now includes Drive ownership transfer + "team files live in
Shared drives" standard; KB on requesting Shared drives. Escalated the governance gap as a Problem (L32).
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Cloud productivity (Workspace). Access/license = **Request**; sign-in/data-loss =
  **Incident**.
- **The same vocabulary, different tool:** triage with the M365-equivalent logic (L11) — identity →
  license → permission → policy — so the desk supports either suite uniformly.
- **Data governance is an offboarding concern:** "leaver took the files" is a recurring **Problem**
  (L32) solved by Shared drives + an ownership-transfer offboarding step (L20), not by heroics each
  time.
- **Security gate:** like M365, 2-Step/password changes are social-engineering targets — verify
  identity out-of-band (L29).
- **Metric angle:** the Workspace↔M365 map keeps cross-suite tickets at high FCR; audit logs support
  security/IR.

---

## §8 — Practical Lab (build this yourself)

**Goal:** navigate the Admin console, understand OUs/groups/Shared drives, and map every concept to
M365 — in a **trial/dev domain**.

### Lens C — Manual → Automation → Why
- **Manual:** create/suspend a user, set their OU and license, add to a group in the Admin console.
- **Automated:** **GAM** scripts a user's full lifecycle (create, license, group, suspend, Drive
  transfer) — the onboarding/offboarding engine (L20) for Workspace.
- **Why:** doing 5 onboardings identically (and a clean offboarding with Drive transfer) is exactly the
  consistency/auditability automation buys; ad-hoc clicking causes the "leaver took the files" incident.

### Steps
1. **Tour the console:** Users, OUs, Groups, Licenses, Security (2-Step), Reports — note the M365
   equivalent of each.
2. **OU policy:** move a test user between two OUs with different sharing settings; observe settings
   cascade (the GPO-like behavior).
3. **Shared drive vs My Drive:** create a Shared drive, add a group as a member; contrast with a file
   shared from My Drive — see why Shared drives survive a leaver.
4. **Lifecycle:** suspend a test user (the offboarding step), note their Drive data persists for
   transfer.
5. **Write the Workspace user-management runbook** + the **Workspace↔M365 reference** (the §1 table,
   expanded) so the team can support either suite.

### Lens D — the raw artifact (My Drive vs Shared drive ownership)
```
Project file "Q3-Plan" owner:  tjones@corp.example (My Drive)   ← owned by a PERSON → leaves with them
                        vs
Project file "Q3-Plan" location: Shared drive "Project X"        ← owned by the TEAM → survives any leaver
#   The single difference between "we lost everything" and "no impact" at offboarding is WHERE the file
#   lives. Shared drives = team-owned = leaver-proof.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/workspace-user-management.md` — create/license/group/suspend + Drive
   transfer.
2. **Troubleshooting Guide:** `docs/troubleshooting/workspace-access.md` — the full spine.
3. **Ticket Notes:** `docs/tickets/ENT-12-leaver-drive-loss.md` — the worked ENT-12.
4. **KB Article:** `docs/kb/` — "Sharing files safely in Drive (use Shared drives)" for end users.
5. **Incident Report:** the data-availability event as a mini incident report + the governance Problem
   (L32).
6. **Portfolio Artifact:** §10 bullet + the Workspace↔M365 map + Shared-drive talking points.
7. **Reference:** `docs/learning/alignment/` or the runbook — the **Workspace↔M365** mapping table.

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Administered Google Workspace (Admin console: users, OUs, groups, licenses,
  2-Step) and mapped it to Microsoft 365 for cross-suite support; resolved a leaver data-availability
  incident via Drive ownership transfer and a Shared-drive governance standard."*
- **Interview talking point:** the **Workspace↔M365 map** (same identity/license/permission logic,
  different surfaces), **OU policy cascade**, and **Shared drives vs My Drive** for leaver-proof data.
- **Serves:** Help Desk T1/T2, IT Support Specialist.

---

## §11 — Certification Crossover Notes

- **Google Workspace** has its own admin certifications (the deep path). **MS-900 / A+:** cloud
  productivity concepts and the transferable identity/license/permission model. Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** when an org runs both suites, users get confused about "which account/where are my
files" — clear guidance (and the map) reduces frustration; for a data-loss scare, lead with "your data
is recoverable" before fixing.

**🔒 Security:** Workspace is a full attack surface like M365 — verify identity out-of-band before
2-Step/password changes (L29); watch the **audit logs** for external auto-forwarding, mass downloads,
or suspicious admin actions; control **external sharing** at the OU level (data-leak prevention); and
ensure **team data lives in Shared drives** so offboarding (L20) doesn't strand or expose it. Suspend
(don't immediately delete) leavers to preserve data for transfer and investigation.

---

## Quiz (Interview-Style, Graded)

**Q1.** Map these Workspace items to their M365 equivalents: Admin console, OU, Shared drive, 2-Step
Verification.
> **Your answer:**

**Q2.** A licensed, active Workspace user can't see a team's Drive files. Where's the problem and how
do you fix it (the right way)?
> **Your answer:**

**Q3.** Why do team files belong in a Shared drive rather than someone's My Drive?
> **Your answer:**

**Q4.** **Scenario:** an employee left and "all the team's documents are gone" from Drive. What do you
do, in order — and what's the permanent fix?
> **Your answer:**

**Q5.** A user says "external sharing is broken — I can't share with a client." Is this necessarily a
bug? How do you check?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `google workspace admin console users OUs groups`
- `shared drives vs my drive ownership`
- `google workspace 2-step verification reset`
- `google workspace drive data transfer leaver`
- `google workspace vs microsoft 365 comparison`

**Tools**
- `GAM google workspace command line`
- `google admin audit logs reports`

**Going further**
- `email troubleshooting` (L13) · `user provisioning and deprovisioning` (L20) ·
  `security awareness` (L29) · `backup and recovery` (L30)

**Service / Security (Lens E):**
- 🤝 `supporting dual M365 and workspace orgs`
- 🔒 `workspace external sharing controls`, `suspend not delete leaver`, `drive audit log compromise`

---

## Lesson Status
- [ ] §8 lab completed (console tour + OU/Shared-drive drills + runbook + Workspace↔M365 map)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 13 — Email Troubleshooting**.

---

*Lesson 12 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: Google Workspace
Admin Help, GAM docs; compare with MS-900 (L11).*
