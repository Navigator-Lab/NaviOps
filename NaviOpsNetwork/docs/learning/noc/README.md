# NOC Operations Modules — NaviOpsNetwork

The **operational** half of the platform: how a Network Operations Center actually runs a
shift. Lesson §6 (NOC perspective) and §7 (Incident-response perspective) draw on these
modules; the **NOC capstone (Lesson 35)** exercises all of them in one simulated shift.

| Module | What it covers |
|---|---|
| [alert-handling.md](alert-handling.md) | alert lifecycle, severity, deduplication, actionable vs noise, runbook-per-alert |
| [escalation-matrix.md](escalation-matrix.md) | tiers, when/how to escalate, severity → owner mapping, comms |
| [ticketing.md](ticketing.md) | ticket types, lifecycle, the NAVI scheme, quality of a good ticket |
| [shift-handover.md](shift-handover.md) | handover template, what carries over, on-call hygiene |
| [rca.md](rca.md) | root-cause analysis methods (5 Whys, fault-domain isolation, fishbone) |
| [sla-concepts.md](sla-concepts.md) | SLA/SLO/SLI, availability math, MTTR/MTBF, error budgets |
| [outage-management.md](outage-management.md) | declare → coordinate → comms → resolve → post-incident review |
| [noc-scenarios.md](noc-scenarios.md) | the 8 realistic NOC scenarios + first-move playbooks |

> These are concise operational references, not lessons — they're the "how a NOC works"
> knowledge that turns networking theory into a job. Each lesson's §6/§7 links back here.
