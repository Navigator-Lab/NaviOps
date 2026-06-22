# Lessons Learned — `SOC-NN`

> Post-incident review. The most valuable output of any incident: it makes the next one faster to
> catch and easier to stop. Blameless — focus on process/technology gaps, not people.

## Incident recap (one line)
<SSH brute force → unauthorized login on web01; detected and contained same shift.>

## What went well
- <e.g. evidence was preserved before containment — clean timeline.>
- <e.g. escalation to T2 was timely and well-documented.>

## What didn't (gaps)
- **Detection (MTTD):** no brute-force rule — the activity ran ~90 min before a generic alert.
- **Prevention:** password SSH + no lockout allowed the attack at all.
- **Process:** <e.g. service-account password policy not enforced.>

## Timeline of *our* response (for MTTR review)
| Metric | Value | Target | Gap |
|---|---|---|---|
| Time to detect (MTTD) | ~90 min | < 5 min | detection rule missing |
| Time to acknowledge | 6 min | ≤ 30 min | ok |
| Time to contain | 38 min | < 60 min | ok |
| Time to recover (MTTR) | 95 min | < 4 h | ok |

## Action items (owned + tracked)
| # | Action | Type | Owner | Status |
|---|---|---|---|---|
| 1 | Add Wazuh frequency rule: ≥10 failed SSH in 60s from one IP | detection | you | committed → `docs/detections/…` |
| 2 | Disable SSH password auth (key-only) on web01 | prevention | sysadmin | open |
| 3 | Deploy fail2ban / lockout | prevention | sysadmin | open |
| 4 | Enforce service-account password policy | process | security | open |

## The new detection (the headline takeaway)
> Every incident should leave behind **at least one new or tuned detection**. Paste/link it here
> and commit it to `docs/detections/`. That's how a SOC turns each incident into permanent
> coverage — and how a detection engineer's portfolio grows.
