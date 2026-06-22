# Project 34 — SOC Operations Project

**Goal:** prove you can **operate a SOC shift** — work a queue of mixed alerts (real + noise),
triage and prioritize, escalate correctly, manage cases, and hand over cleanly. This exercises
every `soc/` module at once.

## Prerequisites
Lessons 17 (triage), 18–24 (detections that feed the queue), 28–30 (IR + reporting). The Wazuh
stack + the `soc/` modules.

## Build steps
1. **Generate a mixed queue** (lab): stage several benign telemetry events of different types and
   severities (a brute force, a port scan, a new user, a vuln-scan FP, a noisy app), so the
   queue has real incidents *and* noise.
2. **Run the shift:** for each alert — triage (TP/FP), set severity, scope, open a `SOC-NN` case,
   investigate to the right depth, and **decide** (close+tune / handle / escalate).
3. **Prioritize:** work them in the right order (Sev1 before Sev4) under a notional SLA.
4. **Escalate** the ones that meet the triggers (`soc/escalation-matrix.md`) with a proper
   escalation note.
5. **Manage cases:** every case gets a timeline + resolution (`soc/case-management.md`).
6. **Hand over:** write the shift-handover note (`soc/shift-handover.md`) and the shift metrics
   (`soc/soc-metrics-sla.md`).

## Deliverables
- The case tickets (`SOC-NN` set) with triage decisions + timelines.
- The shift-handover note.
- A shift report with metrics (alerts handled, escalated, FPs tuned, MTTD/MTTR notes).
- `SOC-34` master ticket.

## Rubric
| Dimension | Pass bar |
|---|---|
| Triage | correct TP/FP + severity on each alert |
| Prioritization | worked in SLA/severity order |
| Escalation | right alerts escalated, with proper notes |
| Case hygiene | every case documented, facts vs assessment |
| Handover | next shift could pick up every open case |
| Metrics | shift numbers reported |

## Resume line
"Operated a simulated SOC shift: triaged a mixed alert queue, prioritized under SLA, escalated
per the matrix, managed cases end-to-end, and produced a metrics-backed shift handover —
`lessons/34`."
