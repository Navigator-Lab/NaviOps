# Lesson 18 — Pure Practical: AWS CloudWatch Monitoring

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **⚠️ Offline-first (no cloud spend).** Use **LocalStack** + `awslocal` (CloudWatch metrics, alarms,
> logs are modeled). The *concepts* (metrics, dimensions, alarms, log filters) transfer 1:1 to real
> AWS. Never commit real account data. **Rules:** type it, diagnose before you fix, run ✅ **Verify**.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a custom metric + an alarm that fires (fluency)

**Scenario.** `NAVI-181`. Publish an app metric (e.g. `HealthcheckFailures`) and create an alarm that
goes ALARM when it breaches a threshold.

**Objective.** Put metric data, create a threshold alarm, and drive it into ALARM state.

**Given / constraints.** A meaningful namespace/dimension. Alarm has sane period + evaluation periods.

**Hints.**
1. `awslocal cloudwatch put-metric-data --namespace NaviOps --metric-name HealthcheckFailures --value 0`.
2. `put-metric-alarm` (threshold, `--comparison-operator GreaterThanThreshold`, period, evaluation-periods).
3. Push a breaching value; check `describe-alarms` state.

✅ **Verify.**
```bash
awslocal cloudwatch put-metric-data --namespace NaviOps --metric-name HealthcheckFailures --value 5
awslocal cloudwatch describe-alarms --query 'MetricAlarms[].StateValue'   # ALARM after breach
```

**Pitfalls.**
- 1-datapoint alarms on a noisy metric → alert flapping. Use evaluation periods.
- Wrong namespace/dimension → alarm watches a metric nothing publishes to (silent).
- No alarm action → it changes state but nobody's told.

🎯 **Stretch.** Add an `OK`→`ALARM`→`OK` cycle and reason about `TreatMissingData` (breaching vs notBreaching).

---

## Task 2 — Ticket-driven: "the alarm never fired during the outage" (diagnose → fix)

**Scenario.** `NAVI-182` (P2). *"We had an outage but CloudWatch never alerted."* Find why the alarm was
blind — **diagnose the metric→alarm chain.**

**Objective.** Make the alarm actually fire on the failure condition, fixing the real gap (no data,
wrong threshold/comparison, missing-data handling, or wrong dimension).

**Given / constraints.** Recreate a misconfigured alarm (e.g. metric never published, or
`TreatMissingData=notBreaching` masking a dead agent). Fix the specific fault.

**Hints.**
1. Is data arriving? `get-metric-statistics` for the metric/dimension over the window.
2. If the agent dies, the metric goes *missing*, not high → `TreatMissingData=breaching` catches "no heartbeat".
3. Check comparison operator + threshold direction match the failure.

✅ **Verify.**
```bash
awslocal cloudwatch describe-alarms --alarm-names <a> --query 'MetricAlarms[].TreatMissingData'
# drive the real failure condition and confirm:
awslocal cloudwatch describe-alarms --query 'MetricAlarms[?StateValue==`ALARM`].AlarmName' | grep -q <a> && echo "FIRES NOW ✅"
```

**Pitfalls.**
- Alarming on a metric that stops publishing when the thing dies → silence exactly when you need noise. Use missing-data=breaching or a heartbeat.
- Threshold set so high nothing ever crosses it.
- Right metric, wrong dimension → watching the wrong resource.

🎯 **Stretch.** Add a composite alarm (metric breach AND heartbeat missing) to cut false positives.

---

## Task 3 — On-call: alert storm — too much noise during an incident (synthesis)

**Scenario.** `NAVI-183` (P1, time-boxed). During an incident, dozens of alarms fire at once; the
signal is buried. Triage the noise, find the root-cause metric, and propose a saner alarm design;
document.

**Objective.** From a burst of alarms + a log group, identify the leading indicator, silence
downstream noise safely, and write an incident note with a "reduce alert fatigue" action.

**Given / constraints.** Simulate multiple correlated alarms + a log stream with the root error. Don't
delete alarms mid-incident — disable actions, don't lose history.

**Hints.**
1. Which alarm fired *first*? Order by `StateUpdatedTimestamp` — the leading indicator, not the cascade.
2. Log insight: `awslocal logs filter-log-events --filter-pattern ERROR` to find the root error.
3. Reduce noise: `disable-alarm-actions` on downstream/dependent alarms (reversible), keep the root one.

✅ **Verify.**
```bash
awslocal cloudwatch describe-alarms --query 'MetricAlarms[?StateValue==`ALARM`]|length(@)'   # count trending down after suppressing downstream
awslocal logs filter-log-events --log-group-name <lg> --filter-pattern ERROR | grep -q ERROR && echo "ROOT ERROR FOUND ✅"
test -f docs/learning/reports/NAVI-183-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-183-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention (+ alert-fatigue fix).

**Pitfalls.**
- Deleting alarms to stop the noise → lose config + history; disable actions instead.
- Chasing the loudest alarm instead of the earliest (root) one.
- No follow-up to fix the alarm design → same storm next incident.

🎯 **Stretch.** Design a 3-tier alerting scheme (page / ticket / dashboard-only) and map these alarms to tiers.

---

## Done?
- [ ] All ✅ Verify pass (LocalStack) · [ ] found the leading indicator · [ ] postmortem written.
- [ ] **No real AWS spend; no account data committed.** → [README Step 7](./README.md).
