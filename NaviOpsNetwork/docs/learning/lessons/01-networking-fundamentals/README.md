# Lesson 01 — Networking Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-22
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** hosts/nodes, MAC vs IP, switches vs routers, bandwidth/latency/throughput, half/full
duplex, unicast/broadcast/multicast — the vocabulary every later lesson assumes.
**Primary artifact:** `scripts/net_diag.sh` (started here, extended through the track).

> **How to use this lesson:** this is Lesson 01 — the foundation. Read §1–§7, then build the first
> version of `net_diag.sh` in §8. Everything later (OSI, TCP/IP, subnetting, routing) refines the
> mental model you set up here.

---

## §1 — Concept (Scientific Theory)

### What it is
A **network** is two or more devices that exchange data over a shared medium using agreed rules
(**protocols**). The devices are **nodes**; an end device that originates or consumes data (PC,
server, phone, printer) is a **host**. Networking is the study of how a host's data is addressed,
framed, forwarded, and delivered across one or many links.

### Why it exists
Standalone computers can't share data, services, or the Internet. Networking exists to move bytes
reliably between hosts that may be on the same desk or opposite sides of the planet — at scale,
across vendors, using **open standards** (IEEE 802.x for the LAN, IETF RFCs for IP/TCP) so a Cisco
switch, a Linux server, and an Apple laptop all interoperate.

### The two addresses every host has (MAC vs IP)
| | MAC address | IP address |
|---|---|---|
| Layer | L2 (Data Link) | L3 (Network) |
| Format | 48-bit hex `aa:bb:cc:11:22:33` | 32-bit dotted `10.0.0.5` (IPv4) |
| Scope | **local link only** (one LAN segment) | **end-to-end** across networks |
| Assigned by | burned in by NIC vendor (OUI prefix) | configured / DHCP |
| Changes in transit? | **yes** — rewritten hop by hop | **no** — stays the same end-to-end* |

*Except when NAT (Lesson 14) deliberately rewrites it. The mental model: **IP is the destination
city + street (end-to-end); MAC is the specific next mailbox on this street (hop-by-hop).**

### Switch vs router (the two core devices)
- **Switch** = an **L2** device. Forwards **frames** within one LAN by **MAC address**, learning
  which MAC lives on which port (the CAM table, Lesson 08). One broadcast domain per VLAN.
- **Router** = an **L3** device. Forwards **packets** between **different networks** by **IP
  address** using a routing table (Lesson 07). Routers separate broadcast domains.

### Performance vocabulary (don't confuse these)
- **Bandwidth** = the link's *maximum capacity* (e.g. 1 Gbps) — the width of the pipe.
- **Throughput** = the *actual* data rate achieved (often < bandwidth due to overhead/congestion).
- **Latency** = *delay* for one bit to travel end-to-end (ms) — distance, queuing, processing.
- **Jitter** = variation in latency (kills VoIP/video before raw latency does).
- **Packet loss** = % of packets that never arrive (forces retransmits, Lesson 03).

### Duplex & transmission types
- **Half duplex:** send *or* receive, not both (old hubs, walkie-talkie) → collisions.
- **Full duplex:** send *and* receive simultaneously (modern switched links) → no collisions.
- **Unicast** = one→one · **Broadcast** = one→all-on-segment (`ff:ff:ff:ff:ff:ff`) · **Multicast**
  = one→a subscribed group · **Anycast** = one→nearest-of-many (used by DNS roots/CDNs).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** devices have addresses; switches connect devices in one office, routers
  connect offices/the Internet; bigger "pipe" (bandwidth) and shorter "delay" (latency) = faster.
- **Level 2 — NetOps/NOC:** you reason in *domains* — a switch is one broadcast domain, a router
  bounds it. You read live interface stats (`ip -s link`) to see throughput, errors, and duplex
  mismatches. A "slow network" ticket is almost always latency/loss/duplex, not bandwidth.
- **Level 3 — Wire/Kernel (Lens D):** a host puts data into a **frame** (L2, MAC src/dst + payload
  + FCS) wrapping a **packet** (L3, IP src/dst). The NIC + Linux kernel driver place bits on the
  wire; the kernel keeps per-interface counters in `/proc/net/dev` and the neighbour/route tables
  decide the next MAC and exit interface for every packet.

### Two Teaching Approaches (Lens B) — addressing
**Technical:** delivery needs *both* addresses — the IP says "ultimately go to `10.0.0.1`", the
MAC says "to do that, hand this frame to the NIC at `aa:bb:..` on this segment right now."

**Analogy:** the **postal system**. The **IP address** is the full street address on the envelope
(unchanged from sender to recipient). The **MAC address** is each local mail carrier who physically
hands the envelope to the next sorting office — different carrier on every leg. *Where it breaks
down:* the post office doesn't broadcast "who has this street?" to the whole town the way ARP does.

### Visual (ASCII) — two hosts, a switch, and a router
```
   PC-A 10.0.0.5            PC-B 10.0.0.6
   mac aa:..:05             mac aa:..:06
        │                        │
        └─────────[ SWITCH ]─────┘     ← L2: forwards by MAC, one broadcast domain
                       │
                  [ ROUTER ] 10.0.0.1 / 203.0.113.1   ← L3: forwards by IP between networks
                       │
                   Internet
   A→B  : same subnet  → switch only (MAC to MAC)
   A→web: different net → frame to router's MAC, packet keeps web's IP
```

---

## §2 — Linux Networking Commands

```bash
ip -br link                     # interfaces + state (UP/DOWN) + MAC, brief
ip -br addr                     # interfaces + their IP addresses, brief
ip -s link show eth0            # per-interface stats: rx/tx bytes, errors, drops
ethtool eth0                    # speed/duplex/link (Speed: 1000Mb/s, Duplex: Full)
ping -c4 10.0.0.1               # reachability + round-trip latency (RTT)
mtr 10.0.0.1                    # live per-hop latency/loss (traceroute + ping)
ss -tuln                        # listening TCP/UDP sockets (what's on the network)
cat /proc/net/dev               # raw kernel per-interface counters
```

**Cisco/CCNA mapping:** `show interfaces status` (speed/duplex), `show interfaces` (error counters),
`show mac address-table` (the switch's learned MACs). `ip -s link` ≈ `show interfaces` counters.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **"The network is slow":** check **duplex mismatch** (`ethtool` shows half on one side) and
   interface **errors/drops** (`ip -s link`) before blaming bandwidth — duplex mismatch tanks
   throughput while the link still shows "up."
2. **Capacity planning:** bandwidth (link size) vs measured throughput tells you whether to upgrade
   a link or chase a bottleneck elsewhere.
3. **VoIP/video quality complaints:** caused by **jitter + loss**, not raw latency — `mtr` reveals
   the lossy hop.
4. **Inventory/onboarding:** enumerate every host's interfaces, MACs, speeds — the first job of
   `net_diag.sh`.

**How NOC engineers use it:** reading interface state, duplex, and error counters is Tier-1 muscle
memory. "Up but slow," "up/down flapping," and "no link" are the three daily L1 verdicts.

**When NOT to:** don't add bandwidth to fix a latency/loss problem — they're different axes.

**Exam framing (Net+/CCNA):** MAC vs IP, switch vs router, the unicast/broadcast/multicast trio,
bandwidth-vs-throughput-vs-latency, and half/full duplex are guaranteed foundational questions.

---

## §4 — Troubleshooting Section

Worked bottom-up (L1 physical → L3):

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| No link light / `state DOWN` | cable/port/NIC (L1) | `ip -br link`; `ethtool eth0` | reseat/replace cable, enable port |
| Up but very slow | **duplex mismatch** | `ethtool eth0` (Half on one side) | force/auto-negotiate matching duplex |
| Rising `errors`/`drops` | bad cable, MTU, congestion | `ip -s link` | replace cable, fix MTU, relieve load |
| Can reach LAN, not Internet | gateway/route (L3) | `ip route`; `ping gateway` | fix default gateway (L05/L07) |
| Reach by IP, not by name | DNS (L13) | `dig`, `cat /etc/resolv.conf` | fix resolver |

**Diagnostic sequence:** `ip -br link` (L1 up?) → `ip -br addr` (have an IP?) → `ping gateway`
(L2/L3 local) → `ping 1.1.1.1` (routing/Internet) → `dig` (DNS). **Redaction check:** examples use
RFC 5737 (`203.0.113.0/24`) — never commit real public IPs.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Confusing bandwidth with throughput | wrong fix (upgrade vs tune) | measure throughput; capacity ≠ achieved |
| Ignoring duplex mismatch | mystery slowness, link still "up" | `ethtool` both ends must match |
| Assuming a switch separates broadcasts | broadcast storms cross the LAN | only a router/VLAN bounds a broadcast domain |
| Thinking MAC routes across the Internet | broken mental model | MAC is link-local; IP is end-to-end |
| Treating "up" as "healthy" | miss errors/loss | always check `ip -s link` counters |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

On a NOC shift this lesson is the **interface dashboard**: link state, utilization (throughput vs
bandwidth), error/discard counters, and duplex. A normal reading is "up/up, low errors, <70%
utilization, full duplex." Abnormal: a flapping port (up/down up/down) raises a Sev2; saturated
utilization raises a capacity ticket; climbing errors raises a "replace cable / check optics" task.
Every alerting interface should map to a device + owner in inventory so triage and escalation are
instant.

---

## §7 — Incident-Response Perspective

- **Detect:** monitoring shows an interface down, flapping, or saturated; users report "slow/no
  network."
- **Triage:** one host (Sev3) vs an uplink/core link (Sev1/2 by blast radius).
- **Diagnose (RCA):** L1 (cable/optic) → L2 (duplex/errors) → L3 (gateway/route) — bottom-up.
- **Fix → Recover → Document:** restore the link, verify with `ping`/`ip -s link`, write a runbook
  (`docs/runbooks/`) capturing symptom → RCA → fix → verification.

---

## §8 — Practical Lab (build this yourself)

**Goal:** start `scripts/net_diag.sh` — a one-command host network snapshot (interfaces, addresses,
gateway, basic reachability) that every later lesson extends.

### Lens C — Manual → Automated → Why
- **Manual:** run `ip -br link`, `ip -br addr`, `ip route`, `ping -c1 <gw>` by hand.
- **Automated:** `net_diag.sh` runs them in order with clear headers and a pass/fail on reachability.
- **Why:** a repeatable snapshot means any analyst captures the *same* baseline during onboarding or
  an incident — production teams attach this output to every ticket.

### Steps
1. Run each §2 command and interpret it on your own machine (note your MAC, IP, duplex, gateway).
2. Build `scripts/net_diag.sh` (skeleton):

```bash
#!/usr/bin/env bash
# net_diag.sh — one-command host network snapshot. Lesson 01 (extended through the track).
set -euo pipefail
rc=0
echo "== interfaces (link) =="; ip -br link
echo "== addresses =="; ip -br addr
echo "== default route =="
if ! ip route show default | grep -q '^default'; then echo "FLAG: no default gateway"; rc=1; fi
ip route show default
gw=$(ip route show default | awk '/default/{print $3; exit}')
echo "== gateway reachability =="
if [ -n "${gw:-}" ] && ping -c1 -W1 "$gw" >/dev/null 2>&1; then echo "OK: gateway $gw reachable"
else echo "FLAG: gateway unreachable"; rc=1; fi
# TODO (operator): add duplex check via `ethtool`, error/drop counters via `ip -s link`.
exit $rc
```

3. `bash -n net_diag.sh` → `shellcheck net_diag.sh` → run it.
4. **Break-it drill:** `sudo ip link set eth0 down` (in a VM), run the script, confirm it flags the
   gateway as unreachable, then `sudo ip link set eth0 up` and re-verify.

### Lens D — see the counters move
`cat /proc/net/dev` before and after a `ping -c100 <gw>` — watch rx/tx packet counts climb for your
interface; this is the kernel's per-interface accounting that `ip -s link` formats.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/net_diag.sh` (committed, shellcheck-clean).
2. **Config/doc:** `docs/networking/host-baseline.md` — your interpreted snapshot (redacted).
3. **Drill:** interface-down induced + flagged by the script (the §8 break-it drill).
4. **NAVI ticket:** `NAVI-01` (Task: "net_diag.sh + host network baseline") To Do→In Progress→Done.
5. **Incident report:** `docs/runbooks/incident-link-down.md` — symptom→RCA→fix→verify.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built a host network-diagnostic script (`net_diag.sh`) capturing interfaces,
  addressing, gateway reachability, and duplex/errors — used as the standard first-look on tickets."
- **Interview talking point:** explain MAC vs IP and switch vs router crisply, and how you'd debug a
  "slow network" by checking duplex/errors before bandwidth.
- **Serves:** NOC Technician (Stage 1) — interface/L1-L3 basics are Tier-1 bread and butter.

---

## §11 — RHCSA Crossover Notes

Strong overlap: identifying interfaces and addresses with `ip`, configuring with `nmcli`, and
verifying link/route are core RHCSA networking objectives. Duplex/speed (`ethtool`) and interface
counters transfer directly to RHEL troubleshooting tasks.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker (1–2 line, Day-1 scale):** the LAN itself is an attack surface — **MAC flooding** to
overflow a switch's CAM table and force it to broadcast (eavesdrop), and **broadcast/discovery**
abuse for **Network Service Discovery** (`T1046`) to map live hosts.

**🔵 Defender:** **port security** (limit MACs/port) and **storm control** on switches; monitor for
unexpected broadcast spikes; baseline which MACs belong on which port. Verify by attempting a
lab-only MAC flood and confirming port-security shuts the port.

---

## Quiz (Interview-Style, Graded)

**Q1.** A host has both a MAC and an IP address. What is each for, and which one changes as a packet
crosses routers?
> **Your answer:**

**Q2.** Differentiate a switch from a router in terms of layer, address used, and broadcast domains.
> **Your answer:**

**Q3.** Define bandwidth, throughput, and latency. A user says "the Internet is slow" — which would
you check first and why?
> **Your answer:**

**Q4.** **Scenario:** a server link shows "up" but transfers are extremely slow with rising error
counts. What's your top suspect and how do you confirm it from Linux?
> **Your answer:**

**Q5.** Contrast unicast, broadcast, and multicast with one real example of each.
> **Your answer:**

**Q6.** What address range should appear in committed documentation/screenshots, and why?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 02.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `mac address vs ip address difference`
- `switch vs router layer 2 layer 3`
- `bandwidth throughput latency jitter`
- `unicast broadcast multicast anycast`
- `half duplex vs full duplex mismatch`

**Tools**
- `ip -s link interface statistics linux`
- `ethtool speed duplex check`
- `mtr traceroute packet loss`

**Going further (future lessons)**
- `osi model 7 layers` (L02) · `tcp ip model` (L03) · `subnetting cidr` (L04)

**Red / Blue (Lens E):**
- 🔴 `mac flooding cam overflow`, `network service discovery T1046`
- 🔵 `switchport port-security`, `broadcast storm control`

---

## Lesson Status
- [ ] §8 lab completed (net_diag.sh built + interface-down drill)
- [ ] §4 drill done
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 02 — OSI Model**.

---

*Lesson 01 written by Navi · 2026-06-22 · full-depth. Sources to cite when worked: IEEE 802.3,
RFC 5737, man7.org `ip-link`, CompTIA Network+ N10-009, MITRE ATT&CK T1046.*
