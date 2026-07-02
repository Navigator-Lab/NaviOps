# Lesson 34 — Pure Practical: SOC Operations Project

> **Companion to [`README.md`](./README.md).** Already hands-on; this adds 3 shift-simulation drills
> (the SOC-analyst day job). **Lab:** full Wazuh stack + victim; dashboard **https://localhost:8443**.
> **Rules:** you're on shift — triage, decide, document. Run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: run a full SOC shift (fluency)

**Scenario.** `SOC-341`. Start-to-end shift: baseline the board, work the alert queue, escalate the real
one, and write the handover.

**Objective.** A shift with a triaged queue, one escalation, and a handover note with metrics.

**Given / constraints.** Generate a mixed alert set. Metrics captured.

**Hints.**
1. Baseline → triage by risk → handle top → escalate the real incident.
2. Track alerts handled + time-to-triage.
3. Handover note.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'wc -l < /var/ossec/logs/alerts/alerts.log' | grep -qE '[0-9]' && echo "ALERTS PRESENT ✅"
test -f docs/learning/reports/SOC-341-shift.md && echo "HANDOVER ✅"
```

**Pitfalls.**
- No baseline → can't spot abnormal.
- FIFO instead of risk-order.
- No handover.

🎯 **Stretch.** Define SLAs per severity and measure against them.

---

## Task 2 — Ticket-driven: end-to-end incident on shift (diagnose → resolve)

**Scenario.** `SOC-342` (P1). An incident surfaces mid-shift. Take it detection → triage → investigate →
respond → report, solo.

**Objective.** Full incident handled with a report (verdict, response, IoCs).

**Given / constraints.** Plant an incident. Timebox. Complete the loop.

**Hints.**
1. Detect → triage → investigate (pivot/enrich) → respond → document.
2. Evidence at each step.
3. IR report.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-342-incident.md && grep -qiE 'verdict|response|ioc' docs/learning/reports/SOC-342-incident.md && echo "INCIDENT REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-342-incident.md`: detection · triage · investigation · response · IoCs.

**Pitfalls.**
- Skipping investigation (respond blind).
- No evidence trail.
- Incomplete loop (no report).

🎯 **Stretch.** Add MTTD/MTTR to the report.

---

## Task 3 — On-call: major incident, SOC lead role (synthesis)

**Scenario.** `SOC-343` (P1, time-boxed). A major, multi-host incident. Coordinate the response, keep
comms, and run a blameless review with metrics and action items.

**Objective.** Major incident coordinated + resolved + a blameless postmortem with metrics + owned
actions.

**Given / constraints.** Multi-host planted incident. Comms cadence + metrics.

**Hints.**
1. Declare, roles (comms/ops), live timeline.
2. Contain across hosts; verify recovery.
3. Postmortem: MTTD/MTTR, root cause, action items.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-343-major.md && grep -qiE 'mttr|action item' docs/learning/reports/SOC-343-major.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/SOC-343-major.md`: timeline · comms · MTTD/MTTR · root cause · action items.

**Pitfalls.**
- No comms cadence.
- Fixing before scoping across hosts.
- Blameful review.

🎯 **Stretch.** Add an external status-update template.

---

## Done?
- [ ] All ✅ Verify pass · [ ] shift→incident→major · [ ] postmortem with metrics + owned actions.
- [ ] **Guardrails:** change default creds; no real data. → [README Reflection](./README.md).
