# Lesson 15 — Ticketing Systems Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the tool you'll spend your whole shift in — the **ITSM/ticketing system**. The universal
model behind **Jira Service Management, ServiceNow, and Zendesk**: tickets, fields, states, queues,
priority, SLAs, assignment, and the professional notes/communication that make a record useful. (The
*workflow* of working a queue is L16; *ITIL* concepts are L17; the real **Jira SM** tool deep-dive is
L33.)
**Primary artifact:** the ticket-note + queue-hygiene templates and runbook.

> **How to use this lesson:** read §1–§7, do §8 (model the three tools + write great tickets), produce
> §9, take the quiz, reflect. Then Lesson 16.

---

## §1 — Concept (Theory)

### What it is
A **ticketing system** (a.k.a. **ITSM** tool) is the system of record for support work. Every request
or incident becomes a **ticket** with structured **fields** (requester, category, priority, assignee,
status), a **conversation** (public replies + internal notes), and a **lifecycle** (states from New to
Closed). Tickets sit in **queues** and are governed by **SLAs** (time targets). The three you'll meet
most — **Jira Service Management**, **ServiceNow**, and **Zendesk** — differ in branding and depth but
share this exact model.

### Why it matters for support
The ticket is the **unit of work** (L01) and your **deliverable**. Your throughput, your handoffs, your
metrics, and the audit trail all live in the ticketing system. Being fast and disciplined in the tool —
correct fields, right priority, clean notes — is as important as the technical fix. Sloppy tickets break
SLAs, lose context, and frustrate the next tech and the user.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "I submitted a ticket and someone will help me" (the portal/email they use).
- **Level 2 — Technician:** the tool is a **queue of tickets with states and SLAs**; you pick up,
  triage (set category/priority), work, document (public reply + internal note), reassign/escalate, and
  resolve/close — keeping fields accurate so routing/reporting work.
- **Level 3 — Engineer/Admin:** tickets are typed records (**incident / service request / problem /
  change**) with **request types/forms**, **workflow states + transitions**, **automation rules**
  (auto-assign, SLA timers, notifications), **SLA policies** (response/resolution clocks with
  pause conditions), **queues/views** by filter, and **reporting** off the structured data. This is
  *why* good field hygiene matters — the automation and metrics are only as good as the data.

### Two Teaching Approaches (Lens B) — one model, three tools
**Approach 1 (technical):** all three systems implement the same abstractions — a ticket entity with
fields, a state machine (workflow), assignment to agents/queues, SLA timers, and a comment stream split
into customer-visible and internal. Learn the abstractions and you can sit down at any of them; only the
labels move (Jira "issue/transition", ServiceNow "record/state", Zendesk "ticket/status").

**Approach 2 (analogy):** a ticketing system is a **hospital records + ER board**. Each patient
(ticket) has a **chart** (fields + history), a **status board** (New→In Progress→Resolved), a
**triage acuity** (priority), an **assigned clinician** (agent), and **time targets** (SLA). The chart
travels with the patient so any clinician can continue care (the internal note); the **discharge
summary** is the closing note. **Where it breaks down:** unlike a hospital, the "patient" (user) reads
part of the chart (the public replies) — so tone and clarity in customer-visible comments matter, and
sensitive details go in **internal** notes only.

### Visual (ASCII) — the ticket anatomy & the three-tool map
```
   A TICKET:  [ID] [Requester] [Category] [Priority P1–P4] [Assignee] [Status] [SLA clock]
              ├─ Public replies  (the user sees these — tone matters)
              └─ Internal notes  (techs only — diagnosis, sensitive detail)
              History/audit: every change, who, when

   ONE MODEL → THREE TOOLS
   concept        Jira Service Mgmt     ServiceNow            Zendesk
   ----------     ------------------    ------------------    -----------
   ticket         Request/Issue         Incident/Request rec  Ticket
   states         Workflow transitions  State field           Status (New/Open/Pending/Solved)
   queue          Queues/Filters        Lists/Assignment grp  Views
   automation     Automation rules      Flow/Business rules   Triggers/Automations
   SLA            SLA goals             SLA definitions       SLA policies
```

---

## §2 — Tools & Commands

This lesson is tool-of-the-trade (mostly GUI/process), so the "commands" are the **fields and
transitions** you must use correctly:

| Element | What it's for | Get it right because… |
|---|---|---|
| **Requester / on-behalf-of** | who it's for (verified) | routing, identity, comms |
| **Category / request type** | classification | routing + reporting accuracy |
| **Priority (Impact × Urgency)** | order of work + SLA | wrong priority = SLA breach or starved P1 |
| **Assignee / group** | ownership | nothing is "everyone's job" |
| **Status / transition** | lifecycle position | dashboards + automation depend on it |
| **Public reply vs internal note** | comms vs record | sensitive detail stays internal |
| **Resolution code + KB link** | closure quality | metrics + future deflection |

> **Jira SM deep-dive (the real tool, with automation/SLAs/reporting) is Lesson 33.** ServiceNow and
> Zendesk are modeled here conceptually so you can adapt to any employer's stack.

---

## §3 — Real-World Support Context & Use Cases

- **You live here.** Whatever the employer runs (Jira SM, ServiceNow, Zendesk, Freshservice…), the
  model is the same — interviewers love "I haven't used *that* one, but they all share tickets, states,
  queues, SLAs, and I pick tools up fast."
- **Channels in:** portal form, email-to-ticket, chat, phone (logged by the agent), walk-up — all land
  as tickets.
- **Field hygiene drives everything:** correct category/priority/assignee makes routing, SLAs, and
  reporting work; bad data quietly breaks all three.
- **Public vs internal comments:** a daily discipline — never put a password, a security detail, or a
  candid "user error" remark in a customer-visible reply.
- **Exam framing:** ITIL (service desk, request/incident) and A+ (Core 2 ticketing/documentation) both
  cover this; the practical depth is here + L16/L33.

---

## §4 — Demonstration (worked walkthrough)

**Watch me create and field a ticket correctly from a phone call.**

> A user calls: *"My laptop won't connect to Wi-Fi since this morning."*

1. **Log it immediately** (phone calls still become tickets): create a ticket, set **Requester** (and
   verify identity, L01/L29).
2. **Classify:** **Category** = Network/Connectivity; **Type** = Incident (something's broken).
3. **Set priority by Impact × Urgency:** one user, can use wired as a stopgap → **P3** (would be P2 if
   fully blocked with a deadline).
4. **Assign:** to yourself (you're working it) — never leave it unassigned in a shared queue.
5. **Document as you go:** **internal note** with the diagnostic steps (L08 ladder); **public reply** to
   the user that's clear and reassuring ("I'm looking into your Wi-Fi now, I'll update you by 11:00").
6. **Resolve + close:** set a **resolution code** (e.g. Network), link a **KB** if relevant, confirm
   with the user, transition to Resolved → Closed.

The point: the *fields and notes* are the job as much as the fix — and they're identical in concept
across every tool.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: ticket/queue hygiene problems that hurt the desk (the "meta" troubleshooting).**

### 1 · Symptoms
SLA breaches · tickets sitting unassigned · "lost" tickets (no one owns it) · duplicate tickets ·
miscategorized/misrouted · reopened tickets · users complaining "no one updated me."

### 2 · Possible Causes (most-likely first)
1. **Unassigned/abandoned** tickets (no owner).
2. **Wrong priority** (P1 starved, or everything marked "urgent").
3. **Miscategorization** → wrong queue/team.
4. **No communication** (SLA response clock or CSAT suffers).
5. **Duplicates** (same issue, many tickets — e.g. an outage).
6. **Premature/sloppy closure** → reopens.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Unassigned view / aging report | tickets with no owner | assign by rule/round-robin |
| 2 | SLA-at-risk view | breaches looming | work oldest-at-risk first |
| 3 | Category vs actual issue | mismatched | recategorize → correct queue |
| 4 | Last-update time | stale | send an update; set expectations |
| 5 | Search for duplicates | many same | merge / link to a master (outage → L31) |
| 6 | Reopen reasons | recurring reopens | improve closure notes / verify with user |

### 4 · Resolution Steps
Assign every ticket an owner; fix priority via Impact×Urgency; recategorize/reroute; communicate
proactively (templates/canned responses); **merge duplicates** and link to a master incident during
outages; close only after user confirmation with a complete note + resolution code.

### 5 · Escalation Criteria
Escalate to the ITSM **admin** (or the queue/process owner) for: broken automation/SLA rules, misrouting
between teams, request-type/form changes, and reporting needs. (Tool administration depth = L33.) For a
flood of duplicate tickets, escalate the underlying issue as a **major incident** (L31) and link the
duplicates.

### 6 · Post-Incident Documentation
The ticket *is* the documentation — a complete note (L01 format), correct fields, resolution code, and
a KB link where it'll recur (L28). Queue-hygiene issues feed continual improvement (L16/L17).

---

## §6 — Ticket Simulation

> **Ticket ENT-15 / process scenario (P2 meta):** *During a brief email outage, the queue fills with
> 30 near-identical "I can't get email" tickets and three different agents start "investigating" the
> same thing.* You're the senior on shift.

**Triage:** this is a **queue-management** problem layered on an **outage**. The fix is process, not a
single endpoint.

**Worked resolution:**
1. **Recognize the pattern:** 30 tickets, same symptom, same timeframe → an **outage**, not 30
   problems → declare/confirm a **major incident** (L31) and check **service health** (L11).
2. **Create/identify a master ticket** for the outage; **merge or link** the 30 duplicates to it so
   they're tracked together (and agents stop triple-working it).
3. **Set one owner + communicate once, broadly:** a single status update on the master (and a
   broadcast/banner) so 30 users get the same honest ETA instead of 30 separate replies.
4. **Field hygiene:** correct category (Email/Service), priority **P1/P2** on the master, assignee = the
   incident owner; the children reference the master.
5. **On resolution:** resolve the master with the cause; **bulk-resolve** the linked children with a
   consistent note; confirm and close.
6. **After:** feed the duplicate-storm into improvement — an **outage banner/auto-response** so the next
   outage doesn't flood the queue.

**The professional note (on the master ticket):**
```
SUMMARY: Email outage (~30 duplicate tickets, 09:10–09:45). Created master INC, linked/merged
duplicates, single broadcast update, bulk-resolved on restoration. Adding an outage-banner automation
to prevent future duplicate storms.
PATTERN: 30 "can't get email" tickets, same window → outage, not 30 incidents.
ACTIONS: declared major incident (L31); checked M365 service health (confirmed provider-side);
created master INC-0811; linked 30 duplicates; posted one status update + banner; bulk-resolved on
restore at 09:45.
RESOLUTION: provider-side mail flow restored; children resolved with reference to master.
FOLLOW-UP: implemented an outage auto-response/banner (improvement); RCA on the master (L32).
```

---

## §7 — Service Desk / ITIL Perspective

- **The ticketing system operationalizes ITIL** (L17): incident/request/problem/change records, SLAs,
  and the service-desk practice all live in the tool.
- **SLAs are contractual time targets:** response and resolution clocks per priority, often with **pause
  states** ("pending customer/vendor"). Knowing how the clock works is essential — and why proactive
  comms protect you.
- **Queues + assignment** are how work is distributed fairly and nothing is dropped — "unassigned" is a
  failure state.
- **Reporting** off the ticket data drives staffing, problem identification, and CSAT/SLA dashboards —
  which is why field hygiene is a service obligation, not bureaucracy.
- **Tool depth:** Jira SM specifics (automation, SLA config, queues, reports) are **Lesson 33**.

---

## §8 — Practical Lab (build this yourself)

**Goal:** internalize the universal model, map it across the three tools, and write tickets that pass
the "next tech needs nothing from you" test.

### Lens C — Manual → Automation → Why
- **Manual:** type each note, set each field, route by hand.
- **Automated:** ITSM tools provide **canned responses/templates**, **request types** with required
  fields, **automation rules** (auto-assign, SLA timers, notifications), and **macros** — the engine
  that makes a busy queue consistent (built for real in L33).
- **Why:** at volume, templates + automation are what keep notes complete and SLAs honored without
  relying on memory; they also produce clean data for reporting.

### Steps
1. **Map the model:** build the three-tool table (§1) in your own words — concept → Jira SM →
   ServiceNow → Zendesk.
2. **Field discipline:** take three of your earlier worked tickets (ENT-01/08/13) and confirm each has
   correct category, priority (Impact×Urgency), assignee, resolution code, and split public/internal
   notes.
3. **Write a great ticket vs a bad one:** create a "lazy note" and rewrite it to the L01 standard —
   keep both as a teaching contrast.
4. **Queue hygiene drill:** given a messy sample queue (unassigned, miswritten, duplicates), apply §5 to
   clean it.
5. **Build the templates:** finalize `docs/templates/ticket-note.md` use + a **canned-responses** set
   (acknowledge, ETA, escalate, close) and the queue-hygiene runbook.

### Lens D — the raw artifact (public vs internal, and why it matters)
```
   PUBLIC REPLY (user sees):  "Thanks Nadia — I've reset this and confirmed it's working. Let me know
                               if anything else comes up!"
   INTERNAL NOTE (techs only): "Account was locked from a stale cached cred on her iPhone mail app;
                               unlocked + advised re-add. If re-locks, pull her device list. Possible
                               repeat — watch."
#   Sensitive/candid detail and next-tech guidance go INTERNAL; the user gets a clean, friendly reply.
#   Putting the internal note in the public reply (or vice-versa) is a classic, avoidable mistake.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/queue-hygiene.md` — assign/triage/prioritize/merge/close discipline.
2. **Troubleshooting Guide:** `docs/troubleshooting/ticket-queue-problems.md` — the meta spine (SLA
   breaches, unassigned, duplicates, reopens).
3. **Ticket Notes:** the cleaned ENT-01/08/13 + the master-incident note from §6
   (`docs/tickets/ENT-15-duplicate-storm.md`).
4. **KB Article:** `docs/kb/` — "How to submit a great ticket" (end-user-facing: what info to include).
5. **Incident Report:** the duplicate-storm/outage handling as a process write-up (feeds L31).
6. **Portfolio Artifact:** §10 bullet + the one-model-three-tools + public-vs-internal talking points.
7. **Templates:** finalized `ticket-note.md` usage + a **canned-responses** set (acknowledge/ETA/
   escalate/close).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Worked tickets in an ITSM workflow (Jira Service Management; conversant in
  ServiceNow & Zendesk concepts): disciplined field hygiene, Impact×Urgency prioritization, public/
  internal note separation, and duplicate-storm handling via a linked master incident."*
- **Interview talking point:** **one model, three tools** (tickets/states/queues/SLAs are universal —
  "I adapt to any ITSM fast"), **public vs internal notes**, and handling an **outage duplicate storm**
  with a master ticket.
- **Serves:** Help Desk T1/T2 (foundational for every desk role).

---

## §11 — Certification Crossover Notes

- **ITIL 4 Foundation:** the service desk practice, incident/request handling, SLAs. **CompTIA A+
  (Core 2):** ticketing systems & documentation (operational procedures). Detail in
  `alignment/CERTIFICATION-MAPPING.md`. (Tool-specific certs: Jira/ServiceNow admin tracks → L33.)

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** the ticketing system is where the user experiences IT — timely, clear **public**
updates and accurate status are the service. "No update" is itself a failure even if you're working
hard; communicate proactively.

**🔒 Security:** tickets contain sensitive data — **never store passwords/secrets** in a ticket; keep
sensitive diagnosis in **internal** notes; verify identity before acting on a request that arrives "as"
a user (email-to-ticket can be spoofed — L29); and respect that the ticket history is an **audit
record** (don't alter/delete it to hide a mistake — note the correction instead).

---

## Quiz (Interview-Style, Graded)

**Q1.** We use ServiceNow but you've only used Jira. Why isn't that a problem? Name the shared concepts.
> **Your answer:**

**Q2.** What's the difference between a public reply and an internal note, and give an example of what
belongs in each?
> **Your answer:**

**Q3.** Why does setting the correct category and priority on a ticket matter beyond just "being tidy"?
> **Your answer:**

**Q4.** **Scenario:** during an outage, 30 identical tickets flood the queue and three agents are
working the same thing. What do you do?
> **Your answer:**

**Q5.** What makes a ticket "closeable," and why do premature closures hurt the desk's metrics?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `ITSM ticket lifecycle states queues SLA`
- `jira service management vs servicenow vs zendesk concepts`
- `public reply vs internal note ticket`
- `impact urgency priority matrix ITSM`
- `merge duplicate tickets master incident`

**Tools**
- `canned responses macros ITSM`
- `SLA pause pending customer`

**Going further**
- `help-desk workflows` (L16) · `ITIL fundamentals` (L17) · `incident management` (L31) ·
  `jira service management` deep-dive (L33)

**Service / Security (Lens E):**
- 🤝 `proactive ticket communication SLA response`
- 🔒 `no passwords in tickets`, `email-to-ticket spoofing`, `ticket audit trail integrity`

---

## Lesson Status
- [ ] §8 lab completed (three-tool map + field hygiene + queue drill + templates/canned responses)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 16 — Help-Desk Workflows**.

---

*Lesson 15 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: ITIL 4 (service
desk), Jira Service Management / ServiceNow / Zendesk product concepts; tool depth → L33.*
