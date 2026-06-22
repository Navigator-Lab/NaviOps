# Ticket Management — NOC Module

Tickets are the **system of record** for a NOC. ServiceNow / Remedy / Jira Service Management
are the common tools; the *workflow* transfers directly. This platform uses a lightweight
**NAVI** scheme so every lesson produces a real ticket trail (the Artifact Contract §9).

## Ticket types

| Type | When | Example |
|---|---|---|
| **Incident** | something is broken / degraded | "DNS resolution failing for site B" |
| **Change** | a planned modification | "Add VLAN 30 trunk to dist-switch" |
| **Problem** | root cause behind recurring incidents | "Repeated link flaps on uplink-2" |
| **Request / Task** | routine work | "Provision monitoring for new host" |

## Lifecycle

```
To Do ──► In Progress ──► (Escalated?) ──► Resolved ──► Closed
  │            │                              │            │
 created    being worked    handed to       fixed +     verified +
 + triaged  + diagnostics   higher tier     documented  no recurrence
```

## The NAVI scheme (this repo)

- ID: `NAVI-NN` (e.g. `NAVI-13` for the Lesson-13 DNS work).
- Each lesson opens a ticket, moves it To Do → In Progress → Done, and **links it to the
  closing commit**. Incident for a drill/outage, Change for a config change, Task for a build.
- The ticket lives as a row in the lesson's `§9 GitHub Artifact` section + a commit message ref.

## What makes a good ticket (interview-relevant)

A good ticket is one another engineer can act on without asking you anything:

```
Title:    [Sev2] High latency to DB subnet 10.0.20.0/24 from app tier
Impact:   App response times 3–8s (normal <500ms); ~40 users affected
Started:  2026-06-20 14:05 (alert: latency_monitor p95 > 200ms)
Symptom:  mtr from app01 shows 180ms + 8% loss at hop 3 (dist-switch-2)
Checked:  ping gateway OK; ss shows connections established but slow;
          ip -s link on app01 = no iface errors; hop 1–2 clean
Suspect:  congestion or duplex mismatch at dist-switch-2 uplink
Next:     escalate to Tier 2 to inspect dist-switch-2 uplink counters
Ticket:   NAVI-21   Commit: <sha>
```

- **Specific** (numbers, IPs-as-ranges, timestamps), **scoped** (who/how many), **evidence-backed**
  (commands run), **actionable** (next step), **traceable** (ticket # + commit).

## Lab tie-in
Every lesson's §9 produces a NAVI ticket. Lesson 26 (network IR) + capstone 35 (NOC) require
a full incident-ticket trail. Sibling NaviOps used the same scheme (`JIRA.md`) — concepts map
1:1 to ServiceNow/Jira SM.
