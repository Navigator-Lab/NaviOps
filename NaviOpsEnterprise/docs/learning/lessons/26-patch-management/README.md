# Lesson 26 — Patch Management

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** keeping the fleet updated **without breaking it** — **Windows Update / WSUS / Intune**,
**deployment rings (pilot → broad)**, reboot/maintenance windows, **failed-update** fixes, and patching as
**change enablement** (L17). Where security (patch the vulnerability) meets stability (don't brick the
fleet).
**Primary artifact:** the patch-deployment runbook + `scripts/patch_status.ps1`.

> **How to use this lesson:** read §1–§7, do §8 (check patch status + fix a failed update + design a
> ring), produce §9, take the quiz, reflect. Then Lesson 27.

---

## §1 — Concept (Theory)

### What it is
**Patch management** is the process of acquiring, testing, and deploying **updates** (OS security/quality
updates, driver updates, app updates) across endpoints and servers — on a schedule, in a controlled way.
Tools: **Windows Update** (the engine), **WSUS** or **Intune/Windows Update for Business** (to approve,
schedule, and **ring** updates centrally), and **SCCM**. The discipline is **deployment rings** — pilot a
patch on a small group, watch for breakage, then expand to the fleet — plus managing **reboots** in
**maintenance windows**, and fixing updates that **fail to install**.

### Why it matters for support
Unpatched systems are the #1 way orgs get breached (known, exploited vulnerabilities), so patching is a
**security imperative**. But a bad patch can **break the fleet** (the BSOD-after-update tickets from L03/
L24 — recall ENT-03). Patch management is the balance: **patch fast for security, but ring/pilot so a bad
update doesn't take everyone down**. It's textbook **change enablement** (L17) and a core sysadmin
responsibility.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "Windows wants to restart for updates / an update failed / it broke after the
  update."
- **Level 2 — Technician:** check **update status/history** (`Get-Hotfix`/Settings), fix a **failed
  update** (the common error codes / Update troubleshooter / clear the cache), manage the **reboot**, and
  recognize a **post-update regression** → roll it back (L24/ENT-03).
- **Level 3 — Engineer:** updates are approved/scheduled centrally (**WSUS**/**Windows Update for
  Business** policies, **Intune** update rings) and deployed in **rings** (pilot → fast → broad) with
  **deferral** and **deadline** settings; failures trace to specific **WU error codes**, a corrupt
  **SoftwareDistribution** cache, disk space (L06), or a servicing-stack issue; a regression is **rolled
  back** (uninstall the KB / `wusa /uninstall` / pause) and held in the ring; patching servers needs
  **maintenance windows** + reboot orchestration. This is *why* rings + rollback + monitoring make
  patching safe, and why "it broke after the update" is a problem-management signal (L32).

### Two Teaching Approaches (Lens B) — rings: patch fast, but safely
**Approach 1 (technical):** you can't patch everything instantly (risk of mass breakage) or never (risk of
breach) — so you **ring** deployment: a **pilot ring** (IT + volunteers) gets updates first; if nothing
breaks after a soak period, a **fast ring**, then the **broad ring** (everyone). Bad patches surface in
the pilot and are **paused/rolled back** before they reach the fleet. Reboots happen in **maintenance
windows**. It's change enablement (L17) with a built-in safety valve.

**Approach 2 (analogy):** patching is **vaccinating the company** against known threats. You don't inject
everyone at once with a brand-new batch — you give it to a **small pilot group first**, watch for adverse
reactions (the **pilot ring**), and only then roll it out **company-wide** — and you keep the ability to
**recall a bad batch** (rollback). Skipping the pilot (deploy to all immediately) risks a mass adverse
reaction (fleet outage); never vaccinating risks the disease (breach). **Where it breaks down:** unlike
vaccines, you can fully **uninstall** a bad patch — but the window matters, so monitoring the pilot
quickly is key.

### Visual (ASCII) — deployment rings + the safety valve
```
   UPDATE released ─▶ PILOT ring (IT + volunteers, ~days soak) ─▶ FAST ring ─▶ BROAD ring (everyone)
                          │ breakage?                                              ▲
                          └─ PAUSE / ROLL BACK (uninstall KB, hold in ring) ───────┘  ← safety valve
   reboots → MAINTENANCE WINDOWS (esp. servers, L22)   ·   failures → WU error code / cache / disk (L06)
   patch FAST (security) but RINGED (stability)   ·   "broke after update" = post-update regression (L24/L32)
```

---

## §2 — Tools & Commands

| Task | GUI | CLI / PowerShell |
|---|---|---|
| Update status/history | Settings → Windows Update | `Get-Hotfix` · `Get-WinEvent -LogName Setup` |
| Central approval/rings | WSUS console / **Intune** / WUfB policies | (admin consoles) |
| Scan/install (module) | — | `Get-WindowsUpdate`/`Install-WindowsUpdate` (PSWindowsUpdate) |
| Uninstall a bad update | Settings → Update history → Uninstall | `wusa /uninstall /kb:5xxxxxx` |
| Pause/defer updates | Settings / policy | WUfB deferral/pause |
| Fix failed updates | Update troubleshooter | reset **SoftwareDistribution** cache; `DISM`/`SFC` (L04) |
| Driver updates | Device Manager / WU | `pnputil` (L04/L24) |
| Pending reboot? | — | check `…\RebootPending` keys / `Get-CimInstance` |

```powershell
Get-Hotfix | Sort InstalledOn -Descending | Select HotFixID, InstalledOn -First 10   # what installed recently
wusa /uninstall /kb:5012345 /quiet /norestart                                        # roll back a bad KB (L24/ENT-03)
# Fix a stuck Windows Update (reset cache):
Stop-Service wuauserv,bits; Rename-Item C:\Windows\SoftwareDistribution SoftwareDistribution.old; Start-Service wuauserv,bits
Get-WinEvent -LogName Setup -MaxEvents 20    # update install results + error codes
```

> **Danger zone** (`navi.project.md` + L17/L22): fleet patch deployment can break many endpoints/servers
> — **pilot ring first**, schedule **maintenance windows**, have a **rollback** plan, and treat it as a
> **Change** (L17). Server reboots affect everyone (L22). Lab/pilot before broad.

---

## §3 — Real-World Support Context & Use Cases

- **"It broke after the update"** is a top ticket family (the L03/L24 BSOD/post-patch incidents, e.g.
  ENT-03) — the desk's clustered post-patch tickets are the **early warning** to pause/roll back fleet-
  wide (problem/major incident — L31/L32).
- **Failed updates** (stuck at %, recurring error codes) — reset the cache, troubleshooter, disk space
  (L06), servicing-stack — a daily fix.
- **Reboot management:** users hate forced reboots — deadlines + maintenance windows + clear comms; servers
  reboot in windows (L22).
- **Rings are the professional standard:** never deploy a fresh patch to 100% at once; pilot → fast →
  broad with a soak period; **pause/rollback** when the pilot breaks.
- **Security driver:** patching closes known exploited vulnerabilities — the single highest-impact security
  hygiene (NaviOpsSec cares deeply); unpatched = breached.
- **Third-party + driver patching** matters too (browsers, Java/Adobe historically, firmware) — not just
  Windows.
- **Exam framing:** A+ (Core 2 — patch/update management, change/operational procedures), MD-102 (update
  rings/WUfB/Intune), ITIL (change enablement — L17).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0507 (P3):** *"Windows Update keeps failing — it downloads, tries to install, fails, and
> rolls back every time. — Wendy, LT-0490."*

1. **Read the failure:** Settings → Update history (or `Get-WinEvent -LogName Setup`) → the **WU error
   code** + which KB. The code routes the fix.
2. **Cheapest-first checks:** **disk space** (L06 — updates need free space; a full disk is a top cause) +
   a **pending reboot** blocking new installs.
3. **Run the Update troubleshooter** (clears common states).
4. **Reset the update cache** (the reliable fix for a corrupt download): stop `wuauserv`/`bits`, rename
   **SoftwareDistribution**, restart the services → re-scan.
5. **Repair components if needed:** `DISM /RestoreHealth` + `sfc /scannow` (L04) for a corrupt servicing
   stack.
6. **Retry + verify:** the update installs and `Get-Hotfix` shows it; reboot in/agreed window.
7. **Document + watch for pattern:** note the fix; if the **same KB fails across many** machines, that's a
   **problem** (L32) — escalate to the patch owner (it may be a bad update to **pause** in the ring).

The teaching point: **the WU error code + the cheap checks (disk/reboot) + the cache reset** resolve most
failed updates; and a *fleet-wide* same-KB failure is a problem signal, not 50 separate tickets.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: update failures + post-update regressions + reboot/ring issues.**

### 1 · Symptoms
Update fails/rolls back (error code) · stuck downloading/installing at % · "it broke after the update"
(BSOD/app/driver — L24) · forced/unexpected reboots · machine not patched (behind) · a bad patch hitting
many (cluster).

### 2 · Possible Causes (most-likely first)
1. **Failed install** — corrupt cache (**SoftwareDistribution**), WU error code, **disk full** (L06),
   pending reboot.
2. **Servicing-stack/component corruption** (`DISM`/`SFC`).
3. **Post-update regression** — a bad KB/driver broke something (L24/ENT-03) → **roll back**.
4. **Reboot management** — user deferring / forced at a bad time.
5. **Not receiving updates** — WSUS/Intune/WUfB policy/scope issue (behind the ring).
6. **Fleet-wide bad patch** — same KB breaking many → pause + problem (L32).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | WU error code (Setup log/history) | code present | route fix by code |
| 2 | Disk space (L06) + pending reboot | low/pending | free space / reboot then retry |
| 3 | Update troubleshooter + reset SoftwareDistribution | corrupt cache | reset + re-scan |
| 4 | `DISM /RestoreHealth` + `sfc` (L04) | component corruption | repair, retry |
| 5 | Did it break *after* a patch? (L24) | regression | uninstall the KB / pause (L24/ENT-03) |
| 6 | Behind on patches? policy/scope | not receiving | fix WSUS/Intune/WUfB targeting |
| 7 | Same KB failing/ breaking many? | fleet pattern | **pause the ring + problem** (L32) |

### 4 · Resolution Steps
Free disk + reboot; run the troubleshooter + **reset SoftwareDistribution**; `DISM`+`SFC`; **roll back**
a regressing KB (`wusa /uninstall`) and **hold it in the ring**; fix update targeting (WSUS/Intune/WUfB);
schedule reboots in a window with comms; for a fleet-wide bad patch, **pause deployment** + raise a
problem/major incident (L31/L32).

### 5 · Escalation Criteria
Escalate to the patch/endpoint-management owner / change board for: pausing or rolling back a patch
**fleet-wide**, ring/policy changes, server patch windows (L22), and security-critical emergency patches.
A **bad patch hitting many** = problem + possibly major incident (L31/L32). Emergency security patches
still get a (fast) **change** (L17). Attach: error codes, affected scope, the KB, what you tried.

### 6 · Post-Incident Documentation
Ticket note (error code + fix, or the KB rolled back), **change record** for deploy/rollback (L17/L26),
problem/RCA for fleet-wide bad patches (L32), patch-compliance reporting (which machines are current —
feeds L27), KB for recurring failed-update fixes.

---

## §6 — Ticket Simulation

> **Ticket ENT-26 / INC-0506 cluster (P1):** *"After last night's patch, dozens of laptops are
> blue-screening on the docking station / won't finish booting — reports flooding in this morning."*
> (The fleet version of ENT-03.)

**Triage:** **many machines**, **all after last night's patch**, same symptom → a **bad patch fleet-wide**
= **major incident** (L31) + **problem** (L32). Priority **P1**. The job: **stop the bleeding** (pause +
roll back) and communicate — not fix dozens of laptops individually.

**Worked resolution (rings + safety valve in action):**
1. **Recognize the pattern fast:** clustered, post-patch, same symptom → correlate the desk's tickets
   (L15/L16) → it's the patch, not 30 coincidences. Declare a **major incident** (L31).
2. **STOP the spread — pause deployment:** in WSUS/Intune/WUfB, **pause/halt** the offending update so it
   stops reaching the **broad ring** (the safety valve — this is *why* rings exist; the pilot ring should
   have caught it, so also note that gap).
3. **Roll back the fix on affected machines:** `wusa /uninstall /kb:<bad>` (push via the management tool)
   or use **Known-Issue Rollback** / the recovery path; for won't-boot machines, the rollback via WinRE/
   recovery. Restore service.
4. **Communicate broadly:** one status update (L31) so affected users and the desk work the master
   incident, not 30 duplicates (L15).
5. **Verify:** affected machines boot + dock works; the patch is paused fleet-wide.
6. **RCA + fix the process (L32):** *why* did a fleet-breaking patch get past the **pilot ring**? (ring too
   small / soak too short / dock model not represented in pilot). Fixes: better pilot coverage, longer
   soak, faster post-patch monitoring — so the next bad patch dies in the pilot, not the fleet.

**The professional incident note (excerpt):**
```
SUMMARY: Last night's cumulative update caused fleet-wide BSOD/boot failure on docked laptops (dozens).
Declared P1 major incident; PAUSED the update in Intune (stopped broad-ring spread); rolled back the KB on
affected machines (boot ones via recovery). Service restored. RCA: pilot ring didn't include the affected
dock model + soak too short.
SCOPE: dozens of laptops, all post-patch, same symptom → bad patch (major incident + problem).
ACTIONS: correlated clustered tickets → declared MI + comms (L31); paused the update (ring safety valve);
wusa /uninstall the KB (+ recovery for no-boot units); verified boot + dock.
CAUSE (RCA, L32): regressing cumulative update interacting with the dock driver; reached broad ring
because the pilot ring lacked that hardware + had too short a soak.
RESOLUTION: update paused fleet-wide; KB uninstalled on affected devices; awaiting a fixed update to
re-pilot.
FOLLOW-UP (Changes/L26): expand pilot-ring hardware coverage + lengthen soak + add post-patch BSOD
monitoring; re-deploy via rings once a fixed update ships. Problem owner assigned.
```

---

## §7 — Service Desk / ITIL Perspective

- **Patch management *is* change enablement** (L17): every deployment is a **Change** — assessed, **ringed/
  piloted**, scheduled in **windows**, with **rollback**. This is the lesson where L17's theory becomes a
  weekly operational reality.
- **Post-patch incident clusters** are the desk's early-warning radar — correlated tickets after a patch =
  pause + problem/major incident (L31/L32), not individual firefighting.
- **The security ↔ stability tension** is the core trade-off: patch fast (close vulnerabilities) but ring
  (avoid mass breakage). Both extremes are failures.
- **Patch compliance reporting** (who's current) is a security + audit metric and feeds asset management
  (L27).
- **Servers (L22)** raise the stakes: reboots affect everyone → strict maintenance windows + orchestration.
- **Metric/risk angle:** patch latency (how fast critical patches deploy) vs change-induced incidents —
  rings optimize both.

---

## §8 — Practical Lab (build this yourself)

**Goal:** check patch status, fix a failed update, roll one back, and design a ring — in the lab.

### Lens C — Manual → Automation → Why
- **Manual:** check Settings → Update history on one machine.
- **Automated:** `patch_status.ps1` reports, per machine/fleet: last-installed updates, **pending reboot**,
  days-since-last-patch (compliance), and recent **failed** updates — so you see who's behind/failing at a
  glance.
- **Why:** patch **compliance** and **failure** are fleet questions — you can't check 200 machines by
  hand; a report drives targeted remediation and proves security posture (and feeds L27/audits). Deployment
  itself is automated centrally (WSUS/Intune) — the script is the **visibility** half.

### Steps
1. **Status:** `Get-Hotfix | Sort InstalledOn -Desc` + check pending-reboot; note how current the machine
   is.
2. **Failed-update fix drill:** simulate/encounter a stuck update → run the troubleshooter → **reset
   SoftwareDistribution** → re-scan (the reliable fix).
3. **Rollback drill:** identify a recent KB and practice `wusa /uninstall /kb:<id>` (lab) — the post-
   regression safety move (ties to ENT-03/L24).
4. **Ring design:** on paper, define **pilot → fast → broad** rings (who's in pilot, soak length, deferral/
   deadline) for the org — the change-enablement artifact (L17).
5. **Compliance report:** write `patch_status.ps1` to flag machines behind/with failures.
6. **Write the patch-deployment runbook** (rings, windows, rollback) + the script.

### Lens D — the raw artifact (compliance + the bad-patch signal)
```
> .\patch_status.ps1   (fleet excerpt)
   Computer   LastPatch    DaysBehind  PendingReboot  RecentFailures
   --------   ---------    ----------  -------------  --------------
   DESK-1102  2026-06-10   11          No             -
   LT-0490    2026-05-02   50          No             KB5012345 (0x800f0922)  ← behind + failing → remediate
   FS01       2026-06-18   3           Yes            -                        ← server pending reboot → schedule window (L22)
#   Two signals: machines BEHIND (security risk → remediate) and a recurring FAILED KB/error code (fix or,
#   if fleet-wide, a bad patch → pause + problem L32). Compliance reporting is the visibility behind safe,
#   secure patching.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/patch-deployment.md` — rings (pilot→broad), maintenance windows, rollback.
2. **Troubleshooting Guide:** `docs/troubleshooting/failed-updates.md` — the full spine (error code/cache/
   disk/component/regression).
3. **Ticket Notes:** `docs/tickets/ENT-26-bad-patch-rollback.md` — the worked ENT-26 (fleet major incident).
4. **KB Article:** `docs/kb/` — internal "Fixing a stuck Windows Update (reset cache)" + user "why we
   reboot for updates".
5. **Incident Report:** the fleet bad-patch event as a **major incident report + RCA** (L31/L32) — the
   centerpiece.
6. **Portfolio Artifact:** §10 bullet + the rings + roll-back-fast talking points.
7. **Script:** `scripts/patch_status.ps1` (compliance + failures, local/fleet; `Invoke-ScriptAnalyzer`-
   clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Ran patch management via deployment rings (pilot → broad) with maintenance windows
  and rollback, built a PowerShell patch-compliance/failure report, and led the rollback of a fleet-wide
  regressing update as a major incident — balancing security currency with stability."*
- **Interview talking point:** **deployment rings** (patch fast but pilot so a bad update doesn't brick the
  fleet), patching as **change enablement** (L17), the **post-patch regression → pause + roll back**
  response (ENT-03/26), and the **security↔stability** trade-off.
- **Serves:** Junior SysAdmin, Infrastructure Support, IT Support.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2):** patch/update management, change & operational procedures. **MD-102:** update
  rings / Windows Update for Business / Intune. **ITIL 4:** change enablement (L17). Security currency ties
  to **NaviOpsSec**. Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** reboots and update breakage frustrate users — communicate **why** (security), give
**maintenance windows + deadlines** (not surprise reboots), and when a patch does break something, own it
fast (pause + roll back + clear status). Honesty during a bad-patch incident builds trust.

**🔒 Security:** patching is the **highest-impact security hygiene** — unpatched, exploited vulnerabilities
are the leading breach cause (NaviOpsSec cares most here). Patch **promptly** (especially critical/
actively-exploited CVEs — sometimes an **emergency change**, L17), track **compliance** (machines behind =
risk), and don't let "stability fear" become "never patch." The tension is real but **ringed fast
patching** resolves it. Also patch **third-party apps/drivers/firmware** (L25), not just Windows. A bad
patch is a stability incident; an unpatched fleet is a security incident waiting to happen.

---

## Quiz (Interview-Style, Graded)

**Q1.** What are deployment rings and why do we use them instead of patching everyone at once?
> **Your answer:**

**Q2.** A user's Windows Update keeps failing and rolling back. Walk me through your fixes, cheapest first.
> **Your answer:**

**Q3.** Dozens of machines break right after a patch. What's your immediate priority and action?
> **Your answer:**

**Q4.** **Scenario:** a critical, actively-exploited vulnerability needs patching now, but you're worried
about breaking things. How do you balance security and stability?
> **Your answer:**

**Q5.** Why is patch management considered "change enablement," and what must every deployment include?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `windows update deployment rings pilot broad`
- `reset softwaredistribution failed update fix`
- `wusa uninstall KB rollback bad update`
- `windows update for business intune WSUS`
- `patch compliance reporting`

**Tools**
- `Get-Hotfix PSWindowsUpdate`
- `windows update error code 0x800f0922`

**Going further**
- `asset management` (L27) · `endpoint troubleshooting` (L24) · `software management` (L25) ·
  `windows server` (L22) · `incident/RCA` (L31/L32) · **NaviOpsSec** (vulnerability/patch security)

**Service / Security (Lens E):**
- 🤝 `maintenance windows reboot communication`, `own a bad-patch incident`
- 🔒 `patch exploited vulnerabilities fast`, `emergency change critical patch`, `patch compliance security` (→ NaviOpsSec)

---

## Lesson Status
- [ ] §8 lab completed (patch status + failed-update fix + rollback + ring design + patch_status.ps1)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 27 — Asset Management**.

---

*Lesson 26 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: Microsoft Windows
Update for Business / Intune update rings / WSUS docs; ITIL change enablement (L17).*
