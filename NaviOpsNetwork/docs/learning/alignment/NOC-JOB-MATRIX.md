# NOC Job Alignment Matrix — NaviOpsNetwork

Maps **what NOC / Network Operations job postings ask for** to the lessons + artifacts that
prove it. Use this to (a) sequence study toward a role and (b) answer "where's my evidence?"
in an interview.

> Source roles synthesized from typical NOC Technician / Network Operations Engineer / Junior
> Network Engineer postings (monitoring + ticketing + escalation + Tier-1 troubleshooting +
> 24/7 shift + documentation). Validate live postings at authoring time per the §2 WebSearch
> rule before relying on specifics.

## Core NOC competencies → lessons → evidence

| NOC competency (from postings) | Lessons | Artifact / evidence |
|---|---|---|
| Read monitoring dashboards; distinguish normal vs abnormal | 21, 22, 23 | `infra/monitoring/`, Grafana/Zabbix dashboard exports (`docs/dashboards/`) |
| TCP/IP, OSI, subnetting fluency | 01–04 | `docs/networking/subnet-cheatsheet.md`, OSI troubleshooting map |
| Tier-1 connectivity troubleshooting (`ping`/`traceroute`/`mtr`) | 18 | `scripts/net_diag.sh`, troubleshooting-method runbook |
| DNS / DHCP troubleshooting | 12, 13 | `scripts/dns_check.sh`, DHCP lab config, DNS-outage drill |
| Firewall / ACL basics | 15 | `scripts/firewall_audit.sh`, nftables ruleset |
| Packet capture awareness (Wireshark/tcpdump) | 19, 20 | `wireshark-filters.md`, `scripts/capture_triage.sh` |
| **Alert handling** | 21, 26, noc/ | `docs/learning/noc/alert-handling.md` |
| **Escalation procedures / matrix** | 26, noc/ | `docs/learning/noc/escalation-matrix.md` |
| **Ticket management** (ServiceNow/Remedy concepts) | all (NAVI tickets) | `docs/learning/noc/ticketing.md` + per-lesson `NAVI-NN` tickets |
| **Shift handover** | noc/ | `docs/learning/noc/shift-handover.md` + handover template |
| **Root cause analysis** | 26 | `docs/runbooks/` incident reports |
| **Incident documentation** | 26, 27 | runbooks + `docs/networking/` as-built docs |
| **SLA / SLO awareness** | noc/ | `docs/learning/noc/sla-concepts.md` |
| **Outage management** | 26, 35, noc/ | `docs/learning/noc/outage-management.md`, NOC capstone (35) |
| SNMP / syslog monitoring | 24, 25 | `scripts/snmp_poll.sh`, central rsyslog config |
| 24/7 shift readiness (process discipline) | 35 | NOC capstone simulated shift |

## NOC scenario coverage (interview-ready)

Each maps to a drill in `troubleshooting-drills.md` and a runbook in `docs/runbooks/`:

| Scenario | Primary lesson | First diagnostic move |
|---|---|---|
| DNS outage | 13 | `dig @<resolver> <name>` vs `dig @8.8.8.8`, check recursion/forwarders |
| DHCP failure | 12 | check scope exhaustion / relay; `journalctl -u dnsmasq`; client `APIPA` 169.254.x.x |
| High latency | 18, 21 | `mtr <dest>` to localize the hop; compare to baseline |
| Packet loss | 18, 20 | `ping` loss %, `mtr` per-hop loss, interface error counters (`ip -s link`) |
| Interface down | 17, 24 | `ip link`, SNMP ifOperStatus, check both ends / duplex |
| Routing issue | 07 | `ip route get <dest>`, traceroute asymmetry, missing/wrong route |
| VLAN misconfiguration | 09 | trunk allowed-VLANs, native-VLAN mismatch, access-port VLAN |
| Firewall blocking traffic | 15 | `nft list ruleset` / counters, `tcpdump` both sides, default-deny hit |

## Tooling familiarity expected (and where it's covered)

| Tool category | Postings name | Covered by |
|---|---|---|
| Monitoring | SolarWinds, PRTG, Nagios, Zabbix, Grafana | 21–23 (Zabbix + Prom/Grafana hands-on; SolarWinds/PRTG concepts) |
| Ticketing | ServiceNow, Remedy, Jira SM | NAVI ticket scheme (`noc/ticketing.md`) — concepts transfer |
| Packet | Wireshark, tcpdump | 19–20 (hands-on) |
| SNMP/flow | SNMP, NetFlow/sFlow | 24 (SNMP hands-on; NetFlow concepts) |
| Logs | syslog, Splunk/ELK | 25 (rsyslog hands-on; SIEM concepts in 28) |

## Gap-honesty note
Real NOC roles often use **vendor tooling** (SolarWinds, Cisco IOS, ServiceNow) the lab can't
fully reproduce. The platform teaches the **transferable fundamentals** (what the dashboard
*means*, what the ticket/escalation *workflow* is, how to troubleshoot bottom-up) so the
vendor specifics are a short ramp, not a wall. Name this honestly in interviews.
