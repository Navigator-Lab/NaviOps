# Lesson 22 — Pure Practical: Observability (Prometheus & Grafana)

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** `./infra/bootstrap.sh monitoring` (Prometheus + node-exporter + Grafana + Nagios).
> Prometheus `:9090`, Grafana `:3000`. **Rules:** type it, diagnose before you fix, run ✅ **Verify**.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: from metric to alert to dashboard (fluency)

**Scenario.** `NAVI-221`. Stand up the monitoring stack, confirm a target is scraped, write one PromQL
query, one alerting rule, and one Grafana panel for it.

**Objective.** node-exporter target UP, a PromQL query returning data, an alert rule loaded, and a
dashboard panel showing it.

**Given / constraints.** Use the lab stack. Alert rule has a `for:` duration (no instant flapping).

**Hints.**
1. Targets: Prometheus `:9090/targets` all `UP`.
2. PromQL: e.g. `100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m]))*100)` = CPU %.
3. Alert rule in `rules.yml` with `for: 5m`; reload Prometheus; add a Grafana panel with the same query.

✅ **Verify.**
```bash
curl -s localhost:9090/api/v1/targets | grep -q '"health":"up"' && echo "TARGET UP ✅"
curl -s 'localhost:9090/api/v1/query?query=up' | grep -q '"value"' && echo "QUERY OK ✅"
curl -s localhost:9090/api/v1/rules | grep -q '"name"' && echo "RULE LOADED ✅"
```

**Pitfalls.**
- Alert without `for:` → fires on a single noisy scrape.
- PromQL on a counter without `rate()` → meaningless ever-growing number.
- Dashboard query differing from the alert query → they disagree during incidents.

🎯 **Stretch.** Add recording rules to precompute an expensive query; use it in both the alert and panel.

---

## Task 2 — Ticket-driven: "a target is DOWN / no data on the dashboard" (diagnose → fix)

**Scenario.** `NAVI-222` (P2). *"Grafana panel is empty and Prometheus shows the target as DOWN."*
Find where the scrape chain breaks — **diagnose first.**

**Objective.** Restore scraping + data, identifying whether it's the exporter, the network, the scrape
config, or a label/datasource mismatch.

**Given / constraints.** Recreate: exporter stopped, wrong `scrape_config` target, or Grafana pointed
at the wrong datasource. Fix the specific break.

**Hints.**
1. `:9090/targets` → the error string (connection refused? 404? scrape timeout?).
2. Exporter reachable? `curl <exporter>:9100/metrics` from the Prometheus container.
3. Grafana empty but Prometheus has data → datasource/query problem, not scrape.

✅ **Verify.**
```bash
curl -s localhost:9090/api/v1/targets | grep -q '"health":"down"' && echo "STILL DOWN ❌" || echo "TARGET UP ✅"
curl -s 'localhost:9090/api/v1/query?query=up{job="node"}' | grep -q '"value"' && echo "DATA FLOWING ✅"
```

**Pitfalls.**
- Blaming Grafana when Prometheus itself has no data (fix upstream first).
- Exporter bound to the wrong interface/port.
- Label mismatch between the dashboard variable and the metric labels.

🎯 **Stretch.** Add `up == 0` as a meta-alert so a dead exporter pages you (monitor the monitoring).

---

## Task 3 — On-call: alert firing — use the golden signals to find root cause (synthesis)

**Scenario.** `NAVI-223` (P1, time-boxed). A latency/error alert fires. Use the four golden signals
(latency, traffic, errors, saturation) + PromQL to localize the cause, mitigate, and document.

**Objective.** From the alert, query the golden signals, identify the saturated/erroring component,
apply a mitigation, and write an incident note with the queries you used.

**Given / constraints.** Drive load/saturation (`stress`/a busy loop) so a resource saturates. Timebox
15 min. Note the exact PromQL used.

**Hints.**
1. Saturation: CPU/mem/disk PromQL. Errors: rate of 5xx / failed probes. Latency: histogram quantiles.
2. Correlate the alert's timestamp with the signal that moved first.
3. Mitigate the saturation (kill the load / scale), confirm the alert clears.

✅ **Verify.**
```bash
curl -s localhost:9090/api/v1/alerts | grep -q '"state":"firing"' && echo "STILL FIRING (mitigate)" || echo "ALERT CLEARED ✅"
grep -qi 'promql\|query' docs/learning/reports/NAVI-223-postmortem.md && echo "QUERIES DOCUMENTED ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-223-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention (+ the golden-signal queries).

**Pitfalls.**
- Staring at one dashboard instead of systematically checking all four signals.
- Silencing the alert instead of fixing the saturation.
- No record of the queries → next on-call re-derives them under pressure.

🎯 **Stretch.** Build a reusable "golden signals" Grafana dashboard row you can drop onto any service.

---

## Done?
- [ ] All ✅ Verify pass · [ ] used golden signals · [ ] queries documented · [ ] postmortem written.
- [ ] **Redaction:** no real endpoints committed. → [README Step 7](./README.md).
