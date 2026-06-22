# Lesson 33 — Jira Service Management

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the real ITSM tool, in depth — **Jira Service Management (JSM)**: queues, **request types &
the portal**, **SLAs**, **automation rules**, **workflows**, the **knowledge base** integration, and
**reporting/dashboards**. Turns the universal ticketing model (L15) and the desk workflow (L16) into a
configured, automated system — the operational capstone of Module H.
**Primary artifact:** the JSM workflow runbook + a queue/SLA/automation configuration guide.

> **How to use this lesson:** read §1–§7, do §8 (configure queues/SLA/automation in a JSM free site),
> produce §9, take the quiz, reflect. Then the capstones (34–36).

---

## §1 — Concept (Theory)

### What it is
**Jira Service Management** is Atlassian's ITSM platform — a concrete implementation of everything in
L15–L17/L31/L32: a **customer portal** + **request types** (forms), **queues** (filtered views agents
work), **SLAs** (response/resolution timers with conditions), **automation rules** (auto-assign, notify,
escalate, transition), **workflows** (the status state-machine per request type), an integrated
**knowledge base** (Confluence) for deflection, and **reporting/dashboards** (FCR, SLA, volume). It maps
ITIL practices to records: **request types** for service requests, **incidents** (incl. major-incident
workflows), **problems** (L32), and **changes** (L26).
.
### Why it matters for support
Employers run a specific ITSM tool and expect you to be productive in it. **JSM** is one of the most
common (with ServiceNow/Zendesk — L15). Knowing JSM concretely — and understanding it's the **same model**
you learned generically (L15) — means you can sit down and work, *and* speak to **SLAs, automation, and
reporting** in interviews. This lesson also operationalizes the whole platform: the queue (L16), incidents
(L31), problems (L32), changes (L26), and the KB (L28) all live here.

### Three-Level Depth (Lens A)
- **Level 1 — User:** uses the **portal** to raise a request / check status (self-service).
- **Level 2 — Agent:** works **queues** by priority/SLA (L16), uses **request types**, transitions tickets
  through the **workflow**, uses **canned responses/KB**, and respects the **SLA timers**.
- **Level 3 — Admin/Engineer:** configures **request types + portal forms**, **queues** (JQL filters),
  **SLA definitions** (goals, calendars, **pause** conditions), **automation rules** (triggers→conditions→
  actions: auto-assign, SLA-breach escalation, notifications, linked-issue updates), **workflows**
  (statuses/transitions/validators), **KB integration** (deflection + linking), and **reports/dashboards**
  (SLA attainment, FCR, created-vs-resolved). This is *why* a well-configured JSM enforces the L16 workflow
  automatically (nothing unassigned, SLA timers always running) and produces the metrics that drive L16/L32.

### Two Teaching Approaches (Lens B) — same model, configured + automated
**Approach 1 (technical):** JSM realizes the universal ITSM model (L15) as configurable objects —
request types/portal (intake), queues (work distribution), SLAs (time targets + automation triggers),
workflows (state machines), automation rules (the engine that enforces the process), KB (deflection),
and reporting (the feedback loop). Configuring these well **encodes the L16 workflow + ITIL practices** so
quality doesn't depend on each agent remembering.

**Approach 2 (analogy):** if L15 taught "what a car is" (any ITSM), JSM is **learning to actually drive a
specific car** — same steering wheel/pedals (tickets/queues/SLAs), but you learn *this* dashboard, *this*
cruise control (automation), and *this* GPS (reporting). Once you can drive one well, you adapt to
ServiceNow/Zendesk fast (L15) — the controls are in slightly different places. **Where it breaks down:**
the analogy understates **automation** — JSM can *drive itself* for routine tasks (auto-assign, auto-
escalate on SLA breach, auto-respond), which is the real power vs a manual queue.

### Visual (ASCII) — JSM components (the model, configured)
```
   CUSTOMER PORTAL ──raise──▶ REQUEST TYPE (form) ──▶ creates a ticket (incident/request/problem/change)
        │ deflect                                          │
   KNOWLEDGE BASE (Confluence, L28)              QUEUES (JQL filters) ← agents work by priority/SLA (L16)
                                                          │
   SLA timers (goal + calendar + PAUSE conditions) ──triggers──▶ AUTOMATION RULES (assign/notify/escalate/transition)
                                                          │
   WORKFLOW (statuses + transitions per type)  ─────▶  REPORTS / DASHBOARDS (SLA · FCR · created-vs-resolved → L16/L32)
   maps ITIL:  request types→service requests · incidents (+major, L31) · problems (L32) · changes (L26)
```

---

## §2 — Tools & Commands

JSM is configured in the UI; the "toolkit" is its objects (and how they map to what you learned):

| JSM object | What it does | Maps to |
|---|---|---|
| **Portal + request types** | self-service intake forms | intake (L01/L15), service requests (L17/L20) |
| **Queues** (JQL) | filtered work views by team/priority/SLA | working the queue (L16) |
| **SLAs** | response/resolution timers, calendars, **pause** | SLAs (L15/L16/L17) |
| **Automation rules** | trigger→condition→action (assign/notify/escalate/transition) | the workflow engine (L16) |
| **Workflows** | statuses + transitions per request type | ticket lifecycle (L01/L15) |
| **Incident / Major incident** | incident handling + on-call/alerts | L31 |
| **Problems / Changes** | problem records + change requests | L32 / L26 |
| **Knowledge base (Confluence)** | KB articles + portal deflection | documentation (L28) |
| **Reports / dashboards** | SLA, FCR, created-vs-resolved, satisfaction | metrics (L16) |
| **JQL** | the query language behind queues/reports | (search syntax) |

```text
# JQL examples (the language behind queues & reports):
project = ITSD AND statusCategory != Done AND assignee is EMPTY ORDER BY created ASC   # unassigned backlog (L16)
project = ITSD AND "Time to resolution" breached() AND statusCategory != Done          # SLA-breached open tickets
project = ITSD AND priority = Highest AND created >= -7d                                # P1s this week
# Automation rule (described): WHEN issue created → IF request type = "Password reset" → THEN assign to
#   Tier1 queue + set priority + post SSPR KB link (deflect/auto-respond).
```

> Lab note: use a **free JSM cloud site** with placeholder data (`navi.project.md` HR#1 — no real
> tenant/user data). Configuration changes affect how the desk runs — in a real org, ITSM config is itself
> change-controlled (L17/L26).

---

## §3 — Real-World Support Context & Use Cases

- **You'll work *a* tool daily** — often JSM/ServiceNow/Zendesk. Deep familiarity with one (JSM here) +
  the universal model (L15) = "I adapt to any ITSM fast" (a strong interview answer).
- **Automation is the force multiplier:** auto-assign (no unassigned tickets — L16), **auto-escalate on
  SLA breach**, auto-respond with a KB link (deflection — L28), auto-transition — the engine that enforces
  the L16 workflow without relying on memory.
- **SLAs operationalized:** JSM **SLA timers** (with business calendars + **pause** on "waiting for
  customer") are how response/resolution targets are measured and trigger escalations — the L15/L16 SLA
  theory made real.
- **The whole platform lives here:** service requests (L20), incidents + major incidents (L31), problems
  (L32), changes (L26), and the KB (L28) are all JSM record types/integrations — this lesson ties Module H
  together.
- **Reporting drives improvement (L16/L32):** SLA attainment, FCR, created-vs-resolved, and CSAT
  dashboards surface where to improve (KB, automation, problem records).
- **Exam framing:** ITIL (service desk + practices realized in a tool — L17); Atlassian has JSM certs; A+
  (ticketing/ITSM concepts). The transferable skill (model + one tool deep) is the takeaway.

---

## §4 — Demonstration (worked walkthrough)

**Watch me configure JSM to enforce the desk workflow for the highest-volume request — password resets
(L21).**

1. **Create the request type + portal form:** "Reset my password" with the fields you need (and identity-
   verification guidance — L29). Self-service intake.
2. **Add a deflection KB article (L28):** link **KB-0001** (self-service reset/SSPR) to the request type so
   users see it *before* raising a ticket — deflect the easy case.
3. **Build the queue (JQL — L16):** a Tier-1 queue filtered to open password/account requests, **ordered by
   SLA risk** (oldest/at-risk first).
4. **Define the SLA:** "Time to first response" + "Time to resolution" goals on a business calendar, with a
   **pause** when "Waiting for customer" (so the clock is fair) — L15/L16.
5. **Add automation rules (the engine):**
   - *On create* → auto-assign to the Tier-1 queue + set priority.
   - *On create* → auto-respond with the SSPR/KB link (deflect).
   - *On SLA breach risk* → escalate/notify (so nothing silently breaches — L16).
6. **Workflow:** confirm the status transitions (Open → In Progress → Resolved → Closed) match the lifecycle
   (L01/L15), with a resolution field on close.
7. **Reporting:** add a dashboard widget for password-reset volume + SLA attainment → this is the data that
   tells you to push harder on **SSPR deflection** (L21/L16) to cut the volume.

The teaching point: JSM lets you **encode the L16 workflow + ITIL practices into the tool** — automation
assigns/escalates/deflects automatically, SLAs are measured + enforced, and reporting closes the
improvement loop. Same model as L15, now *configured and self-running*.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: JSM configuration problems (the tool not enforcing the workflow well).**

### 1 · Symptoms
Tickets land unassigned / in the wrong queue · SLAs not triggering or breaching silently · users can't find
the right request type (portal confusing) · automation not firing (or firing wrong) · no deflection (KB not
surfaced) · reports don't reflect reality · wrong workflow/statuses for a request type.

### 2 · Possible Causes (most-likely first)
1. **Queue/JQL misconfigured** → tickets invisible/unassigned (L16 failure in the tool).
2. **SLA definition wrong** (no calendar/pause, wrong start/stop) → unfair or silent breaches.
3. **Automation rule** mis-scoped (wrong trigger/condition) → not firing / firing wrong.
4. **Request types/portal** unclear → miscategorized intake (L15 field-hygiene failure).
5. **KB not linked** to request types → no deflection (L28).
6. **Workflow** doesn't match the lifecycle (missing statuses/transitions/validators).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Queue JQL — does it capture the right tickets? | misses some | fix the JQL filter |
| 2 | SLA definition (start/stop/pause/calendar) | wrong/silent | fix goal + pause + escalation rule |
| 3 | Automation rule audit log (did it fire?) | no/wrong | fix trigger/condition/action |
| 4 | Request type/portal clarity | confusing | redesign forms/fields (intake hygiene, L15) |
| 5 | KB linked to request types? | no | link articles for deflection (L28) |
| 6 | Workflow statuses/transitions match lifecycle? | no | fix the workflow |

### 4 · Resolution Steps
Fix the **queue JQL**; correct **SLA** definitions (start/stop/pause/calendar) + add a **breach escalation**
automation; repair **automation rules** (use the audit log); clarify **request types/portal** (intake
hygiene, L15); **link KB** for deflection (L28); align the **workflow** to the lifecycle. Treat config
changes in a live instance as **changes** (L17/L26 — they affect how the whole desk runs).

### 5 · Escalation Criteria
Escalate to the **JSM/Jira admin** for: schema/workflow/automation/SLA configuration, portal/request-type
design, app/integration issues, and reporting needs beyond your access. Tool administration is a defined
role; agents request config changes. Big config changes are **changes** (L17/L26). Attach: the queue/SLA/
automation in question + the desired behavior.

### 6 · Post-Incident Documentation
The **JSM workflow/config runbook** (how queues/SLAs/automation are set up + why), config changes recorded
as **changes** (L26), KB linked for deflection (L28), and dashboards documented so the team reads the
metrics consistently (L16).

---

## §6 — Ticket Simulation

> **Project ENT-33 / scenario (P3 — configure for improvement):** *"Our JSM is a mess: tickets sit
> unassigned, SLAs breach without anyone noticing, password resets flood the queue, and management can't
> get a clear SLA/FCR report. Clean it up."* You own the JSM configuration improvement.

**Triage:** a **tool-not-enforcing-the-workflow** problem (the §5 failure modes) — the fix is
**configuration** that encodes L16 + deflection + reporting, treated as a change (it affects the whole
desk). Ties together everything in Module E + H.

**Worked resolution (configure JSM to run the desk):**
1. **Fix unassigned/queues (L16):** build **queues by JQL** (team + priority + **SLA-risk order**) and an
   **automation rule** to **auto-assign on create** so nothing sits unassigned. "Unassigned" becomes
   impossible by design.
2. **Fix SLAs (L15/L16):** define **response + resolution SLAs** on a business calendar with **pause** on
   "Waiting for customer," and add an **automation rule to escalate/notify on breach risk** → no more
   silent breaches.
3. **Deflect the password-reset flood (L21/L28):** add a clear **request type** + link **KB-0001/SSPR** in
   the portal + an **auto-response** with the self-service link → cut the volume at the source (the biggest
   lever, L21).
4. **Right-size workflows + intake (L15/L17):** ensure incident/request/problem/change **request types**
   exist with correct **workflows** (so classification — L17 — is built in, not manual).
5. **Build the reports management wants (L16/L32):** a **dashboard** with **SLA attainment**, **FCR**,
   **created-vs-resolved**, and top recurring request types (which feed **problem records** — L32).
6. **Treat it as a change + document:** config changes affect the whole desk → change-controlled (L26);
   write the **JSM workflow runbook** so the setup is understood + maintainable.
7. **Verify (L16/L32):** post-change, fewer unassigned, SLA breaches caught/escalated, password-reset
   volume down (deflection), and management has live dashboards. Measure the improvement.

**The professional note:**
```
SUMMARY: Reconfigured JSM to enforce the desk workflow: queues + auto-assign (no unassigned), SLAs with
pause + breach-escalation automation (no silent breaches), password-reset request type + KB/SSPR deflection
(cut volume), correct incident/request/problem/change workflows, and an SLA/FCR/created-vs-resolved
dashboard for management.
PROBLEM: tickets unassigned, SLAs breaching silently, password-reset flood, no clear reporting (tool
wasn't enforcing L16/ITIL).
ACTIONS: queues by JQL + auto-assign rule; SLA defs (calendar + pause) + breach-risk escalation automation;
"Reset password" request type + KB-0001/SSPR auto-response (deflection, L21/L28); incident/request/problem/
change request types + workflows (L17); management dashboard (SLA/FCR/created-vs-resolved, L16); changes
recorded (L26).
RESULT: workflow enforced by the tool (not memory); deflection cut reset volume; SLAs visible + escalated;
management has live metrics → drives improvement (L16) + problem records (L32).
FOLLOW-UP: JSM workflow runbook documented; monitor the dashboards; iterate deflection + automation.
```

---

## §7 — Service Desk / ITIL Perspective

- **JSM operationalizes the whole platform:** the universal model (L15), the desk workflow (L16), ITIL
  classification (L17), incidents/major incidents (L31), problems (L32), changes (L26), and the KB (L28)
  are all **records/integrations in the tool** — this lesson is where they run.
- **Automation enforces the workflow:** the L16 discipline (nothing unassigned, SLA timers always running,
  escalate-don't-drop) is **configured**, not left to each agent's memory — the biggest reliability win.
- **Deflection + self-service** (portal + KB, L28/L21) is the strategic volume reducer; JSM makes it
  concrete.
- **Reporting closes the loop (L16/L32):** dashboards make FCR/SLA/volume/recurrence visible → drive KB,
  automation, and problem records. The tool *generates* the continual-improvement data.
- **One tool deep + the model = adaptable:** mastering JSM (or any one ITSM) + the L15 universal model
  means you transfer to ServiceNow/Zendesk quickly — and can speak to SLAs/automation/reporting in
  interviews.
- **Config is change-controlled:** ITSM configuration affects how the whole desk runs → treat it as a
  **change** (L17/L26).

---

## §8 — Practical Lab (build this yourself)

**Goal:** configure a real JSM site to enforce the workflow + deflection + reporting — in a free site with
placeholder data.

### Lens C — Manual → Automation → Why
- **Manual:** work tickets by hand, assign/escalate/respond manually (L16 by memory).
- **Automated (JSM):** **automation rules** (auto-assign, SLA-breach escalation, auto-respond/deflect),
  **SLA timers**, **portal + KB deflection**, and **dashboards** — the tool runs the routine so agents
  focus on real work.
- **Why:** at volume, the tool enforcing the workflow (nothing unassigned, SLAs always tracked, easy cases
  deflected) is what makes a desk reliable + scalable — exactly the L16 problems, solved by configuration.

### Steps
1. **Set up a free JSM cloud site** (placeholder data only — `navi.project.md` HR#1).
2. **Request types + portal:** create a few (password reset, hardware request, "something's broken"
   incident) with sensible forms.
3. **Queues (JQL):** build a Tier-1 queue ordered by SLA risk; try the JQL from §2 (unassigned backlog,
   breached SLAs, P1s this week).
4. **SLAs:** define response + resolution SLAs with a calendar + a **pause** on "waiting for customer."
5. **Automation:** create rules — **auto-assign on create**, **auto-respond with a KB link** (deflection),
   **escalate on SLA breach** — and watch the audit log confirm they fire.
6. **KB + reporting:** link a KB article (L28) to a request type for deflection; build a dashboard (SLA
   attainment, FCR, created-vs-resolved).
7. **Write the JSM workflow runbook** (queues/SLAs/automation/reporting setup + why) as the artifact.

### Lens D — the raw artifact (JQL + automation = the workflow, encoded)
```
   QUEUE (JQL):  project = ITSD AND statusCategory != Done AND assignee is EMPTY ORDER BY created ASC
                 → the "unassigned backlog" that should always be EMPTY (auto-assign keeps it so)

   AUTOMATION RULE:
     WHEN: issue created
     IF:   request type = "Reset my password"
     THEN: assign → Tier1 queue ; set priority = Medium ; comment (public) with KB-0001/SSPR link
   → encodes L16 (no unassigned) + L21/L28 (deflection) so quality doesn't depend on who's on shift.

   SLA: "Time to resolution"  goal 8h (business calendar)  PAUSE when status = "Waiting for customer"
     + automation: WHEN SLA breached() THEN notify lead + raise priority   → no SILENT breaches (L16)
#   Queues (JQL) + automation rules + SLA definitions ARE the L16 workflow + ITIL practices, configured
#   into the tool. This is the difference between "drive the car" (L15) and "tune it to drive itself."
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/jsm-workflow.md` — queues/SLAs/automation/workflows/reporting setup + the
   request-type→KB deflection design.
2. **Troubleshooting Guide:** `docs/troubleshooting/jsm-config.md` — the meta spine (the §5 config failure
   modes).
3. **Ticket Notes:** the JSM-improvement project notes (`docs/tickets/ENT-33-jsm-config.md`).
4. **KB Article:** `docs/kb/` — internal "How our JSM is configured (queues/SLAs/automation)" + user "How
   to raise a request in the portal."
5. **Incident Report:** N/A (config lesson); the **JSM config/automation guide** is the centerpiece.
6. **Portfolio Artifact:** §10 bullet + the model-vs-tool / automation / reporting talking points.
7. **Config guide:** the queue/SLA/automation/reporting configuration (the artifact + JQL examples).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Configured Jira Service Management to enforce the service-desk workflow — JQL queues
  with auto-assignment, SLAs (business calendars + pause + breach escalation), portal request types with
  KB/SSPR deflection, ITIL incident/request/problem/change workflows, and SLA/FCR dashboards — reducing
  unassigned tickets, silent SLA breaches, and password-reset volume."*
- **Interview talking point:** JSM as the **universal ITSM model (L15) configured + automated** ("I know
  JSM deeply and adapt to ServiceNow/Zendesk fast"), how **automation enforces the L16 workflow** (auto-
  assign/escalate/deflect), **SLAs with pause conditions**, and **reporting** that drives improvement +
  problem records (L16/L32).
- **Serves:** all service-desk roles; the operational/tooling depth for IT Support → Junior SysAdmin.

---

## §11 — Certification Crossover Notes

- **ITIL 4 Foundation:** practices realized in a tool — service desk, incident/request/problem/change,
  SLAs (L17). **Atlassian:** JSM-specific certifications (the deep tool path). **CompTIA A+ (Core 2):**
  ticketing/ITSM concepts. Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** a well-configured JSM is *invisible good service* — the portal + KB let users self-serve,
auto-responses set expectations instantly, SLAs keep things on time, and nothing falls through the cracks.
Configuration quality directly shapes the user experience.

**🔒 Security:** the ITSM holds sensitive data — **least-privilege** agent/admin permissions, don't store
**secrets/passwords** in tickets (L15/L29), keep **internal vs portal-visible** content separated (L15
public-vs-internal; L28 data classification), and protect the **portal/identity** (it's an external-facing
auth surface — SSO/MFA, L11). ITSM **config changes are change-controlled** (L17/L26 — they affect the
whole desk). The audit trail (ticket history) is a compliance/security asset — preserve its integrity.

---

## Quiz (Interview-Style, Graded)

**Q1.** We use Jira Service Management. How is it the "same" as ServiceNow/Zendesk, and what are its core
building blocks?
> **Your answer:**

**Q2.** What can automation rules do for a service desk? Give two examples that enforce the L16 workflow.
> **Your answer:**

**Q3.** How do JSM SLAs work, and why does a "pause" condition matter?
> **Your answer:**

**Q4.** **Scenario:** tickets sit unassigned, SLAs breach silently, and password resets flood the queue.
How would you configure JSM to fix all three?
> **Your answer:**

**Q5.** What reports/dashboards would you build for a service desk, and what decisions do they drive?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `jira service management queues JQL`
- `JSM SLA configuration pause condition`
- `jira automation rules trigger condition action`
- `JSM request types portal knowledge base deflection`
- `JSM reports dashboards SLA FCR`

**Tools**
- `JQL query examples service desk`
- `JSM workflows statuses transitions`

**Going further**
- `service-desk capstone` (L34) · `ticketing systems` (L15) · `help-desk workflows` (L16) ·
  `ITIL` (L17) · `incident/problem/change` (L31/L32/L26) · `documentation/KB` (L28)

**Service / Security (Lens E):**
- 🤝 `portal self-service + KB deflection`, `automation sets expectations`
- 🔒 `no secrets in tickets`, `least-privilege ITSM roles`, `portal SSO/MFA`, `config change control`

---

## Lesson Status
- [ ] §8 lab completed (JSM site: request types + queues/JQL + SLAs + automation + KB + dashboard + runbook)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 34 — Service Desk Capstone** (the capstones!).

---

*Lesson 33 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: Atlassian Jira Service
Management docs (queues/SLAs/automation/JQL), ITIL 4 practices (L17); model context from L15.*
