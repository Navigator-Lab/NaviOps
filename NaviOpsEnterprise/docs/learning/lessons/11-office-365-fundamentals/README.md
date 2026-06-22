# Lesson 11 — Microsoft 365 Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the cloud platform most corporate users live in — **Microsoft 365**: identity (**Entra
ID**), **licensing**, the **admin center**, and supporting **Outlook/Exchange Online, Teams,
OneDrive, and SharePoint**. This is where a huge share of modern help-desk tickets land.
**Primary artifact:** an M365 user/license runbook + `scripts/m365_user_report.ps1`.

> **How to use this lesson:** read §1–§7, do §8 (explore the admin center + Graph/Exchange cmdlets in
> a dev tenant model), produce §9, take the quiz, reflect. Then Lesson 12.

---

## §1 — Concept (Theory)

### What it is
**Microsoft 365** is a cloud bundle: **identity** in **Microsoft Entra ID** (formerly Azure AD — the
cloud directory of users/groups, sign-in, and MFA), **email** in **Exchange Online**, **chat/meetings**
in **Teams**, **personal cloud storage** in **OneDrive**, **team/site storage** in **SharePoint**, plus
the Office apps. A **license** (e.g. Business Premium / E3) is what entitles a user to each service.
Admins manage it from the **Microsoft 365 admin center** and the service-specific centers (Entra,
Exchange, Teams), or by **PowerShell** (Microsoft Graph / Exchange Online modules).

### Why it matters for support
Modern users don't have a local mailbox or a file server — they have a **cloud identity** with
**licensed services**. Their tickets are: "I can't sign in" (Entra/MFA), "no email" (Exchange Online +
license), "Teams won't load," "OneDrive isn't syncing," "I can't open the team's files" (SharePoint
permissions). Knowing the M365 model + where each service is administered is the core of contemporary
help desk.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "my email/Teams/OneDrive isn't working" / "I can't sign in to Office."
- **Level 2 — Technician:** check the user in the **admin center** — do they have the right **license**
  (no license = no mailbox/Teams)? is their account **enabled**/sign-in allowed? is **MFA** healthy?
  then go to the service center (Exchange/Teams) for the specific issue.
- **Level 3 — Engineer:** identity is an **Entra object** (UPN, sign-in status, assigned **license
  SKUs** with service plans); a mailbox exists only when an **Exchange Online plan** is licensed;
  **Conditional Access** policies can block sign-in by device/location (a "can't sign in" that's
  actually *policy working*); group-based licensing and **dynamic groups** scale assignment; OneDrive/
  SharePoint share a storage fabric and a **permissions** model (sharing links, site groups). This is
  *why* "assign a license" fixes a missing mailbox and why a blocked sign-in may be intentional.

### Two Teaching Approaches (Lens B) — identity + licensing
**Approach 1 (technical):** in M365, the **user object (Entra)** is the identity; **services**
(mailbox, Teams, OneDrive) are *capabilities unlocked by license assignment*; **access to content** is
governed separately by permissions/sharing. These are three distinct layers — "no mailbox" is a
*license* problem, "can't sign in" is an *identity/auth* problem, "can't open that file" is a
*permissions* problem.

**Approach 2 (analogy):** M365 is a **gym membership**. Your **Entra account** is your **membership
card** (proves who you are at the door — sign-in + MFA); your **license** is the **membership tier**
that unlocks specific facilities (pool = mailbox, classes = Teams, locker = OneDrive); **permissions**
are which **team rooms** you're allowed into (SharePoint). No card → can't enter (sign-in); wrong tier →
card works but the pool's locked (no mailbox); not on the team → the team room is off-limits (SharePoint
access). **Where it breaks down:** unlike a gym, a policy (Conditional Access) can refuse your valid
card from an untrusted location — by design, not a malfunction.

### Visual (ASCII) — the M365 model
```
   ENTRA ID (identity)         LICENSE (SKU: E3/Business Premium…)        SERVICES
   ┌───────────────┐           unlocks ▼                                  ┌───────────────┐
   │ user: jdoe    │──signs in (MFA, Conditional Access)──▶  Exchange Online (mailbox)
   │ enabled? UPN  │                                          Teams (chat/meetings)
   │ groups        │           assign/remove a license ──▶   OneDrive (personal files)
   └───────────────┘                                          SharePoint (team sites) ── permissions
   ticket maps:  sign-in/MFA = identity   |  no mailbox/Teams = license  |  can't open file = permission
```

---

## §2 — Tools & Commands

| Where | What it administers |
|---|---|
| **Microsoft 365 admin center** (admin.microsoft.com) | users, licenses, groups, basic mailbox/reset |
| **Entra admin center** | identity, sign-in logs, MFA, Conditional Access, enterprise apps |
| **Exchange admin center (EAC)** | mailboxes, mail flow, distribution lists, shared mailboxes (L13) |
| **Teams admin center** | Teams policies, meeting/calling settings |
| **SharePoint admin center** | sites, sharing, storage |
| **Microsoft Graph PowerShell** (`Microsoft.Graph`) | users, licenses, groups at scale |
| **Exchange Online PowerShell** (`ExchangeOnlineManagement`) | mailbox ops at scale (L13) |

```powershell
Connect-MgGraph -Scopes "User.Read.All","Directory.Read.All"
Get-MgUser -UserId jdoe@corp.example | Select DisplayName, AccountEnabled, UserPrincipalName
Get-MgUserLicenseDetail -UserId jdoe@corp.example | Select SkuPartNumber      # what licenses they have
# Exchange Online:
Connect-ExchangeOnline
Get-Mailbox jdoe@corp.example | Select DisplayName, PrimarySmtpAddress, ProhibitSendQuota
```

> Lab note: practice against a **Microsoft 365 developer/dev tenant** model with placeholder users —
> never a production tenant (`navi.project.md` HR#1 + danger zones). Bulk Graph/Exchange ops are a
> danger zone (confirm scope).

---

## §3 — Real-World Support Context & Use Cases

- **The modern T1/T2 queue is M365-heavy:** sign-in/MFA, license requests, mailbox/permissions, Teams,
  OneDrive sync, SharePoint access.
- **Licensing is a frequent root cause:** "no mailbox," "Office says unlicensed," "can't use Teams" →
  check/assign the license first (often via a **group-based** assignment tied to onboarding, L20).
- **MFA is the #1 sign-in factor:** new phone, lost token, MFA prompts not arriving — re-registration
  is a core skill (ties to L21).
- **OneDrive Known Folder Move (KFM)** backs up Desktop/Documents to the cloud — central to the
  data-safety story (L06, L30) and the "my files are gone" reassurance.
- **Conditional Access** can *intentionally* block sign-in (untrusted device/location) — recognize
  policy-working vs a fault before chasing a ghost.
- **Exam framing:** **MS-900** (M365 fundamentals — services, identity, licensing) maps directly; A+
  touches cloud/SaaS support.

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0411 (P3):** *"I started Monday but Outlook says I have no mailbox and Office says it's
> unlicensed. — new hire, pmorgan@corp.example."*

1. **Confirm identity exists:** admin center → user `pmorgan` is present and **enabled** (onboarding
   created it, L20).
2. **Check the license:** Licenses tab / `Get-MgUserLicenseDetail` → **no license assigned**. That's
   the cause — no Exchange plan = **no mailbox**, no Office entitlement = "unlicensed."
3. **Verify entitlement:** is a license **available** (free seats) and **approved** for this role?
   (License = cost; confirm before assigning.)
4. **Assign:** add the correct SKU (ideally by adding pmorgan to the **role/onboarding group** that
   grants it — group-based licensing, the scalable way).
5. **Wait + verify:** mailbox provisioning takes a few minutes; confirm `Get-Mailbox pmorgan` returns,
   Outlook connects, Office activates.
6. **Document:** note the license assigned (via group), and fold this into the **onboarding runbook**
   (L20) so new hires don't hit it.

The teaching point: in M365, **"missing service" almost always = "missing license"** — check it before
deep-diving the app.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: an M365 service isn't working for a user.**

### 1 · Symptoms
Can't sign in to Office/portal · MFA prompt not arriving · "no mailbox"/"unlicensed" · Teams won't
load · OneDrive not syncing · can't open a SharePoint/team file · "your sign-in was blocked."

### 2 · Possible Causes (most-likely first)
1. **License** missing/wrong (no mailbox/Teams/Office).
2. **Identity/auth**: account disabled, password (L21), **MFA** not registered / new phone.
3. **Conditional Access** blocking (device/location) — possibly intended.
4. **Permissions**: not in the SharePoint site/Team (it's authz, L07/L23-style).
5. **Client-side**: OneDrive paused/stuck, Teams cache, stale Office credentials.
6. **Service health**: a Microsoft outage (check the service health dashboard).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | **Service health** dashboard | active incident | it's Microsoft-side → comms, wait |
| 2 | User license (`Get-MgUserLicenseDetail`) | missing | assign (entitlement approved) |
| 3 | Account enabled + sign-in logs (Entra) | disabled/blocked | enable / check Conditional Access |
| 4 | MFA registration state | none/old device | re-register MFA (L21) |
| 5 | Permissions to the site/Team | not a member | add via the owning group (L20/23) |
| 6 | Client: OneDrive status / Teams cache / re-sign-in | client error | clear cache / reconnect |

### 4 · Resolution Steps
Assign the right license (by group); enable the account / reset password (L21); re-register MFA; add
to the SharePoint/Team via its group; fix the client (restart OneDrive / clear Teams cache / re-add
Office account); if a Conditional Access block is *intended*, explain it (don't bypass security); if
it's Microsoft-side, communicate and track.

### 5 · Escalation Criteria
Escalate to the M365/identity admin (or Microsoft support) for: Conditional Access changes, tenant-
wide mail-flow/SharePoint issues, license **procurement** (no free seats), and suspected security
events (impossible-travel sign-ins, mass-forwarding — L29). Attach: UPN, license state, sign-in log
entry, service-health status. **Bulk** Graph/Exchange changes = danger zone (confirm scope).

### 6 · Post-Incident Documentation
Ticket note (license/MFA/permission + exact fix), KB (KB-0010 M365 common issues), onboarding-runbook
update (L20) if it's a provisioning gap, problem/security escalation as needed.

---

## §6 — Ticket Simulation

> **Ticket ENT-11 / INC-0108 (P2):** *"I got a new phone and now I can't get into anything — Outlook,
> Teams, the portal all just sit there asking me to approve something I never get. — Priya, LT-0450."*

**Triage:** "new phone" + "approve something I never get" = **MFA registered to the *old* device**;
sign-in stalls at the unanswerable MFA prompt. Blocked from everything → **P2**. Phone identity-verify.

**Worked resolution:**
1. **Verify identity** (out-of-band, per policy — this is exactly the social-engineering risk, L29:
   confirm it's really Priya before touching MFA).
2. **Confirm the cause:** Entra → Priya's **authentication methods** → the registered method is the
   **old phone**; sign-in logs show MFA challenges going unanswered.
3. **Re-register MFA:** from the admin/Entra side, **require re-registration** (revoke the old method /
   reset MFA) so Priya can enroll the **new phone** at next sign-in (via aka.ms/mfasetup).
4. **Walk her through enrollment:** new sign-in → set up the Authenticator on the new phone → approve.
5. **Verify:** she can reach Outlook/Teams/portal. Optionally revoke existing sessions if security
   warrants.
6. **Document + prevent:** note the re-registration; point her to **SSPR/self-service** (L21) and the
   KB so a future phone change is self-served.

**The professional ticket note:**
```
SUMMARY: Priya's MFA was registered to her old phone → all M365 sign-ins stalled on an unanswerable
prompt. Identity verified out-of-band; reset MFA registration; she enrolled Authenticator on the new
phone and regained access.
SYMPTOM: Outlook/Teams/portal hang at MFA "approve" prompt after getting a new phone.
VERIFIED: out-of-band identity check per policy (MFA reset = high-risk, social-eng target).
DIAGNOSIS: Entra auth methods = old device only; sign-in logs show unanswered MFA challenges.
CAUSE: MFA method tied to the replaced phone.
RESOLUTION: required MFA re-registration; guided enrollment of Authenticator on new phone; verified
sign-in to Outlook/Teams/portal.
FOLLOW-UP: enabled/showed SSPR + KB-0010 so future device swaps self-serve; considered session revoke
(not needed — no compromise indicators).
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** M365/Identity. License = often a **Request** (with cost/approval); sign-in/MFA/mailbox
  failures = **Incidents**.
- **Service health first:** before deep-diving, check the **Microsoft 365 service health dashboard** —
  a tenant-wide outage is a Microsoft **major incident**; your job is comms (L31), not 200 tickets.
- **Licensing = money:** assigning a license has a cost; follow the approval/entitlement process — the
  desk doesn't hand out paid SKUs freely.
- **Security gate:** MFA/password actions are prime social-engineering targets — **verify identity
  out-of-band** every time (L29). This is policy, not optional.
- **Metric angle:** M365 is high-volume; group-based licensing + SSPR + good KBs (KB-0010) are the big
  FCR/deflection levers.

---

## §8 — Practical Lab (build this yourself)

**Goal:** navigate the admin centers and report on users/licenses with PowerShell — against a **dev
tenant model**, never production.

### Lens C — Manual → Automation → Why
- **Manual:** click through the M365 admin center to find a user's license and status.
- **Automated:** `m365_user_report.ps1` (Graph) reports a user's enabled state, UPN, licenses, and MFA
  method — or all users for an audit — in seconds.
- **Why:** "does this user have the right license/MFA?" recurs constantly; a script answers it
  instantly and feeds onboarding/offboarding (L20) and access reviews (L27).

### Steps
1. **Tour the centers:** M365 admin, Entra, Exchange, Teams — for each, note one ticket it owns.
2. **Connect Graph:** `Connect-MgGraph`; `Get-MgUser` + `Get-MgUserLicenseDetail` for a test user.
3. **License awareness:** map a SKU (e.g. `ENTERPRISEPACK` = E3) to the services it unlocks (mailbox,
   Teams, OneDrive).
4. **MFA/identity:** view a test user's authentication methods + a sign-in log entry (see what a
   blocked vs successful sign-in looks like).
5. **OneDrive KFM:** understand Known Folder Move (ties data-safety to L06/L30).
6. **Write `scripts/m365_user_report.ps1`** (enabled, UPN, licenses, MFA method) and the M365
   user/license runbook.

### Lens D — the raw artifact (license = the missing service)
```
> Get-MgUserLicenseDetail -UserId pmorgan@corp.example
   (no results)                         ← NO license → no Exchange plan → "no mailbox", Office "unlicensed"
> Get-MgUser -UserId pmorgan@corp.example | Select AccountEnabled
   AccountEnabled : True                ← identity is fine; the gap is LICENSING, not sign-in
#   "No mailbox / unlicensed" with an enabled account = assign the license (the #1 M365 onboarding gap).
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/m365-user-license.md` — check/assign license + verify mailbox.
2. **Troubleshooting Guide:** `docs/troubleshooting/m365-service-issues.md` — the full spine
   (license/identity/MFA/CA/permissions/client/service-health).
3. **Ticket Notes:** `docs/tickets/ENT-11-mfa-new-phone.md` — the worked ENT-11.
4. **KB Article:** `docs/kb/` — KB-0010 "Microsoft 365 common issues" (sign-in, MFA new phone,
   OneDrive sync, Teams won't load) for end users.
5. **Incident Report:** an M365 service-health outage as a major incident (template, L31).
6. **Portfolio Artifact:** §10 bullet + the license=service / identity-vs-permission talking points.
7. **Script:** `scripts/m365_user_report.ps1` (Graph; `Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Supported Microsoft 365 (Entra ID, Exchange Online, Teams, OneDrive,
  SharePoint): built a Graph PowerShell user/license report and runbook, resolving licensing,
  MFA-re-registration, and sign-in incidents."*
- **Interview talking point:** the **identity → license → permissions** model (no mailbox = license,
  can't sign in = identity/MFA, can't open file = permission), **MFA re-registration** for a new phone,
  and checking **service health** before deep-diving.
- **Serves:** Help Desk T1/T2, IT Support Specialist.

---

## §11 — Certification Crossover Notes

- **Microsoft 365 Fundamentals (MS-900):** M365 services, Entra identity, licensing, admin centers —
  core, direct mapping.
- **MD-102:** identity & app management. **A+ (Core 2):** cloud/SaaS support concepts. Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** M365 issues block a user's whole day (no mail/Teams) — acknowledge the impact, check
service health so you're honest about "us vs Microsoft," and set up SSPR so users aren't dependent on
the desk for routine resets.

**🔒 Security:** the M365 admin desk is a **prime attack target** — **verify identity out-of-band**
before MFA/password changes (L29: attackers call posing as a user to capture an account). Watch for
**impossible-travel** sign-ins, **inbox auto-forwarding to external** addresses (a classic compromise
sign — L13/L29), and **MFA-fatigue** (flooding approve prompts). Enforce **least-privilege admin
roles**, and treat **Conditional Access** as a control to respect, not bypass. Never disable MFA "to
make it work."

---

## Quiz (Interview-Style, Graded)

**Q1.** A new user has an account but "no mailbox" and Office says "unlicensed." What's the cause and
the fix?
> **Your answer:**

**Q2.** Name the three distinct layers behind M365 access (identity, license, permissions) and give a
ticket symptom for each.
> **Your answer:**

**Q3.** A user can't sign in after getting a new phone. What's almost certainly wrong, and what's the
fix — plus the one thing you must do first?
> **Your answer:**

**Q4.** **Scenario:** dozens of users suddenly can't access Outlook on the web. Before you touch any
account, what do you check, and why?
> **Your answer:**

**Q5.** Why might a valid user be blocked from signing in even with the correct password and MFA — and
is that a bug?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `microsoft 365 admin center assign license`
- `entra id sign-in logs conditional access`
- `microsoft authenticator re-register MFA new phone`
- `onedrive known folder move`
- `microsoft 365 service health dashboard`

**Tools**
- `Connect-MgGraph Get-MgUserLicenseDetail`
- `ExchangeOnlineManagement Get-Mailbox`

**Going further**
- `google workspace administration` (L12) · `email troubleshooting` (L13) ·
  `user provisioning and deprovisioning` (L20) · `password resets` (L21) · `security awareness` (L29)

**Service / Security (Lens E):**
- 🤝 `service health honest comms`, `SSPR self-service password reset`
- 🔒 `MFA fatigue attack`, `mailbox auto-forward compromise`, `least privilege admin roles entra`

---

## Lesson Status
- [ ] §8 lab completed (admin-center tour + Graph report + m365_user_report.ps1 + runbook)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 12 — Google Workspace Administration**.

---

*Lesson 11 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: MS-900 (Microsoft
365 fundamentals), Microsoft Entra / Exchange Online / Graph PowerShell docs.*
