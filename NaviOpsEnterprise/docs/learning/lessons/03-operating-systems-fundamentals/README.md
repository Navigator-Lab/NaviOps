# Lesson 03 — Operating-Systems Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** what an operating system actually does (processes, memory, the file system, the boot
chain, drivers, user sessions), how Windows / macOS / Linux differ from a support standpoint, and
the mental model that makes "why is this happening?" answerable instead of mysterious.
**Primary artifact:** the "which OS am I supporting + how it boots" KB + an OS-triage runbook.

> **How to use this lesson:** read §1–§7, do §8 (inspect a live system's processes/boot/logs),
> produce §9, take the quiz, reflect. Then Lesson 04.

---

## §1 — Concept (Theory)

### What it is
An **operating system (OS)** is the software layer between the hardware (Lesson 02) and the
applications a user runs. It manages **processes** (running programs), **memory** (who gets which
RAM), the **file system** (how data is organized on disk), **devices/drivers** (talking to hardware),
**users & permissions** (who can do what — Lesson 07), and provides the **boot** sequence that gets
from power-on to a usable desktop.

### Why it exists
Without an OS, every application would have to talk to hardware directly and manage memory, disk,
and the CPU itself — impossible to coordinate. The OS is the **shared manager**: it arbitrates
resources, isolates programs from each other (so one crash doesn't take down everything), enforces
security boundaries, and gives apps a consistent interface. For support, the OS is *where most of
your diagnostics happen* — its logs, its task manager, its services.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "Windows" is the thing with the Start menu where my apps live. It sometimes
  needs to "update" or "restart."
- **Level 2 — Technician:** the OS is a set of inspectable subsystems — **processes** (Task Manager),
  **services** (background programs, `services.msc`), **logs** (Event Viewer), **drivers** (Device
  Manager), **startup items**, **user profiles**. When something misbehaves, you look at the relevant
  subsystem.
- **Level 3 — Engineer:** the **kernel** runs in privileged mode and manages CPU scheduling, virtual
  memory (paging), and hardware via drivers; user programs run in user mode and request services via
  **system calls**; the **boot chain** (firmware → bootloader → kernel → session manager → logon)
  is a sequence where each stage can fail distinctly; **virtual memory** means "out of RAM" first
  becomes "slow" (paging to disk) before it becomes a crash. Understanding this is *why* you read a
  specific log for a specific failure.

### Two Teaching Approaches (Lens B) — what the OS does
**Approach 1 (technical):** the kernel multiplexes finite hardware (CPU time, RAM, disk, devices)
across many processes, enforcing isolation and security, scheduling threads, mapping virtual to
physical memory, and mediating all hardware access through drivers. Applications never touch hardware
directly — they ask the kernel.

**Approach 2 (analogy):** the OS is the **operations manager of an office building**. Tenants
(apps) don't run their own power, plumbing, or security — they ask the building manager (kernel),
who allocates conference rooms (memory), schedules the elevators (CPU), keeps the directory (file
system), checks badges (permissions), and isolates tenants so one tenant's mess doesn't flood
another's office (process isolation). **Where it breaks down:** unlike a building, the OS can give
the *illusion* of more space than exists (virtual memory) — which is why a machine gets sluggish
(paging) before it truly runs out.

### Visual (ASCII) — the layers + the Windows boot chain
```
   ┌─────────────── Applications (Outlook, Chrome, Teams) ───────────────┐  user mode
   ├──────────────── OS services / APIs / drivers interface ─────────────┤
   │  KERNEL: process scheduler · memory manager · file system · drivers │  kernel mode
   └──────────────────────────── HARDWARE (L02) ─────────────────────────┘

   WINDOWS BOOT:  UEFI/BIOS ─▶ bootloader (Windows Boot Mgr) ─▶ kernel + drivers
                  ─▶ session manager ─▶ Winlogon ─▶ user profile loads ─▶ desktop
   failure maps:  POST(L02)   "no boot device"      driver BSOD          slow logon / profile (L24)
```

---

## §2 — Tools & Commands

| Tool (Windows) | What it shows | macOS / Linux analog |
|---|---|---|
| **Task Manager** (`taskmgr`) | processes, CPU/RAM/disk, startup | Activity Monitor / `top`,`htop` |
| **Services** (`services.msc`) | background services + state | launchd / `systemctl` (L05) |
| **Event Viewer** (`eventvwr`) | system/app/security logs + Event IDs | Console.app / `journalctl` (L05) |
| **Device Manager** (`devmgmt.msc`) | drivers, failed devices | System Info / `lspci`,`dmesg` |
| **System Configuration** (`msconfig`) | boot options, startup | — |
| **Resource Monitor** (`resmon`) | deep CPU/mem/disk/net | `top`/`iotop` |
| **`winver`** | exact OS version/build | `sw_vers` / `uname -a`, `lsb_release` |

```powershell
Get-ComputerInfo | Select OsName, OsVersion, OsBuildNumber, CsName
Get-Process | Sort-Object CPU -Descending | Select -First 5     # top CPU consumers
Get-Service | Where-Object Status -eq 'Stopped' | Where-Object StartType -eq 'Automatic'  # services that should be running but aren't
Get-WinEvent -LogName System -MaxEvents 20                       # recent system events
```

---

## §3 — Real-World Support Context & Use Cases

- **You support more than one OS.** Predominantly **Windows** (the corporate desktop + servers),
  often **macOS** (execs, design, dev), some **Linux** (servers, some engineers — Lesson 05), and
  **mobile** (iOS/Android for mail/MFA). Knowing the equivalent tool on each saves you.
- **"Is it the OS or the app?"** is the second great triage question (after "hardware or software?").
  An app crashing → reinstall/repair the app; the whole OS slow/unstable → OS-level (drivers,
  startup, profile, disk, malware).
- **Versions/builds matter:** Windows 10 vs 11, feature updates, and "is it patched?" (Lesson 26)
  decide whether a known bug applies.
- **Exam framing:** CompTIA A+ Core 2 (220-1102) is OS-heavy — Windows features, the command line,
  and OS troubleshooting. MD-102 covers Windows client deployment/management.

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0031 (P3):** *"My PC takes forever to get to the desktop and then everything is slow
> for 10 minutes. — Dan, DESK-1140."*

1. **Reproduce/confirm:** slow **logon** + slow **after** logon — two different stages, note both.
2. **Identify the version/build:** `winver` (rules out a known bad update — cross-ref Lesson 26).
3. **Startup load:** Task Manager → **Startup** tab → sort by "Startup impact"; lots of High-impact
   apps explains a slow desktop-ready time.
4. **Resource pressure:** Task Manager → Performance — is RAM ~100% (paging → upgrade/close apps),
   disk 100% (failing disk from Lesson 02, or an indexing/AV scan), or CPU pinned by one process?
5. **Profile/network:** a roaming/slow profile or a GPO/login-script (Lessons 19) can cause slow
   *logon* specifically — `gpresult` and check sync.
6. **Resolve the dominant cause** (disable heavy startup items, address the maxed resource, fix the
   profile), confirm with Dan, document.

The lesson: **separate the stages** (boot → logon → post-logon) because each maps to different
subsystems and different fixes.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: OS won't boot / boots slowly / is unstable.**

### 1 · Symptoms
"No boot device" / stuck on logo / blue screen (BSOD) / very slow logon / desktop slow after logon /
random app crashes / black screen after login.

### 2 · Possible Causes (most-likely first)
1. **Disk** failing or full (Lesson 02/06) — slow, freezes, won't boot.
2. **Too much at startup** / resource exhaustion (RAM/CPU/disk maxed).
3. **Bad driver or recent update** (BSOD, post-update instability — Lesson 26).
4. **Corrupt user profile** (slow/odd logon for one user only).
5. **Corrupt system files / boot configuration** ("no boot device", boot loop).
6. **Malware** (Lesson 29) — slow, odd processes.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Disk space + `Get-PhysicalDisk` health | full / unhealthy | clean up (L06) / replace (L02) |
| 2 | Task Mgr Performance (which resource is maxed) | one pegged | chase that subsystem |
| 3 | Task Mgr Startup impact | many High | trim startup |
| 4 | Event Viewer (System) for errors/BSOD codes | driver/service error | update/roll back driver |
| 5 | Test a *different* user profile | only original user slow | rebuild profile |
| 6 | `sfc /scannow` / `DISM` | corruption found | repair system files |

### 4 · Resolution Steps
Free/replace disk; trim startup; update or **roll back** a bad driver/update; rebuild the user
profile; `sfc /scannow` + `DISM /Online /Cleanup-Image /RestoreHealth`; repair boot
(`bootrec`); run an AV scan; reimage if corruption is pervasive and data is backed up (L30).

### 5 · Escalation Criteria
Escalate to T2/Sysadmin for: repeated BSODs pointing to a fleet-wide driver/update (problem
management — L32), domain-policy-driven slow logon (L19), or suspected malware needing containment
(L29). Attach: `winver`/build, the BSOD stop code, Event Viewer error IDs, what you tried.

### 6 · Post-Incident Documentation
Ticket note with the build, the root cause (e.g. "KB50xxxxx update + Realtek driver → BSOD; rolled
back"), KB for a recurring fix, problem ticket if it's hitting many machines.

---

## §6 — Ticket Simulation

> **Ticket ENT-03 / INC-0032 (P2):** *"After the update last night my laptop blue-screens every time
> I plug in my docking station. — Erin, LT-0431."* Channel: portal.

**Triage:** reproducible crash tied to a recent **update** + a specific device (dock) → strongly
suggests a **driver/update regression**. Impact: blocked from dual-monitor work → **P2**.

**Worked resolution:**
1. **Capture the stop code:** Event Viewer / the BSOD screen — note the `BugCheck` code and the
   faulting driver (often a display/USB/dock driver).
2. **Correlate to the update:** `Get-Hotfix` / Settings → Update history — what installed last night?
3. **Branch:**
   - If a **driver** updated → Device Manager → roll back the dock/display driver.
   - If a **Windows update** is the culprit and a known issue → uninstall that update, pause updates,
     and flag for the patch ring (Lesson 26) so it doesn't redeploy.
4. **Verify:** reconnect the dock — no BSOD. Confirm with Erin.
5. **Prevent recurrence:** since "after the update" + dock suggests it may hit **others on the same
   model/dock**, raise a **problem ticket** (L32) and notify the patch owner.

**The professional ticket note:**
```
SUMMARY: BSOD on dock connect after overnight update on LT-0431. Rolled back display driver +
uninstalled problem update; pinned for patch-ring review. Stable after fix.
SYMPTOM: BSOD (BugCheck VIDEO_TDR_FAILURE) every time dock connected; began after last night's update.
DIAGNOSIS: 1) stop code = display driver fault 2) update history showed driver + cumulative update
overnight 3) rolled back driver → reproduced? no.
CAUSE: display-driver regression delivered with the update (interacts with the docking station).
RESOLUTION: rolled back driver, paused that driver update, confirmed dock works dual-monitor.
FOLLOW-UP: PROBLEM ticket raised (same model + dock fleet-wide); notified patch owner to hold the
driver in the ring. KB drafted.
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** OS/Endpoint. Usually an **Incident**; "after the update, many people" becomes a
  **Problem** (L32) and possibly a **major incident** (L31).
- **The update connection:** a huge share of "it broke overnight" tickets trace to **patching**
  (L26). The service desk is the early-warning radar — clustered tickets after a patch = escalate
  to problem/change management fast.
- **Priority:** a single reproducible crash blocking work is P2; a fleet-wide post-patch crash is
  P1 (major incident).
- **Metric angle:** post-patch incident spikes are watched closely; good notes (with stop codes +
  KB numbers) let problem management find the pattern quickly (lowers MTTR for the whole cluster).

---

## §8 — Practical Lab (build this yourself)

**Goal:** learn to *read* a live OS — its processes, services, boot, and logs — so failures stop
being mysterious.

### Lens C — Manual → Automated → Why
- **Manual:** open Task Manager / Event Viewer and look.
- **Automated:** `Get-Process`, `Get-Service`, `Get-WinEvent`, `Get-ComputerInfo` pull the same
  facts as text you can capture, compare, and run across many machines.
- **Why:** at scale you triage from a script/log, not by remoting into 50 GUIs; capturing the
  pre/post state of a change is how you *prove* what fixed it.

### Steps
1. **Profile your machine:** run the `Get-ComputerInfo` / top-CPU / stopped-auto-services /
   `Get-WinEvent` block from §2; save as `scripts/os_triage.ps1`.
2. **Map a boot:** restart and note where time goes (firmware → logo → logon → desktop-ready);
   correlate slow logon stages to subsystems.
3. **Read a log:** in Event Viewer, find a recent **Error** in System or Application; record its
   **Event ID + source** and what it means — this is the skill behind every OS diagnosis.
4. **Write the OS-triage runbook** (`docs/runbooks/os-triage.md`) and the "which OS / how it boots"
   KB.

### Lens D — the raw artifact (an Event Viewer entry)
```
Log: System | Source: Microsoft-Windows-Kernel-Power | Event ID: 41 | Level: Critical
"The system has rebooted without cleanly shutting down first."
#   Event ID 41 = the box lost power / hard-crashed (not a clean restart) → check power(L02),
#   overheating(L02), or a driver BSOD just before. The Event ID is your search key.
```
Every Windows problem leaves an Event-ID fingerprint. Learning to read it (Lens D) turns "it
crashed, no idea why" into "Kernel-Power 41 preceded by a display-driver fault."

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/os-triage.md` — boot/logon/post-logon stage isolation.
2. **Troubleshooting Guide:** `docs/troubleshooting/os-wont-boot-or-slow.md` — the full spine.
3. **Ticket Notes:** `docs/tickets/ENT-03-bsod-after-update.md` — the worked ENT-03.
4. **KB Article:** `docs/kb/` — "Which OS am I on, and how to find your version/build" (`winver`).
5. **Incident Report:** the post-patch BSOD as a mini incident report (template) if it spread.
6. **Portfolio Artifact:** §10 bullet + the "separate the boot stages" talking point.
7. **Script:** `scripts/os_triage.ps1` (`Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Built a PowerShell OS-triage script and runbook that captures version,
  processes, services, and recent Event Log errors, standardizing endpoint diagnosis and speeding
  identification of post-patch driver regressions."*
- **Interview talking point:** the OS layer model (kernel/user mode, virtual memory → why a machine
  goes *slow* before it crashes) and reading an **Event ID** to pinpoint a cause.
- **Serves:** Help Desk T2, Desktop Support, Junior SysAdmin.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2, 220-1102):** operating systems (Windows features, command line, OS
  troubleshooting) — a core lesson.
- **MD-102:** Windows client management/maintenance. **MS-900:** light (Windows as part of M365).
  **Net+/ITIL:** N/A directly. Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** OS issues (slow, crashing) are deeply frustrating because they block *everything* —
acknowledge the impact, give a realistic ETA, and protect data before any reimage. "Have you tried
restarting?" is real (it clears state/leaks) but say *why* so the user doesn't feel dismissed.

**🔒 Security:** the OS is the security boundary — keep it **patched** (L26), run with **least
privilege / UAC** (L07), and treat unexplained slowness + odd processes/services as a possible
**malware** signal (L29). The boot chain itself is a security target (Secure Boot exists for a
reason); unexpected boot changes or new auto-start services deserve scrutiny.

---

## Quiz (Interview-Style, Graded)

**Q1.** In one or two sentences, what does an operating system actually do?
> **Your answer:**

**Q2.** A machine is slow. Where do you look first to tell whether it's RAM, disk, or CPU, and what
would each look like?
> **Your answer:**

**Q3.** What's the difference between a process and a service? Give an example of each.
> **Your answer:**

**Q4.** **Scenario:** several users on the same laptop model start blue-screening the morning after
patch night. What do you suspect, what do you check, and how is this more than a single ticket?
> **Your answer:**

**Q5.** Why does a Windows machine usually get *slow* before it runs *out* of memory?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `what an operating system does kernel user mode`
- `windows boot process explained`
- `virtual memory paging why computer slow`
- `windows event viewer event id troubleshooting`
- `process vs service windows`

**Tools**
- `Get-WinEvent PowerShell`
- `sfc scannow DISM RestoreHealth`

**Going further**
- `windows fundamentals for support` (L04) · `linux fundamentals` (L05) ·
  `endpoint troubleshooting` (L24) · `patch management` (L26)

**Service / Security (Lens E):**
- 🤝 `explaining a restart to a user`, `setting expectations on reimage`
- 🔒 `least privilege UAC`, `malware slow computer indicators`, `secure boot`

---

## Lesson Status
- [ ] §8 lab completed (os_triage script + read a real Event ID)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 04 — Windows Fundamentals**.

---

*Lesson 03 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+
220-1102 (operating systems), Microsoft Windows boot/architecture docs.*
