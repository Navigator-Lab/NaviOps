# Escalation Matrix — NOC Module

Escalation is **structured handoff of an incident to the right owner at the right time** — not
"giving up." Knowing *when* and *how* to escalate is a core NOC-interview topic.

## Tiers

| Tier | Who | Scope |
|---|---|---|
| **Tier 1 (NOC Technician)** | you | monitor, triage, run the runbook, basic fixes, route tickets |
| **Tier 2 (NetOps / Sr NOC)** | network engineers | config changes, routing/switching deep-dives, vendor TAC |
| **Tier 3 (Network/Systems Engineering)** | senior/SME | design issues, code/firmware bugs, architectural fixes |
| **Vendor TAC** | Cisco/Juniper/ISP | hardware RMA, bug confirmation, carrier circuit faults |
| **Management / Incident Commander** | duty manager | Sev1 coordination, business comms, major-incident bridge |

## When to escalate (triggers)

- **Severity:** any Sev1 escalates immediately (and notify management).
- **Time-box:** Tier 1 hasn't resolved within the SLA target for that severity → escalate.
- **Scope:** beyond your access/permission (e.g. a config change on a production core switch).
- **Risk:** the fix itself is risky (could cause a bigger outage) — get a second owner.
- **External dependency:** it's the ISP/carrier/cloud provider → open a carrier ticket.

## Severity → owner (example mapping)

| Severity | First responder | Escalate to | Notify |
|---|---|---|---|
| Sev1 | Tier 1 → Tier 2 immediately | Tier 3 + vendor as needed | Incident Commander + mgmt |
| Sev2 | Tier 1 | Tier 2 if not resolved in SLA | shift lead |
| Sev3/4 | Tier 1 | Tier 2 only if blocked | none |

## How to escalate (the handoff quality)

A clean escalation carries the **context so the next tier doesn't restart**:
1. **What** — symptom + severity + customer/business impact.
2. **Where** — device/segment/service, scope (one user vs site-wide).
3. **When** — start time, whether ongoing or intermittent.
4. **What you've checked** — diagnostics run + results (so they don't repeat them).
5. **Why escalating** — time-box / scope / access / risk.
6. **Ticket #** — everything is in the ticket; escalation references it.

> Bad escalation = "the network's broken, help." Good escalation = a 5-line summary + ticket
> that lets Tier 2 act in 60 seconds. This is exactly what `tcpdump`/`mtr`/`dig` evidence from
> the lessons feeds into.

## Lab tie-in
NOC capstone (Lesson 35) requires escalating a simulated Sev1 with a complete handoff packet.
