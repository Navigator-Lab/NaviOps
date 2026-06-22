# Lesson 02 — Computer Hardware

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the physical machine a support tech actually touches — components, what each does, how
to diagnose the classic failures (no-boot, no-display, no-power, overheating, failing disk), and
how to swap parts safely. This is the core of the Desktop Support role.
**Primary artifact:** the hardware-failure troubleshooting guide.

> **How to use this lesson:** read §1–§7, do §8 (diagnose a simulated failure), produce §9, take
> the quiz, reflect. Then Lesson 03.

---

## §1 — Concept (Theory)

### What it is
A computer is a set of cooperating components: a **CPU** (does the work), **RAM** (fast short-term
memory the CPU works in), **storage** (HDD/SSD — keeps data when powered off), a **motherboard**
(connects everything), a **PSU** (power supply — converts wall AC to the DC the parts use), a
**GPU** (drives the display, sometimes built into the CPU), and **peripherals/I/O** (keyboard,
mouse, monitor, USB, network). Support techs diagnose which of these has failed or is
misconfigured.

### Why it matters for support
Software problems get all the attention, but a meaningful slice of tickets are **physical**: a dead
power supply, a failing disk, bad RAM, a loose cable, overheating from dust. Knowing the components
lets you isolate "is this hardware or software?" fast — the single most valuable hardware question a
tech asks.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "my computer won't turn on / is slow / the screen is black." They describe a
  symptom, not a part.
- **Level 2 — Technician:** map the symptom to a likely component (no power → PSU/battery/cable;
  no display but fans spin → RAM/GPU/cable; slow → RAM/disk/thermal), then isolate by swapping or
  testing one variable.
- **Level 3 — Engineer:** understand the **POST** (Power-On Self-Test) the firmware runs at boot,
  what beep/LED codes mean, how the boot order finds an OS, why a dying SSD shows SMART errors and
  rising latency, and why heat causes throttling and instability. This is *why* a fix works.

### Two Teaching Approaches (Lens B) — the components
**Approach 1 (technical):** the CPU executes instructions fetched from RAM; RAM is volatile (lost
on power-off) and fast; storage is non-volatile and slower; the bus/motherboard moves data between
them; the PSU feeds stable DC; insufficient/failing power or memory causes no-boot or random
crashes; heat causes thermal throttling then shutdown.

**Approach 2 (analogy):** a **kitchen**. The **CPU** is the chef, **RAM** is the counter space
(small, fast — the chef works here; clear it and the work is gone), **storage** is the pantry/fridge
(big, slower, keeps things when closed), the **motherboard** is the kitchen layout connecting
everything, the **PSU** is the gas/electric line feeding it all. *Slow* usually means too little
counter space (RAM) or a slow pantry (disk), not a slow chef. **Where it breaks down:** unlike a
kitchen, a single bad RAM stick or a 50¢ capacitor can take the whole machine down — symptoms don't
scale with the size of the failed part.

### Visual (ASCII) — the boot sequence (where failures show up)
```
 Power button ─▶ PSU delivers DC ─▶ Firmware (UEFI/BIOS) runs POST ─▶ finds boot device ─▶ loads OS
      │               │                    │                              │                 │
   no power?       no power?           beeps/no display?            "no boot device"?    OS errors
   (PSU/batt/      (PSU/cable)         (RAM/GPU/CPU)                (disk/boot order)    (software → L24)
    wall/cable)
```

---

## §2 — Tools & Commands

| Tool | What it's for |
|---|---|
| **Anti-static strap / mat** | prevent ESD damage when handling components |
| **Screwdriver kit / spudger** | safe disassembly |
| **`Get-WmiObject`/`Get-CimInstance`** (PowerShell) | query installed hardware programmatically |
| **Task Manager → Performance** | live CPU/RAM/disk/GPU utilization |
| **Resource Monitor / `perfmon`** | deeper performance detail (Lesson 24) |
| **Device Manager (`devmgmt.msc`)** | drivers + detected/failed devices |
| **CrystalDiskInfo / `Get-PhysicalDisk`** | disk health / SMART status |
| **Memory Diagnostic (`mdsched.exe`)** | test RAM for faults |

```powershell
Get-CimInstance Win32_Processor | Select Name, NumberOfCores, MaxClockSpeed
Get-CimInstance Win32_PhysicalMemory | Select Capacity, Speed, Manufacturer
Get-PhysicalDisk | Select FriendlyName, MediaType, HealthStatus, Size
Get-CimInstance Win32_Battery | Select EstimatedChargeRemaining, BatteryStatus   # laptops
```

---

## §3 — Real-World Support Context & Use Cases

- **Desktop Support's bread and butter:** hardware swaps, RAM/SSD upgrades, dock/monitor issues,
  battery replacements, deskside repairs.
- **The first triage question:** *hardware or software?* If it won't POST or there's no display
  with fans running, you're in hardware. If it boots to Windows and misbehaves, it's likely software
  (Lesson 24).
- **Data first, always:** before replacing a failing disk or reimaging, **recover the user's data**
  (OneDrive/Known Folder Move makes this easier — Lesson 30).
- **Repair vs replace** (IT-Support playbook): labor + parts vs replacement cost and device age.
- **Exam framing:** CompTIA A+ Core 1 (220-1101) is heavily hardware — components, laptops,
  troubleshooting hardware, and the methodology.

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0014 (P3):** *"My desktop won't turn on at all — no lights, no fans. — Bob, DESK-1102."*

1. **Confirm "no power" precisely:** any LEDs? fans? sound? (truly dead vs. powers-then-dies)
2. **Cheapest checks first:** is it plugged in? wall outlet live (test with a phone charger)? power
   strip switched on? PSU rocker switch on? cable seated both ends?
3. **Isolate the PSU:** try a known-good power cable; try a different outlet. On a laptop: remove
   battery (if removable), try AC only; try a known-good charger.
4. **Narrow the part:** if a different cable/outlet brings it to life → it was the cable/outlet. If
   still dead with known-good power → suspect **PSU** (desktop) or **charger/DC jack/battery**
   (laptop).
5. **Resolve:** replace the failed part (PSU/charger), or escalate for depot repair if it's the
   board/jack.
6. **Document + recover:** note the fault and fix; if you replaced storage at any point, confirm
   data was recovered first.

The discipline: **change one variable at a time** and confirm the symptom changes — that's how you
*know* the cause instead of guessing.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: a desktop/laptop hardware failure.**

### 1 · Symptoms
No power / no display (with fans) / random shutdowns / blue screens / very slow / loud or hot /
"no boot device" / peripheral not detected.

### 2 · Possible Causes (most-likely first)
1. Loose/failed **cable or power source** (most common, cheapest).
2. **Overheating** (dust, failed fan) → throttling/shutdown.
3. **RAM** fault (no display with fans, random crashes, blue screens).
4. **Storage** failing (slow, freezes, "no boot device", SMART warnings).
5. **PSU** (desktop) / **charger/battery/DC-jack** (laptop).
6. **GPU** (artifacts, no display) or **motherboard** (rare, expensive — last).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Power source/cable/outlet | comes alive | it was power — done |
| 2 | Listen/look at POST (fans, beeps, LEDs) | fans spin, no display | suspect RAM/GPU |
| 3 | Reseat/swap one RAM stick | display returns | bad stick/slot |
| 4 | Check temps / clean dust / verify fan | was overheating | thermal fix |
| 5 | `Get-PhysicalDisk` / SMART / boot error | disk unhealthy | recover data → replace |
| 6 | Device Manager for the peripheral | yellow ⚠ / not present | driver/cable/port |

### 4 · Resolution Steps
Reseat or replace the identified part; clean dust + restore airflow for thermal; replace failing
disk **after data recovery**; update/reinstall a driver for a peripheral; replace cable/charger.

### 5 · Escalation Criteria
Escalate to **depot/vendor (T3)** for: motherboard/CPU faults, in-warranty repairs (don't void
warranty), liquid damage, or anything requiring board-level work. Attach: symptom, what you tested,
the part you suspect, asset tag, warranty status.

### 6 · Post-Incident Documentation
Ticket note (the fault + the part replaced + serials if swapped), asset register update (Lesson 27
— a swapped part changes the asset record), KB if it's a recurring model-specific fault.

---

## §6 — Ticket Simulation

> **Ticket ENT-02 / INC-0015 (P3):** *"My laptop screen is black but I can hear it running and the
> keyboard lights are on. — Carol, LT-0428."* Channel: portal.

**Triage:** one user, blocked from work, no obvious wider impact → **P3** (P2 if she's about to
present). It runs + lights on but **no display** → classic display-path problem, *not* a power
problem.

**Worked resolution:**
1. **External monitor test** (the key diagnostic): plug in an external display.
   - *Image on external → the laptop and GPU are fine; the built-in panel/cable/backlight is the
     fault* → depot for panel, or use a dock/monitor as a stopgap.
   - *No image on external either → suspect RAM/GPU/board* → reseat RAM if accessible; else depot.
2. **Brightness/backlight quick checks:** brightness keys, and shine a flashlight at the panel — if
   you can faintly see the desktop, it's a **backlight/inverter** issue.
3. Resolve per the branch; arrange a loaner if depot is needed (Lesson 27).

**The professional ticket note:**
```
SUMMARY: LT-0428 no internal display (powers on, keyboard lit). External monitor showed image →
isolated to internal panel/cable. Issued loaner; sent unit to depot for panel replacement.
SYMPTOM: black screen, system running, keyboard backlight on.
DIAGNOSIS: 1) external monitor → image present (GPU/board OK) 2) flashlight test → no faint image
(backlight out, not just dim).
CAUSE: failed internal display panel/backlight (hardware).
RESOLUTION: data already in OneDrive (verified); loaner LT-0455 issued + asset record updated;
RMA opened with vendor (in warranty).
FOLLOW-UP: return loaner on repaired-unit receipt; close on user confirmation.
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Hardware. Usually an **Incident**; a new-device or upgrade is a **Request**.
- **Priority:** drive by impact × urgency — a dead laptop for someone presenting in 30 min is P2,
  the same laptop for someone WFH with a spare is P3/P4.
- **The loaner/stock process** (Lesson 27) is what keeps a hardware incident from becoming a
  multi-day productivity loss — issue a loaner, repair in the background.
- **SLA reality:** hardware often involves **vendor/depot** time outside your control — communicate
  that clearly and track it; the SLA may pause on "pending vendor."
- **Metric angle:** hardware tickets affect MTTR badly if you wait on parts; loaners protect CSAT.

---

## §8 — Practical Lab (build this yourself)

**Goal:** practice the hardware diagnostic spine and inventory a machine programmatically.

### Lens C — Manual → Automated → Why
- **Manual:** open the case, read labels, eyeball the parts.
- **Automated:** `Get-CimInstance` / `Get-PhysicalDisk` pull the full spec + health without a
  screwdriver — and can run across many machines for an inventory (Lesson 27).
- **Why:** at scale you can't open 200 cases; a script gives you model, RAM, disk type, and disk
  **health** for the whole fleet — feeding asset management and proactive disk-replacement.

### Steps
1. **Inventory your own machine:** run the `Get-CimInstance`/`Get-PhysicalDisk` block from §2; save
   the output as your asset record draft (`scripts/hardware_inventory.ps1`).
2. **Simulate a diagnosis:** pick a symptom (e.g. "no display, fans spin") and write out the spine
   for it (Symptoms → Causes → Diagnostics → Resolution → Escalation → Docs).
3. **Write the troubleshooting guide** (`docs/troubleshooting/hardware-failure.md` from the
   template) covering no-power / no-display / slow / overheating / failing-disk.
4. **Check disk health:** run `Get-PhysicalDisk` and interpret `HealthStatus`; note what you'd do
   on "Warning."

### Lens D — the raw artifact (disk health / SMART)
```
FriendlyName        MediaType  HealthStatus  Size
-----------         ---------  ------------  ----
Samsung SSD 980     SSD        Healthy       500GB
WDC WD10 (old HDD)  HDD        Warning       1TB     ← SMART flagging reallocated sectors → back up + replace NOW
```
`HealthStatus = Warning` (or SMART reallocated/pending sectors) is the disk telling you it's dying.
The right move is **recover data first, then replace** — never "wait and see."

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/no-power-no-display.md` — the ordered cheap-first checks.
2. **Troubleshooting Guide:** `docs/troubleshooting/hardware-failure.md` — the full spine.
3. **Ticket Notes:** `docs/tickets/ENT-02-laptop-no-display.md` — the worked ENT-02.
4. **KB Article:** `docs/kb/` — "My computer won't turn on — quick checks before you call IT"
   (end-user-facing, safe checks only).
5. **Incident Report:** N/A (single-device); note when a batch/model failure would warrant one.
6. **Portfolio Artifact:** §10 bullet + the external-monitor-test talking point.
7. **Script:** `scripts/hardware_inventory.ps1` (`Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Authored a hardware-failure troubleshooting guide and a PowerShell hardware/
  disk-health inventory script, enabling consistent component-level diagnosis and proactive failing-
  disk replacement before data loss."*
- **Interview talking point:** the **external-monitor test** for "black screen," and the
  hardware-vs-software first question — be able to reason from symptom to component.
- **Serves:** Desktop Support Technician (primary), Help Desk T1.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 1, 220-1101):** mobile/laptop hardware, components, hardware troubleshooting,
  the troubleshooting methodology. This is a core A+ lesson.
- **MD-102:** device maintenance touches here. **Net+/MS-900/ITIL:** N/A directly. Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** hardware issues are visceral for users ("my stuff!") — lead with **data safety** and
a **loaner** so they're never stranded. Explain depot timelines honestly.

**🔒 Security:** physical security counts — a failed disk still holds data (**sanitize or destroy**
retired/replaced drives per policy, never just bin them — Lesson 27/30); beware "tech support"
impostors asking users to open their machine; lock devices and use cable locks in public areas; and
verify before handing out a loaner (asset goes on the right person's record).

---

## Quiz (Interview-Style, Graded)

**Q1.** A desktop has no power at all — no lights, no fans. Walk me through your checks in order.
> **Your answer:**

**Q2.** A laptop powers on (fans, keyboard light) but the screen is black. What's your single most
useful diagnostic, and what do the two outcomes tell you?
> **Your answer:**

**Q3.** What's the difference between RAM and storage, and which one usually makes a machine "feel
slow"?
> **Your answer:**

**Q4.** **Scenario:** `Get-PhysicalDisk` shows a user's drive as `HealthStatus: Warning`. The user
says it's working fine. What do you do and why?
> **Your answer:**

**Q5.** How do you decide whether to repair or replace a failing laptop?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `computer components explained CPU RAM storage motherboard PSU`
- `POST power on self test beep codes`
- `laptop black screen external monitor test`
- `SSD vs HDD SMART health`
- `RAM troubleshooting reseat memory diagnostic`

**Tools**
- `Get-PhysicalDisk HealthStatus`
- `Windows Memory Diagnostic mdsched`

**Going further**
- `operating systems fundamentals` (L03) · `endpoint troubleshooting slow PC` (L24) ·
  `backup and recovery` (L30)

**Service / Security (Lens E):**
- 🤝 `data recovery before reimage`, `loaner device process`
- 🔒 `secure disk disposal sanitization`, `physical device security cable lock`

---

## Lesson Status
- [ ] §8 lab completed (inventory script + troubleshooting guide)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 03 — Operating-Systems Fundamentals**.

---

*Lesson 02 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+
220-1101 (hardware + troubleshooting methodology), vendor hardware docs.*
