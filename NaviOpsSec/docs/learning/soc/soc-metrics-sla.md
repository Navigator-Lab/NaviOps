# SOC Metrics & SLA — SOC Module

What a SOC measures, why, and the SLAs analysts work against. Interviewers ask "what metrics
matter in a SOC?" — and a detection engineer tunes *against* these numbers.

## The core metrics

| Metric | Definition | Why it matters | Improve by |
|---|---|---|---|
| **MTTD** (Mean Time To Detect) | time from attacker action → alert | shorter = less attacker dwell | better detection coverage, lower thresholds (carefully) |
| **MTTR** (Mean Time To Respond/Resolve) | time from alert → contained/closed | shorter = less impact | runbooks, automation, clear escalation |
| **Dwell time** | total time attacker present before eviction | the headline breach metric | detection + fast IR |
| **Alert volume** | alerts per shift/day | capacity + fatigue signal | tuning, dedup, suppression |
| **False-positive rate** | FPs ÷ total alerts | trust + wasted effort | rule tuning, enrichment |
| **Escalation rate** | escalated ÷ handled | T1 effectiveness + tuning need | training, better runbooks |
| **Coverage** | ATT&CK techniques with a detection ÷ relevant total | detection completeness | detection engineering (L26) |

## SLA (typical tiered response targets)

| Severity | Acknowledge | Begin investigation | Target resolution |
|---|---|---|---|
| Sev1 / Critical | ≤ 15 min | immediate | ASAP, continuous |
| Sev2 / High | ≤ 30 min | ≤ 1 h | ≤ 4 h |
| Sev3 / Medium | ≤ 1 h | within shift | ≤ 24 h |
| Sev4 / Low | ≤ 4 h | batch | best effort |

The clock starts when the alert fires (or the SLA defines), and "acknowledge" stops the
first-response clock — which is why **acknowledging** an alert promptly matters even before you've
solved it.

## The tension every analyst lives

Lower thresholds → faster detection (better MTTD) but more false positives (worse FP rate, more
fatigue). Higher thresholds → fewer FPs but risk of false negatives (missed attacks). Tuning is
the art of moving both the right way at once — usually via **context/enrichment** (who/what/when)
rather than just raising/lowering a number. This is the heart of detection engineering (L26).

## Lesson tie-in
Lesson 03 introduces MTTD/MTTR; Lesson 26 (detection engineering) optimizes against FP rate and
coverage; Lesson 34 (SOC ops) reports the shift metrics.
