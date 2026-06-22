# Lesson 32 — Cloud Networking

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** overlay/underlay, SDN concepts, the cloud VPC model, security groups vs NACLs, hybrid connectivity.
**Primary artifact:** `docs/networking/cloud-networking.md`.

> **How to use this lesson:** this is the *concepts* bridge from physical networking to the cloud;
> Lesson 33 is the AWS hands-on. Read §1–§7, write the concept map in §8. No spend (concepts +
> redacted notes only).

---

## §1 — Concept (Scientific Theory)

### What it is
**Cloud networking** is networking implemented in software over a provider's shared physical
infrastructure. The same fundamentals (subnets, routing, firewalls, NAT, load balancing — Lessons
04–31) apply, but they're **software-defined**: you *declare* a virtual network and the provider
realizes it on shared hardware via **SDN** (Software-Defined Networking) and **overlays**. Core
ideas: **overlay vs underlay**, **SDN** (separating the control plane from the data plane), the
**VPC model** (your private virtual network in the cloud), and **hybrid connectivity** (linking
on-prem to cloud).

### Why it exists
Physical networking doesn't scale to multi-tenant cloud (you can't run a cable per customer). SDN +
overlays let providers give each tenant an isolated, programmable virtual network on shared physical
gear, provisioned in seconds via API/IaC. Understanding it is essential as networks move to the
cloud — and it's where NetOps meets DevOps (Stage 6).

### The key concepts
- **Underlay:** the physical network (the provider's actual switches/routers/cables).
- **Overlay:** virtual networks tunneled *over* the underlay (e.g. **VXLAN** encapsulates L2 in
  UDP) — your VPC is an overlay; the provider's data center is the underlay.
- **SDN:** a centralized **control plane** programs the **data plane** (forwarding) via API — so a
  network change is an API call, not a device login. The cloud is SDN at massive scale.
- **VPC model:** a logically isolated virtual network you define (CIDR block → subnets → route
  tables → gateways), reusing all the addressing/routing/subnetting you learned (Lessons 04–07).
- **Security groups vs NACLs:** the cloud firewall model — **security groups** are *stateful*,
  instance-level (Lesson 15 stateful); **NACLs** are *stateless*, subnet-level (Lesson 15
  stateless) — both apply.
- **Hybrid connectivity:** VPN (Lesson 29) or dedicated links (Direct Connect) bridging on-prem ↔
  cloud.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** cloud networking is building your network with software instead of
  cables — you describe the network you want and the provider creates it instantly on their
  hardware.
- **Level 2 — NetOps/NOC:** you design a VPC (CIDR, public/private subnets, route tables,
  gateways), apply the cloud firewall model (stateful SGs + stateless NACLs), and connect hybrid
  (VPN/Direct Connect). You troubleshoot cloud connectivity with the *same* mental model
  (subnet/route/firewall) but cloud tools (flow logs, route tables, SG/NACL rules). It's networking
  fundamentals expressed as API/IaC.
- **Level 3 — Wire/Kernel (Lens D):** overlays like **VXLAN** wrap an inner L2 frame in
  UDP/IP for transport across the underlay (VNI = a 24-bit segment ID, like a VLAN at cloud scale —
  Lesson 09). SDN controllers program forwarding via protocols (OpenFlow/proprietary). On the host
  side it's the same Linux primitives you know (Lesson 17): virtual interfaces, bridges, namespaces,
  iptables/eBPF — the cloud is "Linux networking, orchestrated."

### Two Teaching Approaches (Lens B) — overlay/underlay + SDN

**Approach 1 (technical):** the provider runs a physical **underlay** network; tenant networks are
**overlays** — virtual L2/L3 segments encapsulated (e.g. VXLAN over UDP) and tunneled across the
underlay, isolated by segment IDs. A centralized **SDN control plane** programs the forwarding
state on demand via API, so creating a subnet/route/firewall-rule is a declarative API/IaC
operation, not device CLI. Your VPC is a software construct realized on shared hardware.

**Approach 2 (analogy):** cloud networking is a **co-working building vs owning an office**.
- **Underlay** = the actual building (physical floors, wiring, power) the provider owns.
- **Overlay** = your company's *suite* within it — walls, locks, and a directory that make it feel
  private, even though you share the building's plumbing with other tenants (multi-tenancy).
- **SDN** = the building-management app: you reconfigure your suite (add a meeting room, change a
  lock) through software, instantly, instead of calling a contractor (logging into a device).
- **Security groups vs NACLs** = a *stateful* badge reader on each office door (remembers you're
  inside, lets you back from the kitchen) vs a *stateless* guard at the floor entrance who checks
  *every* pass *every* time (subnet boundary).
- **Where it breaks down:** a building suite is physically bounded; an overlay is logically bounded
  by encapsulation + crypto, so **misconfiguration (an open security group) can expose you globally**
  in a way a locked office door can't — the cloud's "one wrong rule = Internet-exposed" risk the
  building analogy understates.

### Visual (ASCII) — VPC overlay on the provider underlay

```
   YOUR VPC (overlay, you define it)        PROVIDER UNDERLAY (physical, shared)
   10.0.0.0/16                              ┌──────────────────────────────┐
   ├─ public subnet 10.0.1.0/24  ── IGW ──► │  real switches/routers/hosts │
   │   (SG: stateful, instance)             │  VXLAN encapsulation tunnels │
   ├─ private subnet 10.0.2.0/24 ── NAT GW  │  your overlay over their gear│
   │   (NACL: stateless, subnet)            └──────────────────────────────┘
   route tables decide subnet egress (IGW vs NAT GW) — same routing logic as Lesson 07
   hybrid: VPN/Direct Connect ─► on-prem 192.168.0.0/16
```

---

## §2 — Linux Networking Commands (the cloud is Linux networking, orchestrated)

```bash
# The cloud uses the SAME Linux primitives you know (Lesson 17):
ip -br addr ; ip route ; bridge link        # a cloud instance's networking is still iproute2
ip route get <dest>                          # routing decisions still apply
# Overlay inspection (where you control it / in labs):
ip -d link show vxlan0                        # a VXLAN interface (overlay encapsulation)
bridge fdb show dev vxlan0                     # overlay forwarding table
# Provider side is API/CLI (Lesson 33 for AWS specifics):
# aws ec2 describe-route-tables / describe-security-groups / describe-flow-logs ...
# Troubleshooting still uses your toolkit from INSIDE an instance:
ping / traceroute / dig / nc -vz / curl -v / ss   # bottom-up method (Lesson 18) applies
```

**Cisco/CCNA mapping:** CCNA's Automation & Programmability domain covers SDN, controller-based vs
traditional networking, and cloud concepts; this lesson is that domain made concrete. The
fundamentals (subnet/route/firewall) are identical — only the control interface (API/IaC) changes.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Designing a VPC:** CIDR + public/private subnets + route tables + gateways for a cloud app —
   subnetting (Lesson 04) and routing (Lesson 07) applied via API/IaC.
2. **Cloud firewalling:** stateful security groups (per-instance) + stateless NACLs (per-subnet) —
   the cloud expression of Lesson 15.
3. **Hybrid connectivity:** VPN/Direct Connect linking on-prem to the VPC (Lesson 29) for a hybrid
   network.
4. **Troubleshooting "can't reach the instance":** the same bottom-up method, but the "firewall" is
   a security group/NACL and the "route" is a route-table entry — and **flow logs** are the capture.

**How NOC/NetOps engineers use it:** increasingly, the "network" is a cloud VPC; the NOC reads flow
logs, checks SG/NACL/route-table config, and applies the same fundamentals. This is the NetOps→
Cloud/DevOps bridge (Stage 6).

**When NOT to:** don't assume cloud "magic" — it's the same fundamentals (a missing route or a
closed SG breaks things exactly like on-prem); don't expose resources via overly-broad security
groups (the #1 cloud breach cause, §12).

**Exam framing (Net+/CCNA):** cloud models, VPC concepts, SDN, overlay/underlay, and security
groups/NACLs appear in both exams' cloud/automation domains.

---

## §4 — Troubleshooting Section (cloud, same fundamentals)

| Symptom | Cloud cause | Diagnose | Fix |
|---|---|---|---|
| Instance unreachable from Internet | no public IP / IGW route / SG blocks | route table + SG + public IP | add route/IP, open SG |
| Private instance no Internet (outbound) | no NAT gateway / route | route table (NAT GW?) | add NAT GW + route (Lesson 14) |
| Two subnets can't talk | route table / NACL | check route tables + NACLs | fix route/NACL |
| Connects sometimes, not others | stateless NACL missing return rule | NACL rules (both directions) | add return-traffic NACL rule |
| "Firewall" blocks it | SG (stateful) vs NACL (stateless) | check both | fix the right one |

**Redaction check:** **never commit real account IDs/VPC IDs/public IPs** — `<ACCOUNT_ID>`,
`<VPC_ID>`, RFC-1918/5737 only (this is the cloud analog of NaviOps' AWS rule).

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Thinking cloud networking is "different magic" | confused troubleshooting | it's the same fundamentals via API |
| Confusing SG (stateful) with NACL (stateless) | wrong fix; missing return rules | SG=stateful/instance, NACL=stateless/subnet |
| Overly-broad security groups (0.0.0.0/0) | Internet-exposed resources (breach) | least-privilege SGs |
| Forgetting the NAT gateway for private subnets | no outbound | add NAT GW + route (Lesson 14) |
| Committing real account/VPC/IPs | leak | redact everything |
| Ignoring flow logs | blind to cloud traffic | enable + read flow logs |

---

## §6 — NOC Perspective

> Network Operations → Cloud/DevOps (Stages 2, 6, `ROADMAP.md`).

As workloads move to the cloud, the NOC monitors VPCs the way it monitored physical networks —
availability/latency to cloud endpoints, plus cloud-native signals (flow logs, SG/NACL changes,
route-table changes). The mental model is unchanged: an alert about a cloud resource is triaged with
subnet/route/firewall reasoning, just with cloud tools. A change to a security group or route table
is a high-impact **change** (`noc/ticketing.md`) — "what changed in the SG/route table?" is the cloud
version of "what changed in the firewall?"

---

## §7 — Incident-Response Perspective

- **Detect:** a cloud resource unreachable, or a security alert (an exposed SG, anomalous flow-log
  traffic).
- **Triage/Diagnose:** the *same* bottom-up method (Lesson 18) — public IP? route table? SG?
  NACL? — using cloud tools (flow logs = the capture, Lesson 20 analog).
- **Contain/Fix → Recover → Document:** tighten the SG/NACL/route, verify, document. **Exposed
  security groups** are a top cloud security-IR scenario (Lesson 28/§12).

---

## §8 — Practical Lab (build this yourself)

**Goal:** write `docs/networking/cloud-networking.md` — a concept map translating physical
networking to cloud — and (optionally, free-tier-aware) build the overlay concept locally with
VXLAN. **No spend without explicit approval** (`navi.project.md` danger zone).

### Lens C — Manual → Automated → Why
- **Manual:** a concept map (physical → cloud equivalents).
- **Automated:** cloud networking *is* automation — note how the whole VPC is declared as IaC
  (Terraform/CloudFormation), reproducible and version-controlled (ties to the sibling NaviOps IaC
  track).
- **Why:** the cloud's power is that the entire network is code — reproducible, reviewable,
  destroyable; understanding it as "fundamentals + automation" is the NetOps→DevOps leap.

### Steps
1. Write `docs/networking/cloud-networking.md`: a translation table (on-prem ↔ cloud) — subnet ↔
   VPC subnet, router/route ↔ route table, firewall ↔ SG/NACL, NAT router ↔ NAT gateway, gateway ↔
   IGW, VLAN ↔ VXLAN/VNI, VPN ↔ VPN gateway/Direct Connect — with a 1-line note on each.
2. Explain overlay/underlay + SDN + the SG-vs-NACL (stateful vs stateless) distinction in your own
   words, with the §1 ASCII diagram.
3. **Optional local overlay lab:** build a **VXLAN** interface between two Linux hosts/namespaces
   (`ip link add vxlan0 type vxlan id 100 ...`) to *experience* an overlay encapsulating L2 over
   UDP — the cloud's core mechanism, hands-on, for free.
4. **Drill:** reason through "instance unreachable" using the §4 table (route table → SG → NACL) —
   practice the cloud bottom-up method.

### Lens D — VXLAN encapsulation
If you build the VXLAN lab, `tcpdump -nni <underlay-if> udp port 4789` shows the **outer UDP**
carrying your **inner L2 frame** — overlay-over-underlay made visible (the cloud's VLAN-at-scale).

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script/doc:** (optional) the VXLAN overlay lab script + the concept map.
2. **Config/doc:** `docs/networking/cloud-networking.md` (the on-prem↔cloud translation map).
3. **Drill:** the cloud bottom-up reasoning applied (or the VXLAN overlay built).
4. **NAVI ticket:** `NAVI-32` (Task: "cloud networking concept map + overlay lab").
5. **Incident report:** *(optional)* — an "instance unreachable" reasoning runbook.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Mapped physical networking fundamentals to the cloud VPC model (overlay/
  underlay, SDN, security groups vs NACLs) and demonstrated overlay encapsulation with VXLAN on
  Linux."
- **Interview talking point:** "cloud networking is the same fundamentals via API" — explain
  overlay/underlay, SDN, and stateful-SG-vs-stateless-NACL; the bridge from NetOps to DevOps.
- **Serves:** Cloud/DevOps networking (Stage 6) + Network Operations; sets up AWS (Lesson 33).

---

## §11 — RHCSA Crossover Notes

RHCSA-adjacent: cloud instances are usually Linux (RHEL family), so RHCSA networking (`nmcli`,
firewalld, `ip`/`ss`) applies *inside* the instance; and the VXLAN/overlay primitives are Linux
networking (Lesson 17). The IaC angle ties to the sibling NaviOps Terraform track.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** the #1 cloud breach pattern is **misconfigured access** — an overly-broad
**security group** (`0.0.0.0/0` to a database/SSH) or a public resource exposing internal services
(`T1190` Exploit Public-Facing Application, `T1530` Data from Cloud Storage). Attackers scan cloud
ranges for these instantly. Leaked **flow-log/topology** or credentials accelerate it.

**🔵 Defender:** **least-privilege security groups** (no broad `0.0.0.0/0` to sensitive ports),
**private subnets** for backends (no public IP; outbound via NAT GW), **enable + monitor flow
logs** (the cloud capture, feed to SIEM — Lesson 28), and treat SG/route-table changes as audited
changes. The same segmentation/least-privilege principles (Lessons 04/09/15) apply. Verify no SG
exposes a sensitive port to the world (audit, lab/your own account).

---

## Quiz (Interview-Style, Graded)

**Q1.** Explain overlay vs underlay, and give the cloud example (e.g. VXLAN).
> **Your answer:**

**Q2.** What is SDN, and how does it change how you make a network change?
> **Your answer:**

**Q3.** Security groups vs NACLs — stateful vs stateless, instance vs subnet — and a consequence of
the difference.
> **Your answer:**

**Q4.** **Scenario:** A new cloud instance in a private subnet can't reach the Internet for updates.
Walk through what's likely missing (think Lesson 14/07).
> **Your answer:**

**Q5.** How does the bottom-up troubleshooting method (Lesson 18) apply to cloud networking?
> **Your answer:**

**Q6.** What's the #1 cloud-networking security mistake, and how do you prevent it?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 33.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `overlay vs underlay network`
- `software defined networking sdn`
- `cloud vpc model explained`
- `security groups vs nacl`
- `vxlan encapsulation`

**Tools**
- `linux vxlan interface`
- `vpc subnet route table`
- `cloud flow logs`

**Going further (future lessons)**
- `aws vpc networking` (L33) · `terraform vpc iac` · `hybrid cloud vpn direct connect`

**Red / Blue (Lens E):**
- 🔴 `misconfigured security group breach T1190`, `public cloud storage T1530`, `cloud range scanning`
- 🔵 `least privilege security groups`, `private subnet nat gateway`, `vpc flow logs monitoring`

---

## Lesson Status
- [ ] §8 lab completed (concept map + optional VXLAN overlay)
- [ ] §4 drill done (cloud bottom-up reasoning)
- [ ] Evidence committed (§9 — redacted)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 33 — AWS Networking**.

---

*Lesson 32 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: AWS VPC docs,
RFC 7348 (VXLAN), CompTIA Network+ N10-009 (cloud), CCNA Automation domain, MITRE ATT&CK T1190.*
