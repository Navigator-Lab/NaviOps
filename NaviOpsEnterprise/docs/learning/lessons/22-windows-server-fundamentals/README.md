# Lesson 22 — Windows Server Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the servers a Junior SysAdmin keeps alive — **Windows Server**: roles & features, **Server
Manager**, services, **Event/Performance monitoring**, and **remote administration** (RDP / PowerShell
remoting / RSAT). This is the step from "fix one PC" to "keep shared infrastructure healthy."
**Primary artifact:** the server health-check runbook + `scripts/server_health.ps1`. **Lab:** DC01/FS01
(`infra/`).

> **How to use this lesson:** read §1–§7, do §8 (drive Server Manager + remote-admin + a health
> check), produce §9, take the quiz, reflect. Then Lesson 23.

---

## §1 — Concept (Theory)

### What it is
**Windows Server** is the OS that runs shared services: a **role** is a major function the server
provides (AD DS — L18, DNS/DHCP — L09, **File Services** — L23, Print, Web/IIS, Remote Desktop), and a
**feature** is a supporting capability. You manage servers through **Server Manager** (roles/health
dashboard), the **MMC consoles** (services, Event Viewer, Performance Monitor — same as L04, at server
scale), and — critically — **remotely** (RDP, PowerShell remoting, RSAT), because servers usually run
**headless** in a datacenter/cloud with no one at the console.

### Why it matters for support
At Junior-SysAdmin/Infrastructure level you stop owning one user's laptop and start owning **services
many people depend on**. "The file server is down," "the app server is slow," "is the DC healthy?" are
your tickets now. A server problem is a *multi-user* problem (often a major incident, L31), so health
monitoring, fast diagnosis, and safe remote administration are the core skills — and server changes are
**danger zones** (one mistake affects everyone).

### Three-Level Depth (Lens A)
- **Level 1 — User:** doesn't see servers — they just notice "the share/app/email is down" (a server
  behind it).
- **Level 2 — Technician/Jr SysAdmin:** a server runs **roles** providing services; you check the
  **role's service** (`Get-Service`), its **Event logs**, and **resource health** (CPU/RAM/disk), and
  administer it **remotely** (RDP/PS-remoting) — the same triage as an endpoint (L03/L04), scaled up and
  done at a distance.
- **Level 3 — Engineer:** servers are managed at scale via **Server Manager / Windows Admin Center**,
  **PowerShell remoting** (WinRM, `Invoke-Command`/`Enter-PSSession`) and **RSAT** (run the admin
  consoles from your workstation against the server); roles register **services + event channels +
  performance counters**; health is monitored continuously (perfmon data collector sets, SCOM/monitoring
  agents — the NaviOpsNetwork/observability domain); **disk/CPU/memory** pressure and a stopped role
  service are the usual culprits. This is *why* you triage a server from a script remotely, not by
  walking to a rack.

### Two Teaching Approaches (Lens B) — server = roles + remote management
**Approach 1 (technical):** a server is a Windows OS hosting one or more **roles**, each backed by
**services**, **event channels**, and **performance counters**; you keep it healthy by monitoring those
and you manage it **remotely** (RDP for GUI, PowerShell remoting/RSAT for scale) because it's headless.
Diagnosis = role service state → its event log → resource pressure → remediate.

**Approach 2 (analogy):** a server is the **building's utility room** (power, water, network) that every
office depends on — you don't notice it until it fails, and when it does, **everyone** is affected.
Roles are the **specific utilities** it provides (electricity = file service, water = DNS); you monitor
the **gauges** (CPU/RAM/disk, service status) and you usually service it **remotely from a control room**
(remote admin), not by standing in the utility room. **Where it breaks down:** unlike a utility room,
you can (carefully) reconfigure a live server from afar — powerful, but one bad remote change can take
down the whole "building," which is why server changes are change-controlled (L17/26).

### Visual (ASCII) — server roles & remote management
```
   YOUR WORKSTATION ──(RDP / PowerShell remoting WinRM / RSAT)──▶ SERVER (headless)
                                                                    │
   ROLES (each = service + event log + perf counters):   AD DS(L18) · DNS/DHCP(L09) · File(L23) · Print · IIS · RDS
   HEALTH GAUGES:  Get-Service (role up?) · Event Viewer (errors) · CPU/RAM/Disk (Performance) · disk space (L06)
   A server problem = MANY users affected → often a MAJOR INCIDENT (L31).  Server changes = DANGER ZONE.
```

---

## §2 — Tools & Commands

| Task | GUI | PowerShell |
|---|---|---|
| Roles/features + health dashboard | **Server Manager** / Windows Admin Center | `Get-WindowsFeature` · `Install-WindowsFeature` |
| Remote GUI | **RDP** (`mstsc`) | — |
| Remote shell | — | `Enter-PSSession <srv>` · `Invoke-Command -ComputerName <srv> -ScriptBlock {…}` |
| Admin consoles from your PC | **RSAT** (ADUC/GPMC/DNS/DHCP) | — |
| Service health | `services.msc` | `Get-Service` · `Restart-Service` (L04) |
| Event logs | Event Viewer | `Get-WinEvent` (L03) |
| Performance | Performance Monitor (`perfmon`) / Task Mgr | `Get-Counter` |
| Disk space | — | `Get-Volume` / `Get-PSDrive` (L06) |
| Uptime / last boot | `systeminfo` | `(Get-CimInstance Win32_OperatingSystem).LastBootUpTime` |

```powershell
Invoke-Command -ComputerName FS01 -ScriptBlock {
  Get-Service | Where-Object Status -ne 'Running' | Where-Object StartType -eq 'Automatic'  # auto services that are down
  Get-Volume | Select DriveLetter, @{n='FreeGB';e={[math]::Round($_.SizeRemaining/1GB,1)}}   # disk space (L06)
  Get-Counter '\Processor(_Total)\% Processor Time','\Memory\Available MBytes'                # live CPU/RAM
}
Get-WindowsFeature -ComputerName FS01 | Where-Object Installed   # which roles this server runs
```

> **Danger zone** (`navi.project.md`): server role/service/config changes affect many users — **lab only**
> (DC01/FS01), confirm scope, snapshot before risky changes, and treat production changes as **Changes**
> (L17/26). Remote-admin into the **lab** servers, never a production box unauthorized.

---

## §3 — Real-World Support Context & Use Cases

- **Server tickets are multi-user by nature:** "the file server is unreachable," "the app is slow for
  everyone," "is DC01 healthy?" — scope is wide, so priority is high and incidents are often **major**
  (L31).
- **Remote administration is the norm:** servers are headless in a datacenter/cloud — you live in RDP,
  PowerShell remoting, and RSAT (run ADUC/GPMC/DNS from your desk against the server).
- **The triage is the same as an endpoint, scaled:** role service up? (`Get-Service`) → its Event log →
  resource pressure (CPU/RAM/**disk full**, the classic — L06) → remediate. The Linux equivalent is L05.
- **Health monitoring** turns reactive into proactive — a disk filling on a DC should page you *before*
  it takes down logon.
- **Patching servers** is higher-stakes than endpoints (L26 — maintenance windows, reboots affect
  everyone).
- **Exam framing:** the Microsoft server-admin path; A+ touches server/role concepts; ties to
  observability/NOC (NaviOpsNetwork).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0607 (P1):** *"Nobody on the team can reach the Finance file share (\\FS01\Finance) —
> it's completely down."*

1. **Scope = many users, one server → P1 / likely major incident** (L31): this isn't an endpoint
   ticket. Declare/notify accordingly and own comms.
2. **Reach the server remotely:** `Enter-PSSession FS01` (or RDP) — don't walk to the rack.
3. **Check the role's service:** `Get-Service LanmanServer` (the **Server** service backing file
   sharing) → Stopped? That's the lead. Also check the share exists (`Get-SmbShare`, L23).
4. **Why did it stop?** `Get-WinEvent -LogName System -MaxEvents 20` on FS01 → e.g. a service crash, or
   **disk full** (L06 — `Get-Volume`, a top server-down cause) preventing the service/share from working.
5. **Resource check:** CPU/RAM/disk (`Get-Counter`, `Get-Volume`) — is C:/the data volume at 100%?
6. **Remediate the cause:** free disk / restart the role service (`Restart-Service LanmanServer`) /
   address the crash; confirm the share is reachable again (`Test-NetConnection FS01 -Port 445`).
7. **Verify with users + RCA:** confirm the team can reach `\\FS01\Finance`; capture the timeline for an
   **RCA** (L32) — *why* did it fail (disk monitoring gap? a runaway log?).

The teaching point: **server triage = role service → its event log → resource pressure, done remotely**,
and a server-down is a wide-impact incident, not a single ticket.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: a server/role is down, degraded, or unreachable.**

### 1 · Symptoms
A shared service down for many (file/print/app/DNS) · server slow/unresponsive · can't RDP/remote in ·
a role service stopped · disk full on a server · high CPU/RAM · server rebooted unexpectedly (L03 Event
41).

### 2 · Possible Causes (most-likely first)
1. **Role service stopped/crashed** (`Get-Service`).
2. **Disk full** (L06) — stops services, blocks logging/writes (the classic server killer).
3. **Resource exhaustion** (CPU/RAM pinned by a process/runaway).
4. **Network/firewall** — server unreachable (port blocked, NIC, L08; `Test-NetConnection`).
5. **Recent change/patch** (L26) — broke a role (change-induced, L19-style).
6. **Hardware/host** (a VM host issue, failing disk — L02/L06).

### 3 · Diagnostic Steps (ordered)
| # | Check (remote) | If… | …then |
|---|---|---|---|
| 1 | Scope: many users? | yes | **major incident** (L31) + comms |
| 2 | `Test-NetConnection <srv> -Port <svc>` / RDP | unreachable | network/firewall/host (L08) |
| 3 | `Get-Service <role svc>` | stopped | start + find why (event log) |
| 4 | `Get-Volume` (disk space) | ~100% | free space (L06) — top server cause |
| 5 | `Get-Counter` CPU/RAM | pinned | find the process; resource fix |
| 6 | `Get-WinEvent System/Application` | error/crash | act on the cause (or recent change/patch) |

### 4 · Resolution Steps
Restart the role service (and find the crash cause); **free disk space** (L06); kill/fix a runaway
process or add resources; restore network/firewall reachability (L08); **roll back a bad change/patch**
(L19/26); escalate hardware/host issues. Confirm the service is reachable by users (`Test-NetConnection`)
before resolving.

### 5 · Escalation Criteria
Escalate to senior infra / the role owner / vendor for: DC/AD health (`dcdiag`/replication — L18),
clustering/HA, virtualization-host problems, role reconfiguration, and major incidents (L31). Server
changes go through **change control** (L17/26). **Production server changes you're not authorized for stop
at the boundary** (danger zone). Attach: scope, the role/service state, event IDs, resource readings.

### 6 · Post-Incident Documentation
Ticket/incident note (role, root cause, fix), **major incident report + RCA** for outages (L31/L32),
KB/runbook for the recurring pattern (e.g. server disk-full), a Problem for chronic causes (L32),
monitoring improvement (alert on disk/service before it fails).

---

## §6 — Ticket Simulation

> **Ticket ENT-22 / INC (P1):** *"DC01 is at 100% disk and now logons are failing across the company —
> people can't sign in!"* Channel: monitoring alert + flood of tickets.

**Triage:** **DC01** (a domain controller, L18) at 100% disk → **AD/logon depends on it** → company-wide
logon failure → **P1 major incident** (L31). This is the highest-stakes server scenario: the DC failing
breaks authentication for everyone.

**Worked resolution (incident = restore fast, do-no-harm to a DC):**
1. **Declare the major incident** (L31): notify, assign an owner, post status — many users, critical
   service. Don't let 200 tickets pile up uncoordinated (link them, L15).
2. **Reach DC01 remotely** (RDP/PS-remoting) — confirm the disk: `Get-Volume` shows C: at ~100%.
3. **Find the space hog safely:** `Get-ChildItem` the usual culprits — **log files** (a runaway service
   log, AD/DNS debug logging left on), Windows Update cache, a dump file. On a DC, **be careful** what
   you delete (never AD database/SYSVOL files — danger zone).
4. **Free space surgically:** clear/rotate the offending **logs** + Update cache (the safe wins, L06);
   gain enough headroom for AD services to function again.
5. **Restore service + verify:** confirm AD/Netlogon services are healthy and **logons succeed**
   (test with a lab/test account); `Test-NetConnection DC01 -Port 389` (LDAP).
6. **RCA + prevent (L32):** *why* did the DC fill? (debug logging left enabled / no disk monitoring) →
   permanent fixes: disable the runaway logging (a **Change**, L26), **add disk-space monitoring/alerting**
   so this pages *before* it's an outage, and consider more disk. This is the root-cause discipline of L16.

**The professional incident note (excerpt):**
```
SUMMARY: DC01 C: reached 100% (runaway DNS debug log) → AD services degraded → company-wide logon
failures. Major incident declared. Cleared the runaway log + Update cache to restore headroom; AD/logon
recovered. RCA: debug logging left enabled + no disk alerting.
SCOPE/IMPACT: all users (logon depends on DC01) → P1 major incident.
DIAGNOSIS: Get-Volume → C: 100%; largest consumer = DNS debug log (left on after a prior investigation).
ACTIONS: declared MI + comms; remoted to DC01; cleared the debug log + WU cache (did NOT touch AD DB/
SYSVOL); confirmed AD/Netlogon healthy + test logon OK; Test-NetConnection 389 OK.
CAUSE (root, RCA L32): debug logging left enabled (no rotation) + no disk-space monitoring on DCs.
RESOLUTION: freed disk; logons restored at HH:MM.
FOLLOW-UP (Changes/L26): disable DNS debug logging; add disk-space alerting on all DCs/servers; add
disk headroom. PROBLEM raised so no DC silently fills again.
```

---

## §7 — Service Desk / ITIL Perspective

- **Servers = shared services = high-impact:** server incidents are frequently **major incidents** (L31)
  with formal comms, an incident owner, and an **RCA** (L32). The desk's job in the early minutes is
  scope + declare + communicate.
- **Change control is non-negotiable on servers:** role/config/patch changes affect everyone → assess,
  schedule a **maintenance window**, snapshot, **rollback plan** (L17/26). Most server outages are
  self-inflicted by un-controlled changes.
- **Monitoring is the proactive arm:** alert on disk/service/resource health so you fix *before* users
  notice (the observability/NOC bridge — NaviOpsNetwork).
- **Remote-first operations:** RDP/PS-remoting/RSAT/Windows Admin Center are how real admins work —
  efficient and auditable.
- **Metric/risk angle:** server uptime/availability is a headline SLA; a DC or file-server outage is
  among the most visible, highest-cost incidents an org has.

---

## §8 — Practical Lab (build this yourself)

**Goal:** manage a server remotely and build a one-shot health check — against the lab servers.

### Lens C — Manual → Automation → Why
- **Manual:** RDP into the server, click Server Manager, check services/disk/events by hand.
- **Automated:** `server_health.ps1` remotely collects, for one or many servers: uptime, stopped auto
  services, disk free %, CPU/RAM, and recent critical events — a consistent health snapshot.
- **Why:** you can't RDP into 30 servers every morning; a script (run on a schedule) gives you the whole
  fleet's health at a glance and feeds monitoring/alerting — the difference between proactive and "the
  DC filled up and took down logon."

### Steps
1. **Lab:** use DC01/FS01 (`infra/`). From your workstation, set up **remote admin** — enable PS
   remoting (`Enable-PSRemoting` on the server, lab), install **RSAT** on your client.
2. **Remote in:** `Enter-PSSession FS01`; run ADUC/DNS via RSAT against DC01 (the remote-admin workflow).
3. **Roles:** `Get-WindowsFeature | Where Installed` — see which roles each server runs.
4. **Health drill:** check stopped auto services, `Get-Volume` (disk), `Get-Counter` (CPU/RAM), recent
   System/Application errors on FS01.
5. **Break/fix (lab):** stop the **Server** (LanmanServer) service on FS01, observe the share become
   unreachable, restart it remotely, confirm recovery (`Test-NetConnection FS01 -Port 445`).
6. **Write `scripts/server_health.ps1`** (remote, multi-server: uptime/services/disk/CPU-RAM/events) and
   the server health-check runbook.

### Lens D — the raw artifact (a remote health snapshot catches the killer early)
```
> Invoke-Command FS01,DC01 { Get-Volume C | Select PSComputerName,@{n='Free%';e={[math]::Round($_.SizeRemaining/$_.Size*100)}} }
   PSComputerName  Free%
   --------------  -----
   FS01            42
   DC01            3       ← DC01 at 3% free → AD/logon at risk → fix NOW, before it's a P1 outage (§6)
#   One scheduled health snapshot across the fleet turns "the DC filled and took down logon" into a
#   proactive ticket. Disk on a DC is the one to watch.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/server-health-check.md` — remote triage: service → event log → resources.
2. **Troubleshooting Guide:** `docs/troubleshooting/server-down.md` — the full spine.
3. **Ticket Notes:** `docs/tickets/ENT-22-dc-disk-full.md` — the worked ENT-22 (DC disk-full MI).
4. **KB Article:** `docs/kb/` — internal "Remote-administering a Windows server (RDP/PS-remoting/RSAT)".
5. **Incident Report:** the DC disk-full outage as a **major incident report + RCA** (L31/L32).
6. **Portfolio Artifact:** §10 bullet + the server-triage / remote-admin talking points.
7. **Script:** `scripts/server_health.ps1` (remote, multi-server; `Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Administered Windows Server (roles, services, Event/Performance monitoring) via
  remote management (RDP, PowerShell remoting, RSAT); built a multi-server health-check script and
  resolved a domain-controller disk-exhaustion outage that was failing company-wide logons."*
- **Interview talking point:** **server triage** (role service → event log → resource pressure, done
  remotely), why a **server/DC outage is a major incident**, and the **DC-disk-full → logon failure**
  scenario with the RCA (monitoring + controlled change as the fix).
- **Serves:** Junior SysAdmin, Infrastructure Support Engineer.

---

## §11 — Certification Crossover Notes

- **Microsoft server-admin path:** Windows Server roles/administration. **A+:** server/role concepts.
  Observability/monitoring ties to **NaviOpsNetwork**. Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** a server outage affects many people who can't do their jobs — **communication during the
incident** (clear status, honest ETA, L31) is as important as the technical fix; don't go dark.

**🔒 Security:** servers are **high-value targets** — apply **least privilege** (no casual Domain Admin;
use just-enough rights), keep them **patched** (L26 — unpatched servers are prime exploit targets),
restrict **remote access** (RDP exposed to the internet is a top breach vector — use a jump host/VPN, not
open 3389), monitor for unexpected services/accounts (NaviOpsSec domain), and back them up (L30 — a
ransomware'd or failed server needs a tested restore). Every server change is a **danger zone**: snapshot
+ change control + never delete AD DB/SYSVOL or system files to "free space."

---

## Quiz (Interview-Style, Graded)

**Q1.** What's the difference between a server *role* and a *feature*? Give an example of each.
> **Your answer:**

**Q2.** How do you administer a headless server, and name two remote-management methods.
> **Your answer:**

**Q3.** A shared file service is down for the whole team. Walk me through your remote triage, in order.
> **Your answer:**

**Q4.** **Scenario:** a domain controller hits 100% disk and logons start failing company-wide. What's
your priority, what do you do, and what must you be careful NOT to delete?
> **Your answer:**

**Q5.** Why are server changes treated more carefully than changes to a single user's PC?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `windows server roles features server manager`
- `powershell remoting Enter-PSSession Invoke-Command`
- `RSAT remote server administration tools`
- `windows server disk full service down troubleshooting`
- `domain controller health dcdiag logon failures`

**Tools**
- `Get-WindowsFeature Get-Counter Get-Service remote`
- `Test-NetConnection port 445 389`

**Going further**
- `file shares and permissions` (L23) · `patch management` (L26) · `backup and recovery` (L30) ·
  `incident management` (L31) · **NaviOps** (Linux servers) · **NaviOpsNetwork** (monitoring)

**Service / Security (Lens E):**
- 🤝 `major incident communication server outage`
- 🔒 `RDP exposure jump host`, `server least privilege patching`, `server backup ransomware`

---

## Lesson Status
- [ ] §8 lab completed (remote admin + roles + health drill + break/fix + server_health.ps1 + runbook)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 23 — File Shares & Permissions**.

---

*Lesson 22 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: Microsoft Windows
Server / Server Manager / PowerShell remoting docs; Linux server equivalent → NaviOps.*
