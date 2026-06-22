# Lesson 07 — Routing Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-22
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the routing table, longest-prefix match, static vs dynamic routing, the default route,
RIP/OSPF/EIGRP/**BGP** concepts, administrative distance, and `ip route`.
**Primary artifact:** `scripts/route_audit.sh` + a topology in `infra/topologies/`.

> **How to use this lesson:** opens Module 2 (Routing & Switching). Switching (Lesson 08) moves frames
> *within* a network; routing moves packets *between* networks. Read §1, then build `route_audit.sh`
> and a small topology in §8.

---

## §1 — Concept (Scientific Theory)

### What it is
**Routing** is how an L3 device (a router, or any Linux host) decides **where to send a packet whose
destination is on a different network.** It consults its **routing table** — a list of
`destination-network → next-hop/exit-interface` entries — and forwards toward the destination, hop by
hop.

### Longest-prefix match (the core rule)
When multiple routes could match a destination, the router picks the **most specific** one — the
**longest prefix** (largest `/NN`). A packet to `10.0.5.7` matches `10.0.5.0/24` over `10.0.0.0/16`
over `0.0.0.0/0`. The **default route** `0.0.0.0/0` ("gateway of last resort") matches *everything*
but is the *least* specific, so it's used only when nothing better exists.

### Static vs dynamic routing
| | Static | Dynamic |
|---|---|---|
| How | admin configures each route | routers exchange routes via a protocol |
| Scales | small/stable networks | large/changing networks |
| Reacts to failure | no (manual) | yes (reconverges automatically) |
| Overhead | none | CPU/bandwidth for protocol traffic |
| Examples | `ip route add`, default route | OSPF, EIGRP, BGP, RIP |

### Dynamic routing protocols (know the concepts)
| Protocol | Type | Metric | Scope | Note |
|---|---|---|---|---|
| **RIP** | distance-vector | hop count (max 15) | small | legacy, simple, slow |
| **OSPF** | link-state | cost (bandwidth) | enterprise (IGP) | fast convergence, areas |
| **EIGRP** | advanced DV (hybrid) | composite (BW+delay) | Cisco (IGP) | Cisco-centric |
| **BGP** | path-vector | AS-path/policy | **the Internet** (EGP) | routes *between* organizations |

**IGP vs EGP:** IGPs (OSPF/EIGRP/RIP) route *inside* one organization; BGP routes *between*
autonomous systems — it's the protocol that holds the Internet together.

### Administrative distance (AD) — trust between sources
When two protocols offer a route to the same network, the router trusts the one with the **lower AD**:
Connected `0`, Static `1`, EIGRP `90`, OSPF `110`, RIP `120`, External BGP `20`, Internal BGP `200`.
AD picks the *source*; the *metric* picks the best path *within* that source.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** a router is a signpost — it reads a packet's destination and points it to
  the next road. The default route is "if you don't know, send it this way (toward the Internet)."
- **Level 2 — NetOps/NOC:** you read `ip route`, add/remove static routes, recognize a missing or
  wrong **default gateway**, and reason about why a packet took a path (longest-prefix + AD). You see
  `traceroute` as the route table in action, hop by hop.
- **Level 3 — Wire/Kernel (Lens D):** Linux has a **FIB** (forwarding information base) the kernel
  consults per packet via `ip route get`; it supports multiple tables + **policy routing** (`ip rule`)
  and ECMP (multipath). TTL decrements at each hop; TTL=0 → ICMP Time Exceeded (which is how
  `traceroute` works).

### Two Teaching Approaches (Lens B) — routing
**Technical:** each router makes an *independent*, *local* longest-prefix decision; the end-to-end
path emerges from many such hops, each trusting its own table.

**Analogy:** **postal sorting / GPS.** Each sorting office (router) doesn't know the whole route — it
just sends the parcel one hop closer based on the most specific destination it recognizes (city >
region > "international, send to the hub" = default route). *Where it breaks down:* the post office
has a global plan; routers only ever make local next-hop decisions, which is why loops and black-holes
are possible if tables disagree.

### Visual (ASCII) — longest-prefix match + default route
```
 Destination: 10.0.5.7
 Routing table (most specific wins):
   10.0.5.0/24   via 10.0.0.2  dev eth1   ◄── MATCH (longest prefix /24)
   10.0.0.0/16   via 10.0.0.3  dev eth1
   0.0.0.0/0     via 203.0.113.1 dev eth0   (default — used only if nothing else matches)
```

---

## §2 — Linux Networking Commands

```bash
ip route                         # the main routing table (FIB view)
ip route show default            # the default route / gateway of last resort
ip route get 10.0.5.7            # EXACTLY which route+nexthop the kernel uses for a dst
ip route add 10.0.5.0/24 via 10.0.0.2 dev eth1     # add a static route (lab)
ip route add default via 203.0.113.1               # set the default route
ip route del 10.0.5.0/24                            # remove a route
ip rule show ; ip route show table all             # policy routing + all tables (Lens D)
traceroute 1.1.1.1               # per-hop path (TTL trick) — routing table, live
mtr 1.1.1.1                      # traceroute + continuous loss/latency per hop
sysctl net.ipv4.ip_forward       # is this Linux box acting as a router? (1=yes)
```

**Cisco/CCNA mapping:** `show ip route` (the table + AD/metric in `[AD/metric]`), `ip route 10.0.5.0
255.255.255.0 10.0.0.2` (static), `ip route 0.0.0.0 0.0.0.0 203.0.113.1` (default),
`router ospf`/`router bgp` (dynamic). `traceroute` is identical.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Missing/wrong default route:** a host or router with no `0.0.0.0/0` reaches its LAN but not the
   Internet — extremely common, found instantly in `ip route`.
2. **Asymmetric routing:** traffic leaves one path and returns another — breaks stateful firewalls
   (Lesson 15). Diagnosed by comparing forward/return `traceroute`.
3. **Static routes for specific destinations:** a route to a partner network via a specific gateway,
   added without running a full dynamic protocol.
4. **Linux as a router/gateway:** enabling `ip_forward` + routes turns a server into a router
   (containers, VPN gateways, NAT boxes — Lesson 14).

**How NOC engineers use it:** "where does this packet go?" (`ip route get`) and "is the default route
present and correct?" are everyday triage. `traceroute`/`mtr` localize *which hop* is failing during
a path outage.

**When NOT to:** don't pile up static routes where the topology changes — that's what dynamic routing
is for; don't run a heavy IGP on a tiny stable network — a default route suffices.

**Exam framing (Net+/CCNA):** longest-prefix match, AD values, static vs dynamic, default route, and
the protocol comparison table are *guaranteed*.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| LAN works, Internet doesn't | missing/wrong default route | `ip route show default` | add/fix `0.0.0.0/0` |
| Some destinations unreachable | missing specific route | `ip route get <dst>` | add static / fix dynamic |
| Path fails at a hop | downstream router/link | `traceroute`, `mtr` | fix the failing hop |
| Return traffic lost | asymmetric routing | compare fwd/return traceroute | align routes / firewall |
| Routing loop (TTL exceeded) | conflicting/incorrect routes | `traceroute` shows repeats | correct tables |

**Diagnostic sequence:** `ip route` (table sane? default present?) → `ip route get <dst>` (chosen
next-hop) → `ping <next-hop>` → `traceroute <dst>` (which hop dies) → `mtr` (loss localization).
**Redaction check:** RFC 5737 (`203.0.113.0/24`) for any "public" gateway in committed examples.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| No default route | no Internet, LAN fine | add `0.0.0.0/0 via <gw>` |
| Two defaults / wrong metric | flapping, wrong egress | one correct default (or set metrics) |
| Expecting shortest-prefix to win | misread forwarding | **longest** prefix wins |
| Forgetting `ip_forward=1` on a Linux router | box won't route | `sysctl -w net.ipv4.ip_forward=1` |
| Ignoring AD when redistributing | wrong source chosen | lower AD wins; plan redistribution |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1; routing deepens toward NetOps Stage 2, `ROADMAP.md`).

Routing incidents are high-impact on a NOC: a **route flap** or a withdrawn prefix can blackhole a
whole site. Dashboards watch route counts, BGP/OSPF neighbor states, and reachability synthetics.
Normal = stable neighbor adjacencies + expected prefixes; abnormal = flapping adjacency, missing
default, or a `traceroute` that dies mid-path. The NOC's fast checks are "default route present?" and
"where does `traceroute` stop?" before escalating to NetOps.

---

## §7 — Incident-Response Perspective

- **Detect:** reachability synthetics fail; users report "some sites/down," monitoring shows a
  neighbor down or prefix withdrawn.
- **Triage:** one destination (specific route) vs all-Internet (default route) vs a whole region
  (upstream/BGP) — scope by what's unreachable.
- **Diagnose (RCA):** `ip route`/`ip route get` for the local decision; `traceroute`/`mtr` to find
  the failing hop; check neighbor adjacency state for dynamic protocols.
- **Fix → Recover → Document:** restore the route/adjacency, verify end-to-end + return path, and
  capture the topology + which route was wrong in the runbook (`docs/runbooks/`).

---

## §8 — Practical Lab (build this yourself)

**Goal:** build `scripts/route_audit.sh` (snapshot + sanity-check the routing table) and a small
`infra/topologies/routing-lab.md` topology you reason about.

### Lens C — Manual → Automated → Why
- **Manual:** read `ip route`, add a static route, set/verify the default, trace a path.
- **Automated:** `route_audit.sh` prints the table, flags **no default route**, resolves the next-hop
  for a target list (`ip route get`), and pings each next-hop — exit non-zero on any finding.
- **Why:** a one-command routing health check catches the #1 cause of "no Internet" (missing default)
  on any host or gateway during onboarding/incidents.

### Steps
1. Read your `ip route`; identify the default route and any specific routes. Run
   `ip route get 1.1.1.1` and `ip route get <a-LAN-host>` and explain each decision.
2. **Lab (network namespaces — no extra hardware):** create two namespaces + a veth pair, give each a
   subnet, enable `ip_forward`, add routes so they reach each other through a "router" namespace.
   Document it in `infra/topologies/routing-lab.md`.
3. Build `scripts/route_audit.sh` (skeleton):

```bash
#!/usr/bin/env bash
# route_audit.sh — snapshot + sanity-check routing; flag missing default. Lesson 07.
set -euo pipefail
rc=0
echo "== routing table =="; ip route
echo "== default route =="
if ! ip route show default | grep -q '^default'; then echo "FLAG: no default route"; rc=1; fi
echo "== forwarding enabled? =="; sysctl -n net.ipv4.ip_forward
echo "== next-hop resolution for targets =="
for dst in 1.1.1.1 10.0.0.1; do
  nh=$(ip route get "$dst" 2>/dev/null | head -1)
  echo "  $dst -> $nh"
done
# TODO (operator): ping each resolved next-hop; add traceroute to first failing hop.
exit $rc
```

4. `bash -n` → `shellcheck` → run it.
5. **Break-it drill:** `sudo ip route del default`, run the script (it flags "no default route" and
   `traceroute 1.1.1.1` fails), then `sudo ip route add default via <gw>` and re-verify.

### Lens D — TTL and traceroute
`traceroute -n 1.1.1.1` works by sending packets with increasing TTL; each router that decrements TTL
to 0 returns ICMP Time Exceeded — *that's the routing path, hop by hop.* Watch with
`sudo tcpdump -ni eth0 icmp` running alongside.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/route_audit.sh` (committed, shellcheck-clean).
2. **Config/topology:** `infra/topologies/routing-lab.md` (the netns topology + routes, redacted).
3. **Drill:** the missing-default-route drill in `troubleshooting-drills.md`.
4. **NAVI ticket:** `NAVI-07` (Task: "route_audit.sh + routing-lab topology") To Do→In Progress→Done.
5. **Incident report:** `docs/runbooks/incident-missing-default-route.md` — symptom→RCA→fix→verify.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built a routing-table auditor (`route_audit.sh`) flagging missing default routes
  and resolving next-hops; constructed a multi-namespace routing lab to demonstrate static routing on
  Linux."
- **Interview talking point:** explain longest-prefix match, administrative distance, and IGP vs BGP;
  walk through diagnosing "LAN works, Internet doesn't."
- **Serves:** NOC Technician → NetOps/Jr Network Engineer (Stages 1–3).

---

## §11 — RHCSA Crossover Notes

Direct overlap: adding **static routes** and setting the **default gateway** with `nmcli`/`ip route`,
and verifying with `ip route`/`traceroute`, are RHCSA networking objectives. Dynamic protocols
(OSPF/BGP) are "N/A for RHCSA" but the static-route + default-gateway skills transfer exactly.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** **route manipulation** to redirect or intercept traffic — rogue static routes,
**BGP hijacking** (announcing prefixes you don't own to pull traffic), and ICMP-redirect abuse — all
forms of traffic redirection feeding adversary-in-the-middle (`T1557`) and discovery (`T1018`).

**🔵 Defender:** **route filtering / prefix-lists**, **RPKI** for BGP origin validation, disable
ICMP redirects (`net.ipv4.conf.all.accept_redirects=0`), authenticate routing-protocol adjacencies,
and alert on unexpected route changes/flaps. Verify by attempting a lab-only rogue route and
confirming it's filtered/alerted.

---

## Quiz (Interview-Style, Graded)

**Q1.** Explain longest-prefix match. Given routes `10.0.0.0/8`, `10.0.5.0/24`, and `0.0.0.0/0`,
which is used for `10.0.5.7` and why?
> **Your answer:**

**Q2.** Contrast static and dynamic routing; give one situation where each is the right choice.
> **Your answer:**

**Q3.** What is administrative distance, and how does it differ from a metric?
> **Your answer:**

**Q4.** **Scenario:** a server reaches other hosts on its LAN but nothing on the Internet. What's your
first command and likely root cause?
> **Your answer:**

**Q5.** What is the role of BGP, and how does it differ from an IGP like OSPF?
> **Your answer:**

**Q6.** How does `traceroute` actually discover the path (what field does it manipulate)?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 08.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `routing table longest prefix match`
- `static vs dynamic routing`
- `administrative distance values`
- `ospf eigrp bgp rip comparison`
- `default route gateway of last resort`

**Tools**
- `ip route linux add static route`
- `ip route get next hop`
- `traceroute mtr path analysis`

**Going further (future lessons)**
- `switching fundamentals` (L08) · `vlans inter-vlan routing` (L09) · `nat pat` (L14) · `firewalls` (L15)

**Red / Blue (Lens E):**
- 🔴 `bgp hijacking`, `icmp redirect attack`, `route manipulation T1557`
- 🔵 `rpki bgp origin validation`, `prefix list route filtering`, `disable icmp redirects linux`

---

## Lesson Status
- [ ] §8 lab completed (route_audit.sh + routing-lab topology + missing-default drill)
- [ ] §4 drill done
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 08 — Switching Fundamentals**.

---

*Lesson 07 written by Navi · 2026-06-22 · full-depth. Sources to cite when worked: RFC 4271 (BGP),
RFC 2328 (OSPF), man7.org `ip-route`, CompTIA Network+ N10-009, Cisco CCNA 200-301, MITRE ATT&CK
T1557/T1018.*
