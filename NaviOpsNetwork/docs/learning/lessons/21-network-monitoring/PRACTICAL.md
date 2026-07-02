# Lesson 21 — Pure Practical: Network Monitoring

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `./infra/bootstrap.sh monitoring` (Prometheus :9091, Grafana :3001, blackbox
> probing the lab gateways `10.10.1.1`/`10.10.2.1`). **Rules:** type it, diagnose before you fix, run ✅.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: an uptime board for the lab gateways (fluency)

**Scenario.** `NOC-211`. Build the NOC's core view: are the links up? Probe the lab gateways and graph
reachability.

**Objective.** Blackbox ICMP probes for both gateways scraped by Prometheus; a Grafana panel on
`probe_success`.

**Given / constraints.** Add targets to `monitoring/prometheus.yml`, reload, build the panel.

**Hints.**
1. Add `10.10.1.1` and `10.10.2.1` as blackbox targets; reload Prometheus.
2. Query `probe_success` (1=up, 0=down).
3. Grafana stat/timeseries panel on that metric.

✅ **Verify.**
```bash
curl -s localhost:9091/api/v1/query?query=probe_success 2>/dev/null | grep -q '"value"' && echo "PROBES SCRAPED ✅"
```

**Pitfalls.**
- Probing the wrong target/module (icmp vs http).
- Forgetting to reload Prometheus after editing config.
- No alert on `probe_success == 0`.

🎯 **Stretch.** Add an alert rule that fires when a gateway is down for 1m.

---

## Task 2 — Ticket-driven: "a target shows down but it's actually up" (diagnose → fix)

**Scenario.** `NOC-212` (P2). *"Dashboard says a link is down but it pings fine."* A monitoring
false-positive. Find the scrape/probe fault.

**Objective.** Make the probe reflect reality, identifying config/module/network issues in the
monitoring path — diagnose first.

**Given / constraints.** Recreate: wrong blackbox module, unreachable exporter, or bad target. Fix it.

**Hints.**
1. `:9091/targets` — the probe's error. Blackbox module correct (icmp vs tcp)?
2. Can the blackbox container reach the target itself?
3. Fix module/target; confirm `probe_success` flips to 1.

✅ **Verify.**
```bash
curl -s 'localhost:9091/api/v1/query?query=probe_success' | grep -q '"1"' && echo "REFLECTS REALITY ✅"
```

**Pitfalls.**
- Trusting the dashboard over reality (or vice-versa) without checking the probe.
- Wrong probe module.
- Exporter/blackbox network isolation from the target.

🎯 **Stretch.** Add `up` self-monitoring so a dead exporter is distinguishable from a dead target.

---

## Task 3 — On-call: alert storm during a link outage (synthesis)

**Scenario.** `NOC-213` (P1, time-boxed). A core link drops and dozens of dependent probes alert. Find
the leading indicator, suppress downstream noise, and document.

**Objective.** Identify the root (first) alert, quiet dependent alerts, and write a note with an
alert-design improvement.

**Given / constraints.** Correlate alert timestamps. Suppress, don't delete.

**Hints.**
1. Order alerts by fire time — the earliest is the root (the link), the rest are downstream.
2. Silence/group downstream alerts (Alertmanager inhibition).
3. Note the alert-fatigue fix.

✅ **Verify.**
```bash
curl -s localhost:9091/api/v1/alerts 2>/dev/null | grep -q firing && echo "ALERTS PRESENT (triage them)"
test -f docs/learning/reports/NOC-213-alert-storm.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-213-alert-storm.md`: leading indicator · downstream noise · fix (inhibition).

**Pitfalls.**
- Chasing the loudest alert instead of the earliest.
- Deleting alerts to stop noise.
- No inhibition/grouping → same storm next time.

🎯 **Stretch.** Configure Alertmanager inhibition so a "link down" mutes its dependent probes.

---

## Done?
- [ ] All ✅ Verify pass · [ ] found the leading indicator · [ ] alert-storm note written.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
