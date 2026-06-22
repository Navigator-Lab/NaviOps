# Lesson 14 — NAT / PAT

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** SNAT/DNAT/PAT, conntrack, port forwarding, hairpin, nftables NAT, CGNAT concepts.
**Primary artifact:** `infra/configs/nat-nftables.nft`.
**Difficulty:** **Difficult concept** — §1 uses two teaching approaches + an ASCII diagram (Lens B).

> **How to use this lesson:** NAT is how private networks reach the Internet and how you publish
> services. Read §1–§7, build NAT + a port-forward with nftables in §8. Lab/RFC-1918 only.

---

## §1 — Concept (Scientific Theory)

### What it is
**NAT** (Network Address Translation, RFC 3022) rewrites IP addresses (and with **PAT**, ports)
in packet headers as they cross a router/firewall. The dominant form is **PAT** (Port Address
Translation, aka **NAT overload** / masquerade): many private hosts share **one** public IP, kept
distinct by **source port** + a translation table. **DNAT** (destination NAT / port forwarding)
does the reverse — directs inbound traffic on a public IP:port to an internal host.

### Why it exists
IPv4 addresses are scarce (Lesson 04). NAT/PAT lets an entire private network (`10.0.0.0/8`,
Lesson 05) share a handful of public IPs — the single biggest reason IPv4 survived past
exhaustion. It also adds a (weak) layer of obscurity: internal hosts aren't directly addressable
from outside without an explicit port-forward.

### NAT flavors
| Type | Rewrites | Use |
|---|---|---|
| **SNAT** (source NAT) | source IP (→ a fixed public IP) | static one-to-one outbound mapping |
| **PAT / masquerade** | source IP **+ source port** | many private hosts → one public IP (home/office) |
| **DNAT** (port forward) | destination IP:port | publish an internal service on a public IP:port |
| **Static NAT** | 1:1 IP mapping both ways | a server with a dedicated public IP |
| **CGNAT** | carrier-grade PAT (two NAT layers) | ISPs sharing scarce IPv4 among customers |

### How the return path works (the key insight)
NAT must remember translations so **replies** find their way back. The router keeps a
**connection-tracking (conntrack) table**: `(internal IP:port) ↔ (public IP:port, remote
IP:port)`. Outbound, it rewrites source and records the mapping; the reply (to the public
IP:port) is matched in the table and rewritten back to the original internal host. **Stateful**
by necessity.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** your home router makes all your devices look like *one* device to the
  Internet (one public IP), and remembers who asked for what so the answers come back to the
  right device.
- **Level 2 — NetOps/NOC:** you configure masquerade/SNAT for outbound and DNAT/port-forward for
  published services; you troubleshoot "service published but unreachable" (DNAT rule wrong/order)
  and "internal host can't reach the internet" (missing masquerade or `ip_forward=0`). You read
  the **conntrack** table to see live translations. **Hairpin NAT** (a known gotcha) is when an
  internal host tries to reach an internal server via its *public* IP — needs extra rules.
- **Level 3 — Wire/Kernel (Lens D):** on Linux, NAT is **netfilter** + **nftables/iptables** in
  the `nat` table (`prerouting` for DNAT, `postrouting` for SNAT/masquerade) backed by the
  **conntrack** subsystem (`/proc/net/nf_conntrack`, `conntrack -L`). The kernel rewrites headers
  and recalculates checksums per packet, keyed by the conntrack tuple. Masquerade picks the
  outbound interface's current IP automatically (good for dynamic WAN IPs).

### Two Teaching Approaches (Lens B) — PAT & the return path

**Approach 1 (technical):** outbound, PAT rewrites the packet's source IP to the public IP and the
source port to a unique value, recording `(orig src IP:port → public IP:newport, dst)` in
conntrack. The remote server replies to `public IP:newport`; the NAT device looks up that tuple,
rewrites the destination back to `orig src IP:port`, and forwards it internally. Many hosts
coexist on one public IP because each active flow gets a unique public source port.

**Approach 2 (analogy):** a company with one phone number and a switchboard operator.
- 500 employees (private hosts) share **one external number** (public IP). When Alice calls out,
  the **operator** (NAT) places the call from the company number and writes in a ledger "extension
  204 is on line 7" (the source-port mapping).
- When the callee calls back to the company number on line 7, the operator checks the ledger and
  transfers it to **extension 204** — the reply reaches the right person.
- **DNAT/port forward** = a published direct-dial ("dial the company number, press 80, reach the
  web server in the basement").
- **Where it breaks down:** the analogy of one operator implies a bottleneck; real NAT is
  per-packet at line rate, and **CGNAT** is like *two* switchboards stacked (ISP + your router),
  which is why some apps that need inbound connections (gaming, P2P) struggle behind CGNAT.

### Visual (ASCII) — PAT outbound + conntrack

```
  PRIVATE                         NAT ROUTER (public 203.0.113.5)        INTERNET
  10.0.0.10:51000 ──► [SNAT/PAT] ──► 203.0.113.5:40001 ───────────────► server:443
  10.0.0.11:51000 ──► [SNAT/PAT] ──► 203.0.113.5:40002 ───────────────► server:443
                          conntrack table:
                          10.0.0.10:51000 ↔ 203.0.113.5:40001 ↔ server:443
                          10.0.0.11:51000 ↔ 203.0.113.5:40002 ↔ server:443
  reply to 203.0.113.5:40002 ──► looked up ──► rewritten to 10.0.0.11:51000 ✔
```

---

## §2 — Linux Networking Commands

```bash
# Enable forwarding (the host must route)
sysctl -w net.ipv4.ip_forward=1

# Masquerade (PAT) all outbound from the LAN out the WAN interface (nftables):
nft add table ip nat
nft 'add chain ip nat postrouting { type nat hook postrouting priority 100 ; }'
nft add rule ip nat postrouting oifname "eth0" ip saddr 10.0.0.0/24 masquerade

# Port forward (DNAT): public :8080 -> internal web server 10.0.0.20:80
nft 'add chain ip nat prerouting { type nat hook prerouting priority -100 ; }'
nft add rule ip nat prerouting iifname "eth0" tcp dport 8080 dnat to 10.0.0.20:80

# Inspect translations
conntrack -L                       # live connection-tracking table (translations)
cat /proc/net/nf_conntrack
nft list table ip nat              # show the NAT ruleset
```

**Cisco/CCNA mapping:** `ip nat inside source list 1 interface g0/0 overload` (PAT),
`ip nat inside source static tcp 10.0.0.20 80 interface g0/0 8080` (port forward),
`show ip nat translations`. CCNA tests static NAT, dynamic NAT, PAT, and inside/outside.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Internet access for a private LAN:** masquerade/PAT on the edge router — the default for
   nearly every office/home network.
2. **Publishing a service:** DNAT a public IP:port to an internal web/app server (often paired
   with a firewall + load balancer, Lessons 15/30).
3. **Cloud:** an AWS **NAT Gateway** lets private-subnet instances reach the Internet outbound
   without public IPs (Lesson 33) — same concept, managed service.
4. **CGNAT awareness:** when troubleshooting "inbound doesn't work from home," the customer may be
   behind ISP CGNAT (no real public IP).

**How NOC engineers use it:** diagnosing "internal host can't reach internet" (masquerade/forward)
vs "published service unreachable" (DNAT rule/order), and reading conntrack during incidents.

**When NOT to:** don't NAT where you need true end-to-end addressing (some VPNs, IPv6 — which
largely eliminates NAT); avoid overlapping NAT rules that fight each other.

**Exam framing (Net+/CCNA):** SNAT/DNAT/PAT/static, inside vs outside, port forwarding, and "why
NAT exists" are guaranteed.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Internal hosts no internet | missing masquerade / `ip_forward=0` | `sysctl ip_forward`; `nft list table ip nat` | enable forwarding + masquerade |
| Published service unreachable | DNAT rule wrong/missing/order | `nft list ruleset`; `conntrack -L` | fix DNAT + allow in firewall (L15) |
| Works out, replies lost | conntrack/asymmetric path | `conntrack -L`; check return routing | fix routing/state |
| Internal can't reach own server via public IP | hairpin NAT not configured | test from inside vs outside | add hairpin/loopback NAT |
| Inbound from home fails | ISP CGNAT (no public IP) | check WAN IP is private/CGN range | use VPN / IPv6 / provider option |

**Redaction check:** RFC 5737 (`203.0.113.x`) for "public" IPs in committed configs; never real.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Forgetting `ip_forward=1` | NAT silently doesn't route | enable forwarding |
| DNAT without a matching firewall allow | port-forward still blocked | allow the forwarded port (L15) |
| Wrong chain/priority (pre vs post routing) | rule never matches | DNAT=prerouting, SNAT=postrouting |
| Assuming NAT = security | over-reliance | NAT obscures, doesn't filter; use a firewall |
| Hairpin not handled | internal→public-IP access fails | add hairpin NAT |
| Ignoring conntrack limits | table exhaustion under load (DoS) | size `nf_conntrack_max` |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

NAT issues split cleanly: **outbound** ("nothing on this subnet reaches the internet" — broad,
masquerade/forwarding/edge) vs **inbound** ("this one published service is down" — DNAT/firewall,
narrower). That split sets scope/severity. Conntrack-table **exhaustion** under load (or a
flood/DoS) is a subtle incident — the firewall stops accepting new connections though CPU looks
fine; reading `conntrack -L` count vs `nf_conntrack_max` reveals it. Worth a monitoring metric.

---

## §7 — Incident-Response Perspective

- **Detect:** outbound internet down for a subnet, or a published service unreachable.
- **Triage:** outbound (broad) vs inbound (one service); scope → Sev.
- **Diagnose (RCA):** masquerade/forwarding missing (outbound) / DNAT+firewall (inbound) /
  conntrack exhaustion (under load). `nft list ruleset` + `conntrack -L`.
- **Fix → Recover → Document:** correct the rule (and the firewall allow), verify with a real
  flow + `conntrack -L`, document. Related to **drill 8 (firewall/NAT)**.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build PAT (outbound) + a DNAT port-forward (inbound) with nftables; produce
`infra/configs/nat-nftables.nft`.

### Lens C — Manual → Automated → Why
- **Manual:** write the nat table rules, test outbound + the forward, read conntrack.
- **Automated:** a loadable `.nft` ruleset (idempotent, version-controlled) + a verifier that
  checks forwarding is on, the masquerade rule exists, and the forward works.
- **Why:** firewall/NAT rules are change-managed, high-impact, and easy to get wrong; a
  version-controlled ruleset + a verify step is exactly how production teams ship NAT changes
  safely (and roll back).

### Steps (router VM/namespace between a private LAN and a "WAN")
1. Enable `ip_forward`; write `infra/configs/nat-nftables.nft` with: a `nat postrouting`
   masquerade for `10.0.0.0/24` out the WAN iface, and a `nat prerouting` DNAT for
   `tcp dport 8080 → 10.0.0.20:80`.
2. `nft -f infra/configs/nat-nftables.nft`; from a private host, reach the "WAN" → confirm the
   source is translated (`conntrack -L`). From the WAN side, hit `WAN-IP:8080` → reaches the
   internal web server.
3. **Drill 8 variant:** remove the masquerade rule → internal hosts lose internet → diagnose
   (`nft list ruleset`, `conntrack -L`) → restore.
4. Read `conntrack -L` to see the live translations and map them back to your hosts.

### Lens D — watch the rewrite
`tcpdump` on the WAN interface shows the translated source IP/port; on the LAN interface it shows
the original — the same flow, rewritten by netfilter between them.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** a NAT verifier (forwarding on? masquerade present? forward works?).
2. **Config:** `infra/configs/nat-nftables.nft` (masquerade + DNAT, loadable).
3. **Drill:** drill 8 variant (NAT/forward removed → outage → fix).
4. **NAVI ticket:** `NAVI-14` (Change: "add port-forward for web service" + Incident for the drill).
5. **Incident report:** `docs/runbooks/incident-nat.md` (symptom→conntrack/ruleset→fix→verify).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Implemented PAT and DNAT port-forwarding with nftables, validated via
  conntrack; documented a NAT-outage RCA and a version-controlled, rollback-able ruleset."
- **Interview talking point:** explain PAT's return-path via conntrack, SNAT vs DNAT, and why
  NAT isn't a firewall.
- **Serves:** Network Operations / Jr Network Engineer (Stages 2, 4); core to firewalls (15) + AWS (33).

---

## §11 — RHCSA Crossover Notes

RHCSA-relevant: `firewalld` **masquerade** (`firewall-cmd --add-masquerade`) and **port
forwarding** (`firewall-cmd --add-forward-port=...`) are direct RHCSA objectives — the same NAT
concepts via firewalld instead of raw nftables. Enabling `ip_forward` for a RHEL gateway is
exam-adjacent.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** NAT is **not** a security control — a careless **DNAT/port-forward** exposes an
internal service directly to the Internet (`T1133` External Remote Services; misused forwards are
a top breach vector). Conntrack-table **exhaustion** is a DoS vector. Attackers also abuse
**outbound NAT** for exfil/C2 since outbound is usually unrestricted (`T1071`).

**🔵 Defender:** put a **stateful firewall + default-deny** in front of every port-forward (Lesson
15), expose the minimum (consider a reverse proxy/bastion instead of raw DNAT), **rate-limit new
connections** and size `nf_conntrack_max`, and **filter/inspect outbound** (egress filtering) so
NAT isn't a free exfil path. Verify exposed ports with `nmap` from "outside" (lab-only).

---

## Quiz (Interview-Style, Graded)

**Q1.** Why does NAT exist, and how does PAT let many hosts share one public IP?
> **Your answer:**

**Q2.** Distinguish SNAT, DNAT, and PAT, with a use case for each.
> **Your answer:**

**Q3.** How does the NAT device get replies back to the correct internal host? What table makes
this possible?
> **Your answer:**

**Q4.** **Scenario:** You add a port-forward for an internal web server but it's still unreachable
from outside. What two things must both be correct, and how do you check?
> **Your answer:**

**Q5.** Why is "NAT = security" a dangerous assumption?
> **Your answer:**

**Q6.** What is CGNAT, and why might it break inbound connections for a home user?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 15.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `nat pat explained snat dnat`
- `nat overload port address translation`
- `conntrack connection tracking linux`
- `cgnat carrier grade nat`

**Tools**
- `nftables nat masquerade dnat`
- `conntrack -L command`
- `firewalld masquerade port forward`

**Going further (future lessons)**
- `stateful firewall` (L15) · `aws nat gateway vpc` (L33) · `reverse proxy` (L16/L30)

**Red / Blue (Lens E):**
- 🔴 `exposed port forward attack T1133`, `conntrack exhaustion dos`, `outbound nat exfil T1071`
- 🔵 `firewall in front of dnat`, `egress filtering`, `nf_conntrack_max tuning`

---

## Lesson Status
- [ ] §8 lab completed (PAT + DNAT with nftables)
- [ ] §4 drill done (drill 8 variant — NAT removed)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 15 — Firewalls & Packet Filtering**.

---

*Lesson 14 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: RFC 3022,
nftables wiki, netfilter conntrack docs, CompTIA Network+ N10-009, MITRE ATT&CK T1133/T1071.*
