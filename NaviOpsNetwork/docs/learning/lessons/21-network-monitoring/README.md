# Lesson 21 — Network Monitoring

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** what to monitor (availability/latency/loss/utilization/errors), active vs passive, baselines, thresholds, synthetic checks.
**Primary artifact:** `scripts/latency_monitor.sh`.

> **How to use this lesson:** monitoring is *the* NOC competency — "read the dashboard." This
> lesson is the concepts; Lessons 22–25 are the tools. Read §1–§7, build `latency_monitor.sh` in
> §8. It feeds the NOC capstone (35).

---

## §1 — Concept (Scientific Theory)

### What it is
**Network monitoring** is the continuous measurement of network health so problems are detected
(ideally *before* users notice) and alerted on. It answers "is it up, is it fast, is it healthy?"
across devices, links, and services — and turns those measurements into **dashboards** (the NOC
screen) and **alerts** (the NOC's work queue).

### Why it exists
You can't operate what you can't see. Without monitoring, you learn about outages from angry users
(reactive, slow, MTTD measured in hours). With it, you detect threshold breaches in seconds and
fix before impact spreads. Monitoring is what makes a NOC a NOC.

### What to monitor (the golden network signals)
| Signal | Metric | Why |
|---|---|---|
| **Availability** | up/down (ping, port check) | the most basic SLI |
| **Latency** | RTT (ms) | user experience; congestion |
| **Packet loss** | % dropped | reliability; physical faults |
| **Utilization** | % of link capacity | congestion before it saturates |
| **Errors/discards** | interface error counters | bad cables/SFPs/duplex |
| **Saturation** | queue depth, drops | overload |
| **Service health** | HTTP status, cert expiry, DNS resolves | L7 reality (Lesson 16) |

### Active vs passive monitoring
- **Active (synthetic):** you *generate* test traffic — ping, a `dig`, a `curl`, a port check —
  and measure the result. Proves the user-path works end-to-end. (Your `latency_monitor.sh`,
  blackbox-exporter in Lesson 22.)
- **Passive:** you *observe* existing traffic/metrics — SNMP counters (Lesson 24), flow data
  (NetFlow), logs (Lesson 25). Shows real load and trends without generating traffic.
Use both: active proves reachability/SLA, passive shows utilization/trends.

### Baselines & thresholds (the hard part)
A number means nothing without context. **Baseline** = normal behavior over time (this link is
normally 40% utilized, 5 ms RTT). **Thresholds** alert when a metric deviates (RTT > 2× baseline,
util > 80%, loss > 1%). Static thresholds are simple but noisy; baselines/anomaly detection reduce
false alarms (the alert-fatigue problem, `noc/alert-handling.md`).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** monitoring is automatic, constant checking — "is the network okay?" —
  that lights up a dashboard and pages someone when something's wrong.
- **Level 2 — NetOps/NOC:** you decide *what* to measure (the golden signals), set **baselines**
  and **thresholds** that are actionable (not noisy), build **synthetic checks** for the
  user-critical paths (DNS, key services), and design dashboards that show normal-vs-abnormal at a
  glance. You tie alerts to **runbooks** (`noc/alert-handling.md`) and **SLOs** (`noc/sla-concepts.md`).
- **Level 3 — Wire/Kernel (Lens D):** active checks use the same primitives you've learned —
  ICMP (`ping`), TCP connect (`nc`), DNS (`dig`), HTTP (`curl`) — sampled on an interval; passive
  metrics come from kernel counters (`/proc/net`, `ip -s link`) and device counters via SNMP. A
  time-series database (Prometheus, Lesson 22) stores samples; alerting evaluates rules over them.

### Two Teaching Approaches (Lens B) — what makes a *good* alert

**Approach 1 (technical):** a good monitoring signal is **actionable** (a human can do something),
**specific** (says what/where/how bad), tied to a **baseline/threshold** that reflects real impact
(not an arbitrary number), and linked to a **runbook**. Coverage = the golden signals on every
critical link/device/service; alerting = thresholds that fire on real degradation, not noise.

**Approach 2 (analogy):** monitoring is a **hospital patient monitor**.
- It tracks **vital signs** (heart rate = latency, blood pressure = utilization, oxygen = loss) —
  the golden signals.
- A **baseline** is "this patient's normal resting heart rate"; an alarm fires on a meaningful
  deviation, not every minor wiggle (or the staff suffer **alarm fatigue** and ignore the real
  emergency — exactly `noc/alert-handling.md`).
- **Active vs passive** = taking the patient's pulse on demand (synthetic check) vs continuous
  ECG leads (passive metrics).
- **Where it breaks down:** a patient monitor watches one patient; a NOC watches thousands of
  "patients" (devices), so **aggregation, dedup, and correlation** (one root cause → many alarms)
  matter far more — the scale problem the hospital analogy understates.

### Visual (ASCII) — active + passive feeding dashboards + alerts

```
   ACTIVE (synthetic)              PASSIVE (observe)
   ping/dig/curl/nc  ──┐          SNMP counters (L24) ──┐
   latency_monitor.sh  ├──► TSDB (Prometheus, L22) ◄────┤ syslog (L25), flow
                       │         │                        │
                  dashboards (Grafana/Zabbix = the NOC screen)   normal vs abnormal
                       │
                  alert rules (threshold/baseline) ──► alert ──► runbook ──► ticket
```

---

## §2 — Linux Networking Commands

```bash
# Active checks (the primitives behind synthetic monitoring)
ping -c5 -W2 <target>                  # availability + latency + loss
mtr -rwc 50 <target>                    # path latency/loss for trending
dig +short <name> @<resolver>           # DNS synthetic (Lesson 13)
nc -vz -w3 <host> <port>                # service reachability (Lesson 03)
curl -sS -o /dev/null -w '%{http_code} %{time_total}\n' https://<host>   # L7 + timing

# Passive / local metrics
ip -s link show <if>                    # interface rx/tx, errors, drops (passive)
cat /proc/net/dev                        # raw counters
ss -s                                    # socket/connection counts

# Trending: sample on an interval, store, compare to baseline (latency_monitor.sh)
```

**Cisco/CCNA mapping:** `show interfaces` counters (passive), IP SLA (active synthetic on IOS),
and the SNMP/syslog/NetFlow trio (Lessons 24/25). CCNA Network Operations covers baselines,
SNMP, syslog, and monitoring concepts.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Detect before users do:** a link crossing 80% utilization at peak alerts you to add capacity
   before it saturates.
2. **Synthetic SLA checks:** ping/HTTP checks to key services prove the *user* path works and
   measure SLA compliance (`noc/sla-concepts.md`).
3. **Cert-expiry + DNS synthetics:** catch the predictable outages (Lesson 16/13) ahead of time.
4. **Baseline-driven triage:** "is 150 ms latency bad?" — only vs the baseline; the dashboard
   shows the deviation.

**How NOC engineers use it:** *reading the dashboard* (normal vs abnormal) and *handling the
alerts it generates* is the literal NOC job description. This lesson + 22–25 build that skill.

**When NOT to:** don't alert on everything (alert fatigue); don't set thresholds without baselines
(noise); don't monitor metrics with no runbook/action.

**Exam framing (Net+/CCNA):** SNMP/syslog/flow, baselines, thresholds, availability, and active vs
passive are in Network Operations domains.

---

## §4 — Troubleshooting Section

| Symptom | Monitoring angle | Action |
|---|---|---|
| Alert storm from one event | no dedup/correlation | group/correlate (Lesson 22 Alertmanager) |
| Alerts ignored (fatigue) | noisy thresholds | tune to baseline; remove non-actionable alerts |
| Outage with no alert | coverage gap / wrong metric | add the missing synthetic/threshold |
| "Is this normal?" | no baseline | establish baselines |
| False positive flapping | threshold too tight / no hysteresis | add `for:` duration / hysteresis |

**Redaction check:** lab targets/IPs in committed monitoring configs/output.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Monitoring up/down only | misses slow/degraded | add latency/loss/util/errors |
| No baselines | can't tell normal from abnormal | baseline first, then threshold |
| Alerting on everything | alert fatigue → missed Sev1 | actionable alerts only |
| No synthetic user-path checks | "green" while users suffer | active checks on critical paths |
| Alerts without runbooks | slow MTTR | link each alert to a runbook |
| Ignoring cert/DNS synthetics | predictable outages | monitor expiry + resolution |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

This is the NOC's core. The dashboard is the NOC screen; the alerts are the NOC queue. Everything
in `docs/learning/noc/` connects here: alerts → handling/severity (`alert-handling.md`); SLIs →
SLOs/SLAs (`sla-concepts.md`); thresholds → the difference between catching a Sev1 early and
finding out from users. The skill interviewers probe — "how do you know if something's wrong?" —
is answered by the golden signals + baselines + actionable alerts. The NOC capstone (35) runs on
the monitoring you build here.

---

## §7 — Incident-Response Perspective

Monitoring is the **Detect** phase of IR and the **MTTD** lever (`noc/sla-concepts.md`):
- Good coverage + actionable thresholds = fast detection (low MTTD).
- After every incident, the post-incident review asks "**could we have detected this sooner?**" —
  the answer is usually a new/tuned monitor, which becomes the **prevention/detection-gap** item
  in the runbook (`noc/rca.md`). So monitoring continuously improves via IR.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build `scripts/latency_monitor.sh` — an active monitor that samples latency/loss to
targets, compares to a baseline, and alerts on breach.

### Lens C — Manual → Automated → Why
- **Manual:** `ping`/`mtr`/`curl -w` ad hoc.
- **Automated:** `latency_monitor.sh` samples a target list on an interval, computes RTT + loss,
  compares to a stored baseline/threshold, and prints/exits an alert on breach (the seed of a real
  synthetic monitor).
- **Why:** continuous, baseline-aware measurement is the foundation of NOC monitoring; this script
  is the manual prototype of what blackbox-exporter (Lesson 22) does at scale.

### Steps
1. Define a target list (gateway, a public host, a key service) and capture a **baseline** (avg
   RTT/loss over some samples).
2. Build `scripts/latency_monitor.sh`:

```bash
#!/usr/bin/env bash
# latency_monitor.sh — sample latency/loss vs threshold for a target list. Lesson 21.
# Usage: ./latency_monitor.sh targets.txt [rtt_ms_threshold] [loss_pct_threshold]
set -euo pipefail
file="${1:?usage: latency_monitor.sh targets.txt [rtt_ms] [loss%]}"
rtt_max="${2:-100}"; loss_max="${3:-2}"; rc=0
while read -r t; do
  [[ -z "$t" || "$t" == \#* ]] && continue
  out=$(ping -c5 -W2 "$t" 2>/dev/null || true)
  loss=$(echo "$out" | sed -n 's/.* \([0-9]*\)% packet loss.*/\1/p')
  rtt=$(echo "$out"  | sed -n 's#.*= [0-9.]*/\([0-9.]*\)/.*#\1#p')
  printf "%-20s rtt=%-7s loss=%-3s " "$t" "${rtt:-NA}ms" "${loss:-NA}%"
  if [[ -z "$rtt" ]]; then echo "ALERT: unreachable"; rc=1
  elif (( $(printf '%.0f' "${rtt:-0}") > rtt_max )); then echo "ALERT: high latency"; rc=1
  elif (( ${loss:-0} > loss_max )); then echo "ALERT: packet loss"; rc=1
  else echo "OK"; fi
done < "$file"
exit $rc
```

3. `bash -n` → `shellcheck` → run it. **Drill:** inject latency/loss with `tc netem` (drills 3/4)
   and confirm the monitor alerts.
4. Note how you'd schedule it (cron/systemd timer) and how Prometheus blackbox-exporter (Lesson
   22) generalizes this.

### Lens D — sampling + thresholds
Discuss in your notes: the trade-off between sample interval (resolution vs load), the `for:`
duration to avoid flapping alerts, and baseline vs static thresholds.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/latency_monitor.sh` (+ a `targets.txt`).
2. **Config/doc:** a "what we monitor + thresholds + baselines" note in `docs/dashboards/`.
3. **Drill:** drills 3/4 (latency/loss via netem) detected by the monitor.
4. **NAVI ticket:** `NAVI-21` (Task: "latency_monitor.sh + monitoring plan").
5. **Incident report:** a monitor-detected latency/loss incident runbook.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Designed a network-monitoring plan (golden signals + baselines + actionable
  thresholds) and built a synthetic latency/loss monitor; reduced MTTD by alerting on degradation
  before user impact."
- **Interview talking point:** active vs passive, baselines vs thresholds, and how you avoid alert
  fatigue — exactly what "read the dashboard" NOC roles want.
- **Serves:** NOC Technician (Stage 1) — the core competency; feeds Lessons 22–25 + capstone 35.

---

## §11 — RHCSA Crossover Notes

RHCSA-relevant in spirit: monitoring concepts apply to RHEL host health (`ss`, `ip -s link`,
journald), and scheduling checks with **systemd timers**/cron is an RHCSA skill. The sibling
NaviOps platform covers host monitoring in depth; here it's network-focused.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** attackers try to **operate below thresholds** (slow scans, low-and-slow exfil) to
avoid monitoring, and may **disable/blind monitoring** (`T1562` Impair Defenses) before acting.
Gaps in coverage are where attacks hide.

**🔵 Defender:** monitor **security-relevant signals** too (unexpected east-west traffic, new
listeners, traffic to odd ports/destinations — Lesson 28), **alert if monitoring itself goes
silent** (a dead monitor is suspicious), and baseline normal so anomalies surface. Verify your
monitoring detects a (lab) low-rate anomaly.

---

## Quiz (Interview-Style, Graded)

**Q1.** What are the "golden signals" you'd monitor on a network link, and why each?
> **Your answer:**

**Q2.** Active vs passive monitoring — define each and give an example, and why you'd use both.
> **Your answer:**

**Q3.** Why is a metric meaningless without a baseline? Give an example.
> **Your answer:**

**Q4.** **Scenario:** Your team ignores alerts because there are hundreds a day. What's the problem
called, and how do you fix it?
> **Your answer:**

**Q5.** What makes an alert "good" (actionable)? Name the properties.
> **Your answer:**

**Q6.** How does monitoring relate to MTTD and SLOs?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 22.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `network monitoring golden signals`
- `active vs passive monitoring`
- `baseline vs threshold alerting`
- `synthetic monitoring`
- `alert fatigue reduction`

**Tools**
- `ping mtr scripting monitoring`
- `blackbox exporter prometheus` (L22)
- `snmp interface utilization` (L24)

**Going further (future lessons)**
- `prometheus grafana` (L22) · `zabbix` (L23) · `slo sli error budget` (noc/sla-concepts)

**Red / Blue (Lens E):**
- 🔴 `low and slow evasion`, `impair defenses T1562`, `monitoring blind spots`
- 🔵 `security monitoring east-west`, `alert on monitor silence`, `anomaly detection baseline`

---

## Lesson Status
- [ ] §8 lab completed (latency_monitor.sh + baselines)
- [ ] §4 drill done (drills 3/4 detected)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 22 — Prometheus & Grafana**.

---

*Lesson 21 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: Google SRE book
(golden signals/SLOs), CompTIA Network+ N10-009 (Network Operations), Prometheus docs.*
