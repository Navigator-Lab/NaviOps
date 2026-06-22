# Lesson 17 — ITIL Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the service-management vocabulary every IT employer expects — **ITIL 4**: the difference
between **Incident, Service Request, Problem, and Change**; **SLAs**; the **service value** idea; and
the handful of practices a help-desk tech actually uses. This is the framework that names everything
L01–L16 has been doing.
**Primary artifact:** the "incident vs request vs problem vs change" decision runbook.

> **How to use this lesson:** read §1–§7, do §8 (classify real tickets correctly), produce §9, take the
> quiz, reflect. Then Lesson 18.

---

## §1 — Concept (Theory)

### What it is
**ITIL** (IT Infrastructure Library), current version **ITIL 4**, is the most widely adopted framework
for **IT Service Management (ITSM)** — a common language and set of **practices** for delivering and
supporting IT services. For a support tech, the essential core is: classify work correctly (**incident /
service request / problem / change**), understand **SLAs**, and grasp that IT exists to **co-create
value** for the business (not just "fix computers").

### Why it matters for support
Employers use ITIL terms constantly and expect you to speak them: "is this an incident or a request?",
"raise a problem record", "that needs a change". Using the right term routes work to the right process
and SLA, and signals professionalism in interviews. ITIL is the **map's legend** — it names the things
you've been doing since Lesson 01.

### Three-Level Depth (Lens A)
- **Level 1 — User:** doesn't know or care about ITIL — they just want help. (Good ITIL is invisible to
  them.)
- **Level 2 — Technician:** classify every ticket correctly — **Incident** (something's broken, restore
  service), **Service Request** (a standard, pre-approved "please give/do X"), **Problem** (the root
  cause behind recurring incidents), **Change** (a controlled modification to the environment) — and
  work within the **SLA**.
- **Level 3 — Engineer/Process:** ITIL 4 frames IT as a **Service Value System** delivering value
  through the **Service Value Chain**, guided by principles (e.g. *focus on value*, *start where you
  are*, *progress iteratively*, *keep it simple*), across **four dimensions** (organizations & people,
  information & technology, partners & suppliers, value streams & processes), implemented via
  **practices** (incident, service request, problem, change enablement, service desk, etc.). Knowing
  this is *why* incidents and problems are separated (restore fast vs fix permanently) and why changes
  are controlled (blast-radius management).

### Two Teaching Approaches (Lens B) — the four record types
**Approach 1 (technical):** the four are distinct by **intent and process**: an **Incident** is
unplanned disruption → goal: **restore service fast** (workaround OK); a **Service Request** is a
routine, pre-approved ask → goal: **fulfill consistently**; a **Problem** is the **underlying cause** of
one/many incidents → goal: **eliminate recurrence** (root-cause, L32); a **Change** is an addition/
modification/removal in the environment → goal: **do it safely** (assess risk, pilot, rollback). They
have different SLAs, owners, and workflows.

**Approach 2 (analogy):** think **plumbing**. A burst pipe flooding the kitchen *right now* is an
**Incident** — you shut the valve to **restore** normality fast (a workaround), even before you know
why. "Please install a new faucet" is a **Service Request** — routine, pre-approved. Discovering the
pipes keep bursting because of bad pressure is the **Problem** — fix the pressure so it stops recurring.
Re-plumbing the house is a **Change** — planned, risk-assessed, with the water shut off in a controlled
window and a way to undo it. **Where it breaks down:** real tickets can shift type — an incident can
reveal a problem, whose fix is a change — so classification is a routing decision, not a permanent
label.

### Visual (ASCII) — the four record types & how they relate
```
   INCIDENT  (unplanned disruption)  ── restore service fast (workaround) ── SLA: resolution time
       │ recurs / shares a cause
       ▼
   PROBLEM   (root cause of incidents) ── investigate (RCA, L32) ── find permanent fix
       │ permanent fix requires modifying the environment
       ▼
   CHANGE    (controlled modification)  ── assess risk · pilot · schedule · rollback (L26) ── change-enablement

   SERVICE REQUEST (routine pre-approved "give/do X") ── fulfill consistently ── e.g. new laptop, access, software
```

---

## §2 — Tools & Commands

ITIL is a framework, so the "toolkit" is the vocabulary + where each concept lives in your work:

| ITIL concept | Plain meaning | Where you've used it |
|---|---|---|
| **Incident** | something's broken → restore | most troubleshooting lessons (L08/10/13…) |
| **Service Request** | routine pre-approved ask | onboarding/access/software (L20/07/25) |
| **Problem** | root cause of incidents | recurring issues → L32 (RCA) |
| **Change** | controlled environment modification | patching/deployments → L26 |
| **SLA** | agreed time/quality target | every ticket (L15/L16) |
| **Service desk** | the practice you operate | L15/L16 |
| **Known error / workaround** | documented temp fix for a problem | KB (L28) |
| **CMDB / configuration item** | record of assets/services | asset mgmt (L27) |
| **Continual improvement** | measure → improve loop | L16 metrics → action |

---

## §3 — Real-World Support Context & Use Cases

- **Right classification = right process + SLA.** Logging a "please add me to a group" as an *incident*
  (with an urgent restore SLA) or a real outage as a *request* both break the desk. Classify correctly.
- **Incident vs Problem is the big one:** you **restore** the user now (incident) *and*, if it recurs,
  raise a **problem** so it's permanently fixed (L32). Mature desks separate "make it work again" from
  "make it stop happening."
- **Change discipline protects everyone:** anything affecting more than one user (a patch, a GPO, a mail
  rule) goes through **change enablement** — risk assessed, piloted, scheduled, with rollback (L26). A
  cowboy change that breaks the fleet is a career event.
- **SLAs are commitments:** response and resolution targets per priority; service requests have
  fulfillment targets. Knowing them shapes your prioritization (L16).
- **Interview value:** fluently using incident/request/problem/change and explaining incident-vs-problem
  marks you as a professional, not a button-pusher.
- **Exam framing:** **ITIL 4 Foundation** maps directly; A+ touches change/documentation/operational
  procedures.

---

## §4 — Demonstration (worked walkthrough)

**Watch me classify a batch of incoming tickets correctly** (the core ITIL skill):

| Ticket | Classification | Why + the right process |
|---|---|---|
| "I can't log in, account locked" | **Incident** | unplanned disruption → restore (unlock, L21), resolution SLA |
| "Please set up the new hire starting Monday" | **Service Request** | routine, pre-approved → fulfill (onboarding, L20) |
| "Email bounced for several users 3 days in a row" | **Incident(s) → Problem** | restore each, but raise a **Problem** (recurring → RCA, L32) |
| "We need to deploy the new VPN client to all laptops" | **Change** | affects the fleet → change-enablement (pilot/rollback, L26) |
| "Can I get Adobe installed?" (standard catalog) | **Service Request** | pre-approved standard → fulfill (L25) |
| "The whole office lost internet" | **Incident (Major)** | wide disruption → major-incident process (L31) |

Then I set each ticket's type/category/priority + SLA accordingly in the tool (L15) — so routing,
reporting, and the clock all behave.

The point: ITIL gives you a **fast, consistent classification** that decides the process, the owner, and
the SLA — before you do any technical work.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: misclassification & process gaps (the ITIL-shaped problems a desk hits).**

### 1 · Symptoms
Requests logged as incidents (or vice-versa) · recurring incidents never permanently fixed · changes
made with no assessment/rollback (and breaking things) · SLA confusion · "we keep firefighting the same
thing."

### 2 · Possible Causes (most-likely first)
1. **Incident vs request confusion** → wrong SLA/process.
2. **No problem management** → recurring incidents firefought forever (L32 gap).
3. **No change control** → uncontrolled changes cause incidents (L26 gap).
4. **SLA not understood** → wrong prioritization (L16).
5. **No continual-improvement loop** → metrics ignored.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Is it broken or a routine ask? | broken→Incident; ask→Request | set the right type/SLA |
| 2 | Has this incident recurred? | yes | raise a **Problem** (L32) |
| 3 | Does the fix modify the environment for many? | yes | route as a **Change** (L26) |
| 4 | Is the SLA right for the type/priority? | mismatched | correct it (L15/16) |
| 5 | Are metrics driving any improvement? | no | start the CI loop (L16) |

### 4 · Resolution Steps
Reclassify to the correct record type (incident/request/problem/change) and SLA; raise **problem
records** for recurring incidents and pursue RCA (L32); route environment-modifying fixes through
**change enablement** with pilot + rollback (L26); align SLAs to priority (L16); establish the
measure→improve loop (continual improvement).

### 5 · Escalation Criteria
Escalate to **process owners / service-desk management** for: defining/adjusting SLAs, standing up
problem or change management, and CMDB/asset-process decisions. Major incidents follow the **major
incident** process (L31). This is organizational/process scope, not a single ticket.

### 6 · Post-Incident Documentation
Correct record type + SLA on the ticket; problem records + known-error/workaround in the KB (L28);
change records with assessment/rollback (L26); continual-improvement notes from metrics (L16).

---

## §6 — Ticket Simulation

> **Ticket ENT-17 / scenario (P2 meta):** *The "floor printer offline" issue (L10) has now happened
> five times this month, each time fixed by a spooler reset. A manager asks "why does this keep
> happening?" and separately requests that the printer be replaced.* Classify and route this correctly.

**Triage (the ITIL skill):** there are **three distinct ITIL records** hiding in here — don't conflate
them.

**Worked resolution:**
1. **The recurrences are Incidents that signal a Problem:** each offline event was an **Incident**
   (restored via spooler reset, L10). Five recurrences with a shared cause = raise a **Problem record**
   (L32) — the goal shifts from "restore again" to "make it stop."
2. **Investigate the Problem (RCA, L32):** root cause = the printer reboots after-hours and gets a new
   DHCP IP (L09), so Windows points at the wrong address → "offline." The **known error + workaround**
   (spooler reset / re-add by IP) goes in the KB while the permanent fix is pending.
3. **The permanent fix is a Change:** assigning a **DHCP reservation** (or static IP) to the printer
   modifies the environment → route as a **Change** (L26): assess (low risk), schedule, implement,
   verify, with rollback (revert the reservation).
4. **The replacement is a separate Service Request:** "replace the printer" is a routine, (likely)
   pre-approved **Service Request** (procurement + install, L25/L27) — fulfill it on its own track; it
   may even make the problem moot, but classify it correctly regardless.
5. **Close the loop:** the Problem is resolved when the reservation (Change) is in place and the offline
   incidents stop; communicate the root cause to the manager (answers "why does this keep happening?").

**The professional note (Problem record):**
```
SUMMARY: Recurring "PRT-FLOOR2 offline" (5 incidents/month) raised as a Problem. RCA: printer reboots
after-hours → new DHCP IP → Windows points at stale address. Permanent fix = DHCP reservation (raised
as a Change). Separate Service Request to replace the printer is tracked independently.
TYPE: Problem (parent of INC-0307, INC-0308, +3 prior) → Change (DHCP reservation) + Service Request
(printer replacement).
ROOT CAUSE (L32): no DHCP reservation → IP changes on reboot → spool port stale → "offline".
WORKAROUND (known error, KB-0006): spooler reset / re-add by current IP (interim only).
PERMANENT FIX: Change CHG-xxxx — assign DHCP reservation for PRT-FLOOR2 (low risk, off-hours window,
rollback = remove reservation). RESULT: offline incidents stop.
FOLLOW-UP: close Problem on 2 weeks no recurrence; Service Request REQ-xxxx (replacement) tracked
separately.
```

---

## §7 — Service Desk / ITIL Perspective

- **This lesson names the whole platform's practices:** L15/L16 = the **service desk** practice; the
  troubleshooting lessons = **incident management**; L20/07/25 = **service request management**; L31 =
  **major incident**; L32 = **problem management**; L26 = **change enablement**; L27 = **service
  configuration (CMDB)**; L28 = **knowledge management**.
- **Incident vs Problem is the defining ITIL insight for a desk:** restore now (incident) *and*
  eliminate recurrence (problem) are different jobs with different goals — confusing them means you
  firefight forever.
- **Change enablement = blast-radius control** (ties directly to patching, L26, and the danger zones in
  `navi.project.md`): assess, pilot, schedule, rollback.
- **SLAs + continual improvement** are how the desk is held accountable and gets better over time
  (L16).
- **Right-classification is a service act:** it gets the user the right process and the right SLA.

---

## §8 — Practical Lab (build this yourself)

**Goal:** classify fluently and build the decision aid you'll use forever.

### Lens C — Manual → Automation → Why
- **Manual:** decide each ticket's type/SLA by judgment.
- **Automated:** ITSM tools encode ITIL — **request types/catalogs** (service requests),
  **incident/problem/change record types** with their own workflows + SLA policies, and automation that
  routes by type (L15/L33).
- **Why:** encoding the framework in the tool makes correct classification + the right SLA the default,
  not a per-tech decision; reporting by type reveals where the pain is (lots of incidents from one
  source → a problem to raise).

### Steps
1. **Classify a batch:** take 12 tickets from `docs/tickets/INDEX.md` and label each Incident / Service
   Request / Problem / Change — justify each in one line.
2. **Find the hidden Problem:** spot the recurring incidents in the library (e.g. repeated
   lockouts/printer-offline) and write the Problem record that should be raised (links L32).
3. **Find the Change:** identify a fix that modifies the environment for many (e.g. the DHCP
   reservation, a GPO, a patch) and outline its change record (assess/pilot/schedule/rollback — links
   L26).
4. **SLA map:** for each priority P1–P4, note a reasonable response + resolution target (the desk's SLA
   model).
5. **Write the decision runbook** (`docs/runbooks/itil-classification.md`): the flowchart/table to
   classify any ticket in seconds.

### Lens D — the raw artifact (one situation, four ITIL records)
```
   "The floor printer keeps going offline and we want it replaced"
     ├─ INCIDENT(s):  each offline event → restore (spooler reset, L10)            [resolution SLA]
     ├─ PROBLEM:      5 recurrences, shared cause → RCA (L32) → known error+workaround
     ├─ CHANGE:       DHCP reservation = permanent fix that modifies environment (L26) [pilot+rollback]
     └─ SERVICE REQ:  "replace the printer" = routine pre-approved fulfillment (L25/27)
#   Mature support sees FOUR records here, not "a printer ticket." That separation IS ITIL — and it's
#   what stops endless firefighting.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/itil-classification.md` — the incident/request/problem/change decision
   aid + an SLA-target table.
2. **Troubleshooting Guide:** `docs/troubleshooting/misclassification-process-gaps.md` — the meta spine.
3. **Ticket Notes:** the classified batch + the printer Problem record (`docs/tickets/ENT-17-printer-
   problem.md`).
4. **KB Article:** `docs/kb/` — "Incident vs Service Request vs Problem vs Change (with examples)" for
   the team.
5. **Incident Report:** N/A (process lesson); the Problem record + the linked Change *are* the artifacts.
6. **Portfolio Artifact:** §10 bullet + the incident-vs-problem + four-records talking points.
7. **Reference:** the SLA model table + the ITIL-practice → lesson map (§7).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Applied ITIL 4 service management on a service desk: correctly classifying
  incidents, service requests, problems, and changes; raising problem records to eliminate recurring
  incidents; and routing environment changes through change enablement with rollback."*
- **Interview talking point:** **incident vs problem** (restore fast vs eliminate the cause) and **the
  four record types** — be able to take one messy situation (the recurring printer) and split it into
  incident/problem/change/request. This single answer marks you as professional.
- **Serves:** all service-desk roles; foundational for Junior SysAdmin (change/problem ownership).

---

## §11 — Certification Crossover Notes

- **ITIL 4 Foundation:** the entire lesson maps here — SVS, value chain, the four dimensions, guiding
  principles, and the incident/request/problem/change/service-desk practices.
- **CompTIA A+ (Core 2):** change management, documentation, operational procedures. Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** ITIL exists to **co-create value for the user/business**, not to add bureaucracy — the
*focus-on-value* and *keep-it-simple* principles mean classification and process should speed help, not
slow it. Good ITIL is invisible to the user; they just get the right help on the right timeline.

**🔒 Security:** **change enablement is a security control** — uncontrolled changes are a top cause of
both outages *and* vulnerabilities (an un-assessed change can open a hole). Security incidents follow the
**incident/major-incident** process too (L29/L31), and the **CMDB/asset records** (L27) are essential to
security (you can't protect what you don't know you have). Emergency security fixes still get a (fast)
change record, not a cowboy edit.

---

## Quiz (Interview-Style, Graded)

**Q1.** Define Incident, Service Request, Problem, and Change in one line each, with an example.
> **Your answer:**

**Q2.** What's the difference between incident management and problem management, and why separate them?
> **Your answer:**

**Q3.** A fix will be deployed to every laptop in the company. Which ITIL practice governs that, and
what must it include?
> **Your answer:**

**Q4.** **Scenario:** the same issue has caused incidents five times this month. Walk me through how
ITIL says to handle it — including the records you'd raise.
> **Your answer:**

**Q5.** What is an SLA, and how does it shape how you work the queue?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `ITIL 4 incident service request problem change`
- `incident management vs problem management`
- `ITIL change enablement basics`
- `ITIL service value system value chain`
- `SLA OLA service level agreement basics`

**Tools**
- `ITIL 4 guiding principles`
- `known error workaround`

**Going further**
- `active directory fundamentals` (L18) · `patch management / change` (L26) · `asset management / CMDB`
  (L27) · `incident management` (L31) · `root cause analysis / problem` (L32)

**Service / Security (Lens E):**
- 🤝 `ITIL focus on value keep it simple`
- 🔒 `change enablement as security control`, `CMDB for security`, `security incident process`

---

## Lesson Status
- [ ] §8 lab completed (classify a batch + Problem record + Change outline + SLA map + decision runbook)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 18 — Active Directory Fundamentals**
(Module F — the lab stack comes online here).

---

*Lesson 17 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: ITIL 4 Foundation
(AXELOS/PeopleCert), CompTIA A+ 220-1102 (change/operational procedures).*
