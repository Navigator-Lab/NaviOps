# Shift Handover — NOC Module

A NOC runs 24/7, so the **handover** is how continuity survives across shifts. A bad handover
drops an in-flight Sev1; a good one lets the next shift pick up mid-incident with full context.

## Handover template

```
=== NOC SHIFT HANDOVER ===
Shift:        2026-06-20 Night (22:00–06:00)  →  Day (06:00–14:00)
Handed by:    <outgoing>      Received by: <incoming>

OPEN INCIDENTS (carry over):
  NAVI-21  Sev2  High latency to DB subnet — escalated to Tier 2 23:40, awaiting uplink
                 counter check on dist-switch-2. WATCH: latency_monitor p95.
  NAVI-24  Sev3  iface flap on uplink-2 — intermittent, 3 flaps overnight, ticket with Tier 2.

WATCH ITEMS (not incidents yet):
  - core-link util trending up (78% at 05:30) — may cross 80% alert in AM peak.
  - cert for vpn-gw expires in 6 days (NAVI-31, change scheduled).

CHANGES IN PROGRESS / FREEZE:
  - Change window 02:00–03:00 completed (VLAN 30 trunk added) — verify no fallout in AM.

DONE THIS SHIFT:
  - NAVI-19 resolved (DNS forwarder restored), verified, closed.

NOTHING ELSE OUTSTANDING. Monitoring green except items above.
```

## What carries over (and what doesn't)

- **Carries:** open incidents + state + next action, escalations awaiting response, watch
  items trending toward an alert, in-flight/recent changes, freezes.
- **Doesn't:** resolved+verified+closed tickets (mention briefly), routine noise.

## On-call / handover hygiene

- **Acknowledge** receipt — the incoming shift confirms they have context (no silent handoff).
- **Timestamps + ticket #s** for everything — the ticket is the source of truth, the handover
  is the index into it.
- **Watch items** are the value-add — they prevent the next shift being surprised.
- Keep it **scannable** — the incoming engineer reads it in 2 minutes before the desk is theirs.

## Lab tie-in
NOC capstone (Lesson 35) requires writing a handover at the end of the simulated shift,
including the still-open simulated incident. The template above is the deliverable format.
