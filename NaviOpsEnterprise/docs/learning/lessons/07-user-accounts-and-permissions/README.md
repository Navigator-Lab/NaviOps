# Lesson 07 — User Accounts & Permissions

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** who a user *is* (local vs domain vs cloud accounts), what they're *allowed to do*
(NTFS vs share permissions, groups, least privilege, UAC/admin rights), and the #1 access ticket:
**"Access denied."** This is the foundation for Active Directory (L18), provisioning (L20), and file
shares (L23).
**Primary artifact:** the "Access denied" troubleshooting guide + `scripts/whoami_access.ps1`.

> **How to use this lesson:** read §1–§7, do §8 (inspect identities, groups, and ACLs), produce §9,
> take the quiz, reflect. Then Lesson 08.

---

## §1 — Concept (Theory)

### What it is
Two questions sit behind most access problems: **authentication** ("who are you?" — proven by signing
in) and **authorization** ("what are you allowed to do?" — decided by your group memberships and the
permissions on a resource). An **account** is an identity (local to one PC, a **domain** account in
Active Directory, or a **cloud** identity in Entra/M365). **Permissions** are rules attached to
resources (files, folders, shares) granting or denying actions. **Groups** bundle users so
permissions are assigned to a *role*, not a person.

### Why it matters for support
"I can't get into X" is one of the most common ticket families, and it's almost always an
*authorization* problem: wrong group membership, NTFS vs share permission conflict, or a missing
grant. Understanding identity + permissions lets you diagnose precisely instead of guessing — and do
it **securely** (verify identity, least privilege).

### Three-Level Depth (Lens A)
- **Level 1 — User:** "I have a username and password; sometimes I can open a folder, sometimes it
  says access denied."
- **Level 2 — Technician:** map the identity (local? domain? cloud?), check **group membership**
  (`whoami /groups`, AD group), and read the resource's **permissions** (NTFS Security tab + Share
  tab). Access = the *combination* of share + NTFS (most restrictive wins).
- **Level 3 — Engineer:** Windows builds an **access token** at logon containing the user's **SID** and
  every group **SID**; each resource has a **security descriptor / ACL** of **ACEs** (allow/deny per
  SID). Access is decided by matching the token's SIDs against the ACL (**deny wins**, then allow,
  then default-deny). **Effective access** = the intersection of **share** permissions and **NTFS**
  permissions. This is *why* "they're in the group but still denied" happens (an explicit deny, a more
  restrictive share, or a stale token needing re-logon).

### Two Teaching Approaches (Lens B) — share vs NTFS permissions
**Approach 1 (technical):** a network folder is protected by **two independent layers**: **Share
permissions** (apply only over the network) and **NTFS permissions** (apply always, locally and over
the network). When accessed over the network, the user gets the **most restrictive** of the two. Best
practice: set Share to a broad level (e.g. Authenticated Users = Change/Full) and control real access
with **NTFS via groups**.

**Approach 2 (analogy):** getting into a file is like entering an office: the **share permission** is
the **building's front-door badge reader** (only matters if you come from outside/over the network);
the **NTFS permission** is the **lock on the specific office door** (matters however you arrive).
You need to pass **both** — and the *stricter* one decides. **Where it breaks down:** sitting at the
machine locally, the front-door badge (share) doesn't apply at all — only the office lock (NTFS) —
which confuses "works locally, denied over the network" tickets.

### Visual (ASCII) — identity → token → access decision
```
   SIGN IN (authentication) ─▶ access TOKEN { userSID + group SIDs }   (built once at logon)
                                            │
   open \\FS01\Finance ─▶  SHARE perms (network only)  ╲
                          ─▶  NTFS perms (always)        ╲──▶ EFFECTIVE = most restrictive
                                            │                  DENY ACE always wins
   "in the group but denied?"  → token is stale (re-logon), an explicit DENY, or share<NTFS
```

---

## §2 — Tools & Commands

| Task | GUI | PowerShell / CLI |
|---|---|---|
| Who am I + my groups | — | `whoami /groups` · `whoami /user` |
| Local users/groups | `lusrmgr.msc` / Computer Mgmt | `Get-LocalUser` · `Get-LocalGroupMember` |
| Domain user + groups | ADUC (L18) | `Get-ADUser` · `Get-ADPrincipalGroupMembership` (L18) |
| NTFS permissions | folder → Properties → **Security** | `Get-Acl` · `icacls <path>` |
| Share permissions | folder → Properties → **Sharing** → Advanced | `Get-SmbShareAccess` (L23) |
| Effective access | Security → Advanced → **Effective Access** tab | — |
| Am I admin? / elevate | UAC prompt / Run as administrator | `whoami /groups` (look for Administrators) |

```powershell
whoami /groups                                   # every group in your token (the basis of access)
Get-LocalGroupMember -Group Administrators        # who has local admin on this PC
Get-Acl 'D:\Finance' | Format-List                # NTFS ACL on a folder
icacls 'D:\Finance'                               # compact ACL view (who has what)
```

---

## §3 — Real-World Support Context & Use Cases

- **"Access denied" is a daily ticket.** The disciplined fix: identify the user's groups, read the
  resource's permissions, find the gap — don't just "add Full Control to Everyone" (a security
  incident waiting to happen).
- **Grant access by GROUP, not by user.** Adding `jdoe` directly to a folder ACL is unmaintainable;
  adding her to the **Finance** group that already has access is the right move (and is what
  provisioning, L20, automates).
- **Least privilege & local admin:** users should **not** be local admins; UAC exists to gate
  elevation. A huge share of malware impact comes from over-privileged accounts (L29).
- **"Works locally but not over the network"** (or vice-versa) = the share-vs-NTFS distinction.
- **Exam framing:** A+ Core 2 (security, authentication, permissions, UAC); MD-102/MS-900 (identity,
  least privilege); ITIL (access management).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0604 (P3):** *"Please give Jane access to the Finance shared folder — she just moved to
> the Finance team. — manager request."* (A **Request**, not an incident.)

1. **Verify the request + authorization:** is this an approved move? Manager/HR confirms Jane is now
   Finance (don't grant access on a hunch — security).
2. **Find how access is granted:** check `\\FS01\Finance` → Security tab → access is via the **Finance
   security group** (good practice). So the fix is *group membership*, not a new ACL entry.
3. **Add to the group:** add `jdoe` to the **Finance** AD group (L18/L20 cover the how). *Don't* add
   her directly to the folder ACL.
4. **Make it take effect:** group membership is read into the token **at logon** — Jane must **sign
   out/in** (or reboot) to get the new group SID in her token. (This is the classic "I added her but
   she still can't get in" — it's the stale token.)
5. **Verify:** Jane (after re-logon) `whoami /groups` shows Finance; she can open the folder.
6. **Document:** note the group added, the approval, and the re-logon requirement.

The teaching point: **access changes flow through groups and require a fresh token** — knowing this
prevents the most common false "it didn't work."

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: "Access denied" / can't get into a folder, share, or resource.**

### 1 · Symptoms
"Access denied" to a folder/share · can see it but can't open/save · "you don't have permission" ·
worked yesterday, not today · works for a colleague but not them · can't install something (admin).

### 2 · Possible Causes (most-likely first)
1. **Not in the right group** (or removed from it).
2. **Stale token** — added to a group but hasn't re-logged-in.
3. **Share vs NTFS** mismatch (most-restrictive wins; or local-vs-network).
4. **Explicit Deny** ACE (overrides allows).
5. **Wrong identity** (signed in as the wrong/local account, or cached creds — L21).
6. **Needs elevation/admin** (UAC) for the action.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | `whoami /groups` (right user? right groups?) | missing the group | add to group (via L20) |
| 2 | Did they re-logon since the change? | no | sign out/in (stale token) |
| 3 | Resource Security tab / `Get-Acl` | group not granted / Deny present | fix ACL via group; remove errant Deny |
| 4 | Effective Access tab for that user | shows denied | see which layer denies |
| 5 | Local vs over-network? | differs | it's share-vs-NTFS |
| 6 | Action needs admin? (install) | UAC blocks | proper elevation, not making them admin |

### 4 · Resolution Steps
Add the user to the correct **group** (least privilege) → have them **re-logon**; fix the NTFS ACL
**via the group** (not per-user); remove an erroneous **Deny**; align share/NTFS levels; correct the
sign-in identity / clear cached creds (L21); elevate the specific action rather than granting standing
admin.

### 5 · Escalation Criteria
Escalate to Sysadmin/data-owner for: changing **group structure** or share design, granting access to
**sensitive data** (needs data-owner approval), or anything requiring AD/server changes beyond your
rights (L18/L23). Attach: `whoami /groups`, the ACL (`icacls`), effective-access result, the approval.

### 6 · Post-Incident Documentation
Ticket note (group added + approver + re-logon), update access records (who has access to what — feeds
L27 access reviews), KB for the self-service parts.

---

## §6 — Ticket Simulation

> **Ticket ENT-07 / INC-0107 (P2):** *"I had access to the Projects share all year and today it says
> 'Access denied' — I have a deadline! — Karim, DESK-1180."* Channel: phone.

**Triage:** access *lost* (not never-had) → something **changed** (group removal, ACL edit, or a move).
Time-pressured, single user → **P2**. Verify identity on the call.

**Worked resolution:**
1. **Confirm the symptom precisely:** denied to `\\FS01\Projects` specifically; other shares OK? (Yes →
   it's resource-specific, not a broad auth/account problem.)
2. **Check identity + groups:** `whoami /groups` on Karim's session — is the **Projects** group
   present? → **It's missing.**
3. **Why did it leave?** Check the group membership history / recent changes — e.g. an **access review**
   (L27) or an OU move (L18) removed him, or he was taken out during a reorg in error.
4. **Branch:**
   - **Removed in error / still authorized** → re-add to the **Projects** group (with the same
     approval trail), have Karim **sign out/in**, verify access.
   - **Removed intentionally (policy)** → don't silently re-grant; route to the data owner/manager for
     approval (security — don't be social-engineered into restoring access).
5. **Verify + document** the change, approver, and re-logon.

**The professional ticket note:**
```
SUMMARY: Karim lost Projects-share access after being removed from the Projects security group during
an access review. Confirmed still authorized (manager approved); re-added to group, re-logon, access
restored.
SYMPTOM: "Access denied" to \\FS01\Projects (other shares fine); access previously worked.
DIAGNOSIS: whoami /groups → Projects group MISSING; membership log → removed in yesterday's access
review.
CAUSE: removed from the Projects security group (access-review action); user still legitimately needs it.
RESOLUTION: manager re-approved; re-added jdoe→Projects group; Karim signed out/in; verified access.
FOLLOW-UP: noted the review removed an active member → feedback to the access-review process (L27);
KB "Access denied to a share you used to have" linked.
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Account/Access. A new grant is a **Request** (often pre-approved/standard); a *lost*
  access is an **Incident**.
- **Access management (ITIL):** grant the *right* access to the *right* people — every grant traces to
  a **request + approval**, and access is reviewed/recertified periodically (L27). The service desk
  executes within that, it doesn't freelance grants.
- **Priority:** scoped to user impact + deadline; sensitive-data access may *lower* speed in favor of
  **approval** (security gate).
- **Metric/risk angle:** over-granting ("just give Everyone Full Control") is the silent cause of data
  breaches — least privilege is both a security control and an audit requirement.

---

## §8 — Practical Lab (build this yourself)

**Goal:** read identities, group membership, and ACLs — the trio behind every access decision.

### Lens C — Manual → Automation → Why
- **Manual:** open the Security tab, click through Advanced → Effective Access.
- **Automated:** `whoami /groups`, `Get-Acl`/`icacls`, and a script that, given a user + a path,
  reports their groups and the folder's ACL side-by-side.
- **Why:** "access denied" triage repeated daily benefits from one command that shows the gap; at
  scale, scripted ACL/group reporting feeds **access reviews** (L27) and audits.

### Steps
1. **Inspect yourself:** `whoami /user` (your SID) and `whoami /groups` (your access basis).
2. **Local groups:** `Get-LocalGroupMember -Group Administrators` — see who has admin (least-privilege
   check).
3. **ACL drill (lab folder):** create `C:\lab\secure`, set NTFS so only a test group can read it,
   confirm a non-member is denied; read it with `Get-Acl`/`icacls`. Observe a **Deny** overriding an
   Allow.
4. **Token/re-logon truth:** add the test user to the group, show access still denied **until** they
   re-logon — internalize the stale-token rule.
5. **Write `scripts/whoami_access.ps1`** (given a path: show `Get-Acl` + the caller's `whoami /groups`)
   and the "Access denied" troubleshooting guide.

### Lens D — the raw artifact (an ACL via icacls)
```
> icacls D:\Finance
   D:\Finance  CORP\Finance:(OI)(CI)(M)          ← Finance group: Modify (inherited to files/folders)
               CORP\Domain Admins:(OI)(CI)(F)    ← admins: Full
               CORP\jdoe:(DENY)(R)               ← an explicit DENY on jdoe → she's blocked even if in Finance!
#   DENY wins. "She's in the group but can't get in" = read the ACL for an explicit Deny like this.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/grant-folder-access.md` — add-to-group + re-logon + approval trail.
2. **Troubleshooting Guide:** `docs/troubleshooting/access-denied.md` — the full spine.
3. **Ticket Notes:** `docs/tickets/ENT-07-lost-share-access.md` — the worked ENT-07.
4. **KB Article:** `docs/kb/` — "Access denied to a folder you used to have — what to do."
5. **Incident Report:** N/A single-user; note when broad access loss = a change/problem (L32).
6. **Portfolio Artifact:** §10 bullet + the share-vs-NTFS / stale-token talking points.
7. **Script:** `scripts/whoami_access.ps1` (`Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Authored an 'Access denied' troubleshooting guide and a PowerShell access-audit
  script (user groups + NTFS ACL), resolving permission incidents via least-privilege group membership
  instead of ad-hoc ACL edits."*
- **Interview talking point:** **share vs NTFS** (most-restrictive wins; local vs network), why "in the
  group but still denied" = **stale token / explicit Deny**, and **grant-by-group + least privilege**.
- **Serves:** Help Desk T2, IT Support, Junior SysAdmin.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2):** security — authentication/authorization, NTFS vs share permissions, UAC,
  least privilege, local users/groups — core.
- **MS-900 / MD-102:** identity & access, least privilege. **ITIL:** access management. Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** access tickets are urgent for users (they're blocked) — acknowledge the deadline, but
never let urgency pressure you into skipping **identity verification** or **approval** for sensitive
data. "I'll have this approved and done by <time>" beats an unauthorized grant.

**🔒 Security:** this lesson *is* security at the desk — **least privilege** (no standing local admin,
grant the minimum), **grant-by-group** (auditable), **deny by default**, and **verify before you
grant**. Over-granting ("Everyone / Full Control") and standing admin rights are the two most common
findings in breach post-mortems. Access reviews (L27) catch creep; you uphold it one ticket at a time.

---

## Quiz (Interview-Style, Graded)

**Q1.** What's the difference between authentication and authorization? Give a one-line example of each.
> **Your answer:**

**Q2.** Share permissions vs NTFS permissions — which applies when, and which wins when they differ?
> **Your answer:**

**Q3.** You add a user to a group that has access, but they still get "access denied." Give two likely
reasons and how you'd confirm each.
> **Your answer:**

**Q4.** **Scenario:** a user who had access to a share "all year" is suddenly denied today, with a
deadline. Walk me through your diagnosis — and when would you *not* just re-grant it?
> **Your answer:**

**Q5.** Why is "grant by group with least privilege" better than adding each user to a folder's
permissions directly?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `authentication vs authorization`
- `ntfs vs share permissions most restrictive`
- `windows access token group membership re-logon`
- `explicit deny overrides allow ACL`
- `least privilege local admin UAC`

**Tools**
- `icacls Get-Acl PowerShell`
- `whoami /groups effective access`

**Going further**
- `active directory fundamentals` (L18) · `user provisioning` (L20) · `file shares and permissions`
  (L23) · `security awareness for IT support` (L29)

**Service / Security (Lens E):**
- 🤝 `access request approval workflow`, `not bypassing approval under deadline pressure`
- 🔒 `least privilege`, `grant by group`, `access recertification review`

---

## Lesson Status
- [ ] §8 lab completed (identity/groups/ACL drill + whoami_access.ps1 + guide)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 08 — Networking Fundamentals**.

---

*Lesson 07 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+
220-1102 (security/permissions), Microsoft NTFS/share permissions & access-token docs.*
