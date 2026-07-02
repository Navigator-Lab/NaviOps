# Lesson 16 — Pure Practical: Log Analysis Workflows

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** Wazuh dashboard + `siem-victim` logs. **Rules:** evidence before verdict, run ✅
> **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a repeatable analysis workflow (fluency)

**Scenario.** `SOC-161`. Build a consistent workflow: alert → pivot to raw event → enrich → decide →
document — so analysis is repeatable, not ad-hoc.

**Objective.** Run the workflow on one alert and capture each step's output.

**Given / constraints.** Generate an alert; follow the same steps every time.

**Hints.**
1. Pivot from the alert to the decoded event + surrounding context (same host/time).
2. Enrich (user, process, source).
3. Decide + document.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-161-workflow.md && grep -qiE 'pivot|enrich|decide' docs/learning/reports/SOC-161-workflow.md && echo "WORKFLOW ✅"
```

**Pitfalls.**
- Ad-hoc analysis → inconsistent results.
- Not pivoting to surrounding context (tunnel on one line).
- No documentation step.

🎯 **Stretch.** Template the workflow so any analyst produces the same artifact.

---

## Task 2 — Ticket-driven: investigate an alert to a verdict (diagnose)

**Scenario.** `SOC-162` (P2). One alert, full workflow, TP/FP verdict with ≥2 corroborating sources.

**Objective.** A documented verdict backed by multiple evidence sources.

**Given / constraints.** Corroborate across sources before deciding.

**Hints.**
1. Pivot to raw event + a second source (auth log, process, network).
2. Benign vs malicious indicators.
3. Verdict + evidence.

✅ **Verify.**
```bash
grep -ciE 'evidence' docs/learning/reports/SOC-162-verdict.md    # ≥2
grep -qiE 'true positive|false positive' docs/learning/reports/SOC-162-verdict.md && echo "VERDICT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-162-verdict.md`: alert · evidence (≥2) · verdict · action.

**Pitfalls.**
- Single-source verdict.
- Skipping the raw event.
- No action recorded.

🎯 **Stretch.** If FP, produce the tuning; if TP, produce the escalation package.

---

## Task 3 — On-call: multi-alert correlation into one case (synthesis)

**Scenario.** `SOC-163` (P1, time-boxed). Several alerts are actually one incident. Correlate them into a
single case with a timeline and root cause.

**Objective.** A correlated case: grouped alerts, timeline, root cause, scope.

**Given / constraints.** Generate related alerts. Group + timeline; don't treat as separate.

**Hints.**
1. Group by entity/time; build the timeline.
2. Identify the initiating event.
3. Case write-up with scope.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-163-case.md && grep -qi 'timeline' docs/learning/reports/SOC-163-case.md && echo "CASE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-163-case.md`: grouped alerts · timeline · root cause · scope.

**Pitfalls.**
- Treating related alerts as separate tickets.
- No timeline.
- Missing the initiating event.

🎯 **Stretch.** Propose a correlation rule that would auto-group these.

---

## Done?
- [ ] All ✅ Verify pass · [ ] repeatable workflow · [ ] verdicts ≥2 sources · [ ] correlated case.
- [ ] **Guardrails:** no real data committed. → [README Reflection](./README.md).
