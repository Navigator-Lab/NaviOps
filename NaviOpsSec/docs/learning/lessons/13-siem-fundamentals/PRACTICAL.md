# Lesson 13 — Pure Practical: SIEM Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** Wazuh SIEM (`./infra/bootstrap.sh up`) + victim; dashboard **https://localhost:8443**.
> **Rules:** evidence before verdict, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: the SIEM pipeline end to end (fluency)

**Scenario.** `SOC-131`. Trace an event from the victim through collection → decoding → rule → alert →
dashboard — the SIEM's data path.

**Objective.** Generate an event and follow it to a dashboard alert, identifying each pipeline stage.

**Given / constraints.** Use `wazuh-logtest` to see decode+rule; the dashboard for the alert.

**Hints.**
1. Generate a failed login. `wazuh-logtest` — paste a sample line, see decoder + rule + level.
2. Confirm the alert in `alerts.log` and the dashboard.
3. Name each stage.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'echo "Failed password for root from 10.0.0.9 port 22 ssh2" | /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -qi "Rule id"' && echo "PIPELINE TRACED ✅"
```

**Pitfalls.**
- Not understanding decode vs rule (both must match).
- Assuming ingestion = alert (rules decide).
- Skipping `wazuh-logtest` (the fastest feedback loop).

🎯 **Stretch.** Trace a log the SIEM *doesn't* decode and see why no alert.

---

## Task 2 — Ticket-driven: "an event didn't alert" (diagnose → fix)

**Scenario.** `SOC-132` (P2). *"We saw the activity in raw logs but the SIEM stayed silent."* Find the
pipeline break.

**Objective.** Make the event alert, identifying ingestion, decoder, or rule-level as the cause —
diagnose first.

**Given / constraints.** Recreate a gap (log not ingested / no decoder / level below threshold). Fix it.

**Hints.**
1. Ingested? (agent + monitored path). Decoded? (`wazuh-logtest`). Rule level ≥ alert threshold?
2. Fix the specific stage.
3. Re-test with `wazuh-logtest` + a live event.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'echo "<sample malicious line>" | /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -qi "Rule id"' && echo "NOW ALERTS ✅"
```

**Deliverable.** `docs/learning/reports/SOC-132-silent.md`: symptom · stage that failed · fix · verification.

**Pitfalls.**
- Assuming rule when it's ingestion (no data).
- Custom log with no decoder → never matches.
- Alert threshold filtering out the rule level.

🎯 **Stretch.** Write a minimal custom decoder+rule for an unparsed log.

---

## Task 3 — On-call: SIEM is drowning in false positives (synthesis)

**Scenario.** `SOC-133` (P1, time-boxed). Analysts are buried in low-value alerts. Identify the noisiest
rules, tune them (exceptions, not disable), and document the fidelity improvement.

**Objective.** Reduce noise with targeted tuning while preserving true-positive coverage; documented.

**Given / constraints.** Tune with exceptions/thresholds. Prove TPs still fire.

**Hints.**
1. Which rules fire most? Are they low-value?
2. Add a scoped exception / raise threshold — not a blanket disable.
3. Confirm the malicious case still alerts.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'wc -l < /var/ossec/logs/alerts/alerts.log'; echo "noise measured before/after"
test -f docs/learning/reports/SOC-133-tuning.md && echo "TUNING REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-133-tuning.md`: noisy rules · tuning applied · TP still fires · fidelity gain.

**Pitfalls.**
- Disabling a noisy rule (blinds you) instead of a scoped exception.
- Tuning away real positives.
- No before/after measurement.

🎯 **Stretch.** Define an alert-fidelity metric and track it over time.

---

## Done?
- [ ] All ✅ Verify pass · [ ] pipeline stages understood · [ ] tuned without losing TPs.
- [ ] **Guardrails:** change default creds; no real data committed. → [README Reflection](./README.md).
