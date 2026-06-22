# Investigation Notes — `SOC-NN`

> Working notes, written **as you go**, in UTC. Keep **facts** and **assessment** separate — the
> report and any downstream review depend on that line. Raw, messy, honest; the polished version
> is the incident report.

## Hypothesis / why I'm looking
<e.g. Wazuh alert: 240 failed SSH logins from one IP on web01 → suspect brute force, possible success.>

## Evidence collected (before any containment)
| What | Where saved | Hash / note |
|---|---|---|
| /var/log/auth.log (copy) | evidence/auth.log | sha256 <…> |
| `last` / `lastb` output | evidence/last.txt | |
| `ps auxf`, `ss -tunap` snapshot | evidence/proc-net.txt | taken 02:40Z |
| suspect file /tmp/.x | evidence/x.bin | sha256 <…> |

## Findings log (timestamped)
- `02:42Z` **[fact]** auth.log: 240 `Failed password for svc_app from 203.0.113.50` between
  02:05–02:14Z.
- `02:43Z` **[fact]** auth.log: one `Accepted password for svc_app from 203.0.113.50` at 02:14Z.
- `02:43Z` **[assessment]** brute force succeeded → treat as compromise, escalate Sev2.
- `02:48Z` **[fact]** `ss` shows PID 8123 (`bash`, parent = web app) listening on :4444.
- `02:49Z` **[assessment]** looks like a reverse/bind shell; contain after evidence saved.
- `02:55Z` **[fact]** crontab for svc_app has new entry running /tmp/.x every minute.

## Pivots / scope checks
- [ ] Other hosts with logins from 203.0.113.50? (`ioc_sweep.sh`) → <result>
- [ ] svc_app activity on other hosts? → <result>
- [ ] Other new accounts / cron / keys? → <result>

## Open questions
- <e.g. did stage reach host02? confirm before closing scope.>

## ATT&CK so far
T1110 (brute force) → T1078 (valid accounts) → T1059 (execution) → T1053/T1098 (persistence).
