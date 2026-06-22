# Lesson 06 — Filesystems & Storage

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** how data is stored and organized — NTFS vs FAT32/exFAT, partitions/volumes, drive
letters & mount points, Disk Management/`diskpart`, and the two everyday tickets: **"my disk is
full"** and **"my drive is failing/won't show up."** Storage problems silently cause crashes, slow
machines, and data loss.
**Primary artifact:** `scripts/disk_cleanup.ps1` + a disk-full / failing-disk troubleshooting guide.

> **How to use this lesson:** read §1–§7, do §8 (inspect + clean a real disk), produce §9, take the
> quiz, reflect. Then Lesson 07.

---

## §1 — Concept (Theory)

### What it is
A **filesystem** is how an OS organizes data on a storage device into files, folders, and metadata
(names, sizes, dates, permissions). Windows uses **NTFS** for system/data drives (permissions,
journaling, large files), **FAT32** (old, universal, 4 GB file limit) and **exFAT** (modern
removable media) for USB drives. A physical disk is divided into **partitions/volumes**, each
formatted with a filesystem and (on Windows) given a **drive letter** or mounted into a folder.

### Why it matters for support
Storage is behind a surprising share of tickets: a **full disk** stops updates, breaks apps, and
slows everything; a **failing disk** corrupts data and freezes machines; a **wrong filesystem** means
"the file is too big for this USB"; a **lost drive letter** means "my D: drive disappeared." Knowing
the storage stack turns these from mysteries into quick fixes — and protects user data.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "my C: drive is full" / "my USB won't take this file" / "my external drive
  doesn't show up."
- **Level 2 — Technician:** check space (Storage Settings / `Get-PSDrive`), clean it (Disk Cleanup,
  temp files, Storage Sense), check the filesystem (NTFS vs FAT/exFAT for the USB limit), and use
  **Disk Management** for letters/initialization/format.
- **Level 3 — Engineer:** NTFS journals metadata (crash-resilient) and stores **ACLs** (the
  permissions of Lesson 07) and alternate data streams; a disk has a partition table (**GPT**/MBR);
  "free space" interacts with **virtual memory/pagefile** and **temp**; SSD health and **SMART**
  (Lesson 02) predict failure; a "RAW" volume = corrupt/unrecognized filesystem. This is *why* a
  cleanup, a `chkdsk`, or a reformat is the right tool.

### Two Teaching Approaches (Lens B) — disk vs partition vs volume vs filesystem
**Approach 1 (technical):** a physical **disk** is partitioned (GPT) into one or more **partitions**;
each becomes a **volume** formatted with a **filesystem** (NTFS/exFAT) and assigned a **drive
letter/mount**. These are distinct layers — a disk can be healthy while a volume is full, or a
partition can exist with no letter (so it "disappears").

**Approach 2 (analogy):** the **disk** is a **building**; **partitions** are **floors** you divide it
into; **formatting** is **furnishing a floor for a purpose** (NTFS = a full office, exFAT = a simple
storage room); the **drive letter** is the **floor's room number** so people can find it. **Where it
breaks down:** "free space" isn't just empty rooms — Windows needs working headroom (temp, pagefile,
updates), so a drive at 99% misbehaves long before it's truly "full."

### Visual (ASCII) — the storage stack + the full-disk failure
```
   PHYSICAL DISK (SSD/HDD, has SMART health — L02)
     └─ PARTITION (GPT)  ──▶ VOLUME (formatted NTFS) ──▶ drive letter C:
                                   │
   FILESYSTEM choice:  NTFS (system/data, ACLs, >4GB)   exFAT (USB, >4GB)   FAT32 (universal, 4GB max)

   FULL-DISK CASCADE:   C: at ~100% ─▶ no room for updates(L26)/temp/pagefile ─▶ apps fail to save,
                        Windows Update fails, machine slows/freezes  → free space fixes ALL of it
```

---

## §2 — Tools & Commands

| Task | Windows GUI | PowerShell / CLI |
|---|---|---|
| See free space | Settings → Storage / This PC | `Get-PSDrive C` · `Get-Volume` |
| Clean up | Disk Cleanup (`cleanmgr`) / Storage Sense | `cleanmgr /sagerun` |
| Manage partitions/letters | Disk Management (`diskmgmt.msc`) | `diskpart` · `Get-Partition` |
| Check filesystem errors | drive → Properties → Tools → Check | `chkdsk C: /f` |
| Disk health (SMART) | (CrystalDiskInfo) | `Get-PhysicalDisk \| Select HealthStatus` |
| What's eating space | (TreeSize/WinDirStat) | `Get-ChildItem -Recurse \| sort Length` |
| Initialize/format new disk | Disk Management | `Initialize-Disk` · `Format-Volume` |

```powershell
Get-Volume | Select DriveLetter, FileSystem, @{n='FreeGB';e={[math]::Round($_.SizeRemaining/1GB,1)}}, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}}
# find big folders under a path:
Get-ChildItem C:\Users\jdoe -Recurse -ErrorAction SilentlyContinue | Sort Length -Desc | Select FullName,Length -First 15
Get-PhysicalDisk | Select FriendlyName, MediaType, HealthStatus      # SMART/health (L02)
```

---

## §3 — Real-World Support Context & Use Cases

- **"Disk full" is a top-5 ticket.** It manifests as failed updates, "can't save," Outlook errors,
  and slowness — often *without* the user realizing the disk is the cause. Always check free space.
- **USB file-size limit:** "the file's too big to copy to my USB" = FAT32's 4 GB limit → reformat to
  exFAT/NTFS (after backing up the stick).
- **"My drive disappeared":** lost drive letter, offline disk, or a failing/RAW volume — Disk
  Management triages all three.
- **Data safety first:** any failing-disk or reformat task starts with **back up the data** (L30).
- **Exam framing:** A+ Core 1/2 (storage devices, filesystems, partitions, Disk Management,
  `diskpart`/`chkdsk`); MD-102 (device storage).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0305 (P3):** *"My laptop says it's out of space and Windows update keeps failing. —
> Ian, LT-0440."*

1. **Confirm + measure:** Settings → Storage (or `Get-Volume`) → C: shows **0.5 GB free of 256 GB**.
   That single fact explains the failed updates *and* the slowness.
2. **Find the hogs:** Storage breakdown (Temporary files, Downloads, large OneDrive cache); or
   `Get-ChildItem -Recurse | sort Length` on the user profile.
3. **Safe wins first:** Disk Cleanup / Storage Sense → clear **Temporary files, Windows Update
   cleanup, Recycle Bin, Downloads** (confirm with user). Often frees many GB instantly.
4. **OneDrive "Free up space":** set synced folders to online-only to reclaim local space (data stays
   in the cloud).
5. **Verify:** free space now comfortable (>15–20%); re-run Windows Update → succeeds.
6. **Root cause + prevent:** *why* did it fill? (huge Downloads, old profiles, a runaway log) — enable
   Storage Sense, document, consider a larger drive if chronic (L02 repair/replace).

The lesson: a single metric (free space) can be the root cause of several seemingly unrelated
symptoms — **check it early.**

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: storage — full, failing, or "missing" drive.**

### 1 · Symptoms
"Out of space" / updates fail / can't save / very slow · "drive disappeared" / not in Explorer ·
"file too big for USB" · drive shows **RAW**/"needs formatting" · freezes + SMART warnings.

### 2 · Possible Causes (most-likely first)
1. **Disk genuinely full** (temp/Downloads/updates/OneDrive cache/old profiles).
2. **Filesystem mismatch** (FAT32 4 GB limit) for the USB case.
3. **Lost drive letter / offline disk** ("disappeared").
4. **Filesystem corruption** (RAW, "needs formatting", errors) — `chkdsk`.
5. **Failing disk** (SMART Warning, bad sectors — L02) → recover + replace.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | `Get-Volume`/Storage — free space | <~15% | clean up (cheap, safe first) |
| 2 | Storage breakdown / big-folder scan | one hog | clear it (with consent) |
| 3 | Disk Management — letter/online/RAW | no letter / offline | assign letter / bring online |
| 4 | `Get-PhysicalDisk` HealthStatus / SMART | Warning | **back up now**, plan replace (L02) |
| 5 | `chkdsk X: /f` (after backup) | errors fixed | retest; if persistent → failing disk |
| 6 | USB filesystem (`Get-Volume`) | FAT32 + >4GB file | back up stick → reformat exFAT/NTFS |

### 4 · Resolution Steps
Run Disk Cleanup/Storage Sense; clear temp/Downloads/Update cache/Recycle Bin (with consent);
OneDrive free-up-space; assign a drive letter / bring a disk online; `chkdsk /f` for corruption;
reformat a USB to exFAT for large files; **back up then replace** a failing disk (L02/L30).

### 5 · Escalation Criteria
Escalate to Desktop Support/Sysadmin for: hardware replacement (failing disk), RAID/array issues,
server volumes, or suspected data loss needing recovery tooling. **Never reformat or `diskpart clean`
a drive with the user's only copy of data** — back up first; this is a danger zone. Attach: volume
report, SMART status, `chkdsk` output.

### 6 · Post-Incident Documentation
Ticket note (free-space before/after, what was cleared, root cause), KB ("free up space yourself"),
asset update if a drive was replaced (L27), RCA if data was at risk.

---

## §6 — Ticket Simulation

> **Ticket ENT-06 / INC-0521 (P2):** *"My external backup drive (E:) is gone and Windows wants to
> 'format' it — all my photos are on there, please don't lose them!! — Jia, DESK-1170."*

**Triage:** potential **data-loss** event + an emotional user → handle carefully; impact = personal/
irreplaceable data → **P2** and a *do-no-harm* approach. The "needs formatting" prompt = the
filesystem is **unreadable (RAW)** — but the data may still be intact underneath.

**Worked resolution (do-no-harm):**
1. **STOP — do not click Format.** Set expectation: *"I will not format it; let's see if we can read
   it safely first."*
2. **Inspect, read-only:** Disk Management → is E: present but **RAW**? `Get-Volume` confirms
   FileSystem is blank/RAW. `Get-PhysicalDisk` health for the external (failing vs just corrupt FS?).
3. **Branch:**
   - **Healthy disk, corrupt filesystem:** try `chkdsk E: /f` (can repair the filesystem and remount
     the data) — but only if health is OK; on a *failing* disk, `chkdsk` can worsen it.
   - **Failing disk or chkdsk risky:** escalate to data-recovery tooling/vendor; image the drive
     first; never write to it.
4. **Recover + verify:** if `chkdsk` remounts it, confirm the photos open; immediately copy them to a
   second location (no single point of failure — L30).
5. **Prevent:** set up a real backup (3-2-1, L30) — one external drive is not a backup.

**The professional ticket note:**
```
SUMMARY: External E: showed as RAW with a "format" prompt (corrupt filesystem, disk health OK).
Did NOT format. chkdsk repaired the filesystem; all photos recovered and copied to OneDrive as a
second copy. Advised 3-2-1 backup.
SYMPTOM: E: "missing"/"needs formatting"; irreplaceable photos at risk.
DIAGNOSIS: Disk Mgmt → E: present, RAW; Get-PhysicalDisk → Healthy (corrupt FS, not dying disk).
CAUSE: filesystem corruption (likely improper removal/power loss), not hardware failure.
RESOLUTION: chkdsk E: /f remounted filesystem; verified photos open; copied to OneDrive (2nd copy).
FOLLOW-UP: set up 3-2-1 backup (L30); KB "external drive says needs formatting — DON'T" linked.
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Storage/Hardware. Usually an **Incident**; a "new drive/upgrade" is a **Request**.
- **Priority:** drive **up** when irreplaceable data is at risk — data-loss potential changes the
  calculus even for a single user.
- **The data-safety rule** is an org policy, not a preference: techs do not perform destructive
  storage ops without a confirmed backup. This protects the user *and* the tech.
- **Metric angle:** proactive disk cleanup/Storage-Sense reduces a recurring ticket class; failing-
  disk detection (SMART) prevents data-loss incidents that wreck CSAT.

---

## §8 — Practical Lab (build this yourself)

**Goal:** read the storage stack, free space safely, and build a cleanup/report script.

### Lens C — Manual → Automation → Why
- **Manual:** open Settings → Storage and Disk Cleanup; click around.
- **Automated:** `disk_cleanup.ps1` reports free space, finds the biggest folders, and clears known-
  safe temp locations — consistently and fleet-wide.
- **Why:** at scale you proactively report low-disk machines before they ticket, and apply the same
  safe cleanup everywhere instead of ad-hoc clicking; a report also justifies hardware upgrades.

### Steps
1. **Report:** run the `Get-Volume` one-liner from §2; record free %/GB.
2. **Find hogs:** run the big-folder scan on your profile; note the top consumers.
3. **Safe cleanup:** run Disk Cleanup (`cleanmgr`); enable **Storage Sense**; observe the space freed.
4. **Filesystem awareness:** check a USB stick's filesystem (`Get-Volume`); if FAT32, note the 4 GB
   limit and that exFAT fixes it (don't reformat one with data).
5. **Health:** `Get-PhysicalDisk` → read `HealthStatus` (ties to L02).
6. **Write `scripts/disk_cleanup.ps1`** (report + safe temp cleanup with `-WhatIf` default) and the
   troubleshooting guide.

### Lens D — the raw artifact (the volume report)
```
DriveLetter FileSystem FreeGB SizeGB
----------- ---------- ------ ------
C           NTFS          0.5    256     ← 0.2% free → updates fail, apps can't save, machine crawls
E           RAW           —      931     ← RAW = unreadable filesystem (the "needs formatting" ticket)
F (USB)     FAT32         12     32      ← FAT32 → can't hold a single >4GB file (the "too big" ticket)
```
One report line explains three different tickets. Reading it (Lens D) is the skill.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/free-up-disk-space.md` — the safe cleanup order.
2. **Troubleshooting Guide:** `docs/troubleshooting/disk-full-or-failing.md` — the full spine
   (full / RAW / missing letter / failing).
3. **Ticket Notes:** `docs/tickets/ENT-06-raw-external-drive.md` — the worked ENT-06.
4. **KB Article:** `docs/kb/` — "Free up space on your PC" + "External drive says 'needs formatting' —
   don't click it."
5. **Incident Report:** the data-at-risk recovery as a mini incident report (template).
6. **Portfolio Artifact:** §10 bullet + the do-no-harm data-recovery talking point.
7. **Script:** `scripts/disk_cleanup.ps1` (`Invoke-ScriptAnalyzer`-clean, `-WhatIf` safe default).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Built a PowerShell disk-space report + safe-cleanup script and a storage
  troubleshooting guide, proactively flagging low-disk endpoints and recovering a RAW external drive
  without data loss."*
- **Interview talking point:** the **disk-full cascade** (one full C: causes failed updates + "can't
  save" + slowness) and the **do-no-harm** rule when "Windows wants to format" a drive with data.
- **Serves:** Desktop Support, IT Support, Junior SysAdmin.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 1 & 2):** storage devices, filesystems (NTFS/FAT32/exFAT), partitions, Disk
  Management, `diskpart`/`chkdsk`, drive troubleshooting — core.
- **MD-102:** device storage management. Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** storage tickets often involve **irreplaceable personal data** — lead with reassurance
and the do-no-harm rule, get explicit consent before deleting anything, and never click "Format" on a
user's drive to "make the error go away."

**🔒 Security:** retired/replaced drives still hold data — **sanitize or destroy** them per policy
(L27/L30), never bin them. Encryption (**BitLocker**) protects data on lost/stolen drives — know that
a BitLocker-locked drive needs its **recovery key** (don't reformat a locked corporate drive; find the
key in the directory/Entra). Be wary of unknown USB drives (L29 — they can be malicious).

---

## Quiz (Interview-Style, Graded)

**Q1.** A user can't install updates and says the PC is slow. What's one storage check you'd do early,
and why could it explain both symptoms?
> **Your answer:**

**Q2.** A user can't copy a 6 GB video to their USB stick. What's the likely cause and the fix?
> **Your answer:**

**Q3.** Difference between a partition, a volume, and a filesystem?
> **Your answer:**

**Q4.** **Scenario:** a user's external drive shows in Disk Management as RAW and Windows offers to
"format" it — their only copy of family photos is on it. What do you do, in order, and what do you
NOT do?
> **Your answer:**

**Q5.** `Get-PhysicalDisk` reports a drive's HealthStatus as Warning. What's your move?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `NTFS vs FAT32 vs exFAT differences`
- `windows disk cleanup storage sense free space`
- `disk management assign drive letter RAW volume`
- `chkdsk repair file system`
- `FAT32 4GB file size limit`

**Tools**
- `Get-Volume Get-PhysicalDisk PowerShell`
- `diskpart basics`

**Going further**
- `user accounts and permissions` (L07 — NTFS ACLs) · `endpoint troubleshooting` (L24) ·
  `backup and recovery` (L30) · `asset management` (L27)

**Service / Security (Lens E):**
- 🤝 `do no harm data recovery`, `consent before deleting user files`
- 🔒 `secure drive disposal`, `bitlocker recovery key`, `malicious usb drive`

---

## Lesson Status
- [ ] §8 lab completed (volume report + safe cleanup + disk_cleanup.ps1 + guide)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 07 — User Accounts & Permissions**.

---

*Lesson 06 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+
220-1101/1102 (storage & filesystems), Microsoft NTFS/Disk Management docs.*
