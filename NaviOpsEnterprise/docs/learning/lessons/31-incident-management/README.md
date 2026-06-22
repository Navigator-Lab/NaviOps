# Lesson 31 — Incident Management

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** running a **major incident** — declaring it, the **incident commander (IC)** role,
**communications**, the **bridge**, building the **timeline**, restoring service, and the handoff to
**problem/RCA** (L32). This is the discipline that turns the "P1 / many-users-down" scenarios from every
prior module (outage, DC disk-full, fleet bad-patch, ransomware) into a coordinated response.
**Primary artifact:** the major-incident runbook + the incident report (using the L0 template).

> **How to use this lesson:** read §1–§7, do §8 (run a simulated major incident end-to-end), produce §9,
> take the quiz, reflect. Then Lesson 32.

---

## §1 — Concept (Theory)

### What it is
**Incident management** (ITIL, L17) is restoring normal service as fast as possible after a disruption.
Routine incidents are the everyday tickets (worked via L16). A **major incident** is a high-impact/high-
urgency disruption (a P1 — many users, a critical service, an outage, a security event) that needs a
**coordinated response**: **declare** it, appoint an **Incident Commander (IC)**, run a **communications**
cadence + a **bridge** (call/chat war-room), assign roles, **restore service** (workaround first — fix
fast, understand later), keep a **timeline**, and hand the *root cause* to **problem management/RCA**
(L32). This lesson is the orchestration layer over all the P1 scenarios you've already met.

### Why it matters for support
Every module produced a P1: the floor outage (L08/ENT-08), the duplicate-storm (L15), the DC disk-full
(L22/ENT-22), the fleet bad-patch (L26/ENT-26), the ransomware (L29/L30/ENT-30). Knowing the *technical*
fix isn't enough under that pressure — without **coordination + communication**, a major incident becomes
chaos (duplicate work, leadership in the dark, no timeline, no learning). The IC discipline is what makes
high-stakes situations survivable and is a hallmark of a mature, senior operator.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "everything's down — is anyone fixing it, and when will it be back?" (they need
  **communication** above all).
- **Level 2 — Technician:** recognize a **major incident** (scope/impact), **declare/escalate** it fast,
  contribute to **restore** (workaround), and feed the **timeline**; don't solo a P1.
- **Level 3 — IC/Engineer:** the **Incident Commander** *coordinates* (doesn't necessarily fix) —
  assembles responders on a **bridge**, assigns roles (comms lead, technical lead, scribe), drives toward
  **service restoration** (workaround over root-cause during the incident), runs a **stakeholder comms
  cadence** (regular updates with next-update time), maintains the **timeline**, declares **resolved** when
  service is restored, then triggers **post-incident review + RCA/problem** (L32). Severity/priority,
  SLAs, and escalation paths are pre-defined. This is *why* "restore first, RCA later" and "communicate on
  a cadence" are the rules.

### Two Teaching Approaches (Lens B) — coordinate, communicate, restore
**Approach 1 (technical):** a major incident is managed by **separating coordination from fixing**: an
**IC owns the response** (roles, decisions, comms, timeline) while technical responders work the fix on a
**bridge**; the goal is **service restoration** (workaround acceptable — root cause comes later via RCA);
**communications** run on a defined cadence to stakeholders; everything is **timestamped** (the timeline);
**resolved** = service restored, then a **post-incident review** drives prevention. It's the same loop as a
single ticket (L01) but scaled, coordinated, and communicated.

**Approach 2 (analogy):** a major incident is a **building fire**. You don't have everyone freelance —
the **fire chief (IC)** coordinates: directs the crews (technical responders), keeps the **command post**
(bridge), updates the **public/press** on a schedule (comms cadence), and logs **what happened when**
(timeline). The immediate goal is **put out the fire / get people safe (restore service)** — *not* to
investigate the cause yet (that's the **fire marshal's report afterward** = RCA, L32). **Where it breaks
down:** unlike a fire, you can often apply a **temporary workaround** (reroute, failover) to restore
service before the root cause is fixed — so "restored" and "permanently fixed" are two distinct
milestones.

### Visual (ASCII) — the major-incident flow
```
   DETECT/REPORT (monitoring or ticket flood — L15) ─▶ DECLARE major incident (scope×impact = P1)
        │
   ASSIGN IC ─▶ assemble BRIDGE + roles (comms · technical · scribe) ─▶ RESTORE service (WORKAROUND first)
        │                                   │
   COMMS CADENCE (regular updates +    TIMELINE (timestamp everything)
    next-update time, single source)        │
        ▼                                   ▼
   SERVICE RESTORED ─▶ declare RESOLVED ─▶ POST-INCIDENT REVIEW ─▶ PROBLEM/RCA (root cause + prevent, L32)
   rule:  RESTORE FIRST (workaround), RCA LATER  ·  COMMUNICATE on a cadence  ·  ONE source of truth (L15 master ticket)
```

---

## §2 — Tools & Commands

Incident management is coordination; the "toolkit" is roles, cadence, and artifacts:

| Element | What it is | Links |
|---|---|---|
| **Severity/Priority** | impact × urgency → is this a major incident (P1)? | L16 matrix |
| **Declare** | formally open a major incident (don't let it simmer) | ITSM (L15/L33) |
| **Incident Commander (IC)** | coordinates the response (not necessarily the fixer) | this lesson |
| **Bridge / war room** | call/chat where responders converge | comms tool |
| **Roles** | IC · comms lead · technical lead · scribe (timeline) | this lesson |
| **Comms cadence** | regular stakeholder updates + next-update time | status page/email |
| **Master ticket** | one source of truth; link duplicates (L15) | ITSM (L15) |
| **Timeline** | timestamped events (detect→actions→restore) | incident report template (L0) |
| **Post-incident review** | blameless review → RCA/problem | L32 |

> Tools: your ITSM (L15/L33) declares/tracks it; the **incident report template** (`docs/templates/
> incident-report.md`) captures it. This lesson is process, executed with those.

---

## §3 — Real-World Support Context & Use Cases

- **Every prior P1 is a major incident:** floor outage (L08), email/service outage + duplicate-storm
  (L15), DC disk-full → logon failure (L22), fleet bad-patch (L26), ransomware (L29/L30). This lesson is
  how you *run* them.
- **The desk detects + declares:** clustered tickets (L15) or a monitoring alert → recognize the major
  incident and **declare fast** (the #1 failure is letting a P1 simmer as scattered tickets).
- **Communication is the deliverable to users/leadership:** during an outage, a regular, honest status
  (with a next-update time) matters as much as the fix — silence breeds panic + duplicate tickets.
- **Restore first, RCA later:** apply a **workaround** to restore service (failover, reroute, roll back —
  L26); the permanent fix/root cause is **problem management/RCA** (L32) *after*.
- **Roles prevent chaos:** IC coordinates, technical lead fixes, comms lead updates, scribe logs — so no
  duplicate work and nothing is lost.
- **Exam framing:** ITIL (incident & major incident management — L17), A+ (incident response/escalation/
  communication procedures).

---

## §4 — Demonstration (worked walkthrough)

> **Scenario INC-0811 (P1):** *email is down org-wide; the queue is flooding with "can't get email"
> tickets (the L15 duplicate-storm, escalated).* You're senior on shift.

1. **Recognize + declare:** many users, critical service, simultaneous → **major incident**. **Declare it
   immediately** (don't let it stay 50 scattered tickets) and check service health (L11/L13).
2. **Assign the IC + roles:** appoint an **Incident Commander** (maybe you) to coordinate; designate a
   **technical lead** (works the fix), a **comms lead** (updates), and a **scribe** (timeline). Open a
   **bridge** (call/chat war-room).
3. **One source of truth (L15):** create the **master ticket** (INC-0811), **link/merge** the duplicates
   to it so the desk + users track one place (stops 50 separate investigations + 50 separate replies).
4. **Restore first (workaround):** technical lead diagnoses (provider outage? on-prem connector? — L13) →
   apply the fastest **restore** (failover/reroute/provider fix), not the perfect root-cause fix.
5. **Communicate on a cadence:** comms lead posts a **status update with a next-update time** ("email
   degraded, we're engaged with the provider, next update 10:30") — to users + leadership, from one
   channel. Update on schedule even if "no change yet."
6. **Timeline as you go:** scribe timestamps every event (detected, declared, action, restored).
7. **Declare resolved when service is restored;** confirm with users; then **trigger the post-incident
   review + RCA** (L32) — *why* did email go down, and how do we prevent it.

The teaching point: under a P1, **coordinate + communicate + restore-first** — the IC separates running
the response from doing the fix, one master ticket is the source of truth, and communication on a cadence
is as important as the technical work.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: managing the major incident itself (the meta — diagnosing a poorly-run response).**

### 1 · Symptoms
A P1 simmering as scattered tickets (not declared) · no one coordinating (responders tripping over each
other) · leadership/users in the dark (no comms) · no timeline (can't reconstruct it) · "fixed" but it
recurs (no RCA) · duplicate work / conflicting actions.

### 2 · Possible Causes (most-likely first)
1. **Not declared** — treated as individual tickets, no coordination (the #1 failure).
2. **No IC / no roles** — chaos, duplicated effort.
3. **No comms cadence** — panic, duplicate tickets, angry leadership.
4. **No master ticket** (L15) — no single source of truth.
5. **Chasing root cause instead of restoring** — service stays down longer.
6. **No post-incident review/RCA** (L32) — it recurs.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Scope×impact = major? | yes | **declare** + assign IC (stop the simmer) |
| 2 | Is there an IC + roles + bridge? | no | appoint IC, assign roles, open bridge |
| 3 | One master ticket + duplicates linked? (L15) | no | create master, link/merge |
| 4 | Comms cadence running? | no | start regular updates + next-update time |
| 5 | Restoring (workaround) vs chasing root cause? | chasing | restore first; RCA later (L32) |
| 6 | Post-incident review scheduled? | no | trigger RCA/problem (L32) |

### 4 · Resolution Steps
**Declare** the major incident; assign an **IC + roles + bridge**; create the **master ticket** + link
duplicates (L15); run a **comms cadence** (regular updates, next-update time, one channel); drive
**service restoration via workaround** (root cause to RCA); keep the **timeline**; declare **resolved**
when restored; **trigger the post-incident review + RCA/problem** (L32).

### 5 · Escalation Criteria
A major incident **is** the escalation — it pulls in technical teams, vendors, **security** (for security
incidents — L29), and **leadership** (for business-impacting outages). The IC escalates for more resources
/ decisions / external comms. Security incidents follow incident management *plus* the security process
(L29/NaviOpsSec). The desk's role: detect, declare, communicate, support restore; senior/IC owns
coordination.

### 6 · Post-Incident Documentation
The **incident report** (timeline, impact, actions, resolution — `docs/templates/incident-report.md`), the
**post-incident review** (blameless: what went well/poorly), and the handoff to **RCA/problem** (L32) for
root cause + preventive actions. This is the centerpiece artifact.

---

## §6 — Ticket Simulation

> **Scenario ENT-31 / INC-0811 (P1, major incident — run it end-to-end):** *9:05am — monitoring alerts +
> a flood of tickets: the primary line-of-business application is down for the entire company. No one can
> work.* You are the **Incident Commander**.

**Run the major incident:**
1. **Declare (9:06):** company-wide, critical app, all users → **P1 major incident**. Declare it; don't
   let it simmer.
2. **Stand up the response (9:08):** open the **bridge**; assign **technical lead** (app/infra team),
   **comms lead**, **scribe**. As **IC**, you coordinate — you don't dive into the fix yourself.
3. **One source of truth (9:09 — L15):** create master **INC-0811**; link the flood of duplicates;
   instruct the desk to attach new reports to it (not new investigations).
4. **First comms (9:12):** comms lead posts to users + leadership: *"The <app> is down, affecting all
   users since ~9:05. We've engaged the team and are investigating. Next update by 9:30."* (Honest, with a
   **next-update time**.)
5. **Drive restoration, not perfection (9:15–9:40):** technical lead finds the cause (e.g. the app server
   / a dependency — L22); IC pushes for the **fastest restore** (restart/failover/rollback — workaround
   OK) over the perfect fix. Scribe timestamps each action.
6. **Comms on cadence (9:30):** update even if "still investigating, next update 9:45" — never go silent.
7. **Restore + verify (9:40):** service restored via workaround; confirm with representative users; comms
   lead announces restoration.
8. **Declare resolved (9:45)** when service is confirmed back; thank responders; **bulk-resolve** the
   linked duplicates (L15).
9. **Trigger RCA/problem (L32):** schedule the **blameless post-incident review** — *why* did the app go
   down, was the workaround sufficient, what prevents recurrence (the permanent fix is a **problem/
   change**, L32/L26).

**The professional incident report (excerpt — uses the L0 template):**
```
INCIDENT REPORT — INC-0811  (P1 Major Incident)
Summary: Company-wide outage of <LOB app> 09:05–09:40 (35 min). Declared major incident; restored via
<workaround: failover/restart/rollback>; root cause to RCA. All users affected.
Impact: entire company unable to use <app>; ~35 min of lost productivity.
Timeline: 09:05 detected (monitoring + ticket flood) · 09:06 declared P1 · 09:08 bridge + roles (IC/tech/
comms/scribe) · 09:09 master ticket + duplicates linked (L15) · 09:12 first stakeholder comms · 09:30
update · 09:40 service restored (workaround) · 09:45 resolved + announced.
Root cause: <to be confirmed by RCA — L32>.  Resolution: <workaround> restored service.
Follow-up: blameless post-incident review scheduled; RCA + permanent fix (problem/change, L32/L26);
review monitoring/alerting + comms timeliness.
Lessons: what went well (fast declare, clean comms cadence) / improve (alerting lag? duplicate handling?).
```

---

## §7 — Service Desk / ITIL Perspective

- **Major incident management is a defined ITIL capability** (L17): pre-agreed **severity/priority**,
  **IC role**, **comms plan**, and **post-incident review** — invoked the moment a P1 is recognized.
- **Restore vs resolve are distinct:** incident management **restores service** (often via workaround);
  **problem management/RCA** (L32) eliminates the root cause. Conflating them keeps service down longer.
- **The desk is the detection + declaration + communication arm:** clustered tickets (L15) are the signal;
  fast declaration + one master ticket + a comms cadence prevent chaos.
- **Blameless culture** (shared with L29): post-incident reviews focus on the **system**, not blame — so
  people surface what really happened (the only way to actually prevent recurrence).
- **Metric/risk angle:** MTTR (restore time), time-to-declare, comms timeliness, and recurrence (did the
  RCA prevent it?) are the major-incident metrics; major incidents are the most leadership-visible events
  IT has.

---

## §8 — Practical Lab (build this yourself)

**Goal:** run a simulated major incident as IC and produce the runbook + incident report.

### Lens C — Manual → Automation/Process → Why
- **Manual:** ad-hoc scramble when a P1 hits.
- **Systematized:** a **major-incident runbook** (declare → IC → roles → bridge → master ticket → comms
  cadence → restore → resolve → RCA), **comms templates** (the update format), automated **alerting** that
  declares fast, and a **status page** for stakeholder comms.
- **Why:** under P1 pressure, improvisation fails — a pre-built runbook + comms templates mean the response
  is fast and consistent regardless of who's on shift; alerting catches it before the ticket flood.

### Steps
1. **Run the sim:** take ENT-31 (or chain a prior P1 — DC disk-full L22 / fleet bad-patch L26 / ransomware
   L30) and **run it as IC** end-to-end: declare → roles/bridge → master ticket (L15) → comms cadence →
   restore (workaround) → resolve → RCA handoff.
2. **Write the comms updates:** draft the initial + cadence stakeholder updates (honest, next-update time).
3. **Keep the timeline:** timestamp every step as the scribe would.
4. **Produce the incident report:** fill `docs/templates/incident-report.md` for the sim (summary/impact/
   timeline/root cause→RCA/follow-up/lessons).
5. **Blameless review:** note what went well / to improve; identify the **problem/RCA** handoff (L32).
6. **Write the major-incident runbook** (`docs/runbooks/major-incident.md`) + comms templates.

### Lens D — the raw artifact (the timeline is the spine of the report)
```
   INCIDENT TIMELINE — INC-0811 (every entry timestamped by the scribe):
     09:05  detected (monitoring alert + ticket flood, L15)
     09:06  DECLARED P1 major incident; IC = <you>
     09:08  bridge open; roles: tech lead / comms lead / scribe
     09:09  master ticket created; 30+ duplicates linked (L15)
     09:12  first stakeholder comms (next update 09:30)
     09:40  service RESTORED via <workaround>
     09:45  RESOLVED + announced; RCA scheduled (L32)
#   The timeline IS the incident report's backbone and the input to the RCA (L32). "Restore" (09:40) and
#   "root cause fixed" (later, via RCA/problem) are DIFFERENT milestones — incident mgmt owns the first.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/major-incident.md` — declare→IC/roles→bridge→master ticket→comms cadence→
   restore→resolve→RCA.
2. **Troubleshooting Guide:** `docs/troubleshooting/poorly-run-incident.md` — the meta spine (the §5
   failure modes).
3. **Ticket Notes:** the master ticket + linked duplicates handling (`docs/tickets/ENT-31-major-incident.md`).
4. **KB Article:** `docs/kb/` — internal "How we run a major incident (IC, roles, comms cadence)" +
   user-facing "what to expect during an outage."
5. **Incident Report:** the **major-incident report** (the centerpiece — `docs/templates/incident-report.md`).
6. **Portfolio Artifact:** §10 bullet + the IC / restore-first / comms-cadence talking points.
7. **Templates:** the **comms-update template** + the incident report (L0).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Ran major incidents as Incident Commander — declaring, assembling a bridge and roles
  (technical/comms/scribe), driving service restoration via workarounds, maintaining a stakeholder comms
  cadence and timeline, and handing root cause to RCA — reducing chaos and restore time on company-wide
  outages."*
- **Interview talking point:** the **IC role** (coordinate vs fix), **restore-first / RCA-later**, the
  **comms cadence** (regular updates + next-update time, one source of truth), and turning a ticket-flood
  into a **single master incident** (L15) — walk through running a P1 end-to-end.
- **Serves:** Junior SysAdmin, Infrastructure Support, and a team-lead/IC path.

---

## §11 — Certification Crossover Notes

- **ITIL 4 Foundation:** incident management + major incident handling (L17). **CompTIA A+ (Core 2):**
  incident response, escalation, and communication procedures. Security incidents → **NaviOpsSec**. Detail
  in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** during a major incident, **communication is the service** — users/leadership forgive an
outage far more than they forgive **silence**. Regular, honest updates (with a next-update time and one
source of truth) keep trust and stop the duplicate-ticket flood. Calm, coordinated response *is* good
service at the worst moment.

**🔒 Security:** **security incidents are major incidents** (L29) and use this exact framework **plus** the
security process — contain (L29/L20), preserve evidence, engage security/**NaviOpsSec**, and be careful
that comms don't tip off an attacker or leak details. Blameless post-incident reviews (shared with L29)
are essential so people report honestly. The IC coordinates; the SOC/IR (NaviOpsSec) owns the security
investigation depth.

---

## Quiz (Interview-Style, Graded)

**Q1.** What makes an incident a "major incident," and what's the first thing you should do when you
recognize one?
> **Your answer:**

**Q2.** What does an Incident Commander do — and is it their job to fix the problem?
> **Your answer:**

**Q3.** Why "restore first, find the root cause later"? What's the difference between resolving the
incident and the RCA?
> **Your answer:**

**Q4.** **Scenario:** a company-wide app outage hits and tickets are flooding in. Walk me through running
it as IC, including how you handle communications and the duplicate tickets.
> **Your answer:**

**Q5.** Why are post-incident reviews blameless, and what do they produce?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `major incident management process IC`
- `incident commander role responsibilities`
- `restore service vs root cause incident vs problem`
- `incident communication cadence status updates`
- `incident timeline post-incident review blameless`

**Tools**
- `major incident bridge war room roles`
- `incident report template`

**Going further**
- `root cause analysis` (L32) · `change/patch` (L26) · `ITIL incident management` (L17) ·
  `security incidents` (L29) · `backup/recovery (ransomware)` (L30) · **NaviOpsSec** (security IR)

**Service / Security (Lens E):**
- 🤝 `outage communication users leadership`, `silence is the enemy`
- 🔒 `security incident = major incident`, `preserve evidence`, `blameless review` (→ NaviOpsSec)

---

## Lesson Status
- [ ] §8 lab completed (run a simulated major incident as IC + comms + timeline + incident report)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 32 — Root Cause Analysis**.

---

*Lesson 31 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: ITIL 4 incident/
major-incident management, CompTIA A+ 220-1102 incident-response procedures; security IR → NaviOpsSec.*
