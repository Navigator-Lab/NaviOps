# Lesson 16 — Help-Desk Workflows

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** how a professional service desk actually *operates* — the end-to-end workflow (intake →
triage → resolve → escalate → close), **First-Contact Resolution**, **warm handoffs**, **shift
handover**, prioritization under load, and the **metrics** (FCR/MTTR/SLA/CSAT) you're measured on. This
turns "I can fix one ticket" (L01/L15) into "I can run a queue."
**Primary artifact:** the consolidated **HELPDESK-PLAYBOOK** + a shift-handover template.

> **How to use this lesson:** read §1–§7, do §8 (run a simulated shift), produce §9, take the quiz,
> reflect. Then Lesson 17.

---

## §1 — Concept (Theory)

### What it is
A **help-desk workflow** is the repeatable operating rhythm of a support team: how tickets are taken,
prioritized, worked, escalated, communicated, handed off between shifts, and closed — plus the
**metrics** that tell you whether the desk is healthy. L01 taught the single ticket loop; L15 taught the
tool; this lesson is the **operating system of the desk** that ties them together at scale and under
load.

### Why it matters for support
Anyone can fix one calm ticket. The job is fixing *many*, in priority order, under SLA, while keeping
users informed and handing off cleanly — without dropping anything. Employers hire for this operational
discipline. The difference between a good and a struggling tech is rarely raw technical skill; it's
**workflow** (triage, communication, escalation, handover).

### Three-Level Depth (Lens A)
- **Level 1 — User:** "I asked for help and it got handled smoothly and I knew what was happening."
- **Level 2 — Technician:** run the loop at volume — work the **queue by priority + SLA risk**, resolve
  the common 80% at **first contact**, escalate the rest with a complete package, communicate proactively,
  and hand off cleanly at end of shift.
- **Level 3 — Engineer/Lead:** the desk is a **measured flow system** — arrival rate vs resolution rate
  (backlog), **FCR** (deflection of escalations), **MTTR** (cycle time), **SLA attainment**, **CSAT** —
  optimized via knowledge (KB, L28), self-service/automation (L33), shift-load balancing, and problem
  management (L32) to kill recurring ticket sources. This is *why* a KB article or a fixed root cause is
  worth more than a fast individual fix.

### Two Teaching Approaches (Lens B) — running the queue
**Approach 1 (technical):** the desk is a **prioritized queue with SLA deadlines**; you don't work FIFO,
you work **highest (Impact×Urgency) and most SLA-at-risk first**, batching where efficient, escalating
when a ticket exceeds your tier, and protecting first-response times. Throughput and SLA attainment are
the outputs.

**Approach 2 (analogy):** a help desk is an **ER during a busy shift** — you don't treat patients in
arrival order, you **triage by acuity**, stabilize quick cases fast (FCR), send complex cases to
specialists **with the chart** (warm handoff/escalation), keep waiting patients informed, and do a clean
**shift handover** so the next team knows who's mid-treatment. **Where it breaks down:** unlike an ER,
much of your "patient flow" is *preventable* — a good KB and fixing root causes (problem management)
reduce arrivals, something an ER can't do.

### Visual (ASCII) — the desk workflow & the metrics it produces
```
   INTAKE ─▶ TRIAGE(priority+SLA) ─▶ WORK ──┬─▶ RESOLVE@first contact (FCR) ─▶ CLOSE ─▶ CSAT
   (phone/                                   └─▶ ESCALATE (warm handoff +     ─▶ T2/T3
    email/portal/                                complete package) ───────────────┘
    chat/walk-up)        ▲                                                   end of shift ▼
                         └──────────────── SHIFT HANDOVER (open/at-risk/in-flight) ───────┘
   METRICS produced:  FCR · MTTR · SLA attainment · CSAT · backlog/aging
   LEVERS to improve: KB (L28) · self-service/automation (L33) · problem mgmt kills recurring sources (L32)
```

---

## §2 — Tools & Commands

Workflow is process; the "toolkit" is the set of operating practices + where each lives:

| Practice | What it is | Lives in / links |
|---|---|---|
| **Queue triage** | work by priority + SLA risk, not FIFO | ticketing views (L15) |
| **Impact × Urgency matrix** | the priority decision | HELPDESK-PLAYBOOK |
| **First-Contact Resolution** | resolve the common 80% now | KB (L28) + skills (L01–L14) |
| **Warm handoff / escalation** | complete package to T2/T3 | HELPDESK-PLAYBOOK escalation section |
| **Shift handover** | structured pass-down of open/at-risk | handover template (this lesson) |
| **Canned responses** | consistent, fast comms | ticketing (L15) |
| **Metrics dashboard** | FCR/MTTR/SLA/CSAT/backlog | reporting (L33) |

> The full operating manual is `docs/learning/playbooks/HELPDESK-PLAYBOOK.md` — this lesson teaches and
> exercises it.

---

## §3 — Real-World Support Context & Use Cases

- **A normal shift:** a steady queue, occasional spikes, a couple of escalations, and a handover at the
  end — all while keeping SLAs and users informed.
- **The common 80% (FCR targets):** password reset/unlock (L21), printer (L10), connectivity (L08),
  Outlook (L13), browser/SSO (L14), software install (L25), M365 how-to (L11). Resolving these at first
  contact is the single biggest performance lever.
- **Prioritization under load:** when everything's "urgent," Impact×Urgency + SLA risk decides; you
  communicate to the ones who must wait.
- **Warm handoffs:** the difference between "I'll transfer you" (cold, user repeats everything) and
  "I've briefed the network team and sent them your details" (warm) — the latter is the standard.
- **Shift handover:** the open P1s, the at-risk SLAs, the "waiting on user/vendor," and anything in
  flight — so nothing is dropped between shifts.
- **Exam framing:** ITIL (service desk practice, FCR, SLA, continual improvement), A+ (operational
  procedures, communication/professionalism).

---

## §4 — Demonstration (worked walkthrough)

**Watch me run 20 minutes of a busy queue.**

Queue snapshot: 1 P1 (a team can't access a shared app), 4 P3s, 2 P4 requests, plus a phone call coming
in.

1. **Scan & triage first, don't just grab the top:** identify the **P1** (highest Impact×Urgency) →
   it leads. Note which P3s are **SLA-at-risk** (oldest).
2. **Work the P1:** quick scope (how many? L08-style) → it's a real outage → **escalate as a major
   incident** (L31) with a complete package, own the **comms**, and link any duplicates (L15).
3. **Acknowledge everything fast:** even tickets you can't work yet get a first response + ETA (protects
   the response-SLA and CSAT).
4. **Batch the quick wins:** knock out two FCR-able P3s (a password reset, a printer offline) back to
   back.
5. **Warm handoff:** a P3 needs AD changes beyond your access → escalate to T2 **with the package**
   (symptom, tried, suspected cause) and tell the user "I've briefed the team, expect contact by X."
6. **Take the call:** log it (L15), triage, resolve or queue it appropriately.
7. **Update the waiting:** a quick proactive note to the P3s you haven't reached ("I'll be with you by
   X").

The point: **triage → protect SLAs with fast acknowledgement → FCR the easy wins → escalate the rest
warmly → keep everyone informed.** That rhythm *is* the job.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: the *desk itself* is underperforming (how to diagnose a struggling queue/shift).**

### 1 · Symptoms
SLA breaches climbing · growing backlog/aging · low FCR (too much escalated) · low CSAT · the same
tickets recurring · chaotic handovers / dropped tickets · agent overload.

### 2 · Possible Causes (most-likely first)
1. **No real triage** (working FIFO; P1s starved; everything "urgent").
2. **Low FCR** — gaps in skill/KB so easy tickets escalate.
3. **Recurring root causes** never fixed (problem-management gap, L32).
4. **Poor communication** (users chase; CSAT drops).
5. **Weak handover** (in-flight work dropped between shifts).
6. **No self-service/automation** (volume that could be deflected, L33).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | SLA-attainment + aging report | breaches/old tickets | enforce triage by priority+SLA risk |
| 2 | FCR rate + what's escalated | low FCR, easy tickets escalated | build KB (L28) + train the common 80% |
| 3 | Top recurring ticket types | one source dominates | raise a **Problem** (L32) to kill it |
| 4 | CSAT + "no update" complaints | low/late comms | canned responses + proactive updates |
| 5 | Handover quality / reopen-after-shift | drops at shift change | structured handover template |
| 6 | Volume vs self-service | deflectable volume | self-service/automation (L33) |

### 4 · Resolution Steps
Adopt priority+SLA-risk triage (stop FIFO); grow the **KB** and FCR skills; **fix recurring root
causes** via problem management (the biggest lever); standardize proactive comms (canned responses);
implement a **shift-handover** routine; deflect volume with self-service/automation (L33); rebalance
load.

### 5 · Escalation Criteria
Escalate to the **team lead / service-desk manager** for: staffing/load issues, SLA-policy changes,
recurring problems needing a problem owner (L32), and tooling/automation needs (L33). A spike that's an
outage → **major incident** (L31).

### 6 · Post-Incident Documentation
Shift handover notes; KB articles for newly-common issues (L28); problem tickets for recurring sources
(L32); the metrics trend feeds **continual improvement** (L17).

---

## §6 — Ticket Simulation

> **Ticket ENT-16 / shift scenario (P2 meta):** *It's 4:45pm. You have a P1 still in progress (vendor
> engaged), two P3s waiting on the user, and one P3 mid-diagnosis. Your shift ends at 5:00 and the next
> tech is coming on. A user also just walked up needing a quick password reset.*

**Triage:** the risk here is **dropping in-flight work at the shift boundary**. The skill is a clean
**handover** + a fast FCR for the walk-up.

**Worked resolution:**
1. **FCR the walk-up:** verify identity, reset the password (L21), confirm — a 3-minute win, done before
   handover (don't hand off something you can close now).
2. **Stabilize the in-flight P3:** reach a clean stopping point and write a crisp **internal note** of
   exactly where it stands and the next step (so the next tech resumes, not restarts).
3. **Write the shift handover** (template below): the **P1** (status, vendor ref, next checkpoint, comms
   owner), the **two pending-user P3s** (what you're waiting for, when to chase), and the **mid-diagnosis
   P3** (current hypothesis + next step).
4. **Brief the next tech** (warm, verbal + the written handover): 60 seconds on the P1 especially.
5. **Update the users** who are waiting that their tickets continue with the next tech ("you won't have
   to repeat anything").

**The shift-handover note:**
```
SHIFT HANDOVER — 17:00 (you → next tech)
P1  INC-0811 Email/app outage — VENDOR engaged (ref V-2231). Next checkpoint 17:15; I own comms until
    handed to you. Master ticket has 30 linked duplicates — keep updating the master only.
P3  INC-0204 DNS on VPN — PENDING USER (asked Marco to reconnect VPN + send ipconfig /all). Chase at
    17:30 if no reply.
P3  INC-0521 APIPA laptop — PENDING USER (Nadia rebooting; expect result by 17:20).
P3  INC-0513 Temp profile — MID-DIAGNOSIS. Hypothesis: ProfileList .bak; data confirmed safe. NEXT:
    apply documented ProfileList fix + reboot (L04 runbook). ~10 min.
Walk-up password reset (asmith) — RESOLVED/closed (no handover needed).
```

---

## §7 — Service Desk / ITIL Perspective

- **This lesson *is* the ITIL service-desk practice in action** (L17 covers the theory): intake,
  triage, FCR, escalation, SLAs, CSAT, and **continual improvement**.
- **FCR is the headline desk metric** — high FCR means users are served fast *and* T2/T3 isn't buried;
  it's driven by skill + KB + the right scope at T1.
- **SLA attainment + proactive comms** go together: the response clock is protected by fast
  acknowledgement, the resolution clock by triage and escalation discipline.
- **Continual improvement loop:** metrics → find the pain (recurring tickets, low FCR, SLA misses) →
  fix it (KB, problem management, automation) → measure again. This is what turns a reactive desk into a
  good one.
- **Handover is an SLA/continuity control** — dropped in-flight work breaches SLAs and tanks CSAT.

---

## §8 — Practical Lab (build this yourself)

**Goal:** run a simulated shift end-to-end and produce the operating artifacts.

### Lens C — Manual → Automation → Why
- **Manual:** triage and communicate ticket-by-ticket from memory.
- **Automated:** **automation rules** (auto-assign, SLA timers, escalation triggers), **canned
  responses**, **self-service** (password reset/SSPR, KB deflection), and **dashboards** turn the
  workflow into a system that scales (built in L33; designed here).
- **Why:** memory doesn't scale to a busy queue; automation enforces the workflow (nothing unassigned,
  SLA timers always running) so quality doesn't depend on how tired you are at 4:45pm.

### Steps
1. **Run the simulated shift:** take 8–10 tickets from `docs/tickets/INDEX.md` across priorities; triage
   the whole set first (priority + SLA risk), then work them in order, FCR-ing the common 80%.
2. **Practice a warm handoff/escalation** on one ticket — write the complete package (vs a cold "I'll
   transfer you").
3. **Hit a spike:** inject the duplicate-storm (L15) and handle it as a major incident (L31).
4. **End-of-shift handover:** write the handover note (template above) for whatever's open/at-risk/
   in-flight.
5. **Compute the metrics:** for your simulated shift, tally FCR %, count SLA-at-risk handled, note CSAT
   touchpoints — and identify the **one recurring source** you'd raise as a Problem (L32).
6. **Finalize artifacts:** the HELPDESK-PLAYBOOK is your reference; produce the **shift-handover
   template** and a **shift metrics summary**.

### Lens D — the raw artifact (a metrics snapshot drives improvement)
```
   SHIFT METRICS (simulated):
     Tickets handled: 12   FCR: 8/12 (67%)   SLA met: 11/12   CSAT touchpoints: 12   Escalated: 4
     Top source: 3× "account locked" (all from stale cached mobile creds)
   → INSIGHT: the 3 lockouts share ONE root cause → raise a PROBLEM (L32): user education + KB-0002 +
     consider device cred-refresh guidance. Fixing the source removes future tickets — worth more than
     fixing each lockout fast.
#   Metrics aren't a scorecard for its own sake — they point at the improvement that reduces tomorrow's
#   queue.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** the consolidated `docs/learning/playbooks/HELPDESK-PLAYBOOK.md` (intake→close, priority
   matrix, escalation package, comms scripts) — referenced/owned by this lesson.
2. **Troubleshooting Guide:** `docs/troubleshooting/struggling-queue.md` — the meta spine (diagnose a
   underperforming desk).
3. **Ticket Notes:** the simulated-shift tickets + the handover note (`docs/tickets/ENT-16-shift-
   handover.md`).
4. **KB Article:** `docs/kb/` — "What to expect when you contact the Service Desk" (end-user
   expectations) and/or an internal "common 80% quick-fixes" index.
5. **Incident Report:** the spike handled during the shift (links L31).
6. **Portfolio Artifact:** §10 bullet + the run-a-queue / FCR / warm-handoff talking points.
7. **Template:** the **shift-handover template** (`docs/templates/` or the playbook).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Ran a service-desk queue end-to-end: Impact×Urgency triage, first-contact
  resolution of the common 80%, warm escalations with complete handoff packages, structured shift
  handovers, and tracked FCR/MTTR/SLA/CSAT to drive continual improvement."*
- **Interview talking point:** **how you prioritize when everything's urgent** (Impact×Urgency + SLA
  risk, not FIFO), **FCR + warm handoffs**, the **shift-handover** discipline, and using **metrics to
  find and fix recurring sources** (problem management) rather than only fixing fast.
- **Serves:** Help Desk T1/T2 (and the foundation for a team-lead path).

---

## §11 — Certification Crossover Notes

- **ITIL 4 Foundation:** service desk practice, incident management, SLAs, continual improvement —
  central. **CompTIA A+ (Core 2):** professionalism/communication and operational procedures. Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** this lesson is *mostly* the service skill — prioritization that's fair and transparent,
proactive communication so no one is left in the dark, warm handoffs so users never repeat themselves,
and de-escalating frustration with empathy + a clear next step. This is what CSAT actually measures.

**🔒 Security:** under queue pressure is exactly when techs cut corners attackers exploit — **never skip
identity verification because you're busy** (L29), keep sensitive detail in internal notes (L15), and
treat an urgency-+-authority push ("I'm an exec, just do it now") as a *prompt to verify*, not to rush.
A clean shift handover also matters for security continuity (an in-progress security incident must hand
off completely — L31/L29).

---

## Quiz (Interview-Style, Graded)

**Q1.** You have 12 open tickets and a P1 just came in. How do you decide what to work first?
> **Your answer:**

**Q2.** What is First-Contact Resolution, why does it matter so much, and name three ticket types that
should be FCR at T1?
> **Your answer:**

**Q3.** Describe a "warm handoff" and why it's better than just transferring the user.
> **Your answer:**

**Q4.** **Scenario:** your shift ends in 15 minutes with a P1 in progress and several tickets waiting on
users. What do you do before you leave?
> **Your answer:**

**Q5.** Your desk's FCR is dropping and the same three issues keep recurring. What does that tell you and
what would you do about it?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `help desk workflow intake triage escalate close`
- `first contact resolution FCR improve`
- `warm handoff escalation package`
- `service desk shift handover best practices`
- `help desk metrics FCR MTTR SLA CSAT`

**Tools**
- `ticket prioritization under load`
- `canned responses proactive communication`

**Going further**
- `ITIL fundamentals` (L17) · `documentation and knowledge bases` (L28) · `incident management` (L31) ·
  `root cause analysis` (L32) · `jira service management` (L33)

**Service / Security (Lens E):**
- 🤝 `de-escalating frustrated users`, `prioritization transparency`, `proactive updates CSAT`
- 🔒 `don't skip identity verification under pressure`, `secure shift handover in-progress incident`

---

## Lesson Status
- [ ] §8 lab completed (simulated shift + warm handoff + handover note + shift metrics)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 17 — ITIL Fundamentals**.

---

*Lesson 16 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: ITIL 4 Foundation
(service desk, incident, continual improvement), CompTIA A+ 220-1102 (professionalism/procedures).*
