# Lesson 03 — Pure Practical: Security Operations Center (SOC) Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** Wazuh dashboard **https://localhost:8443**; `siem-victim`. **Rules:** evidence
> before verdict, run ✅ **Verify** each task. Reports → `docs/learning/reports/`.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: run a mock SOC shift on the dashboard (fluency)

**Scenario.** `SOC-031`. Learn the analyst's daily loop: monitor the alert feed, pick up an alert,
follow it to the raw event, decide, log.

**Objective.** Navigate the Wazuh alert feed, open one alert to its raw log, and record a triage note.

**Given / constraints.** Generate an alert first (failed logins on the victim). Use the dashboard.

**Hints.**
1. Generate: `for i in $(seq 5); do sshpass -p wrong ssh -o StrictHostKeyChecking=no root@localhost -p 2222 true; done`.
2. Dashboard → Security Alerts → open the alert → view the decoded event + rule.
3. Note: what · severity · action.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'grep -qi "authentication fail" /var/ossec/logs/alerts/alerts.log' && echo "ALERT PRESENT ✅"
test -f docs/learning/reports/SOC-031-shift.md && echo "TRIAGE NOTE ✅"
```

**Pitfalls.**
- Reading the alert title without opening the raw event.
- No triage note → no audit trail.
- Ignoring the rule level (severity).

🎯 **Stretch.** Define shift metrics: alerts handled, time-to-triage, escalations.

---

## Task 2 — Ticket-driven: escalate vs close a single alert (diagnose → decide)

**Scenario.** `SOC-032` (P2). One alert on the queue. Decide: false positive (close + tune) or true
positive (escalate) — with evidence.

**Objective.** A documented escalate/close decision backed by ≥2 pieces of context.

**Given / constraints.** Corroborate before deciding. FP → tuning note; TP → escalation package.

**Hints.**
1. Pivot to context: source, user, timing, frequency.
2. Benign explanation vs malicious indicators.
3. Decide + document the reasoning.

✅ **Verify.**
```bash
grep -qiE 'escalate|close|false positive|true positive' docs/learning/reports/SOC-032-decision.md && echo "DECISION LOGGED ✅"
```

**Deliverable.** `docs/learning/reports/SOC-032-decision.md`: alert · context · verdict · action (tune/escalate).

**Pitfalls.**
- Deciding on the title alone.
- Escalating everything (fatigue) or nothing (missed breach).
- Closing a noisy rule instead of tuning it.

🎯 **Stretch.** Write the escalation as an L2 handoff with everything they'd need.

---

## Task 3 — On-call: manage a burst of alerts (synthesis)

**Scenario.** `SOC-033` (P1, time-boxed). A burst hits the queue. Triage by priority, identify the real
incident among the noise, and produce a shift report.

**Objective.** Prioritized handling, the real incident identified, and a shift report with metrics.

**Given / constraints.** Generate multiple alert types. Timebox. Justify prioritization.

**Hints.**
1. Group/dedup related alerts; prioritize by asset + severity + fidelity.
2. Find the alert that's the real incident vs the noise.
3. Report: handled, escalated, metrics.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'wc -l < /var/ossec/logs/alerts/alerts.log' | grep -qE '[0-9]' && echo "ALERTS PRESENT ✅"
test -f docs/learning/reports/SOC-033-shift-report.md && echo "SHIFT REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-033-shift-report.md`: queue · prioritization · real incident · metrics.

**Pitfalls.**
- Working alerts FIFO instead of by risk.
- Missing the real incident in the noise.
- No dedup/grouping.

🎯 **Stretch.** Propose an alert-tuning change that would have shrunk the burst.

---

## Done?
- [ ] All ✅ Verify pass · [ ] decisions backed by ≥2 context items · [ ] shift report with metrics.
- [ ] **Guardrails:** no real IoCs committed. → [README Reflection](./README.md).
