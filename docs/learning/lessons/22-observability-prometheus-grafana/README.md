# Lesson 22 — Observability Stack: Prometheus & Grafana

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–21. This is the **portable,
> open-source counterpart to Lesson 18's CloudWatch** — same goals (metrics,
> alerts, dashboards), different (cloud-agnostic) implementation, deployed via
> Lesson 12's Docker Compose skills.

---

## Step 1 — Concept

### What it is

**Prometheus** is a time-series database + monitoring system: it
**scrapes** (pulls) metrics from HTTP endpoints on a schedule, stores them,
and evaluates **alerting rules** via **PromQL** (its query language).
**Grafana** is a visualization platform — it queries Prometheus (and other
data sources) to build **dashboards**. **Node Exporter** is a small agent
that exposes a Linux host's metrics (CPU, memory, disk, network — everything
Lesson 04/07's scripts read from `/proc`/`/sys`) in Prometheus's format.

### Why it exists

Lesson 18's CloudWatch is excellent but **AWS-specific** — if you're running
on-prem servers, multiple clouds, or just want a portable skill that works
anywhere, you need an open-source equivalent. Prometheus+Grafana is the
**de facto standard** open-source observability stack — understanding it is
expected for almost any SRE/DevOps role, and it directly formalizes what
Lessons 04/06/07's manual scripts (`user_audit.sh`, `disk_report.sh`) were
doing by hand: periodically check resource metrics, alert on thresholds.

### What problem it solves

| Problem | Solution |
|---|---|
| "I have 5 servers and don't want to SSH into each to check CPU/memory/disk" | Node Exporter on each + Prometheus scraping all of them centrally |
| "I want a visual dashboard of my infrastructure's health" | Grafana dashboards (e.g., the community "Node Exporter Full" dashboard) |
| "Alert me if disk usage > 85% on ANY server" | Prometheus alerting rule + Alertmanager → Slack/email |
| "I need to query 'what was CPU usage 2 hours ago when the incident started'" (Lesson 19) | Prometheus's time-series storage — historical query via PromQL |
| "This works the same on AWS, on-prem, or my laptop" | Open-source, self-hosted, cloud-agnostic |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** Prometheus has a config file (`prometheus.yml`)
  listing **scrape targets** (e.g., `node_exporter:9100`) and a **scrape
  interval** (how often to pull metrics — commonly 15s). Node Exporter runs
  on each host and exposes `/metrics` — a plain-text HTTP endpoint Prometheus
  scrapes. Grafana connects to Prometheus as a **data source** and renders
  dashboards built from PromQL queries.
- **Level 2 — SysAdmin:** Per [Rost Glukhov's 2026 Prometheus monitoring
  guide](https://www.glukhov.org/post/2025/11/monitoring-with-prometheus/)
  and the [DevToolbox 2026 complete
  guide](https://devtoolbox.dedyn.io/blog/prometheus-grafana-complete-guide):
  Prometheus has four **metric types** — **Counter** (only increases, e.g.,
  total HTTP requests — use `rate()` to get per-second rate, the **single
  most important PromQL function**), **Gauge** (goes up/down, e.g., memory
  used — directly analogous to Lesson 07's `free -h` output), **Histogram**
  (buckets observations, e.g., request-duration distributions — preferred
  over **Summary** because histograms can be aggregated across instances).
  **Alerting rules** combine a PromQL condition with a `for` duration (the
  condition must be true for this long before firing) — this is Prometheus's
  version of Lesson 18's "evaluation-periods" (reducing alert fatigue from
  transient spikes). **Alertmanager** (a separate component) receives firing
  alerts and routes them (Slack/email/PagerDuty) — analogous to Lesson 18's
  SNS topic. **15s scrape interval** is the recommended default for most
  metrics; 30-60s for less-critical/high-cardinality targets.
- **Level 3 — Systems/Kernel (Lens D):** **Node Exporter** literally reads the
  same `/proc` and `/sys` pseudo-filesystems your Lesson 04/07 scripts parsed
  manually (`/proc/meminfo`, `/proc/stat`, `/sys/class/...`) and exposes them
  in Prometheus's text format — it's your `user_audit.sh`/`disk_report.sh`
  logic, generalized and continuously running as a daemon with an HTTP
  endpoint instead of a cron job writing to a log file. Prometheus's **pull**
  model (it scrapes targets) vs. CloudWatch agent's **push** model (Lesson
  18 — agent pushes metrics to the API) is a fundamental architectural
  difference: pull means Prometheus needs network access *to* every target
  (a firewall/VPN consideration — ties to Lesson 21), but makes it trivial to
  see "is this target even reachable" (a failed scrape is itself
  informative).

### Analogy (Lens B)

- **Prometheus** = a security guard doing rounds — every 15 seconds, walks to
  each room (target) and reads its gauges/meters (`/metrics` endpoint),
  writes the readings in a logbook (time-series database) with a timestamp.
- **Node Exporter** = the gauges/meters themselves, mounted in each room,
  always showing current readings (CPU/memory/disk) in a standard format any
  guard can read.
- **PromQL `rate()`** = converting "the odometer currently reads 50,000 miles"
  (a counter, ever-increasing) into "you've been driving 60 mph for the last
  hour" (a rate) — the odometer alone doesn't tell you speed; you need the
  *rate of change*.
- **Grafana** = the central monitoring room with big screens, where the
  logbook entries from many guards (Prometheus) are turned into live charts
  for humans to glance at.
- **Alertmanager** = the dispatcher who decides, when a gauge has been in the
  red zone for the required duration (the `for` clause), *who* gets paged and
  *how* (Slack vs. SMS vs. email) — separate from the guard who just reports
  readings.

The "security guard" analogy holds well but breaks down for **PromQL's
aggregation across many targets** (`sum(rate(...)) by (instance)`) — a guard
checking individual rooms doesn't naturally "sum readings across all rooms
grouped by floor" the way PromQL effortlessly aggregates across hundreds of
scrape targets.

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# Check Prometheus targets (are scrapes succeeding?)
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# PromQL via API (or Prometheus UI "Graph" tab)
curl -s 'http://localhost:9090/api/v1/query?query=node_filesystem_avail_bytes' | jq

# Common PromQL queries
# CPU usage % (per instance)
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Disk usage % (root filesystem) - extends Lesson 07's df logic
100 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100)

# Memory usage %
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
```

**Real production scenarios:**
1. **Fleet-wide dashboards** — one Grafana dashboard (e.g., the community
   "Node Exporter Full" dashboard) shows CPU/memory/disk/network for every
   server, replacing "SSH into each one and run `htop`/`df -h`" (Lessons
   04/07).
2. **Incident investigation** (Lesson 19 connection) — "the site went down at
   2:14am" → open Grafana, look at the 2:00-2:30am window across all
   dashboards → spot the metric that changed first (memory climbing → OOM
   kill, Lesson 11/19).
3. **Capacity planning** — PromQL queries over weeks of historical data
   answer "is disk usage trending toward full in the next month?" — informs
   when to act, before Lesson 06/07's "disk full" failure signature occurs.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Forgetting `rate()` on counter metrics | Graphs show ever-increasing lines (the raw counter), not meaningful rates | Always wrap counters in `rate(...)` over a time window |
| Scrape interval too aggressive (e.g., 1s) across many targets | Prometheus storage/CPU overload | 15s default is fine for most; 30-60s for less-critical/high-count targets |
| No alerting rules — dashboards exist but no one's watching them | Same failure mode as Lesson 18 Q1's "alarms exist but nobody confirmed the SNS subscription" — observability without action | Define alerting rules + Alertmanager routing for the metrics that matter |
| Alert with no `for` duration | Alert fires on every transient blip — alert fatigue (same lesson as Lesson 18 Q2) | Set a `for` duration appropriate to the metric (e.g., `for: 5m` for high CPU) |
| Using Summary instead of Histogram for latency metrics that need cross-instance aggregation | Can't compute accurate aggregate percentiles across instances | Prefer Histogram for anything you'll aggregate with `sum`/`avg` across instances |

### When NOT to over-engineer

- For a single learning lab, **Prometheus + Node Exporter + Grafana** via
  Docker Compose (this lesson's hands-on) is plenty — Alertmanager and
  multi-target federation matter once you have multiple servers/services
  (Lesson 24-25).

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| Prometheus+Grafana (this lesson) | CloudWatch (Lesson 18) | CloudWatch is managed/AWS-native (no infrastructure to run); Prometheus+Grafana is portable/open-source and the industry-standard skill outside AWS-only shops — both are valuable, often used together |
| Prometheus's pull model | Push-based systems (StatsD, CloudWatch agent) | Pull simplifies "is this target alive" detection; push is better for ephemeral/short-lived jobs (Prometheus has a "Pushgateway" for this case) |
| Self-hosted Prometheus/Grafana | Grafana Cloud, managed Prometheus (AWS AMP) | Managed options remove the "who monitors the monitoring stack" problem, at a cost |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Deploy Prometheus + Node Exporter + Grafana via Docker Compose
(extending Lesson 12), scrape your lab VM's metrics, build a basic dashboard,
and define one alerting rule.

### Lens C — Manual → Automated → Why

**Manual (Lessons 04/06/07):** `disk_report.sh`/`user_audit.sh` run via cron,
write to local logs — you only see results if you check that one server's
logs.

**Automated (Prometheus stack) — `compose.yaml` sketch:**
```yaml
services:
  node-exporter:
    image: prom/node-exporter:latest
    pid: host
    network_mode: host
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./alert_rules.yml:/etc/prometheus/alert_rules.yml:ro
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
    depends_on:
      - prometheus
```

`prometheus.yml`:
```yaml
global:
  scrape_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: "node"
    static_configs:
      - targets: ["localhost:9100"]   # node_exporter, host network mode
```

`alert_rules.yml`:
```yaml
groups:
  - name: naviops_alerts
    rules:
      - alert: HighDiskUsage
        expr: 100 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100) > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Disk usage above 85% on {{ $labels.instance }}"
```

**Why this matters:** this is **Lesson 07's `disk_report.sh
check_high_usage_alert()` and Lesson 18's CloudWatch disk alarm, expressed a
third way** — same threshold logic (>85% → alert), now portable, queryable
historically, and visualized — directly demonstrating that the **underlying
concept (threshold-based alerting on a metric) is universal**, only the
implementation changes.

### What to build, step by step

1. Create `monitoring/compose.yaml`, `monitoring/prometheus.yml`,
   `monitoring/alert_rules.yml` per the sketches above. Use a `.env` (Lesson
   12 pattern) for `GRAFANA_ADMIN_PASSWORD`.
2. `docker compose up -d`. Verify Node Exporter: `curl
   localhost:9100/metrics | head`.
3. Open Prometheus (`http://localhost:9090`) → Status → Targets — confirm
   the `node` job is `UP`.
4. Run the PromQL queries from Step 2 in Prometheus's "Graph" tab — confirm
   they return sensible values for your lab VM.
5. Open Grafana (`http://localhost:3000`), add Prometheus as a data source
   (`http://prometheus:9090` — Compose's embedded DNS, Lesson 12), and either
   build a small dashboard manually (CPU/memory/disk panels) or import the
   community "Node Exporter Full" dashboard (note its ID for reference).
6. Confirm `alert_rules.yml` is loaded: Prometheus → Alerts tab — your
   `HighDiskUsage` rule should be listed (likely "inactive" unless disk is
   actually >85%).
7. **Test the alert**: temporarily lower the threshold (e.g., to a value
   below your current disk usage) and `for: 0m`, reload Prometheus config,
   confirm the alert transitions to "firing" — then revert.
8. Document your setup in `docs/observability/prometheus-grafana-design.md`.
9. Commit `monitoring/` configs (no real passwords — `.env.example` only) and
   the design doc on `lesson/22-observability-prometheus-grafana`.

---

## Step 5 — Verification

```bash
docker compose -f monitoring/compose.yaml ps
curl -s localhost:9100/metrics | grep node_filesystem_avail_bytes | head -3
curl -s 'localhost:9090/api/v1/query?query=up' | jq '.data.result'

# Confirm alert rule loaded
curl -s localhost:9090/api/v1/rules | jq '.data.groups[].rules[].name'

# Grafana reachable
curl -sI localhost:3000 | head -1
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Prometheus target shows `DOWN` for `node` job | Node Exporter not running, wrong port, or network mode mismatch in Compose | Confirm `curl localhost:9100/metrics` works on the host; check `network_mode: host` is set for node-exporter |
| Grafana can't reach Prometheus data source | Used `localhost:9090` instead of Compose service name `prometheus` | Use `http://prometheus:9090` — Compose's embedded DNS (Lesson 12) |
| PromQL query returns empty result | Metric name typo, or wrong label (e.g., `mountpoint="/"` doesn't match your filesystem layout) | `curl localhost:9100/metrics \| grep node_filesystem` to see actual labels available |
| Alert never transitions to "firing" even when threshold should be crossed | `for` duration not yet elapsed, or `rule_files` not loaded (check Prometheus config reload) | Check Prometheus → Status → Configuration that `alert_rules.yml` is referenced; reload via `docker compose restart prometheus` |
| `rate()` query returns nothing for the first few minutes | `rate()` needs at least 2 data points within the time window | Wait at least 2x the scrape interval before querying `rate()` |

### Redaction check ✅

`.env` (Grafana admin password) must be `.gitignore`d — commit only
`.env.example`. Configs themselves (`prometheus.yml`, `alert_rules.yml`,
`compose.yaml`) contain no secrets and can be committed directly.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Explain Prometheus's **pull** model vs. CloudWatch agent's **push**
model (Lesson 18). What's one advantage of each?

> **Your answer:**

**Q2.** **Scenario:** You write a PromQL query `node_network_transmit_bytes_total`
and get a graph that only ever goes up, even during periods of low traffic.
What's wrong, and how do you fix the query?

> **Your answer:**

**Q3.** What's the difference between a Prometheus **Counter** and a
**Gauge**? Give one example metric of each from this lesson.

> **Your answer:**

**Q4.** How does this lesson's `HighDiskUsage` alert relate to Lesson 07's
`disk_report.sh check_high_usage_alert()` and Lesson 18's CloudWatch disk
alarm? What's the same conceptually across all three, and what's different
about the implementation?

> **Your answer:**

**Q5.** Why does Prometheus's alerting rule have a `for` duration? Connect
this to Lesson 18 Q2's "alert fatigue" discussion.

> **Your answer:**

**Q6.** You're asked: "Should we use CloudWatch or Prometheus+Grafana?" How do
you answer, given a team running entirely on AWS vs. a team running on-prem
+ multiple clouds?

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## Step 8 — Search Keywords For Further Understanding

**Core**
- `prometheus architecture pull model scrape exporters`
- `promql rate counter gauge histogram explained`
- `prometheus alerting rules for duration alertmanager`
- `grafana data sources dashboards node exporter full`

**Tools**
- `node_exporter metrics reference`
- `docker compose prometheus grafana node-exporter stack`
- `promql cheat sheet`

**Going further (future lessons)**
- `wazuh siem prometheus integration`
- `multi-service docker compose monitoring stack`
- `terraform deploy monitoring stack`

---

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 23 — Security
Monitoring & Threat Detection (Wazuh)**.

---

*Lesson 22 written by Navi v28 · 2026-06-11 · WebSearch sources:
[Rost Glukhov Prometheus Monitoring: Complete Setup & Best Practices](https://www.glukhov.org/post/2025/11/monitoring-with-prometheus/),
[DevToolbox Prometheus & Grafana: The Complete Monitoring Guide for 2026](https://devtoolbox.dedyn.io/blog/prometheus-grafana-complete-guide),
[Rost Glukhov Observability in Production 2026](https://www.glukhov.org/observability/),
[Hostperl Infrastructure Monitoring with Prometheus and Grafana 2026](https://hostperl.com/blog/infrastructure-monitoring-prometheus-grafana-production-observability-2026)*
