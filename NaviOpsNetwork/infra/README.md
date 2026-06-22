# infra/ — NaviOpsNetwork lab infrastructure

Lab topologies, monitoring stacks, and device/service configs produced by the lessons. Lab /
RFC-1918 / RFC-5737 ranges only; redact before commit (`docs/learning/LEARNING_STATE.md`).

| Dir | Holds | First lesson |
|---|---|---|
| `topologies/` | network lab topologies (Linux netns/bridge build scripts, GNS3/containerlab notes, ASCII diagrams) | 08 (switching) |
| `configs/` | service & device configs: dnsmasq (DHCP/DNS), nftables (NAT/firewall), VLAN/bonding, WireGuard, HAProxy, keepalived, rsyslog | 09+ |
| `monitoring/` | the observability stack: Prometheus + Grafana + blackbox/node/snmp exporters compose, Zabbix notes, dashboards | 22 |

## Danger-zone reminder
- Firewall/routing/VLAN changes on a live host can cut you off — have console fallback.
- Cloud networking (AWS VPC/NAT GW/ELB) is billing-affecting — human-approved only, redacted.
- Never commit real device credentials, SNMP community strings, VPN PSKs, or raw `.pcap`.
