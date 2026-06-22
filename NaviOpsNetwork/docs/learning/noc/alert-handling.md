# Alert Handling — NOC Module

## The alert lifecycle

```
   fire ──► triage ──► acknowledge ──► investigate ──► act ──► resolve ──► review
    │          │            │              │            │         │           │
 monitor    is it real?   I own it      runbook/      fix or    clear +    tune the
 threshold  sev/impact    (stop the     diagnose      escalate  document    alert if
 crossed    dedup         clock)                                            it was noise
```

## Severity rubric (typical NOC)

| Sev | Meaning | Example | Response |
|---|---|---|---|
| **Sev1 / P1** | Major outage, customer-impacting | Core link down, site offline, DNS down | Immediate, escalate, bridge call, comms |
| **Sev2 / P2** | Significant degradation | High latency/loss on a key path, redundancy lost | Urgent, within SLA, may escalate |
| **Sev3 / P3** | Minor / single-user / non-urgent | One non-critical interface flapping | Queue, handle in shift |
| **Sev4 / P4** | Informational / maintenance | Cert expiring in 30 days | Track, schedule |

## Actionable vs noise (the NOC's hardest skill)

A good alert is **actionable**: it tells you *what*, *where*, *how bad*, and points to a
**runbook**. Noise (flapping, duplicate, self-resolving, no-impact) erodes trust and causes
**alert fatigue** — the real danger, because it hides the Sev1 in a sea of Sev4.

- **Deduplicate**: 500 "interface down" alerts from one switch reboot = one incident.
- **Correlate**: DNS-resolution alerts + web-app alerts at the same timestamp = one root cause.
- **Suppress during maintenance**: planned change ≠ incident.
- **Tune at review**: every false alert gets a threshold/condition fix — alerts you ignore are
  worse than no alert.

## Runbook-per-alert

Every meaningful alert should link to a runbook: *what it means, first 3 diagnostic commands,
known causes, when to escalate*. This platform builds these in `docs/runbooks/` — one per NOC
scenario (`noc-scenarios.md`).

## Lab tie-in
- Lesson 21 (monitoring) sets thresholds/baselines that *generate* alerts.
- Lesson 22 (Prometheus/Alertmanager) implements dedup/grouping/routing.
- Every troubleshooting drill (`troubleshooting-drills.md`) starts from a simulated alert.
