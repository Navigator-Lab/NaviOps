# Outage Management — NOC Module

How a NOC runs a **major incident (Sev1)** from declaration to post-incident review. This is
the high-pressure core of the job; structure beats panic.

## The flow

```
DETECT ─► DECLARE ─► COORDINATE ─► COMMUNICATE ─► RESOLVE ─► RECOVER ─► REVIEW
  │          │            │             │            │          │          │
 alert/    raise to    bridge call,  status to    fix the   confirm    blameless
 report    Sev1 +      roles         stakeholders root /     full       PIR + action
           IC assigned assigned      + customers  failover  restore    items
```

## Roles in a major incident

| Role | Owns |
|---|---|
| **Incident Commander (IC)** | the response, decisions, not the keyboard |
| **Ops/Tech lead** | the actual diagnosis + fix |
| **Comms lead** | stakeholder + customer updates on a cadence |
| **Scribe** | the timeline (feeds the RCA) |

In a small NOC one person may wear several hats — but the *functions* still exist.

## Communication discipline

- **Cadence:** regular updates even when "no change" (e.g. every 15–30 min for Sev1) — silence
  reads as chaos.
- **Audience-appropriate:** engineers get technical detail; business/customers get impact +
  ETA + workaround, no jargon.
- **One source of truth:** the incident ticket/bridge — not scattered DMs.

## Restore first, RCA second

The priority order during an outage:
1. **Restore service** (failover, reroute, roll back the change) — even if you don't yet know
   the root cause.
2. **Preserve evidence** (captures, logs, counters) *before* it rolls off — you'll need it for RCA.
3. **Then** root cause + prevention (post-incident review, `rca.md`).

> Common mistake: chasing root cause while customers are down. Restore (workaround/failover)
> first if you can; understand later.

## Post-incident review (PIR)
Within ~48h, blameless: timeline, root cause, what went well, what didn't, action items with
owners + dates, detection/prevention gaps. Output → `docs/runbooks/` incident report + RCA block.

## Lab tie-in
NOC capstone (Lesson 35) runs a simulated Sev1 end-to-end with this flow, produces the incident
runbook + PIR, and reports MTTD/MTTR (`sla-concepts.md`).
