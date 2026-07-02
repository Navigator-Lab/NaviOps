# Lesson 17 — Pure Practical: Alert Triage Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** Wazuh dashboard + `siem-victim`. **Rules:** evidence before verdict, run ✅
> **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: triage a single alert to a decision (fluency)

**Scenario.** `SOC-171`. Apply the triage model: severity × asset × fidelity → escalate/close, with a note.

**Objective.** A documented triage decision on one alert using the scoring model.

**Given / constraints.** Generate an alert. Score all three factors.

**Hints.**
1. Severity (rule level) × asset criticality × fidelity (TP likelihood).
2. Pivot for the fidelity read.
3. Decision + note.

✅ **Verify.**
```bash
grep -qiE 'severity|asset|fidelity' docs/learning/reports/SOC-171-triage.md && echo "TRIAGE SCORED ✅"
```

**Pitfalls.**
- Severity-only triage (ignore asset/fidelity).
- No pivot → fidelity is a guess.
- No decision recorded.

🎯 **Stretch.** Define SLA times per priority tier.

---

## Task 2 — Ticket-driven: prioritize a mixed queue (diagnose → order)

**Scenario.** `SOC-172` (P2). A queue of mixed alerts. Order by risk, justify the top, and handle it.

**Objective.** A risk-ordered queue + the top alert triaged to a decision.

**Given / constraints.** Consistent scoring. Justify ordering.

**Hints.**
1. Score all; order.
2. Handle the top to a verdict.
3. Rationale documented.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-172-queue.md && grep -qi 'priority\|top' docs/learning/reports/SOC-172-queue.md && echo "QUEUE ORDERED ✅"
```

**Deliverable.** `docs/learning/reports/SOC-172-queue.md`: ordered queue · rationale · top decision.

**Pitfalls.**
- FIFO instead of risk-order.
- Loud > important.
- Top left unhandled.

🎯 **Stretch.** Add dedup/grouping before scoring.

---

## Task 3 — On-call: triage under alert-storm pressure (synthesis)

**Scenario.** `SOC-173` (P1, time-boxed). A storm hits. Rapidly separate signal from noise, escalate the
real one, and report with metrics.

**Objective.** The real incident found + escalated amid noise; a report with time-to-triage metrics.

**Given / constraints.** Generate many alerts. Timebox. Metrics captured.

**Hints.**
1. Group/dedup fast; prioritize; find the real incident.
2. Escalate it with evidence.
3. Report: handled/escalated + time metrics.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-173-storm.md && grep -qiE 'metric|time-to' docs/learning/reports/SOC-173-storm.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-173-storm.md`: storm · prioritization · real incident · metrics.

**Pitfalls.**
- Drowning in noise; missing the real one.
- No grouping.
- No metrics.

🎯 **Stretch.** Propose the tuning/correlation that would shrink the next storm.

---

## Done?
- [ ] All ✅ Verify pass · [ ] scored severity×asset×fidelity · [ ] real incident escalated with metrics.
- [ ] **Guardrails:** no real data committed. → [README Reflection](./README.md).
