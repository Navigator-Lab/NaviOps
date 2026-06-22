# scripts/ — NaviOpsNetwork network automation

Real, runnable Bash network-operations tools. Every lesson that produces a script adds or
extends one of these (never a one-off scratch file — `CLAUDE_TEACHING_RULES.md` Rule 11). All
scripts: `set -euo pipefail`, a usage header, `shellcheck`-clean, safe to run on a host you own.

| Script | Lesson | Purpose | Status |
|---|---|---|---|
| `net_diag.sh` | 01 / 17 | bottom-up L1→L4 network snapshot + default-route check | ✅ seeded |
| `dns_check.sh` | 13 | local vs public resolver compare; flag SERVFAIL / mismatch | ✅ seeded |
| `ip_audit.sh` | 05 | enumerate addresses/ARP, flag duplicate IPs / APIPA | planned |
| `route_audit.sh` | 07 | dump + sanity-check the routing table | planned |
| `firewall_audit.sh` | 15 | summarize nftables ruleset + hit counters | planned |
| `service_probe.sh` | 16 | reachability probe (`nc`/`curl`/`openssl s_client`) | planned |
| `capture_triage.sh` | 20 | headless tcpdump capture → quick triage summary | planned |
| `latency_monitor.sh` | 21 | sample RTT/loss to targets, compare to baseline, alert | planned |
| `snmp_poll.sh` | 24 | poll interface counters via snmpwalk | planned |
| `port_scan_detect.sh` | 28 | detect port-scan / brute-force from logs (defender) | planned |

## Conventions
- **Redaction:** scripts print live network data — redact before pasting output into committed
  docs (`docs/learning/LEARNING_STATE.md`).
- **Verify before commit:** `bash -n script.sh && shellcheck script.sh`.
- **No scanning third parties:** detection/recon scripts run against lab hosts you own only
  (`navi.project.md` danger zones).
