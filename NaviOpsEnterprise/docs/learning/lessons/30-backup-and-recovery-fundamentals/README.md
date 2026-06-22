# Lesson 30 — Backup & Recovery Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** protecting and restoring data — **backup types** (full/incremental/differential), the
**3-2-1 rule**, **RPO/RTO**, **restore testing** (the part everyone skips), **OneDrive/Known-Folder
recovery & versioning**, and **ransomware/DR** basics. The lesson behind every "do-no-harm, data first"
rule in this platform.
**Primary artifact:** the file-recovery runbook + the backup/restore-test checklist.

> **How to use this lesson:** read §1–§7, do §8 (restore a file from versions + verify a backup),
> produce §9, take the quiz, reflect. Then Lesson 31.

---

## §1 — Concept (Theory)

### What it is
**Backup** is keeping recoverable copies of data; **recovery** is restoring it after loss (deletion,
corruption, hardware failure — L02/L06, ransomware — L29, or disaster). Core concepts: **backup types**
(**full**, **incremental** = changes since last backup, **differential** = changes since last full),
the **3-2-1 rule** (3 copies, on 2 different media, 1 off-site/offline), **RPO** (Recovery Point
Objective — how much data you can afford to lose, set by backup frequency) and **RTO** (Recovery Time
Objective — how fast you must be back), **versioning** (OneDrive/Volume Shadow Copy keep prior versions),
and **DR** (disaster recovery for whole systems/sites). The cardinal rule: **a backup you haven't
test-restored is not a backup.**

### Why it matters for support
"I deleted/lost my file," "my drive died with my only copy" (L02/L06 — ENT-06), "ransomware encrypted the
share" (L23/L29), and "restore this from backup" are real, high-stakes tickets. Backup/recovery is the
**safety net under every other lesson** — it's *why* you can confidently reimage (L24), replace a failing
disk (L02), or recover from ransomware (L29). Data loss is often unrecoverable and career/business-
critical, so this discipline (and **restore testing**) is essential.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "I lost my file / can I get it back? / can you recover the old version?"
- **Level 2 — Technician:** recover from the right source — **OneDrive/version history / Recycle Bin /
  Previous Versions (shadow copy) / the backup system**; know what's backed up (and what isn't — local-
  only data) and the **RPO** (how recent a copy exists).
- **Level 3 — Engineer:** backups are designed around **RPO/RTO** (frequency vs recovery speed),
  **3-2-1** (incl. an **offline/immutable** copy to survive ransomware that targets backups),
  **incremental/differential** chains (restore dependencies), **retention**, and **regular restore
  tests/DR drills** (an untested backup often fails when needed); **OneDrive KFM** (L11) makes endpoint
  data resilient by default. This is *why* "data-first" (L24/L02/L06) is safe and why offline/immutable
  backups matter against ransomware (L29).

### Two Teaching Approaches (Lens B) — 3-2-1 and "test your restores"
**Approach 1 (technical):** a sound backup strategy meets a defined **RPO/RTO**, follows **3-2-1**
(3 copies / 2 media / 1 off-site **and** ideally offline/immutable), uses **full + incremental/
differential** to balance space vs restore speed, applies **retention**, and is **validated by regular
restore tests / DR drills** — because backups silently fail and an untested backup is a false sense of
security.

**Approach 2 (analogy):** backups are **insurance + spare keys**. One spare key in your pocket (a single
local copy) is useless if you lose the whole bag (drive dies / house burns) — so you keep spares in
**different places** (3-2-1: a copy at home, one at a friend's, one in a safe-deposit box = off-site/
offline). And insurance you've **never checked** might not pay out — so you **test the claim** (restore
test) *before* the emergency. **Where it breaks down:** unlike spare keys, **ransomware actively hunts and
encrypts your backups too** (L29) — so one copy must be **offline/immutable** (a key the burglar can't
reach), and "it's backed up to the same server" is not real protection.

### Visual (ASCII) — 3-2-1, RPO/RTO, and the recovery sources
```
   3-2-1 RULE:  3 copies · 2 different media · 1 OFF-SITE (+ ideally OFFLINE/IMMUTABLE vs ransomware, L29)
   RPO = how much data you can lose (set by backup FREQUENCY)  ·  RTO = how fast you must recover

   RECOVER FROM (cheapest/fastest first):
     Recycle Bin → OneDrive version history / "restore files" → Previous Versions (Volume Shadow Copy)
       → the backup system → off-site/DR copy
   CARDINAL RULE:  an untested backup is NOT a backup → RESTORE-TEST regularly (DR drill)
```

---

## §2 — Tools & Commands

| Task | GUI | CLI / where |
|---|---|---|
| Restore a deleted file | Recycle Bin / OneDrive Recycle Bin | — |
| OneDrive version history | right-click file → Version history | OneDrive web "Restore files" |
| Previous Versions (shadow copy) | file/folder → Properties → Previous Versions | `vssadmin list shadows` |
| Windows file backup | File History / Backup settings | — |
| Server/enterprise backup | Windows Server Backup / Veeam/etc. | (backup console) |
| Mailbox/M365 recovery | M365 retention / litigation hold (L11/L13) | EAC / compliance |
| Check backup ran/succeeded | the backup console/report | logs/alerts |
| BitLocker recovery key (L06) | Entra/AD recovery key | (don't reformat a locked drive) |

```powershell
vssadmin list shadows                                  # Volume Shadow Copies (Previous Versions source)
Get-ComputerRestorePoint                               # system restore points (config rollback, L03/L24)
# OneDrive KFM (L11) status — is the user's Desktop/Docs actually protected?
Get-ItemProperty 'HKCU:\Software\Microsoft\OneDrive\Accounts\Business1' -EA SilentlyContinue
```

> **Danger zone** (`navi.project.md`): **restore can overwrite good data** — confirm source/target before
> restoring (do-no-harm). Backup/restore of production data: confirm scope; for ransomware, **don't
> restore from a possibly-infected copy** (coordinate with security, L29).

---

## §3 — Real-World Support Context & Use Cases

- **"I lost my file" / "recover the old version"** — daily; recover from the cheapest source first
  (Recycle Bin → OneDrive versions → Previous Versions → backup).
- **"My only copy was on the drive that died"** (L02/L06 — ENT-06) — this is *why* OneDrive **KFM** (L11)
  and 3-2-1 matter; local-only data is at risk.
- **Ransomware** (L29/L23) — recovery is the **answer to ransomware**: restore from a **clean, offline/
  immutable** backup rather than pay; but you must verify the backup isn't also encrypted (why offline
  matters).
- **Reimage/replace safety** (L24/L02) — backups (esp. OneDrive KFM) are what make "wipe and reimage"
  safe.
- **The untested-backup trap:** backups that "ran" but can't actually restore — **restore tests/DR
  drills** are the only proof.
- **RPO/RTO set expectations:** "the last backup was last night" (you may lose today's work — the RPO);
  "restore takes 4 hours" (the RTO) — communicate honestly.
- **Exam framing:** A+ (Core 2 — backup methods, 3-2-1, recovery), ITIL (service continuity), MS-900
  (M365 data protection/retention).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket REQ-0803 (P2):** *"I accidentally overwrote my project file with the wrong version and saved
> it — I need yesterday's version back, it's due today! — Owen, on the Projects share."*

1. **Don't panic the user — versions likely exist:** an overwrite (not just a delete) is recoverable if
   **versioning** is on (OneDrive/SharePoint version history, or **Previous Versions**/shadow copy on the
   share).
2. **Pick the recovery source:** the file lives on the **Projects share** (L23) → **Previous Versions**
   (folder/file → Properties → Previous Versions, backed by Volume Shadow Copy on the server), or if it's
   a synced **SharePoint/OneDrive** library → **Version history**.
3. **Find yesterday's version:** open Version history / Previous Versions → locate the pre-overwrite
   timestamp.
4. **Restore safely (do-no-harm):** **restore to a copy** (or confirm before overwriting) so you don't
   clobber anything else — then give Owen the recovered version. Confirm it's the right one.
5. **Verify + reassure:** Owen confirms yesterday's content is back; deadline saved.
6. **Document + prevent:** note the recovery source; if the file *hadn't* been versioned/backed up, that's
   a gap to fix (enable versioning / KFM) — and a teachable "save-as for versions" tip.

The teaching point: **most "lost/overwrote a file" tickets are recoverable from versions/shadow copies**
— know the sources (Recycle Bin → OneDrive versions → Previous Versions → backup), and **restore to a
copy** so recovery itself does no harm.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: data loss / recovery (deleted, overwritten, corrupted, failed-drive, ransomware).**

### 1 · Symptoms
"Deleted my file" · "overwrote/saved over it" · "drive died with my only copy" (L02/L06) · file corrupted ·
"need an old version" · **ransomware** (files encrypted/renamed + ransom note — L23/L29) · "restore from
backup".

### 2 · Possible Causes / recovery sources (cheapest first)
1. **Deleted** → Recycle Bin (local + OneDrive/SharePoint Recycle Bin).
2. **Overwritten/old version** → OneDrive/SharePoint **version history** or **Previous Versions** (shadow
   copy).
3. **Local-only data on a dead drive** (L02/L06) → was it backed up (KFM/backup)? if not, possibly
   unrecoverable (data-recovery vendor, ENT-06).
4. **Corrupted** → restore last good version/backup.
5. **Ransomware** → restore from a **clean, offline** backup (security-coordinated, L29).
6. **Backup itself failed** (untested) → escalate; try alternate copies.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Recycle Bin (local + cloud) | there | restore (instant win) |
| 2 | OneDrive/SharePoint version history | versioned | restore the prior version (to a copy) |
| 3 | Previous Versions / `vssadmin` (share) | shadow copy exists | restore from it |
| 4 | Was it backed up? (KFM/backup) what's the RPO? | yes | restore from backup (confirm target) |
| 5 | Drive dead + no backup (L02/L06) | no copy | data-recovery vendor (last resort) |
| 6 | Ransomware? (L29) | yes | **isolate** + restore from **offline** backup w/ security |

### 4 · Resolution Steps
Restore from the cheapest available source (Recycle Bin → versions → Previous Versions → backup),
**restoring to a copy** to avoid overwriting (do-no-harm); for a dead drive with no backup, escalate to
data recovery; for **ransomware**, isolate + coordinate with security and restore from a **clean,
offline/immutable** copy (never pay; never restore from a possibly-infected backup) — L29. Then **fix the
gap** (enable versioning/KFM/backup) so it doesn't recur.

### 5 · Escalation Criteria
Escalate to backup/infra admin, data-recovery vendor, or **security** for: backup-system failures, DR
events, data-recovery on failed hardware, and **ransomware** (security incident + IR — L29/L31/NaviOpsSec).
Restoring production/whole-system or DR = beyond desk scope. Attach: what was lost, the RPO, recovery
sources tried.

### 6 · Post-Incident Documentation
Ticket note (what/recovered-from-where/RPO), **fix the backup gap** if data was nearly/actually lost
(enable KFM/versioning/backup), incident+RCA for data-loss or ransomware (L31/L32), update the recovery
runbook + restore-test schedule.

---

## §6 — Ticket Simulation

> **Ticket ENT-30 / INC-0706 (P1, security + data):** *"Files on the Finance share are all renamed with a
> weird extension and there's a 'readme' demanding payment — and it's spreading. — multiple Finance
> users."* (Ransomware on a share — ties L23 + L29.)

**Triage:** **ransomware** encrypting a shared drive, **spreading**, multi-user → **P1 major incident +
security incident** (L31/L29). Recovery (this lesson) is the *answer*, but containment + security come
first. This is where backup/recovery, security, and incident management converge.

**Worked resolution (contain → preserve → recover from clean offline backup):**
1. **Contain FIRST (stop the spread — L29):** isolate affected machines/the share (disconnect from the
   network) and **identify patient zero** (whose account/endpoint is encrypting — disable + revoke, L20).
   Recovery is pointless while it's still encrypting.
2. **Declare major + security incident (L31/L29):** notify, assign IC, engage **security/NaviOpsSec** —
   this is beyond desk scope (scoping, IR).
3. **Do NOT pay; do NOT restore yet from just any copy:** the on-site/connected backups may **also be
   encrypted** (ransomware targets backups) — this is *why* an **offline/immutable** copy exists (3-2-1).
4. **Assess the backups:** find the **last clean, offline backup** (before the encryption timestamp) and
   verify its **RPO** (how much Finance work is lost — yesterday's? last hour's?).
5. **Recover from the clean copy:** once the environment is contained/cleaned (security-confirmed),
   **restore the share** from the clean offline backup to a clean target; verify integrity with Finance.
6. **Verify + RCA (L32):** confirm Finance has their data (minus the RPO gap); the RCA covers *how it got
   in* (phishing? L29) and *whether backups were adequate/offline* — driving prevention (offline/immutable
   backups, faster patching L26, user training L29, least privilege on the share L23).

**The professional incident note (excerpt):**
```
SUMMARY: Ransomware encrypted the Finance share (spreading, multi-user). Contained (isolated share +
endpoints, disabled patient-zero account + revoked sessions); declared P1 major + security incident
(security/NaviOpsSec engaged). Did NOT pay; connected backups suspect → restored from the last CLEAN
OFFLINE backup after cleanup. Finance data recovered to ~last night's RPO.
SCOPE: Finance share + N endpoints; actively spreading → P1 major + security incident.
CONTAINMENT (first): isolated share/endpoints; identified + disabled patient zero (Disable + Revoke
sessions, L20); engaged security/IR (L29).
RECOVERY (this lesson): on-site backup also encrypted (as feared) → used the OFFLINE/immutable copy from
before the encryption timestamp; restored share to a clean target; verified with Finance.
RPO/RTO: lost ~ today's edits (last clean backup = last night); restore completed in ~Xh.
CAUSE (RCA, L32): initial access via phishing (L29) + share over-permissioned (L23) + on-site-only
secondary backup. RESOLUTION: data restored; no ransom paid.
FOLLOW-UP (prevention): immutable/offline backups verified + tested; tighten share least-privilege (L23);
patch/EDR review (L26); user phishing training (L29). NaviOpsSec owns IR depth.
```

---

## §7 — Service Desk / ITIL Perspective

- **Backup/recovery = IT Service Continuity** (ITIL, L17): designed around **RPO/RTO**, validated by **DR
  drills/restore tests** — service continuity is a planned capability, not a hope.
- **Recovery is the safety net under the whole platform:** it's *why* reimage (L24), disk replacement
  (L02/L06), and ransomware response (L29) are survivable — "data-first / do-no-harm" assumes a real
  backup exists.
- **The untested-backup risk** is a tracked operational risk — "backups ran" ≠ "we can recover"; restore
  tests are the control.
- **Ransomware convergence** (L23+L29+L31): recovery is the *answer* to ransomware, which is *why*
  **offline/immutable** backups are now essential — and why this lesson sits next to security/incident.
- **Set honest expectations:** communicate the **RPO** (data you'll lose) and **RTO** (time to recover) —
  users/leadership need the truth during a loss event.
- **Metric/risk angle:** backup success rate, restore-test pass rate, RPO/RTO attainment, and ransomware
  recoverability are key continuity metrics.

---

## §8 — Practical Lab (build this yourself)

**Goal:** recover data from each source, verify a backup, and internalize 3-2-1 + restore-testing.

### Lens C — Manual → Automation/Process → Why
- **Manual:** restore a file by hand from the Recycle Bin / version history.
- **Systematized:** **automated backups** (OneDrive KFM, scheduled server backups) + **scheduled restore
  tests / DR drills** + monitoring that the backup **actually ran and succeeded**; 3-2-1 with an offline/
  immutable copy.
- **Why:** manual/ad-hoc backups get skipped and fail silently; automation + **proven restores** are the
  only real protection — and offline copies are the only defense when ransomware targets your backups
  (L29).

### Steps
1. **Recover drills:** delete + restore from **Recycle Bin**; edit + restore via **OneDrive version
   history**; use **Previous Versions** (`vssadmin list shadows`) on a folder — know each source.
2. **3-2-1 check:** for a sample data set, map your 3 copies / 2 media / 1 off-site(+offline) — find the
   gap (most setups lack the offline copy).
3. **RPO/RTO:** state the backup frequency (RPO) and a realistic restore time (RTO) for a scenario; note
   what work would be lost.
4. **Restore TEST (the key habit):** actually **restore** a backup to a scratch location and **verify the
   data opens** — prove the backup works (not just that it "ran").
5. **KFM check:** confirm OneDrive Known Folder Move (L11) protects Desktop/Documents — the endpoint
   safety net behind reimage (L24).
6. **Write the file-recovery runbook** (sources, restore-to-a-copy) + the **backup/restore-test
   checklist** (3-2-1, RPO/RTO, offline copy, test schedule).

### Lens D — the raw artifact (versions exist → recovery is possible)
```
   File: Q3-Plan.xlsx  — Version history:
     2026-06-21 09:14  (current — wrong/overwritten content)
     2026-06-20 17:02  ← yesterday's good version → RESTORE THIS (to a copy)
     2026-06-19 16:40
   vssadmin list shadows:  Shadow Copy ... created 2026-06-21 02:00  ← Previous Versions source on the share
#   Versioning/shadow copies mean "I overwrote/lost it" is usually recoverable. Pick the right timestamp,
#   restore to a COPY (do-no-harm). No versions + no backup = the real disaster (why 3-2-1 + KFM matter).
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/file-recovery.md` — recovery sources (Recycle Bin→versions→Previous
   Versions→backup), restore-to-a-copy.
2. **Troubleshooting Guide:** `docs/troubleshooting/data-loss-recovery.md` — the full spine (deleted/
   overwritten/dead-drive/corrupt/ransomware).
3. **Ticket Notes:** `docs/tickets/ENT-30-ransomware-recovery.md` — the worked ENT-30.
4. **KB Article:** `docs/kb/` — "Recover a deleted or overwritten file (OneDrive/Previous Versions)" for
   end users.
5. **Incident Report:** the ransomware event as a **major + security incident report + RCA** (L31/L32/L29).
6. **Portfolio Artifact:** §10 bullet + the 3-2-1 / test-your-restores / offline-backup-vs-ransomware
   talking points.
7. **Checklist:** the **backup/restore-test checklist** (3-2-1, RPO/RTO, offline copy, test cadence).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Built file-recovery runbooks and a backup/restore-test checklist (3-2-1, RPO/RTO,
  offline/immutable copies), recovered user data from version history/shadow copies, and contributed to
  ransomware recovery by restoring a share from a clean offline backup — no ransom paid."*
- **Interview talking point:** **3-2-1** (incl. an **offline/immutable** copy because ransomware targets
  backups), **RPO vs RTO**, **"an untested backup isn't a backup"** (restore testing), and recovery as the
  **answer to ransomware** (clean offline restore, don't pay) — plus restore-to-a-copy (do-no-harm).
- **Serves:** IT Support, Junior SysAdmin, Infrastructure Support (and the continuity bridge to NaviOpsSec).

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2):** backup methods (full/incremental/differential), 3-2-1, recovery, BitLocker
  recovery. **ITIL 4:** service continuity. **MS-900:** M365 data protection/retention. Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** data loss is one of the most distressing user experiences — lead with reassurance ("let's
check the versions/backups"), **restore to a copy** so you never make it worse, and set honest **RPO/RTO**
expectations. Then prevent recurrence (enable KFM/versioning) — turn a scare into resilience.

**🔒 Security:** backup/recovery is the **final defense against ransomware** (L29) — but only if a copy is
**offline/immutable** (ransomware deliberately encrypts connected backups); **never pay**, restore from a
**clean** copy after containment, and don't restore from a possibly-infected backup. Backups themselves
hold sensitive data → **encrypt + access-control** them (a stolen backup is a breach); test restores
(continuity = security); and a **lost/stolen device** is recoverable+wipeable when data is backed up +
encrypted (BitLocker, L06). Recovery is where security, continuity, and service meet.

---

## Quiz (Interview-Style, Graded)

**Q1.** What is the 3-2-1 backup rule, and why does the "1" increasingly need to be offline/immutable?
> **Your answer:**

**Q2.** What's the difference between RPO and RTO? Give an example of each.
> **Your answer:**

**Q3.** A user overwrote a file and saved it. Where do you look to recover the previous version?
> **Your answer:**

**Q4.** **Scenario:** ransomware is encrypting a file share and spreading. What's your order of actions,
and why can't you just "restore from backup" immediately?
> **Your answer:**

**Q5.** Why is "the backup ran successfully" not enough — what must you also do, and how often?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `3-2-1 backup rule offline immutable`
- `RPO RTO explained`
- `full incremental differential backup`
- `onedrive version history previous versions shadow copy restore`
- `ransomware recovery clean offline backup don't pay`

**Tools**
- `vssadmin list shadows previous versions`
- `restore test DR drill backup verification`

**Going further**
- `incident management` (L31) · `root cause analysis` (L32) · `security awareness/ransomware` (L29) ·
  `filesystems/storage` (L06) · `file shares` (L23) · **NaviOpsSec** (IR depth)

**Service / Security (Lens E):**
- 🤝 `reassure on data loss restore to a copy`, `RPO/RTO honest expectations`
- 🔒 `offline immutable backup vs ransomware`, `encrypt backups`, `never pay restore clean` (→ NaviOpsSec)

---

## Lesson Status
- [ ] §8 lab completed (recovery drills + 3-2-1 map + RPO/RTO + restore TEST + runbook/checklist)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 31 — Incident Management**.

---

*Lesson 30 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+ 220-1102
(backup/recovery), 3-2-1 guidance, ITIL service continuity; ransomware recovery → NaviOpsSec.*
