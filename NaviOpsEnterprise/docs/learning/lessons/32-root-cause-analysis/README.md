# Lesson 32 — Root Cause Analysis

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** finding and fixing the **real cause** so an incident never recurs — **problem management** +
the techniques (**5 Whys**, **fishbone/Ishikawa**), evidence/timeline, **blameless** analysis, and
writing an **RCA** with **corrective + preventive actions** that actually stick. This is the
"make-it-stop-happening" counterpart to incident management (L31).
**Primary artifact:** the RCA report (using the L0 template) + the problem-record runbook.

> **How to use this lesson:** read §1–§7, do §8 (write a real RCA from a prior incident), produce §9,
> take the quiz, reflect. Then Lesson 33.

---

## §1 — Concept (Theory)

### What it is
**Root Cause Analysis (RCA)** is the structured investigation that finds the **underlying cause** of an
incident (or recurring incidents) so it can be **permanently eliminated** — the heart of ITIL **problem
management** (L17). Where **incident management restores service fast** (L31), problem management/RCA asks
**why did it happen and how do we prevent it.** Techniques: **5 Whys** (keep asking "why" past the
symptom), **fishbone/Ishikawa** (categorize causes — People/Process/Technology/Environment), evidence +
**timeline** (from the incident, L31), all done **blamelessly** (fix the system, not the person). Output:
a **root cause** + **corrective** (fix this instance) and **preventive** (stop recurrence) actions, with
owners and a way to verify the fix held.

### Why it matters for support
Without RCA, you **firefight forever** — the same incidents recur (the recurring printer L10/L17, the
repeated lockouts L21, the post-patch BSODs L26, the DC disk-full L22) because only the symptom was
treated. RCA is what turns a mature desk from reactive to **preventive** (the L16 continual-improvement
engine): each well-analyzed incident **removes future tickets**. It's also a senior, high-value skill —
writing an RCA that prevents recurrence is what distinguishes a problem-solver from a button-pusher.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "you keep fixing it but it keeps happening — *why*?" (they want it to stop, not be
  re-fixed).
- **Level 2 — Technician:** recognize a **recurring incident** → raise a **problem record**; investigate
  past the symptom (5 Whys), find the real cause, propose corrective + preventive fixes (often a **change**
  — L26).
- **Level 3 — Engineer/Problem-owner:** RCA uses evidence (incident timeline L31, logs/Event IDs, the
  scripts' data from prior lessons) + technique (5 Whys / fishbone) to reach a **true root cause** (not
  "human error" as a stopping point — ask *why the system allowed* the error); documents a **known error
  + workaround** while the permanent fix is implemented (as a **change**, L26); and **verifies** the fix
  via a metric/monitor. This is *why* RCA is blameless (blame stops the analysis at "person X messed up"
  and hides the systemic cause) and *why* it feeds change + monitoring.

### Two Teaching Approaches (Lens B) — past the symptom, blamelessly
**Approach 1 (technical):** RCA separates **symptom** from **root cause** by structured questioning (**5
Whys**) or causal categorization (**fishbone**), grounded in **evidence** (timeline, logs, data). The
analysis is **blameless** (targets the system/process, not individuals) and produces **corrective**
(remediate) + **preventive** (eliminate recurrence) actions with owners + a verification of effectiveness.
It converts a recurring incident into a one-time fix.

**Approach 2 (analogy):** RCA is **diagnosing a leak, not just mopping the floor.** Incident management
mops up the water (restores service); RCA finds *why the pipe leaks* (the root cause) and fixes the pipe
so you stop mopping forever. The **5 Whys** is asking past the puddle: *why is there water? (pipe leaks) →
why? (joint corroded) → why? (wrong material) → why? (no spec) → why? (no procurement standard)* — the
real fix is the **standard**, not the puddle. And you don't blame the person who installed the pipe — you
fix the **process** that let the wrong material be used. **Where it breaks down:** not every "why" chain
is linear (multiple contributing causes) — that's when **fishbone** (categorize across People/Process/
Tech/Environment) fits better than a single 5-Whys thread.

### Visual (ASCII) — incident vs problem, and the 5 Whys
```
   INCIDENT MGMT (L31): mop the water — RESTORE service fast (workaround)
        │ recurs / shares a cause
        ▼
   PROBLEM MGMT / RCA (this lesson): find why it leaks — ELIMINATE the cause

   5 WHYS (past the symptom):
     "DC disk filled → logon failed" (symptom, L22)
       why full? → a debug log grew unbounded
         why unbounded? → log rotation wasn't configured + no disk monitoring
           why? → no standard for enabling debug logging / no monitoring baseline
             → ROOT CAUSE: missing operational standard (logging + monitoring), NOT "the tech who left it on"
   OUTPUT: root cause + CORRECTIVE (fix this DC) + PREVENTIVE (logging standard + disk alerting) + VERIFY
   ...implement the permanent fix as a CHANGE (L26).  BLAMELESS throughout.
```

---

## §2 — Tools & Commands

RCA is a thinking discipline; the "toolkit" is technique + evidence + the record:

| Element | What it is | Source / links |
|---|---|---|
| **Problem record** | the tracked investigation (vs the incident) | ITSM (L15/L33) |
| **5 Whys** | iterative "why" past the symptom | this lesson |
| **Fishbone/Ishikawa** | cause categories: People/Process/Tech/Environment | this lesson |
| **Evidence** | the incident **timeline** (L31), logs/**Event IDs** (L03), script data | L31/L03/L18-27 |
| **Known error + workaround** | documented temp fix while permanent fix lands | KB (L28) |
| **Corrective vs preventive actions** | fix instance vs stop recurrence (owners + due) | RCA template (L0) |
| **Permanent fix** | usually a **change** (assess/pilot/rollback) | L26/L17 |
| **Verify effectiveness** | the metric/monitor that proves it held | L16 |

> Tools: your ITSM tracks the **problem record** (L15/L33); the **RCA template** (`docs/templates/rca.md`)
> structures the analysis. This lesson is the method, executed with those.

---

## §3 — Real-World Support Context & Use Cases

- **Recurring incidents = the trigger:** the printer that offlines weekly (L10/L17), repeated lockouts
  (L21), post-patch BSODs across a model (L26), the DC disk-full (L22), a ransomware entry (L29/L30) —
  each should spawn a **problem record + RCA**, not endless re-fixing.
- **RCA is the continual-improvement engine (L16):** metrics reveal the recurring pain → RCA finds the
  cause → corrective+preventive actions remove future tickets → measure again. The single biggest lever
  for reducing volume.
- **Blameless is non-negotiable** (shared with L29/L31): blame ends the analysis at "person X" and hides
  the systemic cause (and makes people hide incidents). RCA targets the **system/process**.
- **The permanent fix is usually a change (L26):** preventive actions (a DHCP reservation, a logging
  standard, monitoring, a process change) go through change enablement (L17).
- **Verification closes the loop:** an RCA isn't done at "root cause found" — it's done when the preventive
  action is implemented **and proven** (the incident stops recurring).
- **Exam framing:** ITIL (problem management — L17), A+ (documentation/RCA in operational procedures).

---

## §4 — Demonstration (worked walkthrough)

> **Problem PRB-0001 (from the L22 incident ENT-22):** *DC01 filled its disk and caused company-wide logon
> failures (a P1 major incident, L31). It was restored — now find the root cause so it never recurs.*

1. **Open a problem record:** the incident is restored (L31); the **why** is a separate, tracked
   **problem** (PRB-0001) — don't close it at "we freed the disk."
2. **Gather evidence:** the incident **timeline** (L31), `Get-Volume` history, what consumed the disk
   (the `Get-ChildItem`/log finding from L22), Event logs (L03), and the change history (L26 — was logging
   enabled by a recent action?).
3. **5 Whys (past the symptom):**
   - Logon failed → *why?* the DC ran services off a full disk.
   - Disk full → *why?* a DNS debug log grew unbounded.
   - Unbounded → *why?* log rotation wasn't configured + debug logging was left enabled.
   - Left enabled / no rotation → *why?* no standard for debug logging + **no disk-space monitoring** on
     DCs.
   - → **Root cause:** a **missing operational standard** (controlled debug logging + monitoring baseline)
     — *not* "the tech who left it on" (blameless: the system allowed it).
4. **Known error + workaround (L28):** document "DC disk fills from unrotated debug log → clear log + free
   space" as the interim workaround while the permanent fix lands.
5. **Corrective + preventive actions:** **corrective** — disable the debug logging / configure rotation on
   DC01; **preventive** — add **disk-space monitoring/alerting** on all DCs (fix the *class*, not just
   DC01), add a logging standard, add headroom. Implement the changes via **change enablement** (L26/L17).
6. **Verify effectiveness:** the monitor now alerts at 80% (before outage); no DC disk-full recurs over the
   next period → the RCA is **closed**.

The teaching point: **restore (L31) ≠ resolve the cause.** RCA asks "why" past the symptom (blamelessly,
with evidence), fixes the **class** of problem (all DCs, via monitoring + standard), implements it as a
**change**, and **verifies** the fix held — so you stop firefighting it.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: doing RCA well (diagnosing weak/failed root-cause analysis).**

### 1 · Symptoms
The same incident keeps recurring (firefighting) · "fixed" but it's back next week · RCA stops at "human
error" / blames a person · root cause vague/unverified · preventive actions never implemented or not
proven · no problem record (recurrence not tracked).

### 2 · Possible Causes (most-likely first)
1. **No problem record** — recurrence isn't tracked, so it's re-fixed each time.
2. **Stopped at the symptom** (treated the puddle, not the pipe) — no real 5 Whys.
3. **Blame instead of system analysis** — "human error" ends the investigation; cause hidden.
4. **No evidence** — guessed the cause (no timeline/logs/data).
5. **Preventive actions not implemented** (no change/owner) — RCA written, nothing changed.
6. **Not verified** — assumed fixed; it recurs.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Is recurrence tracked as a problem? | no | raise a **problem record** |
| 2 | Did the analysis reach a true root cause (5 Whys)? | stopped at symptom | keep asking "why" |
| 3 | Did it stop at "human error"/blame? | yes | ask *why the system allowed it* (blameless) |
| 4 | Is the cause evidence-based? | guessed | ground in timeline/logs/data (L31/L03) |
| 5 | Are preventive actions owned + implemented (change)? | no | assign + implement via change (L26) |
| 6 | Was effectiveness verified? | no | add a metric/monitor; confirm no recurrence |

### 4 · Resolution Steps
Raise a **problem record**; investigate past the symptom (**5 Whys / fishbone**) grounded in **evidence**;
keep it **blameless** (fix the system); document a **known error + workaround** (L28); define **corrective
+ preventive actions** with **owners + due dates**; implement the permanent fix as a **change** (L26/L17);
**verify** via a metric/monitor; close the problem only when recurrence stops.

### 5 · Escalation Criteria
Escalate to the **problem owner / engineering / vendor** for: root causes needing engineering or vendor
fixes (a product bug, a design flaw), cross-team preventive actions, and changes with broad blast radius
(L26). Security root causes → **security/NaviOpsSec** (L29). The desk **raises** the problem + does first-
level RCA; deep/engineering RCA may be owned elsewhere. Attach: the incident timeline, evidence, the
5-Whys/fishbone.

### 6 · Post-Incident Documentation
The **RCA report** (`docs/templates/rca.md` — problem statement, timeline, 5 Whys/fishbone, root cause,
contributing factors, corrective + preventive actions, verification), the **known error + workaround** in
the KB (L28), the **change records** for preventive fixes (L26), and the **verification** result. This is
the centerpiece artifact and the proof the desk learns.

---

## §6 — Ticket Simulation

> **Problem ENT-32 / PRB-0002 (from L26/ENT-26):** *the fleet bad-patch incident (dozens of laptops
> BSOD'd after a patch, restored by rollback) is over — write the RCA so a bad patch never reaches the
> fleet again.*

**Triage:** the **incident** was restored (L31 — paused + rolled back); now the **problem** is "why did a
fleet-breaking patch reach the broad ring?" Write a real RCA with preventive actions that change the
**process**, blamelessly.

**Worked RCA:**
1. **Open the problem record (PRB-0002)** linked to the incident (ENT-26) and the duplicate tickets.
2. **Evidence:** the incident timeline (L31), the bugcheck code + affected model/dock (L24/L26), the patch/
   ring configuration (which ring got it, the soak time), and that the **pilot ring lacked that hardware**.
3. **5 Whys (blameless):**
   - Dozens BSOD'd → *why?* a regressing driver/update reached the broad ring.
   - Reached broad → *why?* the **pilot ring didn't catch it**.
   - Pilot didn't catch it → *why?* the affected **dock/laptop model wasn't represented in the pilot** +
     the **soak period was too short** + no fast **post-patch monitoring**.
   - → **Root cause:** **inadequate pilot-ring coverage + soak + monitoring** (a process gap), *not* "the
     patch admin pushed a bad patch."
4. **Known error + workaround (L28):** "post-patch BSOD on docked <model> → uninstall KB / pause ring"
   (already used in the incident) — documented for any stragglers.
5. **Corrective + preventive actions (owners + due):**
   - **Corrective:** ensure all affected devices are rolled back/patched-clean (done in incident).
   - **Preventive (the real fix, via change — L26):** expand the **pilot ring** to cover representative
     hardware (incl. the dock/model); **lengthen the soak**; add **post-patch BSOD/health monitoring**
     (catch regressions in the pilot fast); document the **patch deployment standard** (L26).
6. **Verify effectiveness:** next patch cycle — a regression (if any) is caught in the pilot ring and never
   reaches broad; monitor BSOD rate post-patch. Close PRB-0002 when proven.

**The professional RCA (excerpt — uses the L0 template):**
```
RCA — PRB-0002  (Fleet bad-patch BSOD; related incident INC/ENT-26)
Problem statement: A regressing cumulative update caused fleet-wide BSOD on docked <model> laptops; it
reached the broad ring because the pilot ring didn't catch it.
Timeline: (from L31 incident) patch night → morning BSOD flood → declared MI → paused ring + rolled back →
restored. [details in the incident report]
5 Whys → Root cause: inadequate PILOT-RING coverage (missing dock/model) + too-short soak + no post-patch
health monitoring — a PROCESS gap (blameless; not the admin's fault).
Contributing factors: dock-driver interaction; broad-ring deferral too aggressive.
Corrective actions: confirm all affected devices clean (owner: desktop team, done).
Preventive actions (via Change, L26):
  - Expand pilot ring to representative hardware incl. dock/model (owner: patch team, due <date>)
  - Lengthen soak period to N days before broad ring (owner: patch team, due <date>)
  - Add post-patch BSOD/health monitoring + alert (owner: monitoring, due <date>)
  - Document the patch-deployment standard (owner: lead, due <date>)
Verification: next cycle — no regression reaches broad ring; post-patch BSOD rate baseline. Close on 1
clean cycle.
```

---

## §7 — Service Desk / ITIL Perspective

- **RCA = ITIL problem management** (L17), the partner to incident management (L31): **incident restores;
  problem prevents.** A mature desk runs both — restore fast, then kill the cause.
- **It's the continual-improvement engine (L16):** metrics surface recurring pain → RCA → preventive
  action → fewer future tickets. The single most effective way to reduce volume and raise FCR over time.
- **Blameless culture** (with L29/L31): the analysis targets the **system/process**; blaming individuals
  hides root causes and discourages reporting. "Human error" is a *starting* point ("why did the system
  allow it?"), never the conclusion.
- **Preventive actions are changes (L26/L17):** the fix that stops recurrence usually modifies the
  environment/process → change-controlled, owned, and **verified**.
- **Metric/risk angle:** recurrence rate (did the RCA work?), problem backlog, and the volume reduction
  from preventive actions are the measures; un-analyzed recurrence is a tracked operational risk.

---

## §8 — Practical Lab (build this yourself)

**Goal:** write a real, verifiable RCA from a prior incident — past the symptom, blameless, with owned
preventive actions.

### Lens C — Manual → Process → Why
- **Manual:** "we think it was X" (a guess, no record, no follow-through).
- **Systematized:** a **problem record** in the ITSM (L33), the **RCA template** (structure), a **known-
  error/workaround** in the KB (L28), preventive actions tracked as **changes** with owners (L26), and a
  **verification** step — so RCAs actually change reality.
- **Why:** an RCA that isn't tracked + implemented + verified is just a document; the process (problem
  record → owned actions → change → verify) is what converts analysis into fewer future incidents (the
  L16 loop).

### Steps
1. **Pick a recurring/major incident** from this platform (DC disk-full L22/ENT-22, repeated lockouts
   L21/ENT-21, fleet bad-patch L26/ENT-26, ransomware L29-30/ENT-30) and **open a problem record**.
2. **Gather evidence:** the incident timeline (L31), logs/Event IDs (L03), and the relevant script data
   (e.g. patch_status, server_health) — ground it, don't guess.
3. **Run the 5 Whys** past the symptom; if causes are multiple, draw a **fishbone** (People/Process/Tech/
   Environment). **Stay blameless** — for any "human error," ask *why the system allowed it.*
4. **Write the RCA** (`docs/templates/rca.md`): problem statement, timeline, 5 Whys/fishbone, **root
   cause**, contributing factors, **corrective + preventive actions (owners + due)**, **verification**.
5. **Document the known error + workaround** (L28) and note the preventive fixes as **changes** (L26).
6. **Define verification:** the exact metric/monitor that proves recurrence stopped (the close condition).
7. **Write the problem-record runbook** + your completed **RCA** as the artifacts.

### Lens D — the raw artifact (the 5 Whys reaches the systemic cause)
```
   5 WHYS — repeated account lockouts (from L21/ENT-21):
     symptom: rkhan's account locks repeatedly
       why? a device keeps submitting his OLD password (Event 4740 → RKHAN-IPHONE)
         why? his phone's mail app wasn't updated after his password reset
           why? users aren't reminded to update saved passwords after a reset
             why? the reset process/KB doesn't include + enforce that step
   → ROOT CAUSE (systemic, blameless): the reset PROCESS omits "update saved credentials on all devices"
   PREVENTIVE (not just "unlock again"): add the step to the reset runbook + KB-0002 + SSPR guidance (L21)
#   Note how the chain moves from a SYMPTOM (locks) past the immediate cause (stale phone cred) to a
#   PROCESS gap (the reset procedure) — and the fix changes the PROCESS, removing future lockouts. That's
#   RCA, not re-unlocking.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/problem-rca.md` — raise problem → evidence → 5 Whys/fishbone → root cause →
   corrective+preventive (as changes) → verify.
2. **Troubleshooting Guide:** `docs/troubleshooting/weak-rca.md` — the meta spine (the §5 failure modes).
3. **Ticket Notes:** the problem record (`docs/tickets/ENT-32-rca-bad-patch.md`) linked to its incident.
4. **KB Article:** `docs/kb/` — the **known error + workaround** for the analyzed problem (L28).
5. **Incident Report / RCA:** the **RCA report** (the centerpiece — `docs/templates/rca.md`).
6. **Portfolio Artifact:** §10 bullet + the 5-Whys / blameless / verify-the-fix talking points.
7. **Template:** the RCA (L0) + a problem-record convention.

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Performed root cause analysis (5 Whys / fishbone) on recurring and major incidents,
  authoring blameless RCAs with owned corrective and preventive actions implemented through change
  enablement — eliminating recurring ticket sources (e.g. DC disk-full, post-patch regressions) and
  verifying the fixes held."*
- **Interview talking point:** **incident vs problem** (restore vs prevent), the **5 Whys past the
  symptom**, **blameless** analysis ("ask why the system allowed the human error"), and that an RCA isn't
  done until the preventive action is **implemented + verified** (recurrence stops). Walk through an RCA
  end-to-end.
- **Serves:** Junior SysAdmin, Infrastructure Support, and a senior/lead path (the preventive-thinking
  skill).

---

## §11 — Certification Crossover Notes

- **ITIL 4 Foundation:** problem management (root cause, known error, workaround) — central (L17).
  **CompTIA A+ (Core 2):** documentation/RCA within operational procedures. Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** RCA is service *for the future* — it stops users hitting the same problem repeatedly
(which they experience as "IT can't actually fix things"). Communicating "we found the root cause and here's
what prevents it" builds far more trust than another quick re-fix.

**🔒 Security:** RCA is essential to security — after a security incident (L29/L31), the RCA finds **how the
attacker got in** and drives preventive controls (patching L26, least privilege L07, training L29, MFA),
done **blamelessly** (a phished user is a *contributing factor*, the root cause is the systemic gap that
let one click cause harm). Security RCA depth is the **NaviOpsSec** domain (post-incident/lessons-learned);
this lesson is the on-ramp. Preserve evidence (L29) so the RCA is grounded, not guessed.

---

## Quiz (Interview-Style, Graded)

**Q1.** What's the difference between incident management and problem management / RCA?
> **Your answer:**

**Q2.** Walk me through the 5 Whys on a recurring problem of your choice — show how you get past the
symptom.
> **Your answer:**

**Q3.** Why must RCA be blameless? What's wrong with stopping at "human error"?
> **Your answer:**

**Q4.** **Scenario:** the same incident keeps recurring even though it's "fixed" each time. What process do
you follow to make it actually stop, and how do you know it worked?
> **Your answer:**

**Q5.** What's the difference between a corrective and a preventive action, and how do preventive actions
usually get implemented?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `root cause analysis 5 whys`
- `fishbone ishikawa diagram cause categories`
- `ITIL problem management known error workaround`
- `blameless postmortem RCA`
- `corrective vs preventive action verify effectiveness`

**Tools**
- `RCA report template`
- `problem record vs incident`

**Going further**
- `jira service management` (L33 — tracking problems) · `incident management` (L31) · `change/patch` (L26) ·
  `ITIL problem management` (L17) · `security RCA` (L29 → NaviOpsSec)

**Service / Security (Lens E):**
- 🤝 `RCA as service for the future`, `communicate the prevention`
- 🔒 `blameless security postmortem`, `RCA finds how attacker got in`, `preventive security controls` (→ NaviOpsSec)

---

## Lesson Status
- [ ] §8 lab completed (open a problem + evidence + 5 Whys/fishbone + write RCA + verification)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 33 — Jira Service Management**.

---

*Lesson 32 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: ITIL 4 problem
management, RCA techniques (5 Whys / Ishikawa), blameless postmortem practice.*
