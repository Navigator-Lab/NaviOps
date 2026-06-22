# Lesson 23 — File Shares & Permissions

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** building and supporting **network file shares** — SMB shares, **share vs NTFS permissions**
(the two-layer model from L07, now applied to real shares), mapped drives, **Access-Based Enumeration**,
and the daily "I can't access / can't save to the share" ticket. The applied sequel to L07 (permissions)
and L22 (the file server).
**Primary artifact:** the share-access troubleshooting guide + `scripts/share_audit.ps1`. **Lab:** FS01
(`infra/`).

> **How to use this lesson:** read §1–§7, do §8 (build a share + break/fix access), produce §9, take
> the quiz, reflect. Then Lesson 24.

---

## §1 — Concept (Theory)

### What it is
A **file share** is a folder on a server (FS01, L22) made available over the network via **SMB**, reached
as `\\FS01\Finance` (or a **mapped drive** like F:). Access is governed by **two independent permission
layers** (L07): **Share permissions** (apply only over the network) and **NTFS permissions** (apply
always); the user's **effective access** over the network is the **most restrictive** of the two. Shares
are commonly delivered to users via **mapped drives** (often by GPO, L19) and made tidy with
**Access-Based Enumeration (ABE)** so users only *see* folders they can access.

### Why it matters for support
Shared drives are where teams keep their work, so "Access denied," "I can open but can't save,"
"my F: drive is gone," and "build us a new team share" are constant tickets. This lesson makes you the
person who can both **diagnose** share access precisely (using the two-layer model) and **build** a share
correctly (group-based, least privilege) — a core Junior-SysAdmin skill that ties together L07
(permissions), L18 (groups), L19 (GPO drive maps), and L22 (the server).

### Three-Level Depth (Lens A)
- **Level 1 — User:** "I can't get into the F: drive / the team folder / I can't save my file."
- **Level 2 — Technician:** check the user's **group membership** (L18) vs the share's permissions,
  remember **share + NTFS, most-restrictive wins** (L07), confirm the **mapped drive/GPO** delivered it
  (L19), and that they **re-logged in** after any change (stale token, L07).
- **Level 3 — Engineer:** SMB shares are published by the **Server service (LanmanServer)** on FS01
  (L22); each share has a **share ACL** and the folder has an **NTFS ACL** (DACL of ACEs keyed on SIDs,
  L07); effective access = intersection (deny wins); **ABE** filters the directory listing by the user's
  access; mapped drives are set by **GPP drive-map GPOs** (L19) scoped by group/OU; "can open, can't
  save" = **Read but not Modify/Write** on NTFS. This is *why* the precise fix is "add to the right group
  + re-logon," not "give Everyone Full Control."

### Two Teaching Approaches (Lens B) — building a share the right way
**Approach 1 (technical):** best practice = set **Share permissions** broad (e.g. Authenticated Users =
Full/Change) and control **real access via NTFS, granted to security groups** (not individuals), at
**least privilege** (Read vs Modify per role); deliver via a **group-scoped drive-map GPO**; enable
**ABE**. Then access is auditable and maintainable: membership in the role group = access; the
two-layer model collapses to "what does NTFS say for this group."

**Approach 2 (analogy):** a share is a **filing room in the building**. The **share permission** is the
**building's outer door for visitors arriving over the network**; the **NTFS permission** is the **lock
on the filing room and each cabinet** (applies however you arrive). Best practice = leave the outer door
broadly open (share = Authenticated Users) but lock the **cabinets by team key (NTFS by group)** so only
Finance opens the Finance cabinet — and with **ABE**, you don't even *see* cabinets you can't open.
**Where it breaks down:** the "most restrictive of two doors" rule confuses people ("it works at my desk
but not from home") — locally the outer/network door (share) doesn't apply at all, only the cabinet lock
(NTFS).

### Visual (ASCII) — the two layers + best-practice design
```
   user (in group "Finance") ─over network─▶ \\FS01\Finance
        │                                        │
   SHARE perms (network only):  Authenticated Users = Full   ╲
   NTFS perms (always, by GROUP): Finance = Modify, others — ╲──▶ EFFECTIVE = most restrictive (DENY wins)
                                                                  → Finance gets Modify; non-members denied
   delivered by:  GPO drive map (F:) scoped to Finance group (L19)   ·   tidy with ABE (see only what you can open)
   "open but can't save" = NTFS Read without Modify   ·   "in group but denied" = stale token (re-logon, L07)
```

---

## §2 — Tools & Commands

| Task | GUI | PowerShell |
|---|---|---|
| Create/manage shares | Server Manager → File and Storage / `fsmgmt.msc` | `New-SmbShare` · `Get-SmbShare` |
| Share permissions | folder → Sharing → Advanced | `Get-SmbShareAccess` · `Grant-SmbShareAccess` |
| NTFS permissions | folder → Security | `Get-Acl` · `icacls` (L07) |
| Effective access | Security → Advanced → Effective Access | — |
| Who's connected / open files | `fsmgmt.msc` → Sessions/Open Files | `Get-SmbSession` · `Get-SmbOpenFile` |
| Map a drive | `net use` / Explorer | `New-PSDrive` / GPO (L19) |
| Access-Based Enumeration | share properties | `Set-SmbShare -FolderEnumerationMode AccessBased` |

```powershell
New-SmbShare -Name Projects -Path D:\Shares\Projects -FullAccess 'Authenticated Users' -FolderEnumerationMode AccessBased
# real access controlled by NTFS, granted to a GROUP at least privilege:
icacls D:\Shares\Projects /grant 'CORP\Projects:(OI)(CI)M'        # Projects group = Modify (inherited)
Get-SmbShareAccess Projects                                       # the share-layer ACL
Get-SmbOpenFile | Where-Object Path -like '*Projects*'           # who has a file open (locks)
```

> **Danger zone** (`navi.project.md`): share/NTFS changes affect many users' access — **lab (FS01)
> first**, change access **by group** (never "Everyone/Full Control"), confirm scope; data-owner
> approval for sensitive shares (L07).

---

## §3 — Real-World Support Context & Use Cases

- **Daily tickets:** "Access denied to \\FS01\X" (L07 spine), "can open but can't save" (Read vs
  Modify), "my mapped drive is gone" (GPO/L19), "build a share for the new team" (a Request, L17).
- **Build-by-group, least privilege:** the maintainable design — access = role-group membership (L18),
  so onboarding/reorg (L20) just changes group membership. Avoid per-user ACLs and "Everyone Full
  Control" (the classic security finding, L07/L29).
- **ABE** keeps big share trees usable (users see only what they can open) and reduces "what's in that
  folder I can't open?" tickets.
- **File locks:** "the file is locked by another user" → `Get-SmbOpenFile` / sessions (close a stale
  lock carefully).
- **The DFS/namespace world** (`\\corp.example\shares\…`) exists in bigger orgs (a logical layer over
  many servers) — know it exists; depth is infra-level.
- **Exam framing:** A+ (shares/permissions, mapped drives), the Microsoft server-admin path (File
  Services), MD-102 (data access).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0605 (P3):** *"I can open the files in the Projects share but when I try to save my edits
> it says I don't have permission. — Karim, in Projects."*

1. **Read the symptom precisely:** **open = yes, save = no** → he has **Read** but not **Modify/Write**
   on NTFS. That's the diagnosis before touching anything.
2. **Confirm via the two layers (L07):** `Get-SmbShareAccess Projects` (share — likely broad/Change) and
   `icacls` / Security tab on the folder → the **Projects** group has **Read** only (should be Modify),
   or Karim isn't in the right group.
3. **Check membership + token:** `Get-ADPrincipalGroupMembership karim` — is he in **Projects** (the
   Modify group)? Did he re-logon since any change? (stale token, L07).
4. **Branch:**
   - **Group has Read not Modify** → the share was built with the wrong NTFS level → grant the
     **Projects** group **Modify** on NTFS (by group, with data-owner OK).
   - **Karim in the wrong (read-only) group** → move him to the Modify group (least privilege) + re-logon.
5. **Verify:** Karim can now save; confirm.
6. **Document:** which layer/level was wrong and the group-based fix.

The teaching point: **"open but can't save" = Read without Modify** — the symptom tells you the exact
NTFS level; fix it **by group**, not by adding Karim to the ACL directly.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: file-share access (can't reach / can't open / can't save / can't see / locked).**

### 1 · Symptoms
"Access denied" to a share · can open but can't save (read-only) · mapped drive missing · can't see a
subfolder · "file locked by another user" · whole share unreachable (server, L22) · "works locally not
over VPN."

### 2 · Possible Causes (most-likely first)
1. **Group membership** missing/wrong (L18/L07) → no/insufficient access.
2. **NTFS level** wrong (Read vs Modify) → "open but can't save."
3. **Share vs NTFS / most-restrictive** mismatch (L07); local-vs-network.
4. **Stale token** — changed groups, no re-logon (L07).
5. **Mapped drive not delivered** (drive-map GPO didn't apply — L19).
6. **Server/share down** (FS01 / LanmanServer / disk — L22/L06) → whole share unreachable.
7. **File lock** — another user/session has it open.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Whole share unreachable or just this folder/action? | whole | server/share/network (L22/L08) |
| 2 | `Get-ADPrincipalGroupMembership` vs share's groups | missing/wrong | fix group (L18/L07) + re-logon |
| 3 | NTFS level (`icacls`/Security) | Read not Modify | grant group Modify (by group) |
| 4 | Re-logged in since change? | no | sign out/in (stale token) |
| 5 | Mapped drive present? `gpresult` (L19) | GPO denied | fix scope/membership (L19) |
| 6 | `Get-SmbOpenFile` (lock) | locked | close stale lock carefully |
| 7 | Effective Access tab for the user | shows denied | see which layer denies |

### 4 · Resolution Steps
Add the user to the correct **role group** at the right **NTFS level** (Read vs Modify), least privilege
(L07) → re-logon; correct the NTFS/share level (by group); fix the drive-map GPO scope (L19); close a
stale file lock (`Close-SmbOpenFile`, carefully); restore the server/share if down (L22/L06). Never
"Everyone/Full Control" as a shortcut.

### 5 · Escalation Criteria
Escalate to senior infra / the **data owner** for: new shares on sensitive data (approval), changing
**share/group structure**, DFS/namespace changes, server-side outages (L22), and reorg-wide access
fixes (L18/L20). Sensitive-data access needs data-owner sign-off (L07). Attach: the two-layer ACLs
(`Get-SmbShareAccess` + `icacls`), group membership, effective access.

### 6 · Post-Incident Documentation
Ticket note (which layer/level + group fix + re-logon), access records updated (feeds L27 access
reviews), KB (KB-0007 "access a shared folder"), Problem if a reorg/build pattern strands many (L32).

---

## §6 — Ticket Simulation

> **Ticket ENT-23 / REQ-0602 (P3, Service Request):** *"Please set up a new shared drive for the new
> Marketing team — about 12 people, they need to read/write their files, and nobody outside Marketing
> should see it. — manager."*

**Triage:** a **build request** (Service Request, L17) — the chance to do shares the *right* way (group-
based, least privilege, ABE) so it never becomes an access-ticket factory.

**Worked resolution (build it correctly):**
1. **Confirm the requirements:** ~12 users, **read/write** for Marketing, **invisible** to non-members,
   data sensitivity (drives approval/owner).
2. **Use a role group (L18):** ensure a **Marketing** security group exists with the right members
   (this is what onboarding/L20 will manage going forward — don't add 12 users individually).
3. **Create the share (L22/FS01):** `New-SmbShare -Name Marketing -Path D:\Shares\Marketing -FullAccess
   'Authenticated Users' -FolderEnumerationMode AccessBased` (share broad; **ABE on** so non-members
   don't even see it).
4. **Control access via NTFS by group, least privilege:** `icacls D:\Shares\Marketing /grant
   'CORP\Marketing:(OI)(CI)M'` (Modify = read/write) and remove broad inherited access so **only**
   Marketing (and admins) have NTFS rights.
5. **Deliver it (L19):** add/scope a **drive-map GPO** (e.g. M:) to the Marketing group/OU so members get
   it automatically at logon.
6. **Verify:** a Marketing member sees + read/writes M:; a non-member **can't see it** (ABE) and is
   denied. Document the design.
7. **Hand off to lifecycle:** access is now "be in the Marketing group" — onboarding/reorg (L20) handles
   it; no future per-user ACL edits.

**The professional ticket note:**
```
SUMMARY: Built \\FS01\Marketing for the new Marketing team (12 users). Share = Authenticated Users (broad)
with ABE ON; real access via NTFS granted to the Marketing security group at Modify (least privilege);
delivered as M: via a group-scoped drive-map GPO. Verified members read/write, non-members can't see it.
REQUEST: read/write team share, invisible to non-Marketing.
DESIGN (best practice): share broad + ABE; NTFS by GROUP (Marketing=Modify); GPO drive map scoped to
Marketing; no per-user ACLs; no Everyone/Full Control.
ACTIONS: confirmed Marketing group membership; New-SmbShare (ABE); icacls grant Marketing:M + removed
broad inheritance; scoped drive-map GPO (L19); verified member access + non-member denied/hidden.
RESULT: maintainable, auditable share; access = Marketing group membership (lifecycle via L20).
FOLLOW-UP: KB-0007 (access a shared folder); access recorded for reviews (L27). Data-owner approved.
```

---

## §7 — Service Desk / ITIL Perspective

- **Build = Service Request; access change = Request; lost access = Incident; share down = Incident
  (often major, via L22).**
- **Group-based, least-privilege design is the ITIL/standardization win:** access tied to role groups
  makes onboarding/offboarding/reorg (L20) and **access reviews** (L27) clean and auditable — the
  opposite of per-user ACL sprawl.
- **Data-owner approval** for sensitive shares is an access-management control (L07/L17) — the desk
  fulfills within governance, doesn't freelance grants.
- **Server/share availability** ties to L22 (a share down is a multi-user incident) and L30 (shares must
  be backed up — a deleted/ransomwared share needs a restore).
- **Metric/risk angle:** "Everyone/Full Control" and ACL sprawl are top audit findings; clean
  group-based shares reduce both tickets and risk.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build a share the right way and diagnose the common access failures — on FS01.

### Lens C — Manual → Automation → Why
- **Manual:** create a share + set permissions via the GUI for one share.
- **Automated:** `share_audit.ps1` reports every share's **share ACL + NTFS ACL + which groups** have
  what — and flags **"Everyone/Full Control"** and per-user ACEs (the bad patterns) across the file
  server.
- **Why:** at scale you can't eyeball dozens of shares; an audit script surfaces over-permissioned shares
  (security/L07/L29) and feeds **access reviews** (L27); scripted creation makes new shares consistent.

### Steps
1. **Lab (FS01):** create `D:\Shares\Projects`; `New-SmbShare` with `Authenticated Users` Full + **ABE
   on**.
2. **NTFS by group:** grant the **Projects** group **Modify** via `icacls`; remove broad inheritance so
   only the group + admins have access.
3. **Two-layer drill:** prove **most-restrictive wins** — set share to Read, NTFS to Modify, observe a
   network user gets Read; flip it; confirm L07's rule.
4. **"Open but can't save" drill:** grant a test user **Read** only → confirm they open but can't save →
   grant Modify (via group) → confirm they can save.
5. **ABE drill:** confirm a non-member **can't see** the share folder.
6. **Lock drill:** open a file as one user; `Get-SmbOpenFile` to see the lock; `Close-SmbOpenFile`
   carefully.
7. **Write `scripts/share_audit.ps1`** (share+NTFS ACLs, flag Everyone/Full + per-user ACEs) and the
   share-access troubleshooting guide.

### Lens D — the raw artifact (the audit catches the bad pattern)
```
> .\share_audit.ps1 FS01
   Share        SharePerm                NTFS (groups)                     Flag
   -----        ---------                -------------                     ----
   Marketing    Auth Users: Full + ABE   CORP\Marketing: Modify            OK (group-based, least priv)
   OldShare     Everyone: Full           Everyone: Full Control            ⚠ EVERYONE/FULL — over-permissioned (L07/L29)
   HR           Auth Users: Full         CORP\jdoe: Modify (per-user ACE)  ⚠ per-user ACL — not maintainable (use a group)
#   The audit surfaces the two classic findings: "Everyone/Full Control" (security risk) and per-user
#   ACEs (unmaintainable). Both are remediated by switching to group-based, least-privilege NTFS.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/build-a-file-share.md` — the group-based, least-privilege, ABE design +
   GPO delivery.
2. **Troubleshooting Guide:** `docs/troubleshooting/share-access.md` — the full spine.
3. **Ticket Notes:** `docs/tickets/ENT-23-build-marketing-share.md` — the worked ENT-23.
4. **KB Article:** `docs/kb/` — KB-0007 "Access a shared folder (and request access)" for end users.
5. **Incident Report:** a share-outage (FS01/disk) or an over-permissioned-share finding as an incident/
   problem (L22/L32).
6. **Portfolio Artifact:** §10 bullet + the share-vs-NTFS + build-by-group talking points.
7. **Script:** `scripts/share_audit.ps1` (`Invoke-ScriptAnalyzer`-clean; flags bad patterns).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Designed and supported SMB file shares with group-based, least-privilege NTFS
  permissions, Access-Based Enumeration, and GPO-delivered drive maps; built a share-audit script that
  flags 'Everyone/Full Control' and per-user ACLs for remediation."*
- **Interview talking point:** **share vs NTFS, most-restrictive wins** (and local-vs-network),
  **build-by-group + least privilege + ABE**, and reading "open but can't save" as **Read without
  Modify** — plus why "Everyone/Full Control" is a finding, not a fix.
- **Serves:** IT Support, Desktop Support, Junior SysAdmin, Infrastructure Support.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2):** shares, NTFS vs share permissions, mapped drives. **Microsoft server-admin
  path:** File Services. **MD-102:** data access. Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** access-to-the-team-drive is blocking and urgent for users — diagnose precisely (the
symptom tells you the layer) and explain the re-logon; for build requests, set expectations around
data-owner approval.

**🔒 Security:** shares are a primary data-exposure surface — **least privilege + group-based** access,
**never "Everyone/Full Control"** (the #1 share audit finding), **ABE** to limit information disclosure,
and **data-owner approval** for sensitive shares (L07). Over-permissioned shares are how ransomware
spreads and how data leaks; **back up shares** (L30 — a ransomwared/deleted share needs a tested restore)
and watch for mass-file changes (encryption = ransomware signal, NaviOpsSec). Every permission change is
a **danger zone**: by group, scoped, approved.

---

## Quiz (Interview-Style, Graded)

**Q1.** Share permissions vs NTFS permissions — when does each apply, and which wins over the network?
> **Your answer:**

**Q2.** A user can open files in a share but can't save changes. What's the exact cause?
> **Your answer:**

**Q3.** What's the best-practice way to grant a team access to a share, and why not just add each person
to the folder's permissions?
> **Your answer:**

**Q4.** **Scenario:** build a new team share that's read/write for the team and invisible to everyone
else. Walk me through how you'd set it up.
> **Your answer:**

**Q5.** Why is "give Everyone Full Control" a problem even though it "makes it work"?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `share vs NTFS permissions most restrictive`
- `New-SmbShare access based enumeration`
- `icacls grant group modify least privilege`
- `mapped drive GPO drive maps`
- `smb open file lock close-smbopenfile`

**Tools**
- `Get-SmbShareAccess Get-Acl`
- `share permissions audit everyone full control`

**Going further**
- `endpoint troubleshooting` (L24) · `windows server` (L22) · `user provisioning` (L20) ·
  `asset/access reviews` (L27) · `backup and recovery` (L30)

**Service / Security (Lens E):**
- 🤝 `precise share-access diagnosis`, `data-owner approval expectations`
- 🔒 `no everyone full control`, `least privilege shares`, `share backup ransomware` (→ NaviOpsSec)

---

## Lesson Status
- [ ] §8 lab completed (build a share + two-layer/ABE/lock drills + share_audit.ps1 + guide)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 24 — Endpoint Troubleshooting**.

---

*Lesson 23 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: Microsoft SMB/File
Services + NTFS/share permissions docs; builds on L07/L18/L19/L22.*
