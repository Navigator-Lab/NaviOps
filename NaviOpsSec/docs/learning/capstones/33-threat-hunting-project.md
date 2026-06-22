# Project 33 — Threat Hunting Project

**Goal:** prove you can hunt — run a **hypothesis-driven** hunt through host + SIEM data, document
the findings (including "found nothing, here's the coverage I confirmed"), and **convert a
finding into a new detection**.

## Prerequisites
Lessons 09–12 (threat intel / ATT&CK / kill chain / IOCs), 16 (log-analysis workflows), 25
(threat hunting), 26–27 (detection engineering / Sigma).

## Build steps
1. **Form a hypothesis** anchored to ATT&CK — e.g. "An attacker established **cron persistence**
   (T1053) on a lab host" or "There is **outbound beaconing** (T1071) we don't alert on."
2. **Gather the data:** the relevant logs/telemetry (cron logs, `auditd`, network connections via
   `ss`/`tcpdump`, Wazuh data).
3. **Hunt:** query for the technique's evidence (`/scripts` + SIEM). Stage benign telemetry first
   if you need a positive to find (lab-only).
4. **Analyze:** TP/FP each hit, scope it, build a mini-timeline for anything real.
5. **Document the hunt** (`docs/playbooks/hunt-template.md` filled): hypothesis, data, queries,
   findings, and **coverage confirmed** (what you can now say is clean).
6. **Operationalize:** turn the strongest finding (or gap) into a **new detection** (Sigma →
   Wazuh) so the hunt becomes permanent coverage.

## Deliverables
- A completed hunt report (`docs/runbooks/hunt-NN.md`).
- The new detection committed (`docs/detections/`).
- `ioc_sweep.sh` (or the hunt script) extended for the hunted technique.
- `SOC-33` ticket.

## Rubric
| Dimension | Pass bar |
|---|---|
| Hypothesis | specific + ATT&CK-anchored (not "look for bad stuff") |
| Method | documented data + queries, reproducible |
| Findings | TP/FP'd + scoped; "nothing found + coverage confirmed" is a valid result |
| Operationalized | a finding/gap became a committed detection |

## Resume line
"Ran a hypothesis-driven threat hunt (ATT&CK T-xxxx) across host and SIEM telemetry, documented
findings and coverage, and converted the result into a new committed detection — `lessons/33`."
