# Capstone 35 — NOC Capstone (Run a Simulated 24/7 NOC Shift)

**Proves:** you can operate like a NOC Technician — monitor, triage, troubleshoot, ticket,
escalate, document, and hand over — under realistic time pressure.
**Prereqs:** Lessons 01–27 + all NOC modules (`docs/learning/noc/`).
**Tooling:** the monitoring stack from Lesson 22 (Prometheus/Grafana/blackbox + node/snmp
exporters) running against a small lab; the troubleshooting drills as the injected incidents.

## The simulation

You run a **simulated shift** against your lab. A driver (a script or a second person) injects
faults from `troubleshooting-drills.md` at unknown times. You operate the shift as if it were
real: dashboards on screen, tickets open, clock running.

### Setup
1. Stand up `infra/monitoring/` (Grafana dashboard = the "NOC screen").
2. Define alerts with thresholds/baselines (Lesson 21) so faults *fire* as alerts.
3. Prepare the runbook index (`docs/runbooks/`) and the NAVI ticket board.

### The shift (inject 3–4 incidents over the window)
Suggested injection set (mixed severity), drawn from the 8 drills:
- **Sev1:** DNS outage (drill 1) — site-wide impact.
- **Sev2:** high latency to a subnet (drill 3) — degradation.
- **Sev2:** firewall blocking a service after a "change" (drill 8).
- **Sev3:** interface flap (drill 5) — single link.

## What you must do for each incident (the operating loop)

```
alert fires ─► triage (sev + scope) ─► open ticket ─► acknowledge (stop MTTA clock)
   ─► diagnose with the runbook (capture evidence INTO the ticket)
   ─► fix OR escalate (with a complete handoff packet)
   ─► verify ─► resolve + document (RCA) ─► tune the alert if it was noisy
```

## Deliverables (the artifacts)

1. **Ticket trail** — one `NAVI-NN` Incident ticket per injected fault, To Do→In Progress→
   Resolved, each with evidence + RCA, linked to a commit.
2. **Incident runbooks** — `docs/runbooks/` report per incident (symptom→diagnose→fix→verify→RCA).
3. **Shift metrics** — MTTD + MTTR per incident (`noc/sla-concepts.md`), and which SLO each
   breached/held.
4. **Escalation packet** — for ≥1 incident, the full Tier-2 handoff (`noc/escalation-matrix.md`).
5. **Shift handover** — the end-of-shift handover doc with any still-open incident
   (`noc/shift-handover.md` template), leaving one incident deliberately open.
6. **PORTFOLIO.md** — "ran a simulated NOC shift: N incidents, MTTR X, escalation + handover"
   + interview talking points.

## Grading rubric (self-assess honestly)

| Dimension | Pass bar |
|---|---|
| Triage | correct severity + scope within minutes |
| Method | bottom-up, evidence captured *before* changes |
| Ticketing | every incident traceable, actionable, linked to commit |
| Escalation | clean handoff packet, right trigger |
| Documentation | runbook + RCA per incident, blameless |
| Handover | scannable, carries open state |
| Communication | severity-appropriate impact statements |

## Done when
All injected incidents are resolved/escalated with tickets + runbooks, shift metrics are
reported, the handover is written, and `PORTFOLIO.md` is complete. Open `NAVI-35` (master
Incident) referencing the per-incident tickets.
