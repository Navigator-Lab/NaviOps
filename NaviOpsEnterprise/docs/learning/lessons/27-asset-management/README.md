# Lesson 27 — Asset Management

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** knowing **what you have, where it is, who has it, and what state it's in** — hardware/software
**inventory**, the **asset lifecycle** (procure → deploy → maintain → retire/dispose), **CMDB basics**,
**asset tags**, **stock/loaners**, license tracking, and **secure disposal**. The unglamorous discipline
that underpins support, security, and cost — and closes Module G.
**Primary artifact:** the asset register template + `scripts/asset_collect.ps1`.

> **How to use this lesson:** read §1–§7, do §8 (build an asset register from a fleet collect), produce
> §9, take the quiz, reflect. Then Lesson 28 (Module H).

---

## §1 — Concept (Theory)

### What it is
**Asset management** (IT Asset Management / ITAM) is tracking an organization's IT assets — **hardware**
(laptops, desktops, monitors, phones, servers, peripherals), **software/licenses**, and (in ITIL terms)
**Configuration Items** in a **CMDB** (Configuration Management Database) — through their full
**lifecycle**: procurement → deployment → maintenance → **retirement/disposal**. Each asset has an
identity (an **asset tag**/serial), an **owner/location**, a **state**, and relationships to users and
services. It also covers the **stockroom/loaner** process and **secure disposal** of retired gear.

### Why it matters for support
Almost everything else in this platform assumes you **know what you have**: you can't secure, patch (L26),
license (L25/L11), back up (L30), or recover (L02 loaner) what you don't know exists. Asset management is
the quiet backbone — it answers "who has LT-0427?", "is this device under warranty?", "how many licenses
are we paying for vs using?", "did we wipe that returned laptop?" Poor ITAM means lost devices, license
waste/violations, security blind spots, and chaos at onboarding/offboarding (L20).

### Three-Level Depth (Lens A)
- **Level 1 — User:** doesn't see it — but benefits ("they knew my laptop was under warranty," "a loaner
  was ready").
- **Level 2 — Technician:** maintain the **asset register** — record each device's tag/serial/model/owner/
  location/state; assign on onboarding, reclaim on offboarding (L20); issue **loaners** (L02/L24); update
  on repair/swap.
- **Level 3 — Engineer:** ITAM is a **CMDB** of **Configuration Items** with attributes + **relationships**
  (this user → this laptop → this software/licenses → these services), fed by **automated discovery**
  (inventory agents, `Get-CimInstance`, Intune/SCCM) reconciled against a source of truth; it underpins
  **security** (know your attack surface), **license compliance** (L25), **patch/vuln coverage** (L26),
  and **lifecycle** (warranty, refresh cycles, **secure disposal**/data sanitization, L06/L30). This is
  *why* an accurate CMDB is foundational to every other practice.

### Two Teaching Approaches (Lens B) — you can't manage what you can't see
**Approach 1 (technical):** ITAM maintains a **single source of truth** (asset register/CMDB) of all
assets, their owners/states/relationships, kept current by **automated discovery** + lifecycle processes
(onboarding/offboarding/repair). It enables security (attack-surface visibility), compliance (license +
patch), finance (spend, refresh), and operations (loaners, warranty). Inaccurate data breaks all of them.

**Approach 2 (analogy):** ITAM is the **company's inventory + property records** — like a library tracking
every book (asset tag), who borrowed it (owner), where it is (location), its condition (state), and when
it's due back/retired (lifecycle). A library that doesn't track its books loses them, can't tell you what
it owns, and can't replace what's missing. **Where it breaks down:** unlike library books, IT assets hold
**data** — so "returning" one isn't enough; it must be **securely wiped** before reuse/disposal (a data-
security step with no library equivalent).

### Visual (ASCII) — the asset lifecycle + the CMDB web
```
   PROCURE ─▶ RECEIVE (asset tag + register) ─▶ DEPLOY (assign to user, L20) ─▶ MAINTAIN (repair/loaner/patch) ─▶
   RETIRE ─▶ SECURE DISPOSAL (wipe/destroy data — L06/L30)

   CMDB relationships (why it underpins everything):
      USER ──has──▶ LAPTOP(LT-0427, tag/serial/warranty) ──runs──▶ SOFTWARE/LICENSES (L25) ──needs──▶ PATCHES (L26)
                         │ backed up by (L30)   │ secured by (L29)   │ part of services
   "you can't secure / patch / license / back up / recover what you don't know you have."
```

---

## §2 — Tools & Commands

| Task | Tool / how |
|---|---|
| Asset register / CMDB | ITAM tool / ServiceNow CMDB / Snipe-IT / a maintained register |
| Automated hardware discovery | Intune / SCCM inventory · `Get-CimInstance` (L02) |
| Automated software/license inventory | `software_inventory.ps1` (L25) · Intune |
| Asset identity | **asset tag** + serial number (`Get-CimInstance Win32_BIOS` SerialNumber) |
| Owner/location | the register (updated at onboarding/offboarding, L20) |
| Warranty lookup | vendor portal (by serial) |
| Loaner/stock tracking | the register (state = In Stock / Loaned / In Repair / Retired) |
| Secure disposal | wipe (BitLocker crypto-erase / DoD wipe) / certified destruction (L06/L30) |

```powershell
# Per-device asset facts (feeds the register — extends L02's hardware_inventory):
Get-CimInstance Win32_BIOS | Select SerialNumber, Manufacturer
Get-CimInstance Win32_ComputerSystem | Select Name, Model, UserName, TotalPhysicalMemory
Get-CimInstance Win32_OperatingSystem | Select Caption, Version, InstallDate
# Fleet collect (remote, L22): asset facts + assigned user + OS, exported for the register
Invoke-Command -ComputerName (Get-Content servers.txt) { Get-CimInstance Win32_BIOS } | Export-Csv assets.csv
```

> **Note:** the asset register contains **owner/location data** (mild PII) — sanitize before committing to a
> public repo (`navi.project.md` HR#1; use placeholders LT-0427/jdoe). **Disposal** is a data-security
> danger zone — never bin a drive without sanitizing (L06/L30/L29).

---

## §3 — Real-World Support Context & Use Cases

- **Underpins everything:** onboarding/offboarding (L20 — assign/reclaim), hardware repair + **loaners**
  (L02/L24), software **licensing** (L25), **patch/vuln coverage** (L26 — unknown devices = unpatched gaps),
  **backup** scope (L30), and **security** (you can't protect unknown assets — L29).
- **Daily tickets/tasks:** "who has this device?", "issue a loaner", "asset transfer to a new owner", "wipe
  this returned laptop", "are we over-licensed?", warranty claims, stock checks.
- **Onboarding/offboarding linkage (L20):** every joiner gets an asset assigned + recorded; every leaver's
  gear is reclaimed, wiped, and re-stocked — the register is the system of record.
- **License compliance (L25):** reconcile installed software vs entitlements — avoid over-spend and
  violations.
- **Security (L29/NaviOpsSec):** an accurate inventory **is** an attack-surface map; shadow/unknown
  devices are blind spots; **secure disposal** prevents data leaks from retired drives (L06).
- **Exam framing:** A+ (Core 2 — asset management, documentation, disposal/recycling, operational
  procedures), ITIL (service configuration management / CMDB — L17).

---

## §4 — Demonstration (worked walkthrough)

> **Task REQ-0805 (P4, Service Request):** *"Three laptops came back from leavers this week — please
> process them for reuse. — IT stockroom."*

1. **Identify each asset:** match the **asset tag**/serial to the register → confirm the recorded owner
   (the leaver), model, warranty, and state.
2. **Verify offboarding done (L20):** the leaver's account is disabled + data transferred (don't wipe a
   device whose data wasn't preserved — do-no-harm, L20/L30).
3. **Secure wipe (the critical data-security step):** **sanitize** each drive — BitLocker crypto-erase / a
   certified wipe — *before* reuse; record the wipe (for audit). Never reuse/dispose without this (L06/
   L29).
4. **Update the register:** set state to **In Stock** (ready), clear the previous owner, note the wipe
   date/method; if retiring instead, mark **Retired** → certified disposal.
5. **Re-image + re-stock:** image to the standard build (L24/L25); the laptop is now a ready **loaner/
   deployment** asset.
6. **Reconcile licenses:** any per-device software/licenses freed up go back to the pool (L25).
7. **Document:** the register reflects reality (state, owner, wipe) — that accuracy is the deliverable.

The teaching point: the asset isn't "processed" until the **register reflects reality** *and* the **data is
securely wiped** — accuracy + sanitization are the whole point of ITAM.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: asset data/lifecycle problems (the "we don't know what we have" failures).**

### 1 · Symptoms
"Who has this device?" unknown · ghost/unknown devices on the network · license over-spend or violation ·
a retired drive with data not wiped · loaner not tracked / can't find stock · warranty missed · onboarding/
offboarding asset steps skipped (L20).

### 2 · Possible Causes (most-likely first)
1. **Register out of date** (assignments/returns not recorded) — the root of most ITAM pain.
2. **No automated discovery** → unknown/shadow assets (security + patch gaps).
3. **Lifecycle steps skipped** (offboarding didn't reclaim/wipe — L20).
4. **License reconciliation gap** (installed vs entitled — L25).
5. **No secure-disposal process** → data-leak risk (L06/L29).
6. **No single source of truth** (data in spreadsheets/people's heads).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Register vs reality (does it match?) | drifted | reconcile; fix the updating process |
| 2 | Automated discovery vs register | unknown devices | investigate/onboard or remove (security, L29) |
| 3 | Offboarding asset steps done? (L20) | skipped | reclaim/wipe; fix the process |
| 4 | Installed software vs licenses (L25) | over/under | reconcile (cost/compliance) |
| 5 | Retired devices wiped? | not sanitized | secure-wipe before disposal (L06) |
| 6 | Single source of truth? | scattered | consolidate into the register/CMDB |

### 4 · Resolution Steps
Reconcile the register to reality + fix the **updating process** (tie asset updates to onboarding/
offboarding/repair, L20); enable **automated discovery** (Intune/SCCM/`Get-CimInstance`) to catch unknown
assets; enforce **secure disposal** (wipe + record, L06/L30); reconcile licenses (L25); consolidate to one
**source of truth** (register/CMDB). Investigate unknown devices as a **security** matter (L29).

### 5 · Escalation Criteria
Escalate to ITAM/CMDB owner / security / finance for: standing up a CMDB or discovery, **shadow/unknown
device** investigation (security, L29), license **true-ups**/procurement (L25), and certified disposal
contracts. Unknown devices on the network = security escalation (NaviOpsSec). Attach: the register vs
discovery delta, the specific assets.

### 6 · Post-Incident Documentation
The **asset register** updated (the core artifact), disposal/wipe records (audit), onboarding/offboarding
runbook updated to keep ITAM accurate (L20), license reconciliation report (L25), Problem if the register
chronically drifts (L32).

---

## §6 — Ticket Simulation

> **Ticket ENT-27 / audit scenario (P3):** *"Internal audit asks: 'How many laptops do we own, who has
> each, are they all encrypted and patched, and can you prove retired ones were wiped?' We have a
> spreadsheet that's... mostly right."* You own the response.

**Triage:** an **ITAM accuracy + compliance** problem — the spreadsheet (no single source of truth, no
discovery) can't answer security/compliance questions confidently. This is the classic "we don't really
know what we have" reckoning.

**Worked resolution (make the register real + reconcile):**
1. **Establish discovery vs the register:** run **automated discovery** (Intune/SCCM or `asset_collect.ps1`
   across the fleet, L22) → a list of **actual** devices with serial/model/owner/OS.
2. **Reconcile against the spreadsheet:** find the gaps — devices **in discovery but not the register**
   (untracked → possibly **shadow/unmanaged** = security risk, L29), and **in the register but not
   discovered** (lost/retired/off-network → investigate).
3. **Enrich with compliance facts:** join encryption (BitLocker on? L06/L30), **patch status** (L26 —
   `patch_status.ps1`), and assigned user → now you can answer "encrypted? patched? who?".
4. **Prove disposal:** pull the **wipe records** for retired assets (the audit's "prove it" question) — if
   missing, that's a process gap to fix (and a finding).
5. **Produce the report:** count, owners, encryption %, patch compliance %, disposal evidence — a real
   answer, not "mostly right."
6. **Fix the root cause (L32):** the spreadsheet drifted because updates weren't tied to lifecycle events →
   move to a **single source of truth** (register/CMDB) **fed by discovery** + **enforced at onboarding/
   offboarding** (L20). Now it stays accurate.

**The professional note:**
```
SUMMARY: Audit asked for laptop count/owners/encryption/patch/disposal proof. Reconciled automated
discovery vs the spreadsheet → found N untracked devices (security follow-up) + M stale entries; enriched
with BitLocker + patch status; produced a real report. Root cause: no single source of truth + manual
updates → moving to a discovery-fed register enforced at on/offboarding.
REQUEST/SCOPE: accurate inventory + encryption/patch compliance + disposal evidence (audit).
ACTIONS: ran fleet discovery (asset_collect.ps1 / Intune); reconciled vs register (found untracked +
stale); joined BitLocker (L30) + patch status (L26) + owner; pulled wipe records for retired units.
FINDINGS: N untracked devices (→ security/L29 investigation); disposal evidence incomplete for K units
(→ process gap).
RESOLUTION: delivered the report; consolidated to a single register fed by discovery; tied asset updates
to onboarding/offboarding (L20) + enforced secure-wipe records.
FOLLOW-UP (Problem/L32): discovery-fed CMDB + lifecycle-enforced updates so the register stays accurate;
investigate untracked devices (NaviOpsSec).
```

---

## §7 — Service Desk / ITIL Perspective

- **ITAM = ITIL Service Configuration Management** (the **CMDB**, L17) — the source of truth that other
  practices (incident, change, problem, security) rely on. An accurate CMDB makes change blast-radius (L26),
  incident scoping (L31), and security (L29) far easier.
- **Tied to onboarding/offboarding (L20):** the register stays accurate only if assignment/reclaim/wipe are
  **part of those processes** — ITAM accuracy is a lifecycle discipline, not a one-time spreadsheet.
- **Loaners/stock** keep hardware incidents (L02/L24) from stranding users — the register tracks state.
- **License management (L25)** rides on ITAM — compliance + cost.
- **Security (L29):** "you can't protect what you don't know you have" — inventory is the foundation of
  attack-surface management, and **secure disposal** prevents data leaks (the unglamorous but critical bit).
- **Metric/risk angle:** asset accuracy %, license compliance, patch/encryption coverage, and disposal
  evidence are real audit/security metrics.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build an asset register from automated discovery and reconcile it — the real ITAM skill.

### Lens C — Manual → Automation → Why
- **Manual:** type each device into a spreadsheet (drifts immediately, as in ENT-27).
- **Automated:** `asset_collect.ps1` collects per-device facts (serial/model/owner/OS/RAM — extends L02's
  hardware_inventory) across the fleet and exports the register; join with `software_inventory.ps1` (L25)
  + `patch_status.ps1` (L26) for a full picture.
- **Why:** automated **discovery** is the only way to keep a register accurate at scale — manual lists rot;
  discovery + lifecycle enforcement (L20) keeps the source of truth real, which everything else depends on.

### Steps
1. **Collect:** run `asset_collect.ps1` locally + against the lab servers (L22) → serial, model, owner, OS,
   RAM, last-boot.
2. **Build the register:** export to `docs/templates/asset-register` (CSV/MD) with tag, serial, model,
   owner, location, **state** (In Use/In Stock/Loaned/In Repair/Retired), warranty, encryption (L30),
   patch status (L26).
3. **Reconcile drill:** introduce a discrepancy (a device not in the register) → catch it via discovery →
   the "unknown device" finding (security tie, L29).
4. **Lifecycle tie-in:** map how onboarding/offboarding (L20) updates the register (assign/reclaim/wipe) —
   so it stays accurate.
5. **Disposal:** document the **secure-wipe** step + record (L06/L30) for retired assets.
6. **Write the asset-register template** (`docs/templates/`) + `scripts/asset_collect.ps1`.

### Lens D — the raw artifact (the asset register as the source of truth)
```
   AssetTag  Serial      Model        Owner               State      Encrypted  Patched(daysBehind)  Warranty
   --------  ------      -----        -----               -----      ---------  -------------------  --------
   LT-0427   5CD1234ABC  Latitude 7x  jdoe@corp.example   In Use     Yes        3                    2027-04
   LT-0455   5CD9999XYZ  Latitude 7x  (loaner→carol)      Loaned     Yes        5                    2027-04
   LT-0490   5CD5555QRS  Latitude 5x  -                   Retired    Yes(wiped) -                    expired
   ??-????   5CD7777NEW  (unknown)    discovered, not in register  ⚠            ⚠ unknown            ⚠ → security (L29)
#   One accurate register answers: who has what, is it encrypted (L30) + patched (L26), under warranty,
#   wiped on retirement — AND flags unknown/untracked devices (security blind spots). This single source of
#   truth underpins onboarding (L20), licensing (L25), patching (L26), backup (L30), and security (L29).
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/asset-lifecycle.md` — receive→deploy→maintain→retire + loaner + secure-wipe.
2. **Troubleshooting Guide:** `docs/troubleshooting/asset-data-drift.md` — the full spine (register accuracy/
   reconciliation/disposal).
3. **Ticket Notes:** `docs/tickets/ENT-27-asset-audit-reconcile.md` — the worked ENT-27.
4. **KB Article:** `docs/kb/` — internal "Issuing/returning/wiping a device (asset process)".
5. **Incident Report:** an unknown-device discovery or a non-wiped-disposal finding as an incident/problem
   (L29/L32).
6. **Portfolio Artifact:** §10 bullet + the source-of-truth + ITAM-underpins-everything talking points.
7. **Template + Script:** the **asset register template** (`docs/templates/`) + `scripts/asset_collect.ps1`
   (`Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Established an IT asset register/CMDB fed by PowerShell + Intune discovery (hardware,
  owner, encryption, patch state), reconciled it against records to surface untracked devices, and enforced
  a secure-disposal (data-wipe) process tied to the onboarding/offboarding lifecycle."*
- **Interview talking point:** **"you can't secure/patch/license/back up/recover what you don't know you
  have"** — ITAM as the source of truth underpinning every other practice; **discovery-fed + lifecycle-
  enforced** accuracy; and **secure disposal** (wipe-and-record) as a data-security control.
- **Serves:** IT Support Specialist, Junior SysAdmin, Infrastructure Support.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2):** asset management, documentation, disposal/recycling & data destruction,
  operational procedures. **ITIL 4:** service configuration management / CMDB (L17). Ties to MD-102
  (device inventory). Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** good ITAM is invisible to users but felt — a loaner is ready, their warranty claim is fast,
their device is tracked. Accuracy is a quiet service that prevents a dozen downstream frustrations.

**🔒 Security:** asset management is **foundational security** — an accurate inventory **is** your attack-
surface map; **unknown/shadow devices** are blind spots to investigate (NaviOpsSec); ITAM enables **patch/
vuln coverage** (L26) and **backup scope** (L30); and **secure disposal** (BitLocker crypto-erase /
certified destruction + a **record**) prevents data leaks from retired drives — never bin a device without
wiping (L06/L29). The register's owner/location data is mild PII — sanitize for public repos (placeholders).
"Protect what you have" starts with "know what you have."

---

## Quiz (Interview-Style, Graded)

**Q1.** Why is asset management foundational to security, patching, and licensing — not just inventory
bookkeeping?
> **Your answer:**

**Q2.** Walk me through the IT asset lifecycle from procurement to disposal.
> **Your answer:**

**Q3.** A laptop comes back from a leaver. What must happen before it's reused, and why?
> **Your answer:**

**Q4.** **Scenario:** an audit asks how many laptops you own, who has them, whether they're encrypted and
patched, and proof retired ones were wiped — and your data is a "mostly right" spreadsheet. What do you do?
> **Your answer:**

**Q5.** How do you keep an asset register accurate over time instead of letting it drift?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `IT asset management lifecycle ITAM`
- `CMDB configuration items relationships`
- `asset tag serial inventory discovery`
- `secure data disposal wipe sanitization drive`
- `software license compliance reconciliation`

**Tools**
- `Get-CimInstance Win32_BIOS serial fleet`
- `intune sccm device inventory`

**Going further**
- `documentation and knowledge bases` (L28) · `provisioning/deprovisioning` (L20) · `software` (L25) ·
  `patch management` (L26) · `backup and recovery` (L30) · `security awareness` (L29)

**Service / Security (Lens E):**
- 🤝 `loaner ready warranty fast`, `invisible-but-felt asset accuracy`
- 🔒 `inventory as attack surface`, `shadow/unknown devices`, `secure disposal data destruction` (→ NaviOpsSec)

---

## Lesson Status
- [ ] §8 lab completed (discovery collect + build register + reconcile drill + disposal + asset_collect.ps1)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 28 — Documentation & Knowledge Bases**
(Module H).

---

*Lesson 27 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+ 220-1102
(asset mgmt/disposal/procedures), ITIL 4 service configuration management (CMDB).*
