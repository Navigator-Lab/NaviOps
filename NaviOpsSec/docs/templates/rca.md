# Root-Cause Analysis — `SOC-NN`

> The disciplined "why." Not "the attacker brute-forced us" (that's the *what*) — the **root
> cause** is the condition that *allowed* it. Use the 5-Whys to get past symptoms.

## Incident
<one line: SSH brute force → unauthorized login on web01, 2026-06-20.>

## 5 Whys
1. **Why** did the attacker get in? → They guessed a valid SSH password.
2. **Why** could they guess it? → The service account used a weak, reused password.
3. **Why** did repeated guessing work? → Password auth was enabled with **no lockout / rate
   limit** after failures.
4. **Why** was there no lockout? → No `fail2ban` / brute-force control was deployed on the host.
5. **Why** wasn't it caught sooner? → No brute-force **detection rule** existed in the SIEM
   (detection gap) — the activity ran ~90 min before a generic alert surfaced it.

## Root cause(s)
- **Primary:** weak/reused credential on an internet-reachable account with password auth + no
  lockout.
- **Contributing:** missing brute-force detection (MTTD gap); over-privileged service account.

## Contributing factors (people / process / technology)
| Factor | Type | Note |
|---|---|---|
| Weak service-account password | process | no enforced policy for service accounts |
| Password SSH enabled | technology | should be key-only |
| No lockout (fail2ban) | technology | no rate limiting |
| No brute-force SIEM rule | detection | the false-negative gap |

## Corrective actions (→ feeds lessons-learned)
- [ ] Disable SSH password auth on web01 (key-only).
- [ ] Deploy lockout / fail2ban.
- [ ] Add Wazuh frequency rule for failed-login bursts (commit to `docs/detections/`).
- [ ] Audit service-account privileges + rotate the credential.
