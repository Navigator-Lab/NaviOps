# Lesson 04 — Windows Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the Windows desktop a support tech lives in — Settings vs Control Panel, Task Manager,
Event Viewer, Services, Device Manager, the registry, user profiles, and the built-in repair tools
(`sfc`, `DISM`, Safe Mode). This is the single most-used environment in the job.
**Primary artifact:** the Windows triage runbook.

> **How to use this lesson:** read §1–§7, do §8 (drive the consoles + PowerShell on a live box),
> produce §9, take the quiz, reflect. Then Lesson 05.

---

## §1 — Concept (Theory)

### What it is
**Windows** (10/11 client, and Server — Lesson 22) is the OS on virtually every corporate desktop.
"Knowing Windows" for support means knowing **where the management surfaces are**: the modern
**Settings** app and the legacy **Control Panel**, the **MMC consoles** (`eventvwr`, `services.msc`,
`devmgmt.msc`, `compmgmt.msc`), **Task Manager**, the **registry**, **user profiles**, and the
**built-in repair tools**. The fixes live in these places.

### Why it matters for support
Most tickets resolve by knowing *which Windows surface owns the problem*: a service won't start →
`services.msc`; a device is broken → Device Manager; an app crashes → Event Viewer (Application
log); a setting is wrong → Settings/Control Panel/Group Policy; the profile is corrupt → user
profile tools. A tech who knows the map fixes fast; one who doesn't reinstalls everything.

### Three-Level Depth (Lens A)
- **Level 1 — User:** Windows is the Start menu, the taskbar, my apps, and Settings.
- **Level 2 — Technician:** Windows is a set of **management consoles + a config store**. Settings
  (modern) and Control Panel (legacy) front the same underlying config; Task Manager/Event Viewer/
  Services are your live diagnostics; the **registry** is the central settings database when nothing
  else exposes a setting.
- **Level 3 — Engineer:** Windows config lives in the **registry** (`HKLM` machine-wide, `HKCU`
  per-user), surfaced by GUIs and set at scale by **Group Policy** (Lesson 19, which writes registry
  keys). User state lives in the **profile** (`C:\Users\<name>`, with `NTUSER.DAT` = `HKCU`). System
  integrity is protected by **WRP/SFC**; the component store (**WinSxS**) is repaired by **DISM**.
  Understanding this is why "delete the profile and re-login" or "`sfc /scannow`" actually works.

### Two Teaching Approaches (Lens B) — Settings vs Control Panel vs registry vs GPO
**Approach 1 (technical):** there are multiple layers writing the same settings. The registry is the
source of truth; Control Panel and Settings are GUIs over it; Group Policy is an *administrative*
override that writes protected registry locations and wins over user choices. When a setting "won't
stick," a GPO is usually overwriting it.

**Approach 2 (analogy):** the registry is the **building's master control panel in the basement**;
Settings and Control Panel are the **light switches on each floor** (convenient, limited); Group
Policy is the **building manager's central override** that can lock a switch regardless of what a
tenant flips. **Where it breaks down:** unlike physical switches, editing the basement panel (the
registry) directly is powerful *and dangerous* — one wrong key can break boot (danger zone).

### Visual (ASCII) — the Windows management map
```
   SETTINGS (modern) ┐                         live diagnostics:
   CONTROL PANEL ─────┼─▶ REGISTRY (HKLM/HKCU) ── Task Manager (processes/perf/startup)
   GROUP POLICY (L19) ┘    (source of truth)      Event Viewer (logs + Event IDs)  ← L03
                                                  Services (services.msc)
   USER PROFILE  C:\Users\<name>  (NTUSER.DAT = HKCU)   Device Manager (drivers)
   REPAIR: sfc /scannow · DISM /RestoreHealth · Safe Mode · System Restore
```

---

## §2 — Tools & Commands

| Surface | Opens with | Use for |
|---|---|---|
| Settings | `Win+I` / `ms-settings:` | modern config (network, accounts, update) |
| Control Panel | `control` | legacy config (some still only here) |
| Task Manager | `Ctrl+Shift+Esc` | processes, performance, startup impact |
| Event Viewer | `eventvwr` | logs + Event IDs (System/Application) |
| Services | `services.msc` | start/stop/configure services |
| Device Manager | `devmgmt.msc` | drivers, failed devices |
| Computer Mgmt | `compmgmt.msc` | disks, local users, event logs in one |
| Registry Editor | `regedit` | last-resort setting changes (⚠ danger) |
| System Config | `msconfig` | boot/startup options |

```powershell
Get-Service -Name Spooler | Restart-Service          # restart the print spooler (L10)
Get-WinEvent -LogName Application -MaxEvents 20       # recent app errors
sfc /scannow                                          # repair protected system files
DISM /Online /Cleanup-Image /RestoreHealth           # repair the component store
Get-LocalUser ; Get-LocalGroupMember -Group Administrators   # local accounts (L07)
gpresult /r                                           # applied policy (L19)
```

---

## §3 — Real-World Support Context & Use Cases

- **The daily environment.** Nearly every endpoint ticket is worked through these consoles. Speed
  here = your throughput.
- **Settings ↔ Control Panel split:** Windows is mid-migration; some settings only live in one. Know
  both, and the `ms-settings:`/`control` shortcuts.
- **Safe Mode + repair tools** rescue machines that won't boot normally (driver/startup loops).
- **Profiles** explain a huge class of "it's broken only for me" tickets — test a second profile to
  isolate user-specific from machine-wide.
- **Exam framing:** CompTIA A+ Core 2 (Windows features, MMC, command-line tools, troubleshooting);
  MD-102 (Windows client config/management).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0047 (P3):** *"I can't print and there's no print option that works. — Fiona,
> DESK-1150."* (printing depth is Lesson 10; here we use it to demo the Windows surfaces.)

1. **Reproduce + classify:** printing fails → likely the **Print Spooler service** or a driver.
2. **Services console:** `services.msc` → find **Print Spooler** → state? If **Stopped**, that's it.
3. **Restart the service:** right-click → Restart (or `Restart-Service Spooler`). Verify it's
   **Running** + Startup type **Automatic**.
4. **Confirm via Event Viewer:** Application log for spooler errors that explain *why* it stopped
   (a bad driver?). Note the Event ID.
5. **Test:** print a test page; confirm with Fiona.
6. **Document:** note the service state + restart + any driver follow-up.

The transferable skill: **symptom → which console owns it → inspect state → act → verify in the
logs.** That loop solves most Windows tickets.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: a Windows feature/app/service is misbehaving on one machine.**

### 1 · Symptoms
A service won't run · a setting won't apply/stick · an app crashes · a device has a yellow ⚠ ·
"only my account is broken" · machine won't boot normally.

### 2 · Possible Causes (most-likely first)
1. A **service** is stopped/disabled.
2. A **driver** is missing/corrupt/wrong (Device Manager ⚠).
3. A **Group Policy** is overriding the setting (L19).
4. **User profile** corruption (only one user affected).
5. **System file / component store** corruption.
6. **Startup item / boot** problem (won't boot normally).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | `services.msc` — is the relevant service running/auto? | stopped/disabled | start + set Automatic |
| 2 | Device Manager for ⚠ | yellow mark | update/reinstall driver |
| 3 | `gpresult /r` (does a policy own this?) | policy applies | it's GPO (L19), not local |
| 4 | Log in as a **different/test user** | works for them | original **profile** corrupt |
| 5 | Event Viewer (App/System) for the error ID | error found | act on that cause |
| 6 | `sfc /scannow` then `DISM …/RestoreHealth` | corruption repaired | retest |
| 7 | **Safe Mode** (`msconfig`/Shift-restart) | works in Safe Mode | a driver/startup item is the cause |

### 4 · Resolution Steps
Start/enable the service; update/roll back/reinstall the driver; fix the GPO (or escalate to the
GPO owner); **rebuild the user profile** (copy data out, recreate); `sfc`+`DISM` repair; use **System
Restore** to roll back a recent bad change; clean-boot to find the offending startup item.

### 5 · Escalation Criteria
Escalate to T2/Sysadmin for: GPO changes (you may not own the policy — L19), fleet-wide driver/update
issues (problem mgmt — L32), domain account/profile issues needing directory access (L18/21), or
registry changes beyond a documented known-fix. Attach: the console state, Event IDs, `gpresult`,
what you tried.

### 6 · Post-Incident Documentation
Ticket note (which surface owned it, the exact fix, Event ID), KB if recurring, problem ticket if
fleet-wide.

---

## §6 — Ticket Simulation

> **Ticket ENT-04 / INC-0513 (P3):** *"I logged in this morning and it's like a brand-new computer —
> my desktop, my files shortcuts, my Outlook signature, all gone. — Greg, DESK-1162."* Channel: walk-up.

**Triage:** "everything personal is gone but the machine works" is the classic **temporary/corrupt
user profile** signature (Windows loaded a *temp* profile because it couldn't load Greg's). One user,
blocked from normal work → **P3** (P2 if he's mid-deadline).

**Worked resolution:**
1. **Confirm the signature:** is the username bar showing "We can't sign in to your account / signed
   in with a temporary profile"? Check `C:\Users\` for a `TEMP` or `greg.CORP` duplicate folder.
2. **Event Viewer:** Application log → **User Profile Service** errors (e.g. Event ID **1511/1515/1500
   series**) confirm a profile load failure.
3. **Don't panic the user:** his data is usually still in the original `C:\Users\greg` folder (and
   OneDrive) — it's a *load* failure, not deletion.
4. **Resolve:** reboot (often clears a transient lock); if persistent, fix the profile via the
   registry `ProfileList` key (rename the `.bak` — a *documented* known-fix, the careful registry
   exception) or recreate the profile and migrate data. Verify OneDrive/Known Folder data is intact.
5. **Confirm + reassure** Greg his files are back.

**The professional ticket note:**
```
SUMMARY: Greg loaded a TEMPORARY profile (User Profile Service load failure). Original profile + data
intact; corrected ProfileList registry entry, rebooted, profile loaded normally.
SYMPTOM: "new computer" appearance — desktop/shortcuts/Outlook signature missing; machine otherwise OK.
DIAGNOSIS: 1) temp-profile banner + C:\Users\TEMP present 2) Event Viewer User Profile Service 1511/1515
3) original C:\Users\greg intact (data safe).
CAUSE: corrupt/locked profile load (ProfileList .bak entry).
RESOLUTION: applied documented ProfileList fix; rebooted; confirmed personal desktop/files/OneDrive
restored. NO data lost.
FOLLOW-UP: confirmed OneDrive Known Folder Move active so future profile issues don't risk files; KB linked.
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** OS/Endpoint. **Incident.** Profile/console issues are usually single-user; a
  Group-Policy or update cause makes them a **Problem** (L32).
- **Priority:** scoped per user impact; "I've lost all my files" *feels* like a P1 to the user —
  manage the panic, confirm data is safe early.
- **Escalation:** anything touching **Group Policy** or the **domain** crosses to the team that owns
  it (you don't unilaterally change org policy from one ticket).
- **Metric angle:** mastering the console map is the biggest lever on **FCR** and **MTTR** for
  endpoint tickets — most don't need a reimage.

---

## §8 — Practical Lab (build this yourself)

**Goal:** become fluent in the Windows management surfaces and the repair tools.

### Lens C — Manual → Automation → Why
- **Manual:** click through `services.msc`, Event Viewer, Device Manager.
- **Automated:** `Get-Service`, `Get-WinEvent`, `Restart-Service`, `sfc`/`DISM` do the same as text —
  scriptable and remotable across many machines.
- **Why:** at T2/sysadmin scale you triage 50 machines from PowerShell remoting, not 50 GUIs;
  capturing state as text lets you prove what changed.

### Steps
1. **Tour the consoles:** open each surface in §2; for each, note one ticket it would solve.
2. **Service drill:** stop the **Print Spooler** in `services.msc`, observe printing break, restart it
   with `Restart-Service Spooler`, confirm recovery. (Safe, reversible.)
3. **Profile awareness:** create a second local test user (`Get-LocalUser` to confirm), log in, see a
   clean profile — this is your "is it the profile?" isolation test.
4. **Repair tools:** run `sfc /scannow` (read the result), then `DISM /Online /Cleanup-Image
   /ScanHealth`. Understand what each checks.
5. **Write the Windows triage runbook** (`docs/runbooks/windows-triage.md`) — symptom → console map.

### Lens D — the raw artifact (a User Profile Service event)
```
Log: Application | Source: User Profile Service | Event ID: 1511
"Windows cannot find the local profile and is logging you on with a temporary profile."
#   This is the fingerprint of the "all my files are gone" ticket — it's a PROFILE LOAD failure,
#   not data loss. The data is in C:\Users\<name>; the fix is to repair the profile, not reimage.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/windows-triage.md` — symptom → which console → action → verify.
2. **Troubleshooting Guide:** `docs/troubleshooting/windows-feature-or-profile.md` — the full spine.
3. **Ticket Notes:** `docs/tickets/ENT-04-temp-profile.md` — the worked ENT-04.
4. **KB Article:** `docs/kb/` — "My desktop/files look gone after login (temporary profile)" +
   reassurance.
5. **Incident Report:** N/A (single-user); note the escalation path if it became fleet-wide.
6. **Portfolio Artifact:** §10 bullet + the console-map talking point.
7. **Script:** `scripts/windows_triage.ps1` (service + log + profile checks; `Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Authored a Windows endpoint-triage runbook and PowerShell script mapping
  symptoms to the owning management surface (Services, Event Viewer, Device Manager, profiles),
  resolving profile-corruption and service failures without reimaging."*
- **Interview talking point:** the **temporary-profile** diagnosis (Event ID 1511, data is safe) and
  the Settings/Control-Panel/registry/GPO layering — *why a setting "won't stick" is usually a GPO*.
- **Serves:** Help Desk T2, Desktop Support, Junior SysAdmin.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2):** Windows editions/features, MMC consoles, command-line tools (`sfc`,
  `DISM`, `gpresult`), Windows troubleshooting — core.
- **MD-102:** Windows client configuration & maintenance. **MS-900:** light. Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** a "lost everything" user is scared — your first job is to **confirm the data is safe**
and say so plainly *before* you start fixing. Calm beats fast.

**🔒 Security:** the registry and Local Administrators group are power — **least privilege** (don't
make users admins; UAC exists for a reason — L07), document any registry change, and never apply a
random "registry fix" from the internet to a corporate machine. Group Policy (L19) is how security
baselines are enforced — respect that a setting "won't change" because **security policy owns it**.

---

## Quiz (Interview-Style, Graded)

**Q1.** A printer/service problem — which Windows console do you open first and what do you check?
> **Your answer:**

**Q2.** A user says a setting they changed keeps reverting after reboot. What's the most likely cause
and how do you confirm it?
> **Your answer:**

**Q3.** What's the difference between `sfc /scannow` and `DISM /RestoreHealth`?
> **Your answer:**

**Q4.** **Scenario:** a user logs in and "all their files and settings are gone," but the machine
works fine. What do you suspect, how do you confirm it, and what do you tell the user immediately?
> **Your answer:**

**Q5.** How do you quickly determine whether a problem is specific to one user's profile or affects
the whole machine?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `windows settings vs control panel`
- `services.msc print spooler restart`
- `windows temporary profile fix profilelist`
- `sfc scannow dism restorehealth difference`
- `windows event viewer user profile service`

**Tools**
- `Get-Service Restart-Service PowerShell`
- `windows safe mode clean boot`

**Going further**
- `linux fundamentals for support` (L05) · `user accounts and permissions` (L07) ·
  `group policy` (L19) · `endpoint troubleshooting` (L24)

**Service / Security (Lens E):**
- 🤝 `reassuring a user data is safe`, `managing panic on data-loss tickets`
- 🔒 `least privilege local admin`, `UAC`, `registry change safety`

---

## Lesson Status
- [ ] §8 lab completed (console tour + spooler drill + repair tools + runbook)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 05 — Linux Fundamentals for Support**.

---

*Lesson 04 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+
220-1102 (operating systems), Microsoft Windows client/management docs.*
