# Lesson 22 — Pure Practical: Prometheus & Grafana

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `./infra/bootstrap.sh monitoring` (Prometheus :9091, Grafana :3001). **Rules:**
> type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: query → alert → dashboard (fluency)

**Scenario.** `NOC-221`. Confirm scraping, write one PromQL query, one alert rule, one panel.

**Objective.** Targets UP, a PromQL query returning data, an alert rule loaded, a Grafana panel.

**Given / constraints.** Alert has a `for:` duration.

**Hints.**
1. `:9091/targets` all UP; query `probe_success` / `up`.
2. Alert rule with `for: 1m`; reload; Grafana panel same query.
3. Query = alert query (consistency).

✅ **Verify.**
```bash
curl -s localhost:9091/api/v1/targets | grep -q '"health":"up"' && echo "TARGET UP ✅"
curl -s localhost:9091/api/v1/rules | grep -q '"name"' && echo "RULE LOADED ✅"
```

**Pitfalls.**
- Alert without `for:` → flapping.
- Counter without `rate()`.
- Dashboard query ≠ alert query.

🎯 **Stretch.** Add a recording rule and use it in both alert + panel.

---

## Task 2 — Ticket-driven: "no data on the panel" (diagnose → fix)

**Scenario.** `NOC-222` (P2). *"Grafana panel is empty."* Find where the chain breaks — scrape,
datasource, or query.

**Objective.** Restore data, identifying exporter down vs datasource vs query fault — diagnose first.

**Given / constraints.** Recreate one break. Fix the specific link.

**Hints.**
1. `:9091/targets` — is the target UP? Does Prometheus have the metric?
2. Grafana datasource pointed at Prometheus? Query valid?
3. Fix upstream first (scrape), then datasource, then query.

✅ **Verify.**
```bash
curl -s 'localhost:9091/api/v1/query?query=up' | grep -q '"value"' && echo "DATA FLOWING ✅"
```

**Pitfalls.**
- Blaming Grafana when Prometheus has no data.
- Wrong datasource URL.
- Label/selector mismatch in the query.

🎯 **Stretch.** Add `up == 0` alert to catch dead exporters.

---

## Task 3 — On-call: use the golden signals to root-cause an alert (synthesis)

**Scenario.** `NOC-223` (P1, time-boxed). A latency/loss alert fires. Query the golden signals to find
the cause, mitigate, document.

**Objective.** From the alert, query latency/traffic/errors/saturation, find the culprit, mitigate,
write a note with the queries.

**Given / constraints.** Drive load/impairment; timebox. Record PromQL used.

**Hints.**
1. Saturation (CPU/link), errors (probe fail rate), latency (RTT) — which moved first?
2. Correlate with the alert time.
3. Mitigate; confirm the alert clears.

✅ **Verify.**
```bash
curl -s localhost:9091/api/v1/alerts | grep -q '"state":"firing"' && echo "STILL FIRING (mitigate)" || echo "CLEARED ✅"
grep -qi 'promql\|query' docs/learning/reports/NOC-223-golden-signals.md && echo "QUERIES DOCUMENTED ✅"
```

**Deliverable.** `docs/learning/reports/NOC-223-golden-signals.md`: Impact · Detection · Root cause · Fix · the queries used.

**Pitfalls.**
- Staring at one panel instead of all signals.
- Silencing instead of fixing.
- No record of queries.

🎯 **Stretch.** Build a reusable golden-signals dashboard row.

---

## Done?
- [ ] All ✅ Verify pass · [ ] used golden signals · [ ] queries documented.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
