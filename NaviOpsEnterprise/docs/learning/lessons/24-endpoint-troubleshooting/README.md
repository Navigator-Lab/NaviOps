# Lesson 24 — Endpoint Troubleshooting

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the deep version of "fix the PC" — the **slow computer**, **won't boot**, **profile
corruption**, **blue screens (BSOD)**, and **performance triage** — plus **remote support** (Quick
Assist/RDP/RMM) and the time-boxed **fix-vs-reimage** decision. Pulls together hardware (L02), OS (L03),
Windows (L04), storage (L06), and software (L25) into a disciplined endpoint method.
**Primary artifact:** the "slow computer" runbook + `scripts/endpoint_triage.ps1`.

> **How to use this lesson:** read §1–§7, do §8 (run a performance triage + a remote-support session),
> produce §9, take the quiz, reflect. Then Lesson 25.

---

## §1 — Concept (Theory)

### What it is
**Endpoint troubleshooting** is the structured diagnosis and repair of a user's computer when it's slow,
unstable, won't boot, or behaves wrong — synthesizing every layer below it: **hardware** (L02), **OS/boot**
(L03), **Windows subsystems** (L04), **storage** (L06), **drivers/updates** (L26), **profile**, and
**software** (L25). It's done increasingly **remotely** (Quick Assist, RDP, an RMM agent) and includes the
judgment call: time-box the fix, and if it's profile/OS corruption with data safely backed up,
**reimage** rather than chase a ghost.

### Why it matters for support
"My computer is slow" is one of the vaguest, highest-volume tickets — and the one that separates a
methodical tech from a flailing one. A disciplined performance triage (which resource is the bottleneck?)
+ the fix-vs-reimage decision keeps MTTR low and users productive. This is the **Desktop Support / IT
Support** core skill, and where remote-support efficiency really pays off.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "my computer is slow / froze / keeps crashing / won't start / it's acting weird."
- **Level 2 — Technician:** identify the **bottleneck** (Task Manager: CPU? RAM? disk? — L03), check
  **startup load**, **disk health/space** (L02/L06), **drivers/recent updates** (L26), **profile** (test
  another user — L04), and decide fix-in-place vs reimage; do it **remotely** where possible.
- **Level 3 — Engineer:** performance is bounded by the **saturated resource** (CPU queue, committed
  memory/paging, disk queue length/latency, sometimes network); the **Reliability Monitor** + **Event
  logs** (L03/L04) timeline instability to a cause (a driver, an update, an app); **BSOD** bugcheck codes
  + the faulting driver pinpoint kernel-level faults; a **corrupt profile** (L04) or pervasive system-file
  corruption (`sfc`/`DISM`, L04) is often faster to **reimage** than repair; **OneDrive KFM** (L11/L30)
  makes reimaging safe. This is *why* "which resource is maxed?" and "is data backed up?" drive the whole
  decision.

### Two Teaching Approaches (Lens B) — find the bottleneck, then decide
**Approach 1 (technical):** a "slow" or unstable endpoint has a **measurable cause** — a saturated
resource (CPU/RAM/disk), a heavy startup set, a failing/full disk, a bad driver/update, malware, or a
corrupt profile/OS. Diagnose by **measurement** (Task Manager/perfmon/Reliability Monitor), fix the
dominant cause, and **time-box**: past a threshold, with data backed up, **reimage** beats endless
in-place repair.

**Approach 2 (analogy):** a slow PC is like a **clogged highway** — the jam has a specific **bottleneck**
(one lane closed = one maxed resource). You don't widen every road randomly; you **find the choke point**
(Task Manager) and clear *that* (close the runaway app, free the disk, replace the dying drive, roll back
the bad driver). And if the road is structurally broken (corrupt OS/profile), it's faster to **repave it**
(reimage) than patch endless potholes — *after* you've moved the residents' belongings to safety (back up
the data). **Where it breaks down:** unlike a highway, the "traffic" can be **malware** (L29) — slowness +
weird behavior + odd processes means check for compromise, not just performance.

### Visual (ASCII) — the endpoint triage funnel
```
   "slow / unstable / won't boot / weird"
        │  (remote in: Quick Assist / RDP / RMM)
   1 MEASURE the bottleneck (Task Mgr): CPU? RAM(→paging)? DISK(100%/queue)? — L03
   2 STARTUP load (heavy auto-starts) · 3 DISK health+space (L02/L06) · 4 DRIVERS/recent UPDATE (L26)
   5 PROFILE? (test another user — L04) · 6 MALWARE? (odd procs/behavior — L29) · 7 BSOD code+driver (L03)
        │
   FIX the dominant cause ──or──▶ TIME-BOX exceeded + data backed up (OneDrive KFM, L11/L30) ──▶ REIMAGE
```

---

## §2 — Tools & Commands

| Task | GUI | PowerShell / tool |
|---|---|---|
| Find the bottleneck | Task Manager → Performance/Processes | `Get-Process \| Sort CPU`/`WS` (L03) |
| Deep performance | Resource Monitor (`resmon`) / `perfmon` | `Get-Counter` (L22) |
| Instability timeline | **Reliability Monitor** (`perfmon /rel`) | — |
| Startup impact | Task Manager → Startup | `Get-CimInstance Win32_StartupCommand` |
| Disk health/space | (CrystalDiskInfo) / Storage | `Get-PhysicalDisk` / `Get-Volume` (L02/L06) |
| Events / BSOD | Event Viewer | `Get-WinEvent` (L03) |
| Drivers / roll back | Device Manager | `pnputil` / roll back (L04/L26) |
| Repair system files | — | `sfc /scannow` · `DISM …/RestoreHealth` (L04) |
| Remote support | **Quick Assist** / RDP / RMM | `Enter-PSSession` (L22) |
| Profile test | log in as another user | `Get-CimInstance Win32_UserProfile` |

```powershell
Get-Process | Sort-Object CPU -Descending | Select -First 5            # CPU hogs
Get-Process | Sort-Object WorkingSet -Descending | Select -First 5     # memory hogs
Get-Counter '\PhysicalDisk(_Total)\% Disk Time','\Memory\% Committed Bytes In Use'   # disk/mem pressure
Get-Volume C | Select @{n='Free%';e={[math]::Round($_.SizeRemaining/$_.Size*100)}}   # disk space (L06)
Get-WinEvent -LogName System -MaxEvents 20 | Where LevelDisplayName -in 'Error','Critical'   # recent faults (L03)
```

> **Note:** **remote support has a consent/security dimension** — confirm you're helping the **verified**
> user (L29), and remote tools are powerful (treat like any privileged access). Reimage is
> **destructive** — confirm data is backed up first (do-no-harm, L06/L30).

---

## §3 — Real-World Support Context & Use Cases

- **"Slow computer"** is high-volume and vague — the disciplined bottleneck method (which resource is
  maxed?) is what resolves it fast instead of "try restarting" forever.
- **Disk 100%** (a dying or full disk — L02/L06) is a leading cause of "slow"; **low RAM → paging** (L03)
  is another; a **runaway process/CPU** a third.
- **Post-update/driver instability** (L26) → Reliability Monitor + Event logs timeline it; roll back.
- **Profile corruption** (L04 — "all my stuff is gone"/odd behavior for one user) → test another profile,
  rebuild or reimage.
- **BSOD** → capture the bugcheck code + faulting driver (L03); recurring fleet BSODs = a problem (L32).
- **Remote support** (Quick Assist/RDP/RMM) is how most endpoint tickets are handled now — efficient,
  but consent + security matter (L29).
- **Fix-vs-reimage:** time-box (~30–45 min for one endpoint, IT-Support playbook); with OneDrive KFM
  (L11/L30) reimaging is fast and safe.
- **Exam framing:** A+ (Core 2 — OS/security/software troubleshooting + the methodology), MD-102
  (endpoint management).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0505 (P3):** *"My computer is so slow I can't work — everything takes forever. —
> Tara, LT-0480."*

1. **Remote in (with consent):** Quick Assist/RDP to LT-0480 — confirm it's the verified user (L29).
2. **Measure the bottleneck (the key step):** Task Manager → Performance.
   - **Disk at 100%** → a process hammering disk (Windows Update/AV scan, indexing) **or** a failing/full
     disk (L02/L06: `Get-PhysicalDisk` health, `Get-Volume` space).
   - **RAM ~100% + paging** → too many apps / too little RAM (L03) → close apps / plan upgrade.
   - **CPU pinned** → `Get-Process | Sort CPU` → the runaway process.
   (Say it's **disk 100%, drive HealthStatus = Warning** → a **dying disk**, L02.)
3. **Confirm the cause:** SMART/`Get-PhysicalDisk` Warning + high disk latency = the slow is a **failing
   drive**, not "too many tabs."
4. **Data first (do-no-harm):** confirm Tara's data is in **OneDrive/KFM** (L11/L30) before any swap/
   reimage.
5. **Resolve:** replace the failing disk (L02) + reimage, or restore to a loaner (L02/L27) so Tara works
   now; data flows back from OneDrive.
6. **Verify + document:** snappy machine; note root cause = failing disk (not user behavior), data safe.

The teaching point: **measure the bottleneck before acting** — "slow" has a specific, measurable cause;
naming it (failing disk vs RAM vs runaway process) is the whole job, and it routes you to the right (often
hardware/reimage) fix.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: endpoint slow / unstable / won't boot / corrupt / crashing.**

### 1 · Symptoms
Very slow · freezes/hangs · BSOD (crashes) · won't boot / boot loop · "all my settings gone" (profile,
L04) · slow only at logon (L03/L19) · weird behavior + slow (possible malware, L29).

### 2 · Possible Causes (most-likely first)
1. **Disk full or failing** (L06/L02) — top "slow"/freeze/won't-boot cause.
2. **RAM exhaustion → paging** (L03).
3. **Runaway process / heavy startup** (CPU, L03).
4. **Bad driver / recent update** (BSOD, post-patch instability — L26).
5. **Corrupt user profile** (L04) — one user only.
6. **Corrupt system files / boot** (L04 `sfc`/`DISM`/`bootrec`).
7. **Malware** (L29) — slow + odd processes/behavior.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Task Mgr: which resource maxed? | disk/RAM/CPU | chase that resource |
| 2 | `Get-PhysicalDisk` health + `Get-Volume` space | Warning/full | replace (L02)/clean (L06) |
| 3 | Startup impact + top processes | heavy/runaway | trim startup / end process |
| 4 | Reliability Monitor + Event logs (L03) | error/BSOD/post-update | roll back driver/update (L26) |
| 5 | Test a different profile (L04) | original only slow | rebuild profile / reimage |
| 6 | `sfc`/`DISM` (L04) | corruption | repair; if pervasive → reimage |
| 7 | AV scan / odd processes (L29) | malware signs | isolate + security process (L29) |

### 4 · Resolution Steps
Free/replace disk (L06/L02); close apps / add RAM; trim startup / kill the runaway; roll back the bad
driver/update (L26); rebuild the profile (L04); `sfc`+`DISM` or **reimage** (data backed up via KFM,
L11/L30); for malware, **isolate + escalate to security** (L29). **Time-box** in-place repair; reimage
when faster + data is safe.

### 5 · Escalation Criteria
Escalate to senior desktop/sysadmin/security for: fleet-wide BSOD/post-patch instability (problem, L32),
hardware replacement/depot (L02), suspected **malware/compromise** (isolate the machine + security
incident, L29/L31), and reimage/redeploy at scale. Attach: the bottleneck measurement, disk health,
BSOD code, Reliability Monitor timeline, what you tried.

### 6 · Post-Incident Documentation
Ticket note (the **measured** root cause + fix; reimaged? data source = OneDrive), asset update if
hardware swapped (L27), KB ("speed up your PC" self-help), Problem/RCA for fleet patterns (L32),
security escalation if malware (L29).

---

## §6 — Ticket Simulation

> **Ticket ENT-24 / INC-0513 (P2):** *"My laptop is crashing constantly with blue screens and it's been
> getting slower for a week — I have a big deadline tomorrow. — Sam, LT-0481."* Channel: phone.

**Triage:** **BSODs + progressive slowdown over a week** + a deadline → could be a **failing disk** (L02),
a **bad driver/update** (L26), or **malware** (L29). Deadline raises urgency → **P2**. Methodical
measurement decides; data safety is paramount given the deadline.

**Worked resolution:**
1. **Protect the work first:** confirm Sam's files are in **OneDrive/KFM** (L11/L30) — the deadline work
   must be safe before any invasive step. If not synced, get it backed up *now*.
2. **Capture the BSOD evidence:** Reliability Monitor + Event Viewer (L03/L04) → the **bugcheck code** +
   **faulting driver/module**; note frequency.
3. **Correlate + measure:** progressive slowdown + BSODs → check **disk health** (`Get-PhysicalDisk` →
   Warning?) and **recent updates/drivers** (L26 — `Get-Hotfix`); rule out **malware** (odd processes,
   L29).
4. **Branch on the evidence:**
   - **Failing disk (SMART Warning + disk-related bugcheck)** → hardware (L02): with data safe, **issue a
     loaner** (L02/L27) so Sam meets the deadline, RMA/replace the disk + reimage in the background.
   - **Bad driver/update** → roll it back (L26); verify stability.
   - **Malware** → isolate + security incident (L29).
   (Most likely here: failing disk → deadline saved by a loaner, not a risky in-place gamble.)
5. **Verify + document:** stable machine (or loaner) before the deadline; data intact; measured root
   cause recorded.

**The professional ticket note:**
```
SUMMARY: LT-0481 BSODs + week-long slowdown = FAILING DISK (SMART Warning + disk-related bugcheck).
Confirmed Sam's files safe in OneDrive; issued loaner LT-0455 so he meets tomorrow's deadline; RMA'd the
disk + reimaging the unit in the background. No data lost.
SYMPTOM: frequent BSODs + progressive slowdown over ~1 week; deadline tomorrow.
DIAGNOSIS (measured): Reliability Monitor → recurring bugcheck (storage-related); Get-PhysicalDisk →
HealthStatus Warning + high latency; ruled out malware (no odd processes) and recent-update regression.
CAUSE: failing internal disk (hardware, L02).
RESOLUTION (data-first, deadline-aware): verified OneDrive/KFM had his work; issued loaner (asset record
updated, L27); RMA + reimage original. Data restored from OneDrive on the loaner.
FOLLOW-UP: return loaner on repaired unit; KB on "back up to OneDrive" reinforced; if model shows a
failing-disk pattern → Problem (L32).
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Endpoint/Hardware/OS. Single = **Incident**; fleet-wide BSOD/post-patch = a **Problem**
  (L32) and possibly a **major incident** (L31); a reimage/loaner is standard fulfillment.
- **The fix-vs-reimage decision is a productivity + MTTR lever:** time-boxing in-place repair (with KFM
  making reimage safe) keeps users working; a **loaner** (L27) protects deadlines while you repair.
- **Remote support** (Quick Assist/RMM) is the efficiency multiplier — most endpoint tickets never need a
  deskside visit; but it's privileged access (consent + security, L29).
- **Measured root cause** (not "I restarted it") feeds problem management — fleet BSODs/failing-disk
  models become problems, not endless individual tickets.
- **Metric/risk angle:** endpoint MTTR + first-contact (remote) resolution are key desk metrics;
  data-loss-on-reimage is the cardinal sin (always KFM/backup first).

---

## §8 — Practical Lab (build this yourself)

**Goal:** run a real performance triage, a remote-support session, and build the one-shot endpoint-triage
script.

### Lens C — Manual → Automation → Why
- **Manual:** open Task Manager/Resource Monitor/Reliability Monitor and read them.
- **Automated:** `endpoint_triage.ps1` captures the bottleneck snapshot — top CPU/RAM processes, disk
  health + free %, recent critical events, last boot, heavy startup items, and pending reboots — locally
  or **remotely**.
- **Why:** "why is this slow?" recurs constantly; one script gives a consistent, attachable diagnosis
  (and runs remotely across machines), turning "I restarted it" into a measured root cause that feeds
  problem management.

### Steps
1. **Measure a bottleneck:** open Task Manager → Performance on your machine; identify which resource is
   busiest; correlate with `Get-Process | Sort CPU/WorkingSet`.
2. **Reliability Monitor:** open `perfmon /rel` — see the stability timeline; find a recent error/crash
   and its source.
3. **Disk + boot ties:** `Get-PhysicalDisk` (health, L02) + `Get-Volume` (space, L06) — the top "slow"
   causes.
4. **Remote-support drill:** run a **Quick Assist** (or RDP/PS-remoting, L22) session to another lab
   machine — practice the consent + remote-triage flow.
5. **Reimage awareness:** confirm **OneDrive KFM** (L11/L30) is what makes a reimage safe; note the
   time-box/decision rule.
6. **Write `scripts/endpoint_triage.ps1`** (bottleneck + disk health/space + events + startup + uptime,
   local/remote) and the "slow computer" runbook.

### Lens D — the raw artifact (the bottleneck names the cause)
```
> .\endpoint_triage.ps1   (excerpt)
   TopProc(CPU):  System Interrupts 38%, MsMpEng(AV) 22%
   Disk:  C: Free 61%  HealthStatus: Warning  AvgLatency: 240ms   ← failing disk → "slow" + BSOD risk (L02)
   RecentCritical:  BugCheck 0x7A KERNEL_DATA_INPAGE_ERROR (storage)   ← storage-related BSOD = dying disk
   Startup(High):  none unusual
#   Disk HealthStatus Warning + a storage bugcheck + high latency = the "slow + crashing" is a FAILING
#   DISK, not "too many apps." Measure → name the cause → route to the right fix (hardware + reimage,
#   data-first). The script makes this conclusion repeatable and attachable to the ticket.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/slow-computer.md` — the measure-the-bottleneck funnel + fix-vs-reimage.
2. **Troubleshooting Guide:** `docs/troubleshooting/endpoint.md` — the full spine (slow/BSOD/won't-boot/
   profile/malware).
3. **Ticket Notes:** `docs/tickets/ENT-24-bsod-failing-disk.md` — the worked ENT-24.
4. **KB Article:** `docs/kb/` — KB-0009 "Remote Desktop / remote support" + "Speed up your PC" self-help.
5. **Incident Report:** a fleet-wide BSOD/post-patch event as an incident/RCA (L31/L32).
6. **Portfolio Artifact:** §10 bullet + the measure-the-bottleneck + fix-vs-reimage talking points.
7. **Script:** `scripts/endpoint_triage.ps1` (local/remote; `Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Built a PowerShell endpoint-triage script (bottleneck, disk health, instability
  timeline, startup, remote-capable) and a 'slow computer' runbook; diagnosed failing-disk and
  post-update BSOD root causes and applied a time-boxed fix-vs-reimage method with OneDrive-backed data
  safety."*
- **Interview talking point:** **measure the bottleneck** (CPU/RAM/disk) before acting, reading
  **Reliability Monitor/BSOD codes** to a root cause, and the **fix-vs-reimage** decision (time-box +
  data safe via KFM) — plus issuing a **loaner** to protect a deadline.
- **Serves:** Desktop Support, Help Desk T2, IT Support.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2):** OS/software/security troubleshooting + the troubleshooting methodology — core.
  **MD-102:** endpoint management/maintenance. Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** "slow computer" users are frustrated and often blamed-feeling ("too many tabs") — measure
objectively, name the real cause (often hardware, not them), protect their data first, and use a **loaner**
to keep them working. A reimage is scary to users; reassure that data is safe in OneDrive before you do it.

**🔒 Security:** slowness + odd behavior + unknown processes can be **malware** (L29) — don't just
"optimize"; if compromise is suspected, **isolate the endpoint** (disconnect network) and start the
**security incident** process (L29/L31), preserving evidence (NaviOpsSec domain). **Remote support tools**
are privileged access — confirm the **verified** user, and beware attackers posing as IT to get a user to
grant a remote session (a real scam — L29). Reimaging destroys evidence, so on a suspected-compromise box,
image/preserve before wiping.

---

## Quiz (Interview-Style, Graded)

**Q1.** A user says their computer is "slow." What's the first thing you determine, and what tool tells
you?
> **Your answer:**

**Q2.** Name three different root causes of "slow" and how you'd tell them apart.
> **Your answer:**

**Q3.** When do you stop trying to fix a machine in place and reimage it instead — and what must be true
first?
> **Your answer:**

**Q4.** **Scenario:** a laptop has frequent BSODs and a week of slowdown, and the user has a deadline
tomorrow. Walk me through your approach, in order.
> **Your answer:**

**Q5.** What would make you suspect a "slow computer" is actually malware, and what changes about your
response?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `windows slow computer task manager bottleneck disk 100%`
- `reliability monitor crash history`
- `BSOD bugcheck code faulting driver`
- `corrupt user profile reimage decision`
- `quick assist remote support windows`

**Tools**
- `Get-PhysicalDisk Get-Counter endpoint`
- `onedrive known folder move reimage safe`

**Going further**
- `software installation and management` (L25) · `patch management` (L26) · `hardware` (L02) ·
  `filesystems/storage` (L06) · `backup and recovery` (L30) · `security awareness` (L29)

**Service / Security (Lens E):**
- 🤝 `objective slow-PC diagnosis not blame`, `loaner protect deadline`
- 🔒 `malware slow computer isolate`, `remote support scam impersonation`, `preserve before reimage` (→ NaviOpsSec)

---

## Lesson Status
- [ ] §8 lab completed (performance triage + remote-support session + endpoint_triage.ps1 + runbook)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 25 — Software Installation & Management**.

---

*Lesson 24 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+ 220-1102
(troubleshooting methodology), Microsoft Reliability Monitor / BSOD bugcheck references.*
