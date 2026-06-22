# Executive Summary — `SOC-NN: <title>`

> For **non-technical leadership**. One page. No jargon, no log lines. Answers: what happened,
> how bad, what we did, what it means for the business, and what we recommend. Written *after* the
> technical report, distilled from it.

**Date:** <YYYY-MM-DD> · **Prepared by:** <you> · **Classification:** Internal

## What happened
In plain language: <e.g. "An attacker repeatedly guessed the password for a service account on a
web server and succeeded, gaining access for approximately 90 minutes before being detected and
removed.">

## Business impact
- **Systems affected:** <one web server (web01); no customer-facing outage>.
- **Data impact:** <a marked test file was copied; no confirmed customer/PII data accessed>.
- **Service impact:** <~20 min during containment/recovery>.
- **Severity:** <High — confirmed unauthorized access, contained same shift>.

## What we did
1. Detected the activity via our monitoring (SIEM).
2. Investigated and confirmed the unauthorized access.
3. Contained the attacker (blocked access, disabled the account, isolated the server).
4. Removed the attacker's foothold and restored the server to a clean state.
5. Verified the system is clean and added a new detection to catch this faster next time.

## Why it happened (root cause, plainly)
<A service account had a weak password and the server allowed password logins with no lockout
after repeated failures.>

## Recommendations
| Recommendation | Benefit | Effort |
|---|---|---|
| Enforce key-based SSH (disable passwords) | removes this entire attack class | low |
| Add automatic lockout + brute-force alerting | catches the next attempt in minutes | low |
| Review service-account password policy | prevents weak credentials | medium |

## Bottom line
<e.g. "The incident was detected and fully contained the same shift with limited impact. The
gap that allowed it is straightforward to close; the recommended controls would prevent
recurrence and reduce detection time from ~90 minutes to under 5.">
