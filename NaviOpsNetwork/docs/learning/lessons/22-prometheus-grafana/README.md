# Lesson 22 — Prometheus & Grafana

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** exporters (node/blackbox/snmp), PromQL, dashboards, Alertmanager, recording rules.
**Primary artifact:** `infra/monitoring/compose.yaml` (the monitoring stack).

> **How to use this lesson:** this is where monitoring (Lesson 21) becomes a real, running stack —
> the NOC dashboard you'll demo in interviews. Read §1–§7, stand up the compose stack in §8.
> Lab only; the dashboard is the centerpiece artifact.

---

## §1 — Concept (Scientific Theory)

### What it is
**Prometheus** is an open-source time-series database + monitoring system that **scrapes** metrics
from **exporters** over HTTP, stores them, and evaluates **alerting rules** with its query
language **PromQL**. **Grafana** is the visualization layer — it queries Prometheus and renders
**dashboards** (the NOC screen). **Alertmanager** handles the alerts Prometheus fires
(deduplication, grouping, routing, silencing). Together they're the de-facto open-source
monitoring stack.

### Why it exists
Lesson 21's `latency_monitor.sh` works for a few targets, but real environments need: persistent
time-series storage, a query language to express SLOs/thresholds, auto-discovery, dashboards,
and proper alert routing. Prometheus+Grafana provide all of that — and the network-specific
exporters (blackbox, snmp) make it a network-monitoring system.

### The architecture
| Component | Role |
|---|---|
| **Exporters** | expose metrics over HTTP for Prometheus to scrape |
| → **node_exporter** | host metrics (CPU/mem/disk/**network counters**) |
| → **blackbox_exporter** | **active/synthetic** probes (ICMP, TCP, HTTP, DNS, TLS-expiry) |
| → **snmp_exporter** | poll network devices via SNMP (Lesson 24) → metrics |
| **Prometheus** | scrapes exporters on an interval, stores TSDB, evals rules |
| **PromQL** | query language (rates, aggregations, thresholds) |
| **Alertmanager** | dedup/group/route/silence the alerts |
| **Grafana** | dashboards + visualization (queries Prometheus) |

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** Prometheus regularly asks each thing it monitors "what are your
  numbers?" and saves them; Grafana draws graphs of those numbers; alerts fire when a number
  crosses a line.
- **Level 2 — NetOps/NOC:** you deploy exporters (blackbox for synthetic reachability/latency/
  DNS/TLS — generalizing Lesson 21's script; snmp for device counters), write **PromQL** for SLIs
  (e.g. `probe_success`, `rate(node_network_receive_bytes_total[5m])`, `probe_ssl_earliest_cert_expiry
  - time()` for cert days-left), build **Grafana dashboards** (red/green panels = the NOC view),
  and wire **Alertmanager** for dedup/routing to avoid the alert storms from Lesson 21.
- **Level 3 — Wire/Kernel (Lens D):** Prometheus is **pull-based** — it HTTP-GETs `/metrics`
  (plain-text exposition format) on a scrape interval; targets can be statically listed or
  **service-discovered**. blackbox_exporter performs the *same* primitives you learned (ICMP echo,
  TCP connect, HTTP GET, DNS query, TLS handshake) on demand and exposes the result as metrics —
  it's literally `latency_monitor.sh` as a service. node_exporter reads `/proc/net`/`/sys`
  (Lesson 17).

### Two Teaching Approaches (Lens B) — pull-based metrics & PromQL

**Approach 1 (technical):** every monitored thing exposes a `/metrics` endpoint of
`name{labels} value` samples; Prometheus scrapes them on a schedule into a TSDB keyed by metric
name + label set; PromQL queries select/aggregate/transform those series (`rate()` over counters,
`avg by (instance)`, comparisons for thresholds); alerting rules are PromQL expressions that, when
true for a `for:` duration, fire alerts to Alertmanager.

**Approach 2 (analogy):** Prometheus is a **factory floor supervisor with a clipboard doing
rounds**.
- Every machine (exporter) has a **gauge panel** (`/metrics`); the supervisor (Prometheus) walks
  the floor every 15 seconds and **writes down every reading** (scrape) in a logbook (TSDB).
- **PromQL** is how you ask the logbook questions: "average temperature per machine over the last
  5 minutes," "which machines exceeded the red line."
- **Grafana** is the **control-room wall of screens** showing those answers as live graphs.
- **Alertmanager** is the **shift bell** — but smart: it rings *once* for "machine 7 overheating"
  even if it's been true for 10 rounds (dedup), and routes it to the right team (routing).
- **Where it breaks down:** the supervisor *pulls* readings on rounds (Prometheus is pull-based) —
  unlike a system where machines phone in (push). For short-lived jobs that finish between rounds,
  you need a pushgateway — a real Prometheus nuance the clipboard analogy highlights.

### Visual (ASCII) — the stack

```
   TARGETS                 EXPORTERS                PROMETHEUS         GRAFANA
   hosts ──────────────► node_exporter   ┐
   services/URLs ──────► blackbox_exporter├─ /metrics ─► scrape ─► TSDB ─► PromQL ─► dashboards
   network devices ────► snmp_exporter    ┘                 │
                                                      alerting rules
                                                            │
                                                      Alertmanager ─► dedup/route ─► ticket/page
```

---

## §2 — Linux Networking Commands

```bash
# Run the stack (docker compose — see §8 infra/monitoring/compose.yaml)
docker compose -f infra/monitoring/compose.yaml up -d
curl -s localhost:9090/-/healthy            # Prometheus health
curl -s localhost:9100/metrics | head        # node_exporter metrics
curl -s 'localhost:9115/probe?target=example.com&module=http_2xx' | grep probe_success
curl -s 'localhost:9090/api/v1/query?query=up' | jq .   # PromQL via API

# Useful PromQL (enter in Prometheus/Grafana)
up                                          # which targets are scrapeable (1/0)
probe_success                                # blackbox synthetic up/down
rate(node_network_receive_bytes_total[5m])  # interface throughput
(probe_ssl_earliest_cert_expiry - time())/86400   # TLS cert days remaining
probe_duration_seconds                       # synthetic latency
```

**Cisco/CCNA mapping:** Prometheus+Grafana is the open-source analog of SolarWinds/PRTG/Zabbix
that NOC postings list; snmp_exporter polls the same SNMP MIBs/OIDs CCNA covers (Lesson 24).

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **The NOC dashboard:** Grafana panels for availability (probe_success), latency
   (probe_duration), interface utilization/errors (snmp/node), and cert-expiry — the at-a-glance
   normal-vs-abnormal screen.
2. **Synthetic SLA monitoring:** blackbox probes to critical services/DNS prove the user path and
   measure SLO compliance.
3. **Device monitoring at scale:** snmp_exporter polls switches/routers; PromQL turns counters
   into utilization/error rates with alerts.
4. **Smart alerting:** Alertmanager dedups a switch reboot's 50 link-down alerts into one incident
   and routes by severity/team.

**How NOC engineers use it:** Grafana *is* the NOC screen; Prometheus alerts *are* the work queue.
This is the concrete realization of Lesson 21 and the demo-able portfolio centerpiece.

**When NOT to:** don't scrape too aggressively (load); don't build dashboards with no thresholds
(pretty but not actionable); don't skip Alertmanager (raw Prometheus alerts = the storm problem).

**Exam framing:** more tooling than exam, but Network+ Network Operations covers monitoring
systems, SNMP, and dashboards conceptually.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Target `up == 0` | exporter down / network / wrong port | `curl exporter:port/metrics` | fix exporter/scrape config |
| No data in Grafana | datasource/PromQL/time range | test query in Prometheus | fix datasource/query |
| Alert storm | no Alertmanager grouping | check routing/grouping config | group by alertname/instance |
| Synthetic probe fails but service is up | blackbox module/target wrong | test the `/probe?...` URL | fix module/params |
| Cert-expiry alert wrong | TLS module/target | check `probe_ssl_earliest_cert_expiry` | fix probe config |

**Redaction check:** lab targets/IPs in committed `compose.yaml`/configs/dashboards.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Dashboards without thresholds/alerts | pretty, not actionable | tie panels to alert rules |
| No Alertmanager | alert storms | dedup/group/route |
| Scrape interval too low | TSDB/load pressure | sensible interval (15–60s) |
| Counters vs rates confusion | wrong graphs | `rate()` for counters |
| Probing from one location only | misses path issues | probe from relevant vantage points |
| Committing real targets | leak | lab/RFC-1918 only |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

This lesson builds the literal NOC screen. The Grafana dashboard you create is the "read the
dashboard, normal vs abnormal" artifact every NOC posting wants — and it's demo-able in
interviews. Alertmanager directly solves the alert-fatigue/dedup problems from
`noc/alert-handling.md`. The NOC capstone (35) runs its simulated shift against *this* stack:
alerts fire here, you triage from this dashboard.

---

## §7 — Incident-Response Perspective

- **Detect:** a Prometheus alert fires (probe_success=0, util>threshold, cert<14d) → Alertmanager
  routes it → the NOC queue.
- **Triage/Diagnose:** Grafana dashboards give the at-a-glance picture; drill into PromQL for the
  specific series.
- **Document/Improve:** post-incident, add the missing alert/dashboard panel (the detection-gap
  prevention item, `noc/rca.md`). The stack is how MTTD keeps improving.

---

## §8 — Practical Lab (build this yourself)

**Goal:** stand up `infra/monitoring/compose.yaml` (Prometheus + Grafana + blackbox + node
exporters), build a network dashboard, and wire one alert.

### Lens C — Manual → Automated → Why
- **Manual:** Lesson 21's `latency_monitor.sh`.
- **Automated:** the blackbox_exporter generalizes that script into a scalable service; the whole
  stack automates collection → storage → visualization → alerting.
- **Why:** this is how monitoring is actually run in production (and the demo-able portfolio
  piece); it replaces ad-hoc scripts with a maintainable system.

### Steps
1. Write `infra/monitoring/compose.yaml`: services for `prometheus`, `grafana`,
   `blackbox_exporter`, `node_exporter`, (optional `alertmanager`, `snmp_exporter`). Add
   `prometheus.yml` with scrape configs (blackbox probing a few lab targets + node_exporter).
2. `docker compose up -d`; confirm targets are `up` in Prometheus, and `probe_success` works.
3. Build a Grafana dashboard: panels for availability (`probe_success`), latency
   (`probe_duration_seconds`), interface throughput (`rate(node_network_*_bytes_total[5m])`), and
   **cert days-left** (`(probe_ssl_earliest_cert_expiry - time())/86400`). Export the dashboard
   JSON to `docs/dashboards/`.
4. Write one alert rule (e.g. `probe_success == 0 for: 1m`) and confirm it fires (stop a probed
   service). **Drill:** induce a latency/loss/probe-down condition and watch the dashboard + alert.

### Lens D — the exposition format
`curl localhost:9100/metrics` shows the plain-text `name{labels} value` format; note how
blackbox's `/probe` runs the same ICMP/TCP/HTTP/DNS/TLS primitives from earlier lessons and
exposes them as metrics.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script/stack:** `infra/monitoring/compose.yaml` + `prometheus.yml` (the monitoring stack).
2. **Config/doc:** the Grafana dashboard JSON + PromQL notes in `docs/dashboards/`.
3. **Drill:** a probe-down/latency alert fired and seen on the dashboard.
4. **NAVI ticket:** `NAVI-22` (Change: "deploy Prometheus/Grafana monitoring stack").
5. **Incident report:** a dashboard-detected incident runbook.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Deployed a Prometheus + Grafana + blackbox/node-exporter monitoring stack
  (Docker Compose) with synthetic availability/latency/cert-expiry checks, PromQL alerting, and a
  NOC dashboard."
- **Interview talking point:** demo the dashboard; explain pull-based scraping, PromQL for SLIs,
  and Alertmanager dedup/routing — strong NOC/observability signal.
- **Serves:** NOC + Network Operations + Cloud/DevOps networking (Stages 1–2, 6); centerpiece of
  capstone 35.

---

## §11 — RHCSA Crossover Notes

Mostly **N/A for RHCSA** as a topic, but it's built with Docker/Compose (a containers skill) on a
RHEL-family host, and node_exporter reads the same `/proc`/`/sys` metrics RHCSA admins use. The
sibling NaviOps platform covers the host-monitoring angle; here it's network/synthetic.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** monitoring endpoints leak topology/inventory if exposed (an unauthenticated
Prometheus/Grafana is recon gold — `T1590`); attackers may **disable monitoring** (`T1562`) before
acting. Grafana/Prometheus have had real CVEs — exposed instances get exploited.

**🔵 Defender:** **authenticate + network-restrict** Grafana/Prometheus (never expose to the
Internet), keep them patched, **alert if monitoring goes silent** (a dead monitor is suspicious),
and feed **security metrics** (failed-probe spikes, odd traffic — Lesson 28) into the same stack.
Verify the endpoints aren't externally reachable (nmap from "outside", lab).

---

## Quiz (Interview-Style, Graded)

**Q1.** Explain Prometheus's pull model and what an exporter is. Name three exporters and what each provides.
> **Your answer:**

**Q2.** What does blackbox_exporter do, and how does it relate to the `latency_monitor.sh` you built?
> **Your answer:**

**Q3.** Write (in words or PromQL) how you'd alert when a TLS cert has fewer than 14 days to expiry.
> **Your answer:**

**Q4.** **Scenario:** A switch reboot generates 50 link-down alerts. How does Alertmanager prevent
this from drowning the NOC?
> **Your answer:**

**Q5.** Why do you use `rate()` on a counter metric like `node_network_receive_bytes_total`?
> **Your answer:**

**Q6.** Why must Prometheus/Grafana never be exposed unauthenticated to the Internet?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 23.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `prometheus pull model exporters`
- `promql rate aggregation examples`
- `blackbox exporter synthetic probes`
- `alertmanager grouping routing`
- `grafana dashboard prometheus`

**Tools**
- `prometheus node_exporter network metrics`
- `snmp_exporter network device`
- `grafana cert expiry panel`

**Going further (future lessons)**
- `zabbix` (L23) · `snmp` (L24) · `slo recording rules`

**Red / Blue (Lens E):**
- 🔴 `exposed grafana prometheus recon T1590`, `disable monitoring T1562`, `grafana cve`
- 🔵 `secure prometheus grafana auth`, `alert on monitoring silence`, `security metrics dashboard`

---

## Lesson Status
- [ ] §8 lab completed (monitoring stack + dashboard + alert)
- [ ] §4 drill done (probe-down/latency alert)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 23 — Zabbix**.

---

*Lesson 22 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: Prometheus &
Grafana docs, blackbox_exporter README, Google SRE (alerting), Network+ N10-009.*
