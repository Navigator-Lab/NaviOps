# SLA / SLO / SLI Concepts — NOC Module

NOC work is measured against **service-level targets**. Knowing the vocabulary and the math is
a common interview filter.

## The three terms

| Term | Definition | Example |
|---|---|---|
| **SLI** (Indicator) | a measured metric | availability %, p95 latency, packet loss % |
| **SLO** (Objective) | the internal target for an SLI | "99.9% availability monthly", "p95 < 100ms" |
| **SLA** (Agreement) | the contractual promise (+ penalty) to a customer | "99.9% uptime or service credits" |

SLI is what you measure, SLO is what you aim for, SLA is what you're liable for. SLO is usually
stricter than SLA (so you breach the internal target before the contractual one).

## Availability math ("the nines")

| Availability | Downtime / year | Downtime / month | Downtime / day |
|---|---|---|---|
| 99% ("two nines") | 3.65 days | 7.2 h | 14.4 min |
| 99.9% ("three nines") | 8.77 h | 43.8 min | 1.44 min |
| 99.99% ("four nines") | 52.6 min | 4.38 min | 8.6 s |
| 99.999% ("five nines") | 5.26 min | 26.3 s | 0.86 s |

`Availability = uptime / (uptime + downtime)` = `MTBF / (MTBF + MTTR)`.

## MTTR / MTBF / MTTD

| Metric | Meaning | NOC lever |
|---|---|---|
| **MTTD** (detect) | time to notice | better monitoring/alerting (Lessons 21–25) |
| **MTTA** (acknowledge) | time to own | staffing, on-call, alert routing |
| **MTTR** (repair/restore) | time to fix | runbooks, automation, escalation speed |
| **MTBF** (between failures) | reliability | redundancy/HA (Lesson 31), RCA prevention |

The NOC most directly improves **MTTD** (monitoring) and **MTTR** (runbooks + escalation) —
which is exactly what this platform builds.

## Error budget (SRE framing)

If the SLO is 99.9%, the **error budget** is 0.1% (≈43 min/month). Spend it on changes/risk;
when it's exhausted, freeze risky changes. Connects SLOs to change management.

## Lab tie-in
- Lesson 21 sets the SLIs (what to monitor) and baselines.
- Lesson 31 (HA) is how you buy more nines.
- NOC capstone (35) reports the simulated shift's MTTD/MTTR for its incident.
