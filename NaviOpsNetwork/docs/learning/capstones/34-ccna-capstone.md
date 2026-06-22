# Capstone 34 — CCNA Capstone (Design · Build · Verify a Routed/Switched Network)

**Proves:** you can take requirements → a network design → a built+verified topology with
services, the way a Junior Network Engineer is expected to.
**Prereqs:** Lessons 01–16 (foundations, routing, switching, VLANs, STP, services).
**Tooling:** Linux network namespaces / Linux bridges + VLANs (built-in, free) for the
Linux-first build; **Packet Tracer / GNS3 / CML** for the Cisco-IOS mapping. Lab ranges only.

## Scenario (requirements)

Design and build a small multi-segment network for a fictional 3-department office:

| Segment | Purpose | Subnet | VLAN |
|---|---|---|---|
| Servers | DNS/DHCP/web | `10.10.10.0/24` | 10 |
| Staff | workstations | `10.10.20.0/24` | 20 |
| Guest | isolated internet-only | `10.10.30.0/24` | 30 |
| Mgmt | device management | `10.10.99.0/24` | 99 |
| P2P uplink | router↔WAN | `10.10.255.0/30` | — |

Requirements: inter-VLAN routing for Servers↔Staff; Guest isolated from internal VLANs;
DHCP for Staff+Guest; DNS for all; a default route to the (simulated) WAN; STP loop-free;
one redundant link (EtherChannel/bonding).

## Deliverables (the artifacts)

1. **Design doc** — `docs/diagrams/ccna-capstone-topology.md`: ASCII topology, IP/VLAN plan
   (VLSM-justified), routing plan, and the security policy (Guest isolation).
2. **Built topology** — `infra/topologies/ccna-capstone/` (netns/bridge build script **and**
   the Packet Tracer/GNS3 file or its config exports, redacted).
3. **Service configs** — `infra/configs/`: dnsmasq (DHCP+DNS), nftables (inter-VLAN policy +
   Guest isolation + NAT to WAN).
4. **Verification report** — `docs/runbooks/ccna-capstone-verification.md`: every requirement
   tested with the command + output (subnet membership, inter-VLAN reachability, Guest
   isolation proof, DHCP lease, DNS resolution, route table, STP state, bond/EtherChannel up).
5. **PORTFOLIO.md** — resume bullets + interview talking points + the design *why*.

## Phases

| Phase | Work | Verify |
|---|---|---|
| 1 — Design | IP/VLAN/routing/security plan on paper | peer/self review vs requirements |
| 2 — L2 | VLANs, trunk, access ports, STP, EtherChannel/bond | `bridge vlan show`, intra-VLAN ping, bond `up` |
| 3 — L3 | inter-VLAN routing, default route, SVIs/subinterfaces | `ip route`, inter-VLAN ping, `ip route get` |
| 4 — Services | DHCP scopes, DNS zones | client gets lease in-range; `dig` resolves |
| 5 — Security | Guest isolation, NAT to WAN, default-deny | Guest→Staff blocked; Guest→WAN works; `nft` counters |
| 6 — Verify+doc | run the full verification report; map each step to CCNA domain | all requirements pass |

## CCNA domain coverage (self-check)
Network Fundamentals (subnetting, addressing) · Network Access (VLAN/trunk/STP/EtherChannel) ·
IP Connectivity (static + default routing, inter-VLAN) · IP Services (DHCP/DNS/NAT) · Security
Fundamentals (ACL/isolation). Use `alignment/CCNA-ALIGNMENT.md` to close any IOS-syntax gaps in
Packet Tracer/GNS3 before sitting the exam.

## Done when
Every requirement in the verification report passes with captured output, the topology rebuilds
from the script, and `PORTFOLIO.md` is written. Open `NAVI-34` (Change) and link the closing commit.
