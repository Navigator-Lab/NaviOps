# Lesson 34 — Service Desk Capstone

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (capstone variant) (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the integrative project for **Help Desk T1/T2** — run a simulated service desk: **handle 50
tickets**, document resolutions, **create KB articles**, **perform escalations**, and **produce a metrics
report**. Proves you can *work a queue*, not just recite facts. Pulls together Modules A–E (+ H).
**Primary artifact:** the capstone portfolio package — `docs/learning/capstones/34-service-desk-project.md`.

> **How to use this capstone:** read §1–§4 (the brief + how it integrates), execute §5–§8 (run the desk),
> produce §9 (the portfolio package), self-assess §10. This is a *project*, not a reading lesson.

---

## §1 — Concept (the capstone brief)

You are the service desk for **Corp (corp.example)**. Over a simulated period you will **work a queue of
50 tickets** drawn from `docs/tickets/INDEX.md` (the 100+ library) across all categories — account/access,
connectivity, hardware, email/M365, software, printing — applying everything from Modules A–E: the
**ticket loop** (L01), the **diagnostic spine**, **triage by Impact×Urgency + SLA** (L16), **FCR** on the
common 80%, **warm escalations** (L16), and clean **documentation** (L15/L28). You'll spin up **KB
articles** to deflect repeats, handle at least one **major incident** (L31) and one **security** event
(L29), and finish with a **metrics report** (FCR/MTTR/SLA/CSAT/backlog) that shows you understand the
*business* of support.

**This capstone proves:** you can run a real queue under SLA, communicate, escalate cleanly, document, and
report — i.e. you're hireable as Help Desk T1/T2.

---

## §2 — What it integrates (the lessons behind it)

| Capability | From |
|---|---|
| Ticket loop · triage · priority · SLA · FCR · handoffs · shift handover | L01, L15, L16, L17 |
| The technical fixes (account/network/hardware/email/M365/software/print) | L02–L14, L21 |
| Documentation: ticket notes, runbooks, troubleshooting guides, KB | L15, L28 |
| Major incident handling (the duplicate-storm / outage) | L31 (+L08/L15) |
| Security event handling (phishing/compromise/social-eng) | L29 (+L13/L21) |
| Metrics + continual improvement (find recurring sources → problem) | L16, L32 |

---

## §3 — Real-World framing

This *is* a Help Desk T1/T2 role, compressed. Employers don't ask "define DHCP" — they ask "here's the
queue, go." The capstone is the closest thing to the job: a realistic mix of tickets, real SLAs, an outage
that tests your incident handling, a security event that tests your judgment, and a metrics report that
tests whether you understand what the desk is *for*. The output is a **portfolio package** you can show in
an interview: "here's a service desk I ran, the tickets I worked, the KBs I wrote, and the metrics."

---

## §4 — Demonstration (the standard to match)

The platform already demonstrated the unit skills (each lesson's §4/§6 worked a ticket; ENT-08 a major
incident; ENT-29 a security event; ENT-16 a shift). This capstone is **doing it at volume, end-to-end,
self-directed** — to the standard those examples set: every ticket triaged + documented to the L01 note
format, escalations packaged (L16), the outage run as an IC (L31), the security event contained + escalated
(L29), and the whole thing measured.

---

## §5 — The project (run the desk)

### Stage 1 — Work 50 tickets
- Pull **50 tickets** from `docs/tickets/INDEX.md` spanning all categories + priorities (P1–P4).
- **Triage the whole set first** (Impact×Urgency + SLA risk — L16), then work them in priority order.
- For each: apply the **diagnostic spine**, resolve (FCR the common 80%) or **escalate with a package**
  (L16), and write a **professional ticket note** (L01 format) — save to `docs/tickets/` (or a capstone
  ticket log).
- Track time-to-respond / time-to-resolve vs a notional SLA per priority.

### Stage 2 — Handle a major incident
- Inject an **outage** (e.g. the floor-network outage L08/ENT-08 or the email duplicate-storm L15) → run
  it as an **Incident Commander** (L31): declare, master ticket + link duplicates (L15), comms cadence,
  restore (workaround), timeline, resolve → RCA handoff (L32). Produce the **incident report**.

### Stage 3 — Handle a security event
- Inject a **security event** (phishing victim / account takeover — L29/ENT-29): recognize → **contain**
  (disable + revoke sessions, L20/L21) → escalate to security. Produce the **security incident note**.

### Stage 4 — Create KB articles (deflection)
- Identify the **recurring** ticket types in your 50 → write/refine **KB articles** (L28, to the quality
  checklist) so those deflect next time. Aim for ≥5 (e.g. password reset, VPN, Wi-Fi, printer, email).

### Stage 5 — Produce the metrics report
- Compute and report: **FCR %**, **MTTR**, **SLA attainment**, **CSAT** (touchpoints), **backlog/aging**,
  ticket **volume by category**, and the **top recurring source** → recommend a **problem record** (L32)
  + a deflection/automation action (L16/L33). This is the centerpiece deliverable.

---

## §6 — Ticket Simulation (the queue is the simulation)

The whole capstone is the simulation — the 50-ticket queue, the injected major incident, and the security
event. Use the `docs/tickets/INDEX.md` library as the source; the worked examples (ENT-01…ENT-33) are your
quality reference for notes, escalations, the incident, and the security response.

---

## §7 — Service Desk / ITIL Perspective

This capstone *is* the ITIL service-desk practice in action (L17): incidents + service requests worked
under SLA, a major incident (L31), a problem identified from metrics (L32), KB/knowledge management (L28),
and continual improvement (L16). The metrics report is how the desk is held accountable and improved.

---

## §8 — Execution checklist

- [ ] 50 tickets triaged (Impact×Urgency + SLA) and worked in priority order
- [ ] Every ticket documented to the L01 note standard (public/internal split, L15)
- [ ] FCR on the common 80%; the rest escalated with complete packages (L16)
- [ ] One **major incident** run as IC + incident report (L31)
- [ ] One **security event** contained + escalated + note (L29)
- [ ] ≥5 **KB articles** created/refined to the quality checklist (L28)
- [ ] **Metrics report** (FCR/MTTR/SLA/CSAT/backlog/volume + recommended problem + deflection)
- [ ] Portfolio package assembled (§9)

---

## §9 — GitHub Artifact (the capstone portfolio package)

Assemble in `docs/learning/capstones/34-service-desk-project.md` (+ supporting files):
1. **The ticket log** — 50 worked tickets (notes; link to `docs/tickets/`).
2. **The major-incident report** (`docs/templates/incident-report.md`).
3. **The security-incident note** (L29).
4. **The KB articles** created (`docs/kb/`).
5. **The metrics report** — FCR/MTTR/SLA/CSAT/backlog/volume + the recommended problem + deflection action.
6. **A short "what I'd improve" reflection** (continual improvement, L16).

This package is the single strongest **Help Desk** portfolio piece — "a service desk I ran."

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Ran a simulated service desk end-to-end: triaged and resolved 50 tickets under SLA
  with first-contact resolution, commanded a major incident, contained a security event, authored KB
  articles for deflection, and produced an FCR/MTTR/SLA metrics report driving a problem record and
  automation improvements."*
- **Interview talking point:** walk through **running the queue** (triage→FCR→escalate→document), the
  **major incident** (IC), the **security event** (recognize→contain→escalate), and **what the metrics told
  you** (the recurring source → problem/deflection). This is your flagship "I can do the job" story.
- **Serves:** Help Desk Tier 1 → Tier 2 (the hireable proof).

---

## §11 — Certification Crossover Notes

Integrates **ITIL 4** (service desk/incident/problem/SLA), **CompTIA A+** (troubleshooting + operational
procedures across the queue), and touches **Network+/MS-900** (the network/M365 tickets). Detail in
`alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** the capstone is graded as much on **communication, triage fairness, and documentation** as
on technical fixes — that's what the desk is judged on (CSAT/SLA). Run it like a real shift.

**🔒 Security:** the injected security event tests the non-negotiables — **verify identity, recognize the
attack, contain (disable + revoke), escalate** (L29) — under the pressure of a busy queue, which is exactly
where techs slip. Handling it correctly *while* the queue is busy is the mark of a pro.

---

## Quiz (Interview-Style, Graded) — capstone debrief

**Q1.** Walk me through how you ran your 50-ticket queue — how did you decide order, and what was your FCR?
> **Your answer:**

**Q2.** Tell me about the major incident you handled — your role, the comms, and restore vs root cause.
> **Your answer:**

**Q3.** What did your metrics report reveal, and what improvement did you recommend?
> **Your answer:**

**Q4.** How did you handle the security event in the middle of a busy queue?
> **Your answer:**

**Q5.** If you ran this desk for a month, what's the one change that would most reduce ticket volume?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the capstone)* — What was hardest at volume? · Where did your documentation/triage slip under
pressure? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `service desk metrics report FCR MTTR SLA CSAT`
- `help desk queue triage at volume`
- `ticket documentation portfolio`
- `major incident commander service desk`
- `KB deflection reduce ticket volume`

**Going further**
- `IT support capstone` (L35) · `junior sysadmin capstone` (L36) · all of Modules A–E + L31/L32

**Service / Security (Lens E):**
- 🤝 `running a queue communication CSAT`
- 🔒 `security event under queue pressure` (→ NaviOpsSec)

---

## Capstone Status
- [ ] 50 tickets worked + documented · major incident · security event · ≥5 KB · metrics report
- [ ] Portfolio package assembled (`capstones/34-service-desk-project.md`)
- [ ] Debrief quiz answered + professional-answer comparisons
- [ ] Reflection complete

When complete, run the Update Protocol, then move to **Lesson 35 — IT Support Capstone**.

---

*Lesson 34 written by Navi · 2026-06-21 · full-depth (capstone). Integrates Modules A–E + L31/L32; sources
per the integrated lessons.*
