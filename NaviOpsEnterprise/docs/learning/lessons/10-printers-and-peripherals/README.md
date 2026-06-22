# Lesson 10 — Printers & Peripherals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the most relentless ticket category in IT support — **printers** (offline, stuck queue,
wrong driver, can't add) — plus the peripherals techs touch daily (docks, monitors, USB devices,
headsets, webcams). The print stack looks trivial and breaks constantly; mastering it is FCR gold.
**Primary artifact:** the "printer offline" runbook + `scripts/spooler_reset.ps1`.

> **How to use this lesson:** read §1–§7, do §8 (break/fix the spooler + add a printer), produce §9,
> take the quiz, reflect. Then Lesson 11.

---

## §1 — Concept (Theory)

### What it is
Printing is a small pipeline: an **application** → the **printer driver** (translates the doc into the
printer's language) → the **print spooler** (a Windows service, `spoolsv.exe`, that queues jobs) →
the **port/connection** (USB, or a network IP/print server) → the **printer**. A "peripheral" is any
device attached to the PC (printer, dock, monitor, keyboard/mouse, headset, webcam), reaching the OS
through a **driver** over a **bus** (USB/Bluetooth/Thunderbolt/network).

### Why it matters for support
Printers are the punchline of IT support because the pipeline has many failure points and users depend
on them at the worst moments. Each stage maps to a specific fix: spooler stuck → restart the service;
"offline" → connection/port; garbled output → driver; can't add → driver/permissions/discovery.
Peripherals follow the same logic (device → driver → bus). Knowing the pipeline turns "ugh, printers"
into a fast, confident fix.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "it won't print" / "the printer's offline" / "it prints gibberish."
- **Level 2 — Technician:** locate the failing stage — is the **Spooler** service running? is the
  **queue** stuck? is the printer **reachable** (ping the IP)? is the **driver** right? — and fix that
  stage.
- **Level 3 — Engineer:** the **Print Spooler** service holds jobs in `C:\Windows\System32\spool\
  PRINTERS`; a **corrupt job** can wedge the whole queue (clear the folder + restart the service);
  "offline" is often Windows' **SNMP status** check failing (the printer is fine, Windows thinks it's
  down — "Use Printer Offline" toggles it); network printers resolve by **IP or print-server share**
  (`\\PRINTSRV\PRT-FLOOR2`); a wrong **driver/PDL** (PCL vs PostScript) yields garbage. This is *why*
  the spooler reset and the offline toggle are the two power moves.

### Two Teaching Approaches (Lens B) — the print pipeline
**Approach 1 (technical):** a print job flows app → driver → spooler queue → port → device; any stage
can fail independently. The spooler is a single service all local printing depends on, so a stuck job
or crashed spooler kills *all* printers at once — which is why "restart the spooler + clear the queue"
fixes a huge fraction of printer tickets.

**Approach 2 (analogy):** printing is a **restaurant kitchen**. Your document is the **order**; the
**driver** is the **translator** writing it in the kitchen's language; the **spooler** is the
**order rail** where tickets line up; the **printer** is the **cook**. One **garbled/stuck order**
jams the whole rail so nothing comes out — you clear the rail (queue) and restart the expeditor
(spooler). **Where it breaks down:** unlike a kitchen, "offline" often means the *front-of-house
thinks the kitchen is closed* when it's actually open (the SNMP/offline-status quirk) — the cook is
ready; Windows just stopped asking.

### Visual (ASCII) — the pipeline & where it breaks
```
   APP ─▶ DRIVER ─▶ SPOOLER (service + queue) ─▶ PORT/CONN ─▶ PRINTER
    │       │            │                          │            │
  app bug  wrong PDL   stuck job / service stopped  IP/share    paper/toner/
           = garbage   = ALL printing dead          unreachable error state
                       (restart spooler+clear queue) = "offline"  = device-side
```

---

## §2 — Tools & Commands

| Task | GUI | PowerShell / CLI |
|---|---|---|
| Printers list / queue | Settings → Bluetooth & devices → Printers; `control printers` | `Get-Printer` · `Get-PrintJob` |
| The spooler service | `services.msc` → Print Spooler | `Get-Service Spooler` · `Restart-Service Spooler` |
| Clear stuck jobs | open queue → Cancel All | `Get-PrintJob -PrinterName X \| Remove-PrintJob` |
| Add a printer | Settings → Add device / `\\PRINTSRV\PRT...` | `Add-Printer` · `Add-PrinterPort` |
| Test reachability (network) | — | `Test-NetConnection <printer-IP> -Port 9100` · `ping` |
| Driver management | Print Mgmt (`printmanagement.msc`) | `Get-PrinterDriver` · `Add-PrinterDriver` |
| Toggle "Use Printer Offline" | queue → Printer menu | (uncheck "Use Printer Offline") |

```powershell
Get-Printer | Select Name, DriverName, PortName, PrinterStatus
Get-PrintJob -PrinterName 'PRT-FLOOR2'                      # what's stuck in the queue
Restart-Service Spooler                                     # the #1 printer fix
Test-NetConnection 10.10.5.40 -Port 9100                    # is the network printer reachable (RAW/9100)?
```

The classic full spooler reset:
```powershell
Stop-Service Spooler
Remove-Item "$env:windir\System32\spool\PRINTERS\*" -Force   # clear the wedged jobs
Start-Service Spooler
```

---

## §3 — Real-World Support Context & Use Cases

- **Highest-volume category at many desks.** "Printer offline" alone is a daily occurrence; the
  spooler reset + offline toggle resolve most.
- **Network vs local printers:** network printers (by IP or print-server share) add reachability and
  driver-deployment dimensions; USB printers add cable/port/driver.
- **Peripherals at the desk:** **docks** (no external monitor / no network through the dock — often a
  dock firmware/driver or a Thunderbolt/USB-C power issue), **monitors** (no signal, wrong input,
  resolution), **headsets/webcams** (not the default device in Teams — L11), **keyboard/mouse** (USB/
  Bluetooth/battery).
- **"Default device" tickets:** half of "my mic/printer doesn't work" is "the wrong device is set as
  default."
- **Exam framing:** A+ Core 1 (printers — types, install/config, troubleshooting; peripherals, USB,
  display) is a whole domain.

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0307 (P3):** *"The floor printer says 'offline' and nobody can print to it. — multiple
> users, PRT-FLOOR2."*

1. **Scope:** multiple users to **one** printer → it's the **printer/connection/server**, not each PC.
2. **Is the device actually up?** Physically: powered, no error/paper/toner light, on the network. Ping
   it / `Test-NetConnection 10.10.5.40 -Port 9100`.
   - **Unreachable** → network/power/IP issue (it may have changed IP — DHCP vs reservation, L09) →
     fix connectivity or update the port.
   - **Reachable but Windows says "offline"** → the **status quirk**: clear the "Use Printer Offline"
     flag and restart the spooler.
3. **Queue check:** a **stuck/corrupt job** at the head can wedge it → clear the queue (`Get-PrintJob |
   Remove-PrintJob`) and `Restart-Service Spooler`.
4. **Test:** print a test page from one machine; confirm with users.
5. **Root cause + document:** *why* did it go offline? (printer rebooted and got a new DHCP IP → set a
   **reservation**; or a bad job → user-education) — note it so it stops recurring.

The transferable move: **scope → device-reachable? → queue/spooler → driver** — in that order.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: printing fails / printer offline / peripheral not working.**

### 1 · Symptoms
"Offline" · jobs stuck / nothing prints · garbled/gibberish output · can't add the printer · prints
to the wrong printer · (peripheral) dock/monitor/headset/webcam not detected or not default.

### 2 · Possible Causes (most-likely first)
1. **Stuck queue / spooler** stopped or wedged (kills all printing).
2. **"Offline" status quirk** (printer up, Windows thinks it's down).
3. **Connectivity** — network printer unreachable / changed IP / USB cable.
4. **Wrong/corrupt driver** (garbage output, can't add).
5. **Wrong default** printer/device selected.
6. **Device-side**: paper/toner/jam/error state.
7. **(Peripheral)** driver/bus/power (dock), wrong input (monitor), not-default (audio/video).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Scope (one user vs many) | many→printer; one→PC | aim at the right layer |
| 2 | `Get-Service Spooler` + queue | stopped/stuck | restart spooler + clear queue |
| 3 | "Use Printer Offline" flag | checked | uncheck it |
| 4 | `Test-NetConnection IP -Port 9100` / cable | unreachable | fix network/IP/port or USB |
| 5 | Driver (`Get-Printer`/Print Mgmt) | wrong/corrupt | reinstall correct driver |
| 6 | Default printer/device | wrong | set correct default |
| 7 | Device panel (paper/toner/jam) | error | clear device-side |

### 4 · Resolution Steps
Restart spooler + clear `spool\PRINTERS`; uncheck "Use Printer Offline"; restore connectivity / set a
**DHCP reservation** for the printer (L09) or correct the port; reinstall the **correct PDL driver**;
set the right default; clear paper/toner/jam; for peripherals — reinstall the driver, try another
port, update dock firmware, select the device as default in Teams/Sound settings.

### 5 · Escalation Criteria
Escalate to Desktop Support/print-admin/vendor for: print-server queue management, driver deployment
fleet-wide (a bad driver pushed to many → problem, L32), hardware faults (fuser/roller), or network
changes (printer VLAN/IP). Attach: scope, `Get-Printer`/`Get-PrintJob`, reachability test, driver name.

### 6 · Post-Incident Documentation
Ticket note (which stage + fix, e.g. "spooler reset + DHCP reservation"), KB (KB-0006 printer
self-help), problem ticket if a driver/print-server issue hit many.

---

## §6 — Ticket Simulation

> **Ticket ENT-10 / INC-0308 (P3):** *"I sent my report to print 20 minutes ago, nothing came out, and
> now I can't print anything at all — every print just 'spins'. — Omar, DESK-1210."*

**Triage:** "first one job hung, now *nothing* prints" is the textbook **wedged spooler / corrupt job**
signature (one bad job blocks the whole queue). Single user, blocked → **P3**.

**Worked resolution:**
1. **Confirm the signature:** `Get-PrintJob` shows a job stuck in "Spooling/Error" at the head; new
   jobs pile behind it.
2. **Clear + reset (the power move):**
   `Stop-Service Spooler` → clear `spool\PRINTERS\*` → `Start-Service Spooler`.
   (Or queue → Cancel All, then `Restart-Service Spooler` if a single job clears cleanly.)
3. **Test:** print a fresh, small doc → comes out. Confirm with Omar.
4. **Root cause:** *why* did the first job wedge? (a huge/corrupt PDF, a driver mismatch) — if it's a
   specific document, note it; if the driver's wrong, fix it so it doesn't re-wedge.

**The professional ticket note:**
```
SUMMARY: Corrupt print job wedged the spooler queue on Omar's PC → all printing hung. Cleared the
queue + restarted the Print Spooler; printing restored. Suspected oversized/corrupt PDF as trigger.
SYMPTOM: one job hung, then ALL subsequent jobs "spin"/never print.
DIAGNOSIS: Get-PrintJob → head job stuck in Error; new jobs queued behind (classic spooler wedge).
CAUSE: corrupt job at queue head blocking the spooler.
RESOLUTION: Stop-Service Spooler → cleared spool\PRINTERS\* → Start-Service Spooler → test page OK.
FOLLOW-UP: advised re-saving/flattening the problem PDF before printing; KB-0006 (printer quick fixes)
linked. If recurs across users → driver problem ticket.
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Hardware/Peripheral (Print). Single user = **Incident** (P3); a print-server or
  fleet-driver failure = wider **Incident/Problem**.
- **Priority:** usually P3, but rises when it blocks something time-critical (a customer-facing print
  run, shipping labels) — judge impact, not just "it's a printer."
- **The recurring-printer-ticket trap:** if the *same* printer offlines weekly, that's a **Problem**
  (L32) — fix the root cause (DHCP reservation, firmware, placement), don't reset the spooler forever.
- **Metric angle:** printers are a huge FCR opportunity (the spooler reset + offline toggle are
  self-serviceable via a good KB) and a backlog risk if root causes are ignored.

---

## §8 — Practical Lab (build this yourself)

**Goal:** own the spooler reset, add a printer, and recognize the offline quirk.

### Lens C — Manual → Automation → Why
- **Manual:** open the queue, Cancel All, restart the spooler in `services.msc`.
- **Automated:** `spooler_reset.ps1` stops the spooler, clears the wedged jobs, restarts it, and
  reports the printer status — one safe command for the #1 printer ticket.
- **Why:** it's the most-repeated printer fix; a script makes it consistent and self-service-able, and
  remotable so you don't need to sit at the user's desk.

### Steps
1. **Inspect:** `Get-Printer` and `Get-PrintJob` — read driver, port, status, and any queued jobs.
2. **Break/fix drill:** pause a printer / send a job while disconnected to create a stuck queue, then
   run the spooler reset and watch it clear. (Safe, reversible.)
3. **Add a printer:** add one by share (`\\PRINTSRV\PRT-FLOOR2`) or IP port; confirm a test page.
4. **Offline quirk:** find "Use Printer Offline" in the queue's Printer menu — know where it lives.
5. **Reachability:** `Test-NetConnection <printer-IP> -Port 9100` — tie printing back to networking
   (L08/L09).
6. **Write `scripts/spooler_reset.ps1`** (stop → clear → start → status) and the offline runbook.

### Lens D — the raw artifact (the wedged queue)
```
> Get-PrintJob -PrinterName 'PRT-FLOOR2'
   Id  Document            JobStatus           Size
   --  --------            ---------           ----
   17  Q3-report.pdf       Error, Spooling     48 MB    ← stuck at the head, blocking everything
   18  invoice.docx        Spooling                     ← queued behind it, will never print until 17 clears
#   One Error/stuck job at the head wedges the whole spooler. The fix is clear-the-queue + restart,
#   not "reinstall the printer."
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/printer-offline.md` — scope → reachable? → spooler/queue → driver.
2. **Troubleshooting Guide:** `docs/troubleshooting/printing-and-peripherals.md` — the full spine
   (incl. docks/monitors/audio default-device).
3. **Ticket Notes:** `docs/tickets/ENT-10-spooler-wedge.md` — the worked ENT-10.
4. **KB Article:** `docs/kb/` — KB-0006 "Printer issues — quick fixes" (restart, offline toggle,
   re-add) for end users.
5. **Incident Report:** N/A single-user; note when a print-server/driver issue = a problem (L32).
6. **Portfolio Artifact:** §10 bullet + the spooler-wedge / offline-quirk talking points.
7. **Script:** `scripts/spooler_reset.ps1` (`Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Built a PowerShell print-spooler reset script and a 'printer offline' runbook,
  resolving the highest-volume ticket category at first contact and eliminating a recurring
  network-printer offline issue via a DHCP reservation."*
- **Interview talking point:** the **print pipeline** (app→driver→spooler→port→device) and the two
  power moves — **spooler reset + clear queue** for "nothing prints," and the **offline toggle** for
  the status quirk — plus recognizing a recurring printer as a *problem*, not endless resets.
- **Serves:** Help Desk T1, Desktop Support.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 1):** printers (types, install/config, troubleshooting), peripherals, USB,
  display devices — a full domain.
- **MD-102:** device/peripheral management (light). Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** printer tickets feel petty to IT but are real blockers to users — don't roll your eyes;
a calm, fast spooler reset + a KB so they can self-serve next time builds enormous goodwill.

**🔒 Security:** printers are networked computers — they have firmware, web admin panels (change
default passwords!), and **store scanned/printed documents** (a multifunction device's drive can hold
sensitive data → wipe before disposal, L27). **Secure/pull printing** (badge-release) prevents
confidential docs sitting in the tray. Printed output is a data-leak vector; "print to PDF" to an
unmanaged location can exfiltrate data. Don't expose printer admin panels to untrusted networks.

---

## Quiz (Interview-Style, Graded)

**Q1.** A user says "nothing prints anymore — every job just spins." What's the most likely cause and
your fix?
> **Your answer:**

**Q2.** A network printer shows "offline" in Windows but it's powered on with no errors. Name two
things you'd check and the quick fix for the common case.
> **Your answer:**

**Q3.** A printer suddenly prints pages of random characters. What's the likely cause?
> **Your answer:**

**Q4.** **Scenario:** the same floor printer goes "offline" every few days after-hours. Resetting the
spooler keeps "fixing" it. What's really going on and what's the permanent fix?
> **Your answer:**

**Q5.** A user's Teams calls have no microphone, but the headset works elsewhere. Where do you look
first?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `windows print spooler restart clear queue`
- `printer offline fix use printer offline`
- `network printer not printing port 9100`
- `printer prints garbage wrong driver PCL postscript`
- `set default printer audio device windows`

**Tools**
- `Get-Printer Get-PrintJob Restart-Service Spooler`
- `printmanagement.msc add printer driver`

**Going further**
- `microsoft 365 fundamentals` (L11 — Teams device settings) · `DNS/DHCP` (L09 — printer reservations)
  · `asset management` (L27 — device disposal/wipe)

**Service / Security (Lens E):**
- 🤝 `self-service printer KB first contact resolution`
- 🔒 `secure pull printing`, `printer firmware default password`, `MFP hard drive wipe disposal`

---

## Lesson Status
- [ ] §8 lab completed (spooler break/fix + add printer + spooler_reset.ps1 + runbook)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 11 — Microsoft 365 Fundamentals**.

---

*Lesson 10 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+
220-1101 (printers & peripherals), Microsoft Print Spooler / PrintManagement docs.*
