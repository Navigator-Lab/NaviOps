# Project 31 — Security Monitoring Project

**Goal:** prove you can stand up a security-monitoring capability — log collection, a SIEM, and a
baseline dashboard — and detect a simulated event **end-to-end** (event → log → alert → triage).

## Prerequisites
Lessons 04–06 (Linux logs / log management), 13–16 (SIEM + Wazuh). A lab host + the Wazuh stack
from Lesson 14.

## Build steps
1. **Log pipeline:** ensure auth/syslog/audit logs flow from a lab host (Wazuh agent) to the
   manager. Verify ingestion (`/var/ossec/logs/alerts/alerts.json`, dashboard).
2. **Baseline:** capture a "normal" day — what logs/alerts look like with no attack. Document the
   baseline (this is what makes anomalies visible).
3. **Dashboard:** build a SOC overview dashboard (alert volume by level, top sources, auth
   events, agent health). Export it (sanitized) to `docs/dashboards/`.
4. **Detect end-to-end:** generate a simple lab event (e.g. a failed-login burst), then show the
   full path: log line → Wazuh decoder → rule → alert → your triage note.
5. **Document:** write the monitoring-setup runbook + a short detection report for the event.

## Deliverables
- `infra/wazuh/` config proving the pipeline (sanitized).
- `docs/dashboards/soc-overview.md` (definition/export, sanitized).
- A monitoring runbook (`docs/runbooks/`) + an end-to-end detection report.
- `SOC-31` ticket (To Do → Closed).
- `PORTFOLIO.md` if this closes the Wave-2 milestone.

## Rubric
| Dimension | Pass bar |
|---|---|
| Pipeline | logs from ≥1 host reliably reach the SIEM |
| Baseline | "normal" documented, so abnormal is visible |
| Dashboard | answers "is anything wrong right now?" at a glance |
| End-to-end | one event traced log→decoder→rule→alert→triage |
| Documentation | someone else could rebuild it from your runbook |

## Resume line
"Built a security-monitoring pipeline (Wazuh SIEM + agents), baselined normal activity, and
demonstrated end-to-end detection of a simulated event with a SOC dashboard — `lessons/31`."
