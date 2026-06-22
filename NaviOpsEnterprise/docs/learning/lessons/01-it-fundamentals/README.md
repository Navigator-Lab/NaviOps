# Lesson 01 — IT Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** what IT support *is*, the tier model (T1→T2→T3), and the single most important skill on
day one — taking a ticket from "the user is stuck" to "resolved and documented." Every later
lesson is a specialization of this loop.
**Primary artifact:** the "anatomy of a ticket" runbook + your first worked ticket.

> **How to use this lesson:** read §1–§7, do §8 (work a ticket end-to-end), produce §9, take the
> quiz, reflect. Then Lesson 02.

---

## §1 — Concept (Theory)

### What it is
**IT support** is the function that keeps people productive with their technology. When something
breaks, is confusing, or is needed (a new laptop, access to a folder), IT support is who restores
the user to working order. The work arrives as **tickets** (also called cases/incidents/requests)
in a queue, and the support organization is layered into **tiers** by depth of skill and access.

### Why it exists
Organizations run on technology, and technology fails or confuses people constantly. Without a
structured support function, every problem becomes a fire drill and nothing is learned. IT support
provides **a single front door, a consistent method, and an audit trail** — so problems get fixed
predictably, knowledge accumulates, and the business keeps moving.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "I have a computer problem, I contact IT, someone helps me." The user sees a
  helpful person and a fix.
- **Level 2 — Technician (T1/T2):** support is a **queue of tickets** worked through a repeatable
  loop — intake → verify identity → triage/priority → diagnose → resolve → document → close — under
  **SLAs** (time targets), with **escalation** when a ticket exceeds your access or skill.
- **Level 3 — Engineer/Service-owner:** support is a **system** with measurable health (FCR, MTTR,
  CSAT, backlog), feeding **problem management** (fix recurring root causes) and **knowledge**
  (KB so the same problem is solved faster next time). The ticket is also a legal/audit record of
  *who changed what, when, and why*.

### Two Teaching Approaches (Lens B)
**Approach 1 (technical):** IT support is a tiered queueing system. Tickets are classified by
**impact × urgency** into priorities; each priority has an SLA; tickets flow through states (New →
In Progress → Resolved → Closed) and escalate vertically (T1→T2→T3/vendor) when they exceed the
current tier's authority or expertise. Throughput and quality are measured.

**Approach 2 (analogy):** a **hospital ER**. Patients (tickets) arrive; a nurse does **triage**
(how urgent? how severe?); routine cases are handled at the front (T1); complex cases go to a
specialist (T2/T3) with the chart attached (the ticket note) so the patient doesn't repeat their
story. Charts are kept (documentation); patterns drive prevention (problem management). **Where it
breaks down:** users aren't sick patients — tone, communication, and setting expectations matter
as much as the technical fix; a "cured" patient who feels ignored still leaves an angry review (low
CSAT).

### Visual (ASCII) — the support tiers & the ticket loop
```
   USER ──ticket──▶  ┌─────────── SERVICE DESK ───────────┐
                     │  T1  ── common 80% (reset, printer, │  escalate ▲
                     │        connectivity, app how-to)    │           │
                     │  T2  ── deeper (AD, M365, GPO,       │  ─────────┤
                     │        endpoint, mail flow)         │           │
                     │  T3 / SysAdmin / Vendor ── infra,   │  ─────────┘
                     │        servers, product bugs        │
                     └─────────────────────────────────────┘

   THE LOOP (every ticket):
   Intake → Verify ID → Triage(P) → Diagnose → Resolve → Document → Close
```

---

## §2 — Tools & Commands

You'll go deep on these in later lessons; here's the day-one map of where the work happens.

| Tool / place | What it's for | Lesson |
|---|---|---|
| **Ticketing system** (Jira SM / ServiceNow / Zendesk) | the queue — where tickets live | 15, 33 |
| **Knowledge base (KB)** | self-service + tech reference | 28 |
| **Remote support tool** (Quick Assist / RDP / RMM) | see the user's screen | 24 |
| **Directory** (Active Directory / Entra) | accounts, groups, resets | 18, 21 |
| **M365 / Workspace admin** | mail, licensing, collaboration | 11, 12 |
| **Windows consoles** (Event Viewer, Services, Task Mgr) | diagnose the endpoint | 04 |

First real commands you'll use constantly (previewed; mastered later):
```text
ipconfig /all        # the machine's network identity (L08)
ping / nslookup      # is it reachable / does the name resolve (L08-09)
gpresult /r          # what policy applies to this user/computer (L19)
whoami /groups       # what groups grant this user access (L07)
```

---

## §3 — Real-World Support Context & Use Cases

- **The queue is the job.** You will not pick what to work on randomly — you work the queue by
  priority and SLA risk. Learning to *triage* is as important as learning to *fix*.
- **The common 80%** at T1: password resets, account unlocks, printer issues, basic connectivity,
  Outlook/M365 questions, software install requests, new-hire setup. Master these and you're
  hireable (the rest of this curriculum makes you *good*).
- **Tickets vs the ITIL vocabulary** (Lesson 17): an **Incident** = something is broken; a
  **Request** = "please give/do X" (standard, pre-approved); a **Problem** = the root cause behind
  recurring incidents. Knowing which is which sets the right process and SLA.
- **Exam framing:** CompTIA A+ Core 2 covers ticketing, documentation, and professional/operational
  procedures directly; ITIL 4 covers the service-management vocabulary. This lesson is foundational
  for both.

---

## §4 — Demonstration (worked walkthrough)

**Watch me take a simple ticket end-to-end.**

> **Ticket INC-0001 (P3):** *"Hi, my work laptop is asking me to change my password and I don't
> know how. — Jane Doe, Sales."* Channel: portal. Asset: LT-0427.

1. **Acknowledge + set expectations:** reply within SLA — *"Hi Jane, happy to help you change your
   password. First, let me confirm I'm working with the right account."*
2. **Verify identity:** confirm via the agreed method (e.g. a call-back to the number on file, or
   manager confirmation, or a verified portal session). *Never skip this.*
3. **Triage/priority:** one user, not blocked from critical work, low urgency → **P3**.
4. **Diagnose:** is this a routine expiry (every 90 days) or a forced reset? Check the account —
   password expiry is set, account is healthy, not locked.
5. **Resolve:** walk Jane through `Ctrl+Alt+Del → Change a password` (on-network) *or* the
   self-service portal; confirm the new password meets policy; confirm she can sign in.
6. **Document (the note):**
   > *SUMMARY: User unable to change expiring password; guided through Ctrl+Alt+Del change, success.
   > VERIFIED: call-back to number on file. CAUSE: routine 90-day expiry. RESOLUTION: user set new
   > compliant password, confirmed sign-in at 10:14. FOLLOW-UP: none.*
7. **Close:** set resolution category **Account/Access**, confirm with Jane, close.

That's the whole job in miniature. Every lesson adds depth to one of these steps.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

The generic spine you'll apply to *every* problem class (here applied to "a user contacts support
but I'm not sure what's wrong"):

1. **Symptoms** — get specifics: exact wording of the error, what they were doing, when it started,
   what changed, can they reproduce it.
2. **Possible Causes** — form a ranked hypothesis list (most-likely first) instead of guessing.
3. **Diagnostic Steps** — cheapest, most-likely check first; isolate (is it the app? the account?
   the device? the network?). One variable at a time.
4. **Resolution Steps** — apply the fix for the confirmed cause; confirm with the user.
5. **Escalation Criteria** — escalate when it exceeds your access/skill, breaches SLA risk, or is a
   P1/major incident — with a complete handoff package.
6. **Post-Incident Documentation** — write the ticket note; create/update a KB if it'll recur;
   raise a problem ticket if it's recurring.

**Anti-patterns to avoid from day one:** changing multiple things at once (you won't know what
fixed it), skipping identity verification, resolving without confirming with the user, and the
one-line note "fixed it" (useless to the next tech).

---

## §6 — Ticket Simulation

> **Ticket ENT-01 / INC-0002 (P2):** *"None of my passwords work and now it says my account is
> locked. I have a client call in 20 minutes!! — Alex Smith, Account Mgr."* Channel: phone.

**Intake & triage:** urgency High (client call, blocked), impact Low-Med (one user) → **P2**. Phone
gives you a live identity-verification opportunity.

**Worked resolution:**
1. Verify identity on the call (security questions / known details per policy).
2. Reassure + set expectation: *"I can unlock this now; give me about two minutes."*
3. Diagnose: account is **locked out** (too many bad attempts) — not disabled, not expired.
4. Resolve: unlock the account (Lesson 21 covers the how); confirm Alex can sign in.
5. Note the likely cause for follow-up: repeated lockouts often mean a **stale cached password** on
   a phone or mapped drive — flag to check after the call (root cause, not just symptom).

**The professional ticket note:**
```
SUMMARY: AD account locked from repeated bad attempts; unlocked, user signed in before client call.
VERIFIED: phone identity check per policy.
SYMPTOM: "passwords don't work, account locked"; user time-pressured (client call in 20 min).
CAUSE: account lockout threshold hit (suspected stale cached credential on mobile device).
ACTIONS: 1) verified identity 2) confirmed lockout state 3) unlocked account 4) confirmed sign-in.
RESOLUTION: unlocked at 13:41; user confirmed access. P2 met within SLA.
FOLLOW-UP: scheduled check of mobile/mapped-drive cached creds to prevent re-lockout; KB linked.
```
**Lazy note vs great note:** *"unlocked account"* tells the next tech nothing. The note above lets
the next person see the suspected root cause and the prevention step — that's the standard here.

---

## §7 — Service Desk / ITIL Perspective

- **Queue/category:** Account/Access. **Incident** (something is broken), not a request.
- **Priority:** impact × urgency (Lesson 16 matrix). A blocked exec before a client call legitimately
  raises urgency.
- **SLA:** the clock starts at ticket creation; you're measured on **time-to-respond** and
  **time-to-resolve**. Communicate proactively so the clock never surprises you.
- **Escalation path:** T1 handles resets/unlocks; T2 handles the *why it keeps happening*; a true
  outage becomes a major **incident** (Lesson 31).
- **Metrics this feeds:** **FCR** (did you fix it on first contact?), **MTTR**, **CSAT**. The
  service desk is the most-measured team in IT — and the most visible.

---

## §8 — Practical Lab (build this yourself)

**Goal:** internalize the ticket loop by working one end-to-end and producing your first artifacts.

### Lens C — Manual → Automated → Why
- **Manual:** you read the ticket, think, type a note by hand.
- **Automated:** mature desks use **templates** (canned responses), **request types** with required
  fields, and **automation rules** (auto-assign, auto-acknowledge, SLA timers) — Lessons 15/33.
- **Why:** templates make every note complete and consistent; automation makes the SLA clock and
  routing reliable instead of dependent on memory. You'll feel the difference at volume.

### Steps
1. **Set your placeholders:** use `corp.example` identities from `LEARNING_STATE.md` (jdoe, asmith).
2. **Write the "anatomy of a ticket" runbook** (`docs/runbooks/` from `templates/runbook.md`):
   the ticket loop as a repeatable procedure with the verify-identity pre-check.
3. **Work a ticket:** take ENT-01 (above) and write the full ticket note using
   `templates/ticket-note.md`; save it to `docs/tickets/` (e.g. `ENT-01-account-lockout.md`).
4. **Self-grade:** does your note pass the "next tech can continue without asking you anything" test?
5. **Reflect** on where in the loop you felt least confident — that points to your next lessons.

### Lens D — the raw artifact (what a ticket record actually contains)
```
INC-0002 | Priority: P2 | Status: Resolved | Type: Incident | Category: Account/Access
Requester: asmith@corp.example | Asset: LT-0427 | Channel: Phone
Created: 2026-06-21 13:38 | First response: 13:39 | Resolved: 13:41 | SLA: met
Assignee: you | Resolution code: Unlocked account
[ work notes / public reply / internal note threads … ]
```
Every field is there for a reason — routing, SLA measurement, reporting, and audit. Understanding
the *record* (Lens D) is understanding what the queue is really doing.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/anatomy-of-a-ticket.md` — the ticket loop + identity-verification
   pre-check.
2. **Troubleshooting Guide:** `docs/troubleshooting/where-do-i-start.md` — the generic diagnostic
   spine as a starting decision guide.
3. **Ticket Notes:** `docs/tickets/ENT-01-account-lockout.md` — the worked ENT-01 note.
4. **KB Article:** `docs/kb/` — "How to change your Windows password" (end-user-facing).
5. **Incident Report:** N/A at this scale — note "single-user incident, ticket note suffices"
   (you'll write a full one at Lesson 31).
6. **Portfolio Artifact:** the §10 resume bullet + talking point.

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Documented a standardized service-desk ticket workflow (intake → identity
  verification → triage → resolution → documentation → closure) and a reusable ticket-note
  template, producing consistent, audit-ready records."*
- **Interview talking point:** the **ticket loop** and **impact × urgency** triage — be able to walk
  it end-to-end with the account-lockout example, including *why you verify identity first* and
  *why a great note names the suspected root cause*.
- **Serves:** Help Desk T1 (foundational for every role).

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2):** operational procedures — ticketing systems, documentation, professional
  communication, the troubleshooting methodology.
- **ITIL 4 Foundation:** service management basics, the service desk practice, incident vs request.
- **MS-900 / MD-102:** N/A directly (foundational). Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** the fix is half the job; the *experience* is the other half. Acknowledge fast, set
expectations, never go silent, confirm before closing. A user who feels heard forgives a slow fix;
a user who feels ignored resents a fast one.

**🔒 Security:** the service desk is the #1 social-engineering target — attackers call pretending to
be a user (or pretending to be IT) to get a reset or access. **Verify identity before you change
anything**, apply least privilege, never read a password aloud or send it in plain text, and be
suspicious of urgency + authority pressure ("I'm the CEO, do it now"). This thread deepens in
Lesson 29.

---

## Quiz (Interview-Style, Graded)

**Q1.** Walk me through the lifecycle of a single ticket from the moment it's created to closure.
> **Your answer:**

**Q2.** How do you decide a ticket's priority? Give the two factors and an example of each level.
> **Your answer:**

**Q3.** When should a T1 technician escalate a ticket, and what should the handoff include?
> **Your answer:**

**Q4.** **Scenario:** a caller says "I'm the new VP, I need the finance share unlocked right now,
I'm in a board meeting." What do you do and why?
> **Your answer:**

**Q5.** What's the difference between an Incident and a Request? Why does it matter?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `help desk ticket lifecycle`
- `IT support tiers T1 T2 T3`
- `impact urgency priority matrix`
- `incident vs service request ITIL`
- `first contact resolution FCR`

**Tools**
- `Jira Service Management queue basics`
- `ticket documentation best practices`

**Going further**
- `ticketing systems` (L15) · `help-desk workflows` (L16) · `ITIL fundamentals` (L17)

**Service / Security (Lens E):**
- 🤝 `setting customer expectations support`, `de-escalating an angry user`
- 🔒 `service desk social engineering`, `caller identity verification policy`

---

## Lesson Status
- [ ] §8 lab completed (runbook + worked ticket written)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 02 — Computer Hardware**.

---

*Lesson 01 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+
220-1102 operational procedures, ITIL 4 Foundation (service desk / incident management).*
