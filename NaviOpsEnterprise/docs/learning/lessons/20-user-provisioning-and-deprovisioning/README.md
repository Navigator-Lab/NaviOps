# Lesson 20 — User Provisioning & Deprovisioning

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the two most relatable, portfolio-defining IT processes — **onboarding** (create everything a
new hire needs) and **offboarding** (cleanly, safely remove a leaver) — across **AD + M365 + groups +
mailbox + device**, done as a **repeatable, scripted, auditable** workflow. This is *the* Junior-SysAdmin
showpiece.
**Primary artifacts:** `scripts/new_user_onboard.ps1` + `scripts/offboard_user.ps1` + the
onboarding/offboarding runbooks. **Lab:** DC01 + M365 dev-tenant model (`infra/`).

> **How to use this lesson:** read §1–§7, do §8 (run a full onboard + offboard in the lab), produce §9,
> take the quiz, reflect. Then Lesson 21.

---

## §1 — Concept (Theory)

### What it is
**Provisioning** (onboarding) is creating and equipping a new user's identity and access: the **AD
account** (right OU, naming standard), **group memberships** (role-based access, L07), an **M365 license
+ mailbox** (L11), **home/share access + mapped drives** (L23), a **device** (imaged, assigned,
asset-tagged, L27), **MFA enrollment**, and a secure first-login handoff. **Deprovisioning**
(offboarding) is the reverse, done **safely and in order**: disable the account, revoke sessions,
preserve/transfer data and mailbox, reclaim license + device + access, and schedule deletion per policy.

### Why it matters for support
These are the processes a hiring manager most relates to ("our onboarding takes a week and is a mess —
can you fix it?"). Done well, they're **repeatable, scripted, and auditable**; done poorly, new hires
sit idle (lost productivity) and leavers retain access (a security/compliance risk). A clean
onboard/offboard runbook + script is the single strongest artifact in an IT-support portfolio.

### Three-Level Depth (Lens A)
- **Level 1 — User/Manager:** "the new person needs to be set up by Monday" / "so-and-so left, lock
  their stuff."
- **Level 2 — Technician:** run the **checklist** — create the AD account (correct OU/naming), add the
  **role groups**, assign **license + mailbox**, set up **drives/access**, assign + image a **device**,
  **MFA** + secure password handoff; on exit, **disable + revoke + preserve + reclaim** in order.
- **Level 3 — Engineer:** onboarding is a **pipeline** ideally driven from HR data (a CSV / HR-system
  feed) → `Import-Csv | New-ADUser` with templated attributes, **group-based** access + licensing
  (membership grants the license/GPO/drives automatically — L07/L11/L19), hybrid sync to **Entra**
  (L11/L18); offboarding is **staged + reversible-where-possible** (disable not delete; revoke
  **sessions/tokens** because disabling doesn't kill live sessions; mailbox → shared/forward or
  retention hold; **transfer** OneDrive/Drive ownership — L12 — so data isn't stranded; license reclaim;
  device wipe/return; deletion after a retention window). This is *why* "disable + revoke + transfer"
  beats "delete," and why group-based + CSV-driven onboarding scales and stays consistent.

### Two Teaching Approaches (Lens B) — the lifecycle as a controlled pipeline
**Approach 1 (technical):** identity has a **lifecycle** (joiner → mover → leaver). Onboarding is a
*create + grant* transaction (account, groups, license, mailbox, drives, device, MFA); offboarding is a
*revoke + preserve + reclaim* transaction in a deliberate order (disable → revoke sessions → preserve/
transfer data → reclaim license/device/access → delete after retention). Group-based access makes both
consistent: add/remove from a role group and the access/license/GPO follows.

**Approach 2 (analogy):** onboarding is **issuing a new employee their badge, keys, desk, phone, and
parking pass on day one**; offboarding is **collecting them on the last day** — but in a safe order:
**deactivate the badge first** (disable account + revoke active sessions, so they can't walk back in),
**box up their files for the team** (transfer data, don't shred — L12), **hand back the laptop and
phone** (reclaim device/license), then **close the HR file** after the required retention. **Where it
breaks down:** unlike physical keys, a digital "key" can be **copied into live sessions** — so just
deactivating the badge (disabling the account) isn't enough; you must also **revoke the sessions**
already in use.

### Visual (ASCII) — the joiner/leaver pipeline
```
   ONBOARD (joiner):  HR data ─▶ AD account (OU+naming) ─▶ role GROUPS ─▶ M365 license+mailbox ─▶
                       drives/share access ─▶ device (image+asset tag) ─▶ MFA + secure handoff ─▶ doc/ticket
                       (group membership auto-grants license/GPO/drives — L07/L11/L19)

   OFFBOARD (leaver):  DISABLE account ─▶ REVOKE sessions/tokens ─▶ reset pw / block sign-in ─▶
                       PRESERVE/TRANSFER mailbox + files (L12) ─▶ RECLAIM license+device+access ─▶
                       DOCUMENT ─▶ DELETE after retention window
                       (disable ≠ delete; reversible-where-possible; ORDER matters for security)
```

---

## §2 — Tools & Commands

| Task | GUI | PowerShell |
|---|---|---|
| Create AD user | ADUC → New User | `New-ADUser` |
| Bulk create from HR CSV | — | `Import-Csv \| ForEach { New-ADUser … }` |
| Add to role groups | ADUC → Member Of | `Add-ADGroupMember` |
| Assign M365 license (L11) | M365 admin / group-based | `Set-MgUserLicense` / group membership |
| Disable / enable account | ADUC | `Disable-ADAccount` / `Enable-ADAccount` |
| Reset pw / block sign-in | ADUC | `Set-ADAccountPassword` (L21) / `Set-ADUser` |
| Revoke M365 sessions | Entra → user → Revoke sessions | `Revoke-MgUserSignInSession` |
| Convert/forward mailbox | EAC | `Set-Mailbox -Type Shared` / forwarding |
| Move/remove object | ADUC | `Move-ADObject` / `Remove-ADUser` (⚠) |

```powershell
# Onboard (lab; -WhatIf first):
Import-Csv .\newhires.csv | ForEach-Object {
  New-ADUser -Name $_.Name -SamAccountName $_.Sam -Path "OU=Sales,OU=Corp,DC=corp,DC=example" `
    -Title $_.Title -Department $_.Dept -AccountPassword (ConvertTo-SecureString $_.TempPw -AsPlainText -Force) `
    -ChangePasswordAtLogon $true -Enabled $true -WhatIf
  Add-ADGroupMember -Identity $_.RoleGroup -Members $_.Sam -WhatIf   # role group grants access+license+GPO
}
# Offboard (staged):
Disable-ADAccount jdoe -WhatIf            # 1) disable (don't delete)
# 2) revoke live M365 sessions (token still valid until revoked):
Revoke-MgUserSignInSession -UserId jdoe@corp.example
# 3) preserve: Set-Mailbox jdoe -Type Shared ; transfer OneDrive/Drive ownership (L11/L12)
```

> **Danger zone** (`navi.project.md`): provisioning/deprovisioning are destructive identity ops —
> **lab only**, `-WhatIf` first, confirm the **exact target** (one wrong SAM offboards the wrong
> person). Disable before delete; deletion only after the retention window.

---

## §3 — Real-World Support Context & Use Cases

- **Onboarding** is a recurring, deadline-driven request (new hires, often in **batches** — "5 people
  start Monday") — the perfect case for a **CSV-driven script** (consistency + speed + audit trail).
- **Offboarding** is a **security + compliance** event: a leaver who keeps access is an audit finding and
  a breach risk; the **order** (disable + revoke first) matters because disabling alone doesn't kill
  live sessions.
- **Data continuity:** a leaver's mailbox and files must be **preserved/transferred** (shared mailbox /
  forward; OneDrive/Drive ownership transfer — L11/L12) so the team isn't stranded (the L12 "leaver took
  the files" incident).
- **Group-based everything:** access, licensing (L11), and GPO/drives (L19) all flow from **role group**
  membership — so onboarding = "put them in the right groups," offboarding = "remove them."
- **The mover case:** role changes/reorgs are mini onboard+offboard (add new role groups, remove old —
  ties to the L18 reorg incident).
- **Exam framing:** MD-102 (identity lifecycle, device enrollment), MS-900 (licensing/identity), ITIL
  (service request fulfillment — L17).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket REQ-0104 (P3, Service Request):** *"New hire **pmorgan** starts Monday in Sales — please set
> up everything."*

1. **Gather the inputs:** name, role/title, department, manager, start date, required access (from HR/
   the manager). Map the role → **role groups** (Sales, plus standard "All Staff").
2. **Create the AD account** (right OU + naming standard): `New-ADUser` in `OU=Sales`, with title/
   department/manager, a strong **temp password**, **ChangePasswordAtLogon = true**.
3. **Grant access by group:** `Add-ADGroupMember Sales pmorgan` (and All-Staff) → this **auto-grants**
   the M365 license (group-based licensing, L11), GPO drive maps (L19), and share access (L07/L23).
4. **Mailbox + license:** confirm the license applied and the **mailbox provisions** (L11); add to any
   distribution lists.
5. **Device:** assign + image a laptop, **asset-tag** it, record it to pmorgan (L27).
6. **MFA + secure handoff:** pre-register/enable MFA; deliver the temp password **securely** (not over
   email/chat in plain text — L29); send a first-login guide (KB-0101/KB-0010).
7. **Verify + document:** pmorgan can sign in, has email/Teams/OneDrive, the right drives, and the
   device. Close the request with a complete note; the **manager** is notified.

The teaching point: **map the role → groups, then let group membership drive license/GPO/drives** — that's
what makes onboarding fast, consistent, and auditable instead of a 20-step manual slog.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: onboarding/offboarding gaps & failures.**

### 1 · Symptoms
New hire "can't do X" on day one (no mailbox/license/drive/access) · onboarding inconsistent between
hires · leaver **still has access**/sessions · leaver's **data/mailbox lost or stranded** · license not
reclaimed (cost) · device not recovered.

### 2 · Possible Causes (most-likely first)
1. **Missing group membership** → no license/GPO/drive/access (L07/L11/L19).
2. **License not assigned/provisioning delay** → no mailbox (L11).
3. **Offboarding incomplete/out-of-order** → access or live **sessions** remain.
4. **Data not transferred** before disable/delete → stranded files/mailbox (L11/L12).
5. **Manual, un-scripted process** → inconsistency + missed steps.
6. **Hybrid sync timing** → on-prem change not yet in Entra (L11/L18).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | New hire: group memberships vs role | missing | add role group (auto-grants license/GPO/drives) |
| 2 | License + mailbox state (L11) | none | assign/await provisioning |
| 3 | Leaver: account disabled? sessions revoked? | not fully | disable + **revoke sessions** |
| 4 | Leaver: mailbox/files preserved/transferred? | not yet | shared mailbox/forward + Drive transfer (L11/L12) |
| 5 | License reclaimed / device returned? | no | reclaim (cost) / recover device (L27) |
| 6 | Hybrid synced? | no | force/await sync (L11/L18) |

### 4 · Resolution Steps
Add the correct **role groups** (drives/license/GPO follow); assign license + confirm mailbox (L11);
for a leaver — **disable + revoke sessions + block sign-in**, then **preserve/transfer** mailbox & files
(L11/L12), **reclaim** license + device + access, **document**, and schedule deletion after retention;
script the whole thing for consistency.

### 5 · Escalation Criteria
Escalate to a senior admin / security / HR for: bulk/automated provisioning pipelines, license
**procurement**, retention/legal-hold decisions, suspected **insider risk** on a leaver (preserve, don't
destroy — security, L29), and anything affecting many. Deletions and bulk identity ops are **danger
zones** — confirm scope, never on a live domain unauthorized. Attach: the checklist state, what's done/
pending.

### 6 · Post-Incident Documentation
The onboarding/offboarding **runbook + checklist** (the artifact), the ticket note (what was provisioned/
deprovisioned + approver), access/asset records updated (L27), and a Problem (L32) if the process keeps
missing steps (drive the move to scripting).

---

## §6 — Ticket Simulation

> **Ticket ENT-20 / REQ-0105 (P2, Service Request → security-sensitive):** *"**asmith** is leaving — her
> last day was today and she gave notice on bad terms. Please offboard her and make sure she has no
> access, but the team needs her project files and her client emails. — manager, urgent."*

**Triage:** an offboarding with a **security edge** (bad-terms departure) + a **data-continuity**
requirement. Priority **P2** (security + business data). Order and completeness matter — this is exactly
where ad-hoc offboarding fails.

**Worked resolution (staged, security-first, do-no-harm to data):**
1. **Verify authorization:** confirm with HR/the manager that the offboarding is approved and the date
   (don't offboard on a single unverified request — though a bad-terms case raises *urgency to secure*).
2. **Cut access first (security):** `Disable-ADAccount asmith` **and** `Revoke-MgUserSignInSession`
   (disabling alone leaves live M365 sessions valid) + reset password / block sign-in. Now she can't get
   in even via an open session.
3. **Preserve before you remove (do-no-harm):** convert her mailbox to a **shared mailbox** (or set
   forwarding to the manager) so the team keeps the **client emails** (L11/L13); **transfer OneDrive/
   Drive ownership** of her **project files** to the manager / a Shared drive (L11/L12) — *before* any
   deletion.
4. **Reclaim:** remove from role groups (revokes share/app access, L07), reclaim the **license** (cost),
   recover the **device** and wipe/re-stock it (L27).
5. **Document thoroughly:** a bad-terms departure may need an **audit trail** — note every step + time;
   preserve logs (don't delete the account yet — retention + possible investigation, security/L29).
6. **Schedule deletion** only after the retention window; the account stays **disabled** (recoverable)
   meanwhile.

**The professional ticket note:**
```
SUMMARY: Offboarded asmith (bad-terms, same-day). Cut access first (disabled + REVOKED sessions + blocked
sign-in), then preserved data (mailbox→shared to manager; OneDrive ownership transferred), reclaimed
license + device, documented every step. Account DISABLED (not deleted) pending retention.
SYMPTOM/REQUEST: secure offboarding + retain her project files and client emails.
AUTHORIZATION: confirmed with HR + manager (approved, last day today).
ACTIONS (order matters): 1) Disable-ADAccount + Revoke-MgUserSignInSession + reset pw/block sign-in
2) mailbox → Shared (manager access) 3) OneDrive ownership → manager 4) removed role groups (revokes
share/app access) 5) license reclaimed 6) device recovered + queued for wipe (L27).
RESULT: no remaining access (incl. live sessions); team retains files + emails; nothing deleted.
FOLLOW-UP: account stays disabled until retention window, then delete; preserved logs for any
investigation (security/L29); offboarding runbook + script followed end-to-end.
```

---

## §7 — Service Desk / ITIL Perspective

- **Onboarding = Service Request** (routine, pre-approved fulfillment — L17); **offboarding = Service
  Request with a security/compliance dimension** (and sometimes an incident if access lingered).
- **Order is a security control:** disable + **revoke sessions** *before* anything else; preserve/
  transfer *before* delete. A documented, repeatable order is what audits look for.
- **Access reviews (L27)** depend on clean joiner/mover/leaver — orphaned accounts and access creep are
  the failures these processes prevent.
- **Group-based provisioning** (L07/L11/L19) is what makes the process scriptable and consistent — the
  ITIL "standardize the service request" ideal.
- **Metric/risk angle:** onboarding speed = new-hire productivity; offboarding completeness =
  security/compliance posture. Both are highly visible to leadership.

---

## §8 — Practical Lab (build this yourself)

**Goal:** run a complete onboard and a complete offboard in the lab, scripted and auditable.

### Lens C — Manual → Automation → Why
- **Manual:** click through ADUC + admin centers for each step (slow, inconsistent, error-prone).
- **Automated:** `new_user_onboard.ps1` (CSV → account + role groups → license-by-group → drives/GPO via
  group → output a handoff sheet) and `offboard_user.ps1` (disable → revoke sessions → mailbox→shared →
  Drive transfer → remove groups → reclaim license → report) — the showpiece scripts.
- **Why:** this is the textbook automation case — "do 5 onboardings *identically*" and "offboard *with no
  missed steps, in the right order, with an audit trail*" are exactly what consistency/auditability buy.
  Manual offboarding is how leavers keep access.

### Steps
1. **Lab:** use DC01 + the M365 dev-tenant model (`infra/`); prepare a `newhires.csv` of placeholder
   users.
2. **Onboard one (manually first):** create `pmorgan` in the right OU, add role groups, confirm license/
   mailbox (L11), drives (L19/L23), MFA; produce a secure handoff sheet.
3. **Onboard in bulk (scripted):** run `new_user_onboard.ps1` from the CSV **with `-WhatIf`**, review,
   then for real in the lab; verify consistency across the batch.
4. **Offboard one (staged):** run `offboard_user.ps1` on a test leaver — confirm **disable + revoke
   sessions** happen first, mailbox→shared, Drive transfer, groups removed, license reclaimed, and a
   report is produced. Confirm the account is **disabled, not deleted**.
5. **Prove data continuity:** confirm the "team" can still reach the leaver's transferred files/mailbox
   (the L12 lesson).
6. **Write the runbooks** (`onboarding.md`, `offboarding.md`) + the two scripts (`shellcheck`/
   `Invoke-ScriptAnalyzer`-clean, `-WhatIf` defaults).

### Lens D — the raw artifact (disable ≠ revoke: why order matters)
```
   Disable-ADAccount asmith        → she can't START a new sign-in
   ...but her Outlook/Teams on her phone keep working — the existing TOKEN is still valid!
   Revoke-MgUserSignInSession ...  → invalidates the live tokens → existing sessions die too
#   Disabling an account does NOT kill sessions already in progress. For a real offboarding (especially
#   bad-terms), you MUST revoke sessions, not just disable. This single detail separates a safe
#   offboard from a leaver who still reads email for hours.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook(s):** `docs/runbooks/onboarding.md` + `docs/runbooks/offboarding.md` — the two checklists
   (the portfolio centerpieces).
2. **Troubleshooting Guide:** `docs/troubleshooting/provisioning-gaps.md` — the full spine.
3. **Ticket Notes:** `docs/tickets/ENT-20-offboard-bad-terms.md` + the REQ-0104 onboarding note.
4. **KB Article:** `docs/kb/` — "New starter: your first-day setup" (end-user) + an internal joiner/mover/
   leaver checklist.
5. **Incident Report:** an offboarding-gap incident (a leaver retained access) as an incident/RCA
   (L31/L32) — the cautionary case.
6. **Portfolio Artifact:** §10 bullet + the onboarding-script + disable-vs-revoke talking points.
7. **Scripts:** `scripts/new_user_onboard.ps1` + `scripts/offboard_user.ps1` (`Invoke-ScriptAnalyzer`-
   clean; `-WhatIf` defaults; lab-targeted).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Built a scripted user-onboarding process (PowerShell + AD + M365) that provisions a
  new hire's account, role-based group access, license, mailbox, and device from a single CSV — and a
  staged offboarding script (disable → revoke sessions → preserve/transfer data → reclaim license/device)
  ensuring no residual access and zero data loss."*
- **Interview talking point:** the **joiner/mover/leaver lifecycle**, **group-based provisioning** (role
  → groups → license/GPO/drives), and the offboarding **order** — especially **disable ≠ revoke
  sessions** and **preserve/transfer data before delete**. This is the showpiece answer.
- **Serves:** IT Support Specialist, Junior SysAdmin (the single strongest portfolio artifact).

---

## §11 — Certification Crossover Notes

- **MD-102:** identity & device lifecycle, enrollment. **MS-900:** licensing/identity. **ITIL 4:**
  service request management (standardized fulfillment). Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** onboarding is a new hire's **first impression of the company** — a smooth, everything-
works day one matters; deliver a clear first-login guide and a friendly handoff. For offboarding,
coordinate respectfully with HR/manager.

**🔒 Security:** offboarding **is** a security control — incomplete offboarding (lingering access, live
sessions, orphaned accounts) is a top audit finding and breach vector. **Disable + revoke sessions
first**; **least privilege** on onboarding (only the groups the role needs — no "just give them admin");
deliver temp passwords **securely** (never plain-text email/chat — L29); for bad-terms/insider-risk
leavers, **preserve** (don't destroy) data and logs for possible investigation (NaviOpsSec domain). Every
provisioning/deprovisioning op is a **danger zone**: `-WhatIf`, confirm the exact target, lab/authorized
only.

---

## Quiz (Interview-Style, Graded)

**Q1.** Walk me through onboarding a new hire end-to-end. What do you set up and in what order?
> **Your answer:**

**Q2.** Why is "add them to the right groups" the key to fast, consistent onboarding?
> **Your answer:**

**Q3.** When offboarding, why isn't disabling the account enough — what else must you do immediately?
> **Your answer:**

**Q4.** **Scenario:** an employee leaves on bad terms today, but the team needs her project files and
client emails. What do you do, in order — and what do you NOT do?
> **Your answer:**

**Q5.** Why disable (not delete) a leaver's account, and for how long?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `user onboarding offboarding checklist IT`
- `New-ADUser bulk import-csv provisioning`
- `offboarding disable account revoke sessions order`
- `group based licensing M365`
- `transfer onedrive mailbox leaver data`

**Tools**
- `Revoke-MgUserSignInSession`
- `Set-Mailbox shared offboarding`

**Going further**
- `password resets and account recovery` (L21) · `file shares and permissions` (L23) ·
  `asset management` (L27) · `security awareness` (L29) · `microsoft 365` (L11) · `workspace` (L12)

**Service / Security (Lens E):**
- 🤝 `new hire first-day experience`, `secure temp password handoff`
- 🔒 `incomplete offboarding breach risk`, `disable vs revoke sessions`, `preserve leaver data investigation`

---

## Lesson Status
- [ ] §8 lab completed (manual + scripted onboard, staged offboard, data-continuity proof, runbooks)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 21 — Password Resets & Account Recovery**.

---

*Lesson 20 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: Microsoft AD/Entra
identity-lifecycle docs, `ActiveDirectory`/`Microsoft.Graph` PowerShell, ITIL service request mgmt.*
