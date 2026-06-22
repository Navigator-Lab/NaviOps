# Incident Report — `SOC-NN: <short title>`

> Technical write-up for the security team. The headline portfolio artifact. Fill in, sanitize,
> commit to `docs/runbooks/`. All times **UTC**.

## 1. Summary
- **Incident ID:** SOC-NN
- **Title:** <e.g. SSH brute force → unauthorized login on web01>
- **Severity:** Sev<1–4>
- **Status:** <Investigating / Contained / Eradicated / Closed>
- **Date detected:** <YYYY-MM-DD HH:MMZ>   **Date closed:** <…>
- **Analyst:** <you>
- **One-paragraph summary:** what happened, the impact, and the outcome — in plain English.

## 2. Affected assets
| Asset | Address | Role | Owner | Impact |
|---|---|---|---|---|
| host01.lab.example | 10.0.0.20 | web server | <team> | <e.g. account compromised> |

## 3. Detection
- **Source:** <Wazuh rule ID / log / hunt> — how we found it.
- **Initial signal:** <the alert/log line, sanitized>.

## 4. Timeline (UTC)
| Time | Event | Evidence | ATT&CK |
|---|---|---|---|
| 02:05Z | 240 failed SSH logins from 203.0.113.50 | auth.log | T1110 |
| 02:14Z | Accepted password for `svc_app` from 203.0.113.50 | auth.log | T1078 |
| 02:16Z | process `bash` spawned from web service, opened socket :4444 | ps/ss | T1059 |
| … | … | … | … |

## 5. Investigation findings
- **Root cause / entry point:** <how they got in>.
- **What the attacker did:** <execution, persistence, etc.>.
- **Scope:** <hosts/accounts affected — confirmed boundaries>.

## 6. Indicators of Compromise (IOCs)
| Type | Indicator | Context |
|---|---|---|
| IP | 203.0.113.50 | brute-force + login source |
| Account | svc_app (compromised), svc_tmp (created) | T1078 / T1136 |
| File | /tmp/.x (sha256: <hash>) | dropped payload |
| Persistence | crontab entry `* * * * * …`; `authorized_keys` line | T1053 / T1098 |

## 7. Response actions taken
| Time | Phase | Action | By |
|---|---|---|---|
| 02:40Z | Investigation | collected auth.log, `last`, process/socket snapshot, hashed /tmp/.x | analyst |
| 02:52Z | Containment | blocked 203.0.113.50, disabled svc_app, isolated host | analyst/T2 |
| 03:10Z | Eradication | removed cron + key + svc_tmp + payload; rotated creds | T2 |
| 03:40Z | Recovery | restored service, validated clean, heightened monitoring | T2 |

## 8. Root-cause analysis
See [`rca.md`](rca.md) — weak credential + password auth enabled + no brute-force lockout.

## 9. Lessons learned & recommendations
See [`lessons-learned.md`](lessons-learned.md). Key: enforce key-only SSH, add brute-force
frequency rule (committed: `docs/detections/…`), alert on new-account creation.

## 10. Evidence
See [`evidence-package.md`](evidence-package.md) — collected artifacts + hashes (sanitized).
