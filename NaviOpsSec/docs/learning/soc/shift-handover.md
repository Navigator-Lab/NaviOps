# Shift Handover — SOC Module

A SOC runs 24/7 across shifts; an attacker doesn't stop at the end of yours. The handover note is
how continuity survives the shift change — the next analyst must pick up open incidents with zero
context loss.

## The handover note (template)

```
=== SOC SHIFT HANDOVER ===
Shift: 2026-06-20 22:00Z → 06:00Z      Analyst: <you>      To: <next analyst>

OPEN INCIDENTS (action required)
- SOC-19 (Sev2, Investigating): brute force → successful login on web01. Evidence collected,
  NOT yet contained (awaiting T2 confirm). NEXT: T2 to approve block of 203.0.113.50.
- SOC-22 (Sev3, Investigating): new user `svc_tmp` on db01 at 23:40Z. Scoping persistence.
  NEXT: check cron + authorized_keys, confirm with sysadmin if change was planned.

WATCH ITEMS (no action yet, keep an eye)
- Elevated failed-login noise from 10.0.5.0/24 — looks like a misconfigured app, not an attack.
  Suppressed for 4h; revisit if it changes shape.

ENVIRONMENT / CHANGES
- Wazuh manager restarted 22:10Z (config reload) — brief gap in alerts 22:09–22:12Z.
- Planned maintenance on host03 00:00–01:00Z — expect agent-offline alerts, do NOT escalate.

CLOSED THIS SHIFT
- SOC-21 (FP, tuned): vuln-scanner traffic from 10.0.0.9 — added to allowlist.

METRICS: alerts handled 47 · escalated 2 · FPs tuned 5 · open at handover 2
```

## Rules for a good handover

- **Open incidents first**, each with an explicit **NEXT** action — the next analyst should never
  have to guess what you'd do.
- **Distinguish watch items from incidents** — don't bury a real open case under noise.
- **Note environment changes** (restarts, maintenance, alert gaps) — they explain anomalies the
  next shift will see.
- **State suppressions and their expiry** — a forgotten suppression is a blind spot.
- **Numbers at the bottom** — feeds the metrics (`soc-metrics-sla.md`).

## Lesson tie-in
Lesson 34 (SOC Operations Project) ends a simulated shift by writing this note — the deliverable
proves you can hand over cleanly, which every SOC interview probes ("how do you do handover?").
