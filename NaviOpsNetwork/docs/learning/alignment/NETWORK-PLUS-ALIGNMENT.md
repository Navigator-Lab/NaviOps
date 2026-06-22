# CompTIA Network+ Alignment Matrix — NaviOpsNetwork

Maps the **CompTIA Network+ (N10-009)** exam domains to NaviOpsNetwork lessons. Network+ is the
**highest-leverage cert for the first NOC door** (`JOB_MILESTONES.md` Wave 1), so this matrix
is the primary cert tracker for Stage 1.

> N10-009 domain weightings (CompTIA blueprint): 1.0 Networking Concepts 23% · 2.0 Network
> Implementation 20% · 3.0 Network Operations 19% · 4.0 Network Security 14% · 5.0 Network
> Troubleshooting 24%. Verify the current blueprint at exam time. Note how heavily the exam
> weights **Operations (19%) + Troubleshooting (24%) = 43%** — exactly this platform's focus.

## Domain 1.0 — Networking Concepts (23%)

| Network+ objective | Lesson |
|---|---|
| OSI model | 02 |
| Ports/protocols, traffic types (unicast/multicast/broadcast/anycast) | 01, 03, 16 |
| Cloud concepts (NFV, VPC, connectivity) | 32, 33 |
| Network topologies/architectures (3-tier, spine-leaf, collapsed core) | 08, 27 |
| IPv4/IPv6 addressing, subnetting | 04, 05, 06 |
| Modern network environments (SDN, SD-WAN, IaC, VXLAN concepts) | 32 |

## Domain 2.0 — Network Implementation (20%)

| Network+ objective | Lesson |
|---|---|
| Routing technologies (static/dynamic, OSPF/BGP/EIGRP, NAT/PAT, FHRP) | 07, 14, 31 |
| Switching (VLANs, trunking 802.1Q, STP, link aggregation, port security) | 08, 09, 10, 11 |
| Wireless (802.11, channels, security) | 32 (concepts) |
| Physical installations / transceivers | 01, 08 |

## Domain 3.0 — Network Operations (19%)

| Network+ objective | Lesson |
|---|---|
| Documentation (diagrams, IPAM, SOPs, as-built) | 27 |
| Lifecycle / change management | 26, 27 + NAVI tickets |
| Monitoring (SNMP, flow, syslog, baselines, SIEM) | 21, 24, 25, 28 |
| DR/HA concepts (RTO/RPO, redundancy, FHRP) | 31 |
| Services (DHCP, DNS, NTP) | 12, 13, 16 |

## Domain 4.0 — Network Security (14%)

| Network+ objective | Lesson |
|---|---|
| Security concepts (CIA, zero trust, defense in depth) | 28 |
| Attack types (DoS/DDoS, on-path/MITM, spoofing, scanning, social) | 28 + every §12 Lens E |
| Hardening (segmentation, ACLs, port security, 802.1X, disabling services) | 09, 15, 28 |
| Remote access (VPN, IPsec, SSL/TLS) | 29 |

## Domain 5.0 — Network Troubleshooting (24% — the heaviest domain)

| Network+ objective | Lesson |
|---|---|
| The troubleshooting methodology (7 steps) | 18, 26 |
| Cable/connectivity issues | 08, 18 |
| Hardware tools (cable tester, etc.) — concepts | 18 |
| **Software tools** (`ping`, `traceroute`/`tracert`, `nslookup`/`dig`, `ip`/`ifconfig`, `netstat`/`ss`, `tcpdump`, `nmap`, protocol analyzer) | 17, 18, 19, 20 |
| Common issues (latency, loss, jitter, MTU, DNS, DHCP, VLAN, routing, firewall) | 12–18, troubleshooting-drills.md |

## CompTIA "software tools" → Linux-first coverage (the platform's strength)

Network+ explicitly lists the command-line tools below — every one is taught hands-on here:

| Network+ tool | Lesson | NaviOpsNetwork command focus |
|---|---|---|
| `ping` | 18 | reachability, loss, TTL |
| `traceroute`/`tracert` / `tracepath` / `mtr` | 18 | path + per-hop loss/latency |
| `nslookup` / `dig` | 13 | resolution, record types, `+trace` |
| `ipconfig`/`ifconfig` → `ip` | 05, 17 | iproute2 (`ip addr`/`link`/`route`) |
| `netstat` → `ss` | 03, 17 | sockets, listening ports + owning process |
| `arp` → `ip neigh` | 05 | ARP table, neighbor discovery |
| `tcpdump` | 20 | BPF capture filters, headless capture |
| Protocol analyzer (Wireshark) | 19 | display filters, follow stream |
| `nmap` | 28 | host/port discovery, scan detection (defender side) |

## How to use this matrix
1. Network+ is **Wave 1** — target it after Stage-1 lessons (01–04, 13, 15, 18, 21, 26).
2. Domains 3.0 + 5.0 (Operations + Troubleshooting = 43%) are this platform's core — you'll be
   over-prepared there; spend extra study time on 2.0 implementation specifics and wireless.
3. Use `troubleshooting-drills.md` as live Domain-5.0 practice (scenario-based, like the exam).
