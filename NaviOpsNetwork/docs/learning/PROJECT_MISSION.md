# NaviOpsNetwork — Project Mission

This is the **constitution** for NaviOpsNetwork. A future Claude session that reads ONLY this
file should understand the entire mission. For the lesson mechanics (the 12-section schema),
see `docs/learning/CLAUDE_TEACHING_RULES.md` — it is the single source of truth and is not
restated here.

> Origin: modeled on the sibling project **NaviOps** (`/home/sys-ctl/NaviOps`) — same Navi
> framework, same documentation system, same quality bar — retargeted to a networking / NOC /
> network-security curriculum at the operator's request.

## Mission

Build **NaviOpsNetwork** — a world-class, project-based, **operations-focused Networking**
learning platform — in public, on top of the [Navi](https://github.com/Navigator-Lab/Navi)
framework, while the operator learns networking by **building and operating** real network
services, monitoring, and incident response — not by cramming for an exam.

**This is NOT an exam-cram platform. It is an operational training platform.** Every lesson
produces real artifacts: scripts, configs, lab topologies, troubleshooting procedures,
monitoring dashboards, incident reports, and practical evidence for GitHub.

## End Goal

A portfolio-quality, public, MIT-licensed repo that demonstrates:
- Linux networking · Network fundamentals (OSI/TCP-IP/subnetting) · Routing & switching
  (VLAN/STP/EtherChannel) · Core services (DHCP/DNS/NAT) · Firewalls · Network
  troubleshooting · Packet analysis (Wireshark/tcpdump) · Network monitoring
  (Prometheus/Grafana/Zabbix/SNMP/syslog) · Network incident response · Network security &
  detection · VPN · Load balancing · High availability · Cloud & AWS networking
- A working lab capable of: diagnosing connectivity bottom-up, capturing and reading packets,
  running DNS/DHCP/NAT services, monitoring a network and alerting on it, triaging and
  documenting an outage end-to-end, and detecting reconnaissance/brute-force/scan activity.

## Career Goal

- **Primary near-term target:** **NOC Technician** — read dashboards (normal vs abnormal),
  run Tier-1 network/Linux troubleshooting, open/route tickets, follow an escalation matrix,
  document incidents, hand over cleanly.
- **Then:** **Network Operations Engineer · Linux Network Administrator · Infrastructure
  Support Engineer · Junior Network Engineer.**
- **On-ramp (security track):** **SOC Analyst (networking foundations) · Security Analyst
  (networking)** — built from every lesson's attacker/defender + incident-response thread.

## Roles this platform realistically prepares for

| Tier | Roles |
|---|---|
| **Prepares for (direct)** | NOC Technician · Network Operations Engineer · Linux Network Admin · Infrastructure Support · Junior Network Engineer |
| **Foundation for** | RHCSA (networking objectives) · Security Analyst · SOC Analyst · DevOps · Cloud Engineering |

## Learning Philosophy (the NaviOps standards, applied to networking)

- **Documentation First** — write the runbook/cheatsheet before/while you build.
- **Learn by Building** — stand up the service (DNS, DHCP, monitoring) yourself.
- **Learn by Operating** — run it like a NOC shift: dashboards, alerts, tickets.
- **Learn by Troubleshooting** — every lesson has a break-it-then-fix-it drill.
- **Learn by Incident Response** — diagnose → contain → fix → document → verify.
- **Learn by Monitoring** — if it isn't observed, it isn't operated.
- **Learn by Reporting** — every lesson generates portfolio + interview evidence.
- No courses, no theory-first cramming. Every lesson must improve the real lab
  (`scripts/`, `infra/`, `docs/`). No disconnected toy exercises.
- Progression is **gated**: the learner demonstrates understanding (graded quiz + reflection)
  before the next lesson begins (see `CLAUDE_TEACHING_RULES.md`).

## Relationship Between Navi, NaviOps, and NaviOpsNetwork

- **Navi** (`Navigator-Lab/Navi`) is the project-agnostic **framework**: the `.agent/` router,
  protocols (P00–P14), and the `docs/` memory system. It stays generic.
- **NaviOps** is the Linux/DevOps/Cloud platform built on Navi.
- **NaviOpsNetwork** (this repo) is the **networking/NOC/network-security** platform built on
  the same Navi core and the same documentation system — the sibling track. The two
  interlock: NaviOps' RHCSA/Linux depth + NaviOpsNetwork's networking depth = a complete
  Linux-network-operations engineer.

## Lesson Schema

See `docs/learning/CLAUDE_TEACHING_RULES.md` — every lesson, command, service, or technology
follows its **12-section schema**: Concept (scientific theory) → Linux networking commands →
Real-world use cases → Troubleshooting → Common mistakes → NOC perspective → Incident-response
perspective → Practical lab → GitHub artifact → Portfolio artifact → RHCSA crossover →
Security notes — graded with a quiz and professional-answer comparisons, with two teaching
approaches + an ASCII diagram for difficult concepts.

## Technical Skills To Master

| Area | Topics |
|---|---|
| Network fundamentals | OSI, TCP/IP, encapsulation, ports/sockets, IPv4/IPv6 addressing, subnetting/CIDR/VLSM |
| Routing | static & dynamic routing, routing tables, longest-prefix match, RIP/OSPF/EIGRP/BGP concepts, `ip route` |
| Switching | MAC learning, broadcast/collision domains, VLANs, trunking (802.1Q), STP/RSTP, EtherChannel/LACP |
| Core services | DHCP (DORA), DNS (recursion, record types, `dig`), NAT/PAT, reverse proxy, time/NTP |
| Firewalls & filtering | stateful vs stateless, `nftables`/`iptables`/`firewalld`/ufw, ACLs, security zones |
| Linux networking | NetworkManager/`nmcli`, `ip`/`ss`, network namespaces, bridges, bonding, policy routing |
| Troubleshooting | bottom-up method, `ping`/`traceroute`/`tracepath`/`mtr`, `curl`/`nc`/`socat`, latency/loss/MTU |
| Packet analysis | `tcpdump` capture & BPF filters, `tshark`/Wireshark, reading a 3-way handshake / DNS / TLS |
| Monitoring & observability | Prometheus/Grafana, blackbox-exporter, Zabbix, SNMP (`snmpwalk`), syslog/rsyslog, NetFlow concepts |
| Network operations (NOC) | alert handling, escalation matrix, ticketing, shift handover, RCA, SLA/SLO, outage management |
| Network security | recon/scan detection (`nmap`), traffic analysis, IDS (Suricata), brute-force/failed-login/port-scan detection, Wazuh/SIEM, MITRE ATT&CK |
| VPN / HA / LB | IPsec/WireGuard/OpenVPN concepts, VRRP/keepalived, ECMP, L4/L7 load balancing, ALB/NLB |
| Cloud networking | VPC/subnets/route tables/IGW/NAT GW, security groups vs NACLs, Route 53, VPC peering/TGW |
| Linux internals tie-in | sockets, the kernel network stack, conntrack, netfilter hooks, `/proc/net`, network namespaces |

If a missing but important skill is identified mid-project, it gets added to this table and
the roadmap without waiting for permission — the rationale is logged in `docs/DECISIONS.md`.

## Portfolio Objectives

Every completed milestone produces (per `CLAUDE_TEACHING_RULES.md`):
1. A **Portfolio Summary** (`docs/learning/lessons/<milestone>/PORTFOLIO.md`)
2. **Resume Bullet Points**
3. **Interview Talking Points**

— each framed for NOC Technician, Network Operations Engineer, Linux Network Admin, and
Junior Network Engineer roles. See `docs/learning/alignment/` for the GitHub portfolio
strategy and job/cert matrices.

## Rules For Future Claude Sessions

1. Read `docs/STATUS.md` AND `docs/learning/LEARNING_STATE.md` first — resume with zero
   re-explanation.
2. Follow `CLAUDE_TEACHING_RULES.md` for every lesson — no exceptions, no skipped sections.
3. Honor `navi.project.md` Hard Rules, especially public-repo redaction (no real IPs/configs/
   captures) and the no-scan-without-authorization danger zone.
4. Use Navi's `/navi` router and the standard `docs/` memory protocol for anything that isn't
   a lesson (e.g. "review this capture", "fix this nftables rule") — normal EXP/PLAN/REVIEW/
   DEBUG requests.
5. After every lesson/milestone, run the `CLAUDE_TEACHING_RULES.md` Update Protocol.

## Definition Of Done — NOC Technician (primary milestone)

- [ ] Can read a network-monitoring dashboard and distinguish normal from abnormal.
- [ ] Can run bottom-up troubleshooting (`ping`/`traceroute`/`mtr`/`ip`/`ss`/`dig`) and name
      the OSI layer at each step.
- [ ] Can capture and read packets (`tcpdump` BPF filters; a 3-way handshake, a DNS query, a
      failed TLS handshake in Wireshark).
- [ ] Understands DHCP (DORA), DNS resolution, NAT/PAT, and basic firewall rules well enough
      to troubleshoot them.
- [ ] Can open/route a ticket, follow an escalation matrix, and write a clean shift handover.
- [ ] Has documented ≥1 network incident end-to-end (symptom → RCA → fix → verification).

## Definition Of Done — Network Operations / Junior Network Engineer

- [ ] Can design and verify a subnet/VLAN plan and reason about routing between segments.
- [ ] Operates a monitoring stack (Prometheus/Grafana or Zabbix + SNMP + syslog) with alerts.
- [ ] Can configure and troubleshoot DNS/DHCP/NAT/firewall services on Linux.
- [ ] Has detected and documented reconnaissance/brute-force/scan activity from traffic+logs.
- [ ] Has built ≥1 of the three capstones (CCNA / NOC / Network-Security) end-to-end.
- [ ] Portfolio includes ≥3 milestone write-ups with resume bullets + interview talking points.

## Success Criteria

By the end of this journey, the operator should be able to:
- Pass NOC Technician / Junior Network Engineer interviews.
- Troubleshoot connectivity, DNS, DHCP, NAT, and firewall issues independently, Linux-first.
- Read packet captures and explain what a protocol exchange is doing.
- Stand up and operate a network-monitoring stack and respond to its alerts.
- Triage, contain, and document a network incident end-to-end.
- Map network attacks to MITRE ATT&CK and detect recon/brute-force/scan activity.
- Point to NaviOpsNetwork — a real, public, MIT-licensed open-source project — as proof of
  practical, operational networking experience.
