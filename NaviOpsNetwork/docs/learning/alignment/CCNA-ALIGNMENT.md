# CCNA Alignment Matrix — NaviOpsNetwork

Maps the **Cisco CCNA 200-301** exam domains to NaviOpsNetwork lessons. The platform teaches
networking **Linux-first** and operationally (not IOS-cram), then maps to Cisco syntax — so
this matrix is the bridge: it shows the operator is covering CCNA ground while building real
skills, and flags the **IOS-specific gaps** to close with a Cisco emulator (Packet Tracer /
GNS3 / CML) before sitting the exam.

> CCNA 200-301 weightings (Cisco blueprint): Network Fundamentals 20% · Network Access 20% ·
> IP Connectivity 25% · IP Services 10% · Security Fundamentals 15% · Automation &
> Programmability 10%. Verify the current blueprint at exam time.

## Domain 1 — Network Fundamentals (20%)

| CCNA topic | Lesson | Linux-first coverage | IOS gap to close |
|---|---|---|---|
| Components (router/switch/AP/firewall) | 01 | concept + roles | physical device CLI |
| OSI & TCP/IP, encapsulation | 02, 03 | full, with captures | — |
| Cabling/interfaces, duplex/speed | 01, 08 | `ip link`, `ethtool` | IOS `show interfaces` |
| IPv4 addressing & subnetting/VLSM | 04, 05 | full | — |
| IPv6 addressing (types, SLAAC) | 06 | `ip -6`, NDP | IOS IPv6 config |
| TCP vs UDP, ports | 03 | `ss`, captures | — |

## Domain 2 — Network Access (20%)

| CCNA topic | Lesson | Linux-first coverage | IOS gap to close |
|---|---|---|---|
| VLANs (normal range), access/trunk | 09 | Linux VLAN interfaces, 802.1Q | IOS `switchport`, `vlan` |
| Inter-switch connectivity / trunking (802.1Q) | 09 | bridge + VLAN | DTP, trunk config |
| L2 discovery (CDP/LLDP) | 08 | `lldpctl`/`lldpd` | CDP (Cisco) |
| EtherChannel (LACP/PAgP) | 11 | Linux bonding LACP | IOS `channel-group` |
| STP / RSTP basics | 10 | concept + Linux bridge STP | IOS `spanning-tree`, PortFast/BPDU Guard |
| Wireless principles (WLC/AP, SSID) | 01, 32 | concepts | hands-on WLC |

## Domain 3 — IP Connectivity (25%)

| CCNA topic | Lesson | Linux-first coverage | IOS gap to close |
|---|---|---|---|
| Routing table interpretation | 07 | `ip route`, longest-prefix | IOS `show ip route` codes |
| Static routing (incl. default) | 07 | `ip route add` | IOS `ip route` |
| OSPFv2 (single area) | 07 | concept + analogy + FRR option | IOS OSPF config/verify |
| Administrative distance / metrics | 07 | concept | IOS AD table |
| First-hop redundancy (HSRP/VRRP) | 31 | keepalived/VRRP | IOS HSRP |

## Domain 4 — IP Services (10%)

| CCNA topic | Lesson | Linux-first coverage | IOS gap to close |
|---|---|---|---|
| NAT (static/dynamic/PAT) | 14 | nftables NAT, conntrack | IOS `ip nat` |
| NTP | 16 | `chrony`/`timedatectl` | IOS `ntp` |
| DHCP (server/relay/client) | 12 | dnsmasq/ISC, relay | IOS `ip helper-address` |
| DNS | 13 | `dig`, resolver config | IOS `ip name-server` |
| SNMP | 24 | `snmpwalk`, v2c/v3 | IOS SNMP config |
| Syslog | 25 | rsyslog severities/facilities | IOS `logging` |
| QoS concepts | 21, 30 | concept (DSCP/queues) | IOS QoS policy |

## Domain 5 — Security Fundamentals (15%)

| CCNA topic | Lesson | Linux-first coverage | IOS gap to close |
|---|---|---|---|
| Threats/vulnerabilities, defense concepts | 28 | recon/scan/MITM, ATT&CK | — |
| ACLs | 15 | nftables/iptables rules | IOS `access-list` |
| L2 security (port security, DAI, DHCP snooping) | 09, 12 | concept + Linux analogs | IOS L2 security config |
| AAA, 802.1X concepts | 28 | concept | ISE/RADIUS hands-on |
| VPN (site-to-site/remote) | 29 | WireGuard/IPsec hands-on | IOS IPsec |
| Wireless security (WPA2/3) | 32 | concept | — |

## Domain 6 — Automation & Programmability (10%)

| CCNA topic | Lesson | Linux-first coverage | IOS gap to close |
|---|---|---|---|
| Automation impact, controller vs traditional | 32 | SDN/overlay concepts | — |
| REST APIs, data formats (JSON/YAML) | 22, 33 | Prometheus/AWS APIs, `curl`+`jq` | NETCONF/RESTCONF |
| Config mgmt (Ansible/Puppet/Chef) concepts | — (NaviOps L13) | Ansible via sibling repo | network-device playbooks |
| Bash scripting (cross-cutting) | all | every `/scripts` artifact | — |

## How to use this matrix before the exam
1. Work the lessons Linux-first (builds durable, operational understanding).
2. For each "IOS gap to close" cell, do the equivalent in **Packet Tracer / GNS3 / CML** —
   the concept is already understood, so it's syntax mapping, not new theory.
3. The **CCNA capstone (Lesson 34)** is the integration check: design + build + verify a
   multi-VLAN routed network and confirm each domain's commands.
