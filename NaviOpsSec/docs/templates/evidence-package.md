# Evidence Package — `SOC-NN`

> The index of collected evidence + chain of custody. Evidence is collected **before**
> containment and **hashed** so its integrity is provable. Everything here is **sanitized** before
> commit (no real PII/creds/IPs) — for a portfolio, share the *index + decoded fields*, never raw
> PII-bearing captures.

## Collection summary
- **Collected by:** <you>   **When:** <YYYY-MM-DD HH:MMZ>   **Host:** host01.lab.example
- **Method:** copied off-box to the analysis workstation before any containment action.

## Evidence inventory
| # | Item | Source path | Collected (UTC) | SHA-256 | Notes |
|---|---|---|---|---|---|
| 1 | auth.log | /var/log/auth.log | 02:40Z | `<hash>` | failed + accepted logins |
| 2 | syslog | /var/log/syslog | 02:41Z | `<hash>` | cron + service events |
| 3 | last/lastb output | (command) | 02:41Z | `<hash>` | login history |
| 4 | process/network snapshot | `ps auxf` + `ss -tunap` | 02:42Z | `<hash>` | live state |
| 5 | suspect binary | /tmp/.x | 02:44Z | `<hash>` | dropped payload |
| 6 | crontab (svc_app) | /var/spool/cron/… | 02:45Z | `<hash>` | persistence |
| 7 | pcap (if captured) | (tcpdump) | 02:46Z | `<hash>` | **sanitize / don't commit raw** |

## Chain of custody
| When | Action | By |
|---|---|---|
| 02:40Z | collected items 1–6 from host01 to workstation | analyst |
| 02:47Z | hashed all items, recorded above | analyst |
| 02:50Z | copied to case store (read-only) | analyst |
| 03:00Z | handed reference to T2 for analysis | analyst → T2 |

## Integrity verification
```bash
# regenerate + compare hashes to prove nothing changed since collection
sha256sum -c evidence/SHA256SUMS
```

> **Why hash first:** if you contain (kill/isolate/block) before collecting + hashing, you lose
> volatile evidence (process memory, sockets, `/tmp`) and can't prove the artifact you analyzed is
> the one that was on the box. Hash = integrity = a report that holds up.
