# Lesson 04 — Subnetting Masterclass

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-22
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** CIDR, the subnet mask, network/broadcast/usable hosts, VLSM, supernetting, and fast
subnet math — with `ipcalc` to check your work.
**Primary artifact:** `docs/networking/subnet-cheatsheet.md`.

> **How to use this lesson:** subnetting is the one skill every network interview tests live, on a
> whiteboard, no calculator. Read §1, then build the cheatsheet in §8 and **drill the math until it's
> reflex.** `ipcalc` checks you; the exam doesn't have it.

---

## §1 — Concept (Scientific Theory)

### What it is
**Subnetting** divides one IP network into smaller logical networks (**subnets**) by borrowing host
bits for the network portion. The **subnet mask** marks which bits are network (1s) vs host (0s).
**CIDR** (Classless Inter-Domain Routing, RFC 4632) writes the mask as a prefix length: `/24` =
24 network bits.

### The mask, in three forms
| CIDR | Dotted mask | Network bits | Host bits | Usable hosts |
|---|---|---|---|---|
| /24 | 255.255.255.0 | 24 | 8 | 254 |
| /25 | 255.255.255.128 | 25 | 7 | 126 |
| /26 | 255.255.255.192 | 26 | 6 | 62 |
| /27 | 255.255.255.224 | 27 | 5 | 30 |
| /28 | 255.255.255.240 | 28 | 4 | 14 |
| /29 | 255.255.255.248 | 29 | 3 | 6 |
| /30 | 255.255.255.252 | 30 | 2 | 2 (point-to-point links) |

### The two formulas (memorize)
- **Total addresses in a subnet** = 2^(host bits)
- **Usable hosts** = 2^(host bits) − 2 (subtract network + broadcast)
- *(exception: /31 RFC 3021 = 2 usable for P2P links; /32 = a single host)*

### The four numbers of any subnet
For a block, you always identify: **Network address** (all host bits 0, the block's name),
**Broadcast address** (all host bits 1, talks to everyone in the block), **First usable**
(network+1), **Last usable** (broadcast−1).

### The "magic number" (block size) method — fast manual subnetting
The **block size = 256 − (the interesting octet of the mask)**. Subnets step by that block size in
the interesting octet.
Example `192.168.1.0/26`: mask `255.255.255.192`, block size `256−192 = 64`. Subnets:
`.0`, `.64`, `.128`, `.192`. For host `192.168.1.100` → it's in the `.64` block (64–127): network
`.64`, broadcast `.127`, usable `.65–.126`.

### VLSM (Variable Length Subnet Masking)
Instead of one mask for everything, **size each subnet to its need** — allocate largest-first to
avoid waste. E.g. from `10.0.0.0/24`: a 100-host LAN → `/25` (.0–.127), a 50-host LAN → `/26`
(.128–.191), a 10-host LAN → `/28` (.192–.207), P2P links → `/30`s. This is how real address plans
are built.

### Supernetting / route summarization
The inverse: combine contiguous blocks into one shorter prefix to shrink routing tables. `10.0.0.0/24`
+ `10.0.1.0/24` summarize to `10.0.0.0/23`.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** a subnet mask says "how big is my local network." `/24` = 254 usable
  addresses; the first is the network name, the last is broadcast.
- **Level 2 — NetOps/NOC:** you design address plans with VLSM, spot a **wrong mask** instantly
  (host can't reach its own gateway because the gateway is "off-subnet"), and summarize routes. You
  recognize a `/30` as a router-to-router link.
- **Level 3 — Wire/Kernel (Lens D):** the host decides "local vs remote" by **ANDing** its IP and a
  destination IP with the mask: same network portion → deliver on the LAN (ARP for it); different →
  send to the default gateway. This single AND operation drives every forwarding decision.

### Two Teaching Approaches (Lens B) — subnetting
**Technical:** borrowing *n* host bits creates 2^n subnets, each with 2^(remaining)−2 usable hosts;
the boundary moves the network/host split rightward.

**Analogy:** **street addresses.** The network is the street name; host bits are the apartment
numbers. Subnetting is splitting one long street into several shorter streets — fewer apartments per
street, but cleaner delivery and isolation. *Where it breaks down:* you "lose" two apartments per
street (network + broadcast) — a quirk addresses have that streets don't.

### Visual (ASCII) — /24 split into four /26 blocks
```
 192.168.1.0/24  (256 addrs)  →  block size 256-192 = 64
 ┌───────────┬───────────┬───────────┬───────────┐
 │ .0   /26  │ .64  /26  │ .128 /26  │ .192 /26  │
 │ net  .0   │ net  .64  │ net  .128 │ net  .192 │
 │ bc   .63  │ bc   .127 │ bc   .191 │ bc   .255 │
 │ use .1-.62│ use 65-126│use129-190 │use193-254 │
 └───────────┴───────────┴───────────┴───────────┘
```

---

## §2 — Linux Networking Commands

```bash
ipcalc 192.168.1.100/26          # network, broadcast, usable range, host count (check your math)
ipcalc -b 10.0.0.0/24            # without ANSI colors (scriptable)
sipcalc 10.0.0.0/22              # alternative, supports splitting (sipcalc -s)
ip route get 10.0.0.200          # which interface/gateway the kernel picks (local vs via gw)
ip -br addr                      # see your own prefix (/NN) on each interface
python3 -c "import ipaddress as i; n=i.ip_network('192.168.1.0/26'); print(n.network_address, n.broadcast_address, n.num_addresses)"
```

**Cisco/CCNA mapping:** `ip address 10.0.0.1 255.255.255.192`, `show ip interface brief`,
`ip route 10.0.0.0 255.255.254.0 ...` (a summary route). On the exam you compute these by hand —
`ipcalc` is for verifying practice, not for the test.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Designing an address plan:** VLSM-allocate per-site/per-VLAN subnets sized to host count, with
   room to grow — documented in IPAM (Lesson 27).
2. **"Can't reach the gateway":** a **wrong mask** puts the gateway off-subnet — the host tries to
   ARP for it locally and fails. Classic field bug.
3. **Route summarization:** advertise `10.1.0.0/22` instead of four `/24`s to keep routing tables
   small and stable (Lesson 07).
4. **P2P links:** router interconnects use `/30` (or `/31`) — exactly 2 usable addresses, no waste.

**How NOC engineers use it:** mask sanity-checks are constant — "is this host's mask right, and is
the gateway inside its subnet?" resolves a large share of "no connectivity" tickets.

**When NOT to:** don't over-subnet tiny networks into unusable fragments; and don't use classful
defaults — always think in CIDR.

**Exam framing (Net+/CCNA):** "how many subnets/hosts," "what's the network/broadcast of X," and VLSM
design problems are *guaranteed* and timed.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Can't reach own gateway | wrong subnet mask (gw off-subnet) | `ip -br addr`; `ipcalc`; is gw in range? | correct the prefix |
| Two "different" hosts can't talk locally | masks disagree (one /24, one /25) | compare `ip -br addr` both | align masks |
| Routing loop / overlap | overlapping subnets | map all subnets; `ipcalc` | re-plan non-overlapping |
| Wasted/overflowing addresses | wrong-sized subnet | recount hosts vs 2^h−2 | resize with VLSM |
| Host thinks remote is local (or vice-versa) | mask boundary error | `ip route get <dst>` | fix mask/route |

**Diagnostic sequence:** `ip -br addr` (my IP/prefix) → `ipcalc <ip>/<prefix>` (network/broadcast/
range) → is the **gateway inside** that range? → `ip route get <dst>` (local vs via-gw decision).
**Redaction check:** RFC 1918 / RFC 5737 ranges only in committed examples.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Forgetting −2 for usable hosts | wrong host count | usable = 2^h − 2 |
| Gateway outside the subnet | no off-net connectivity | gateway must be in the host's block |
| Mixing masks on one segment | partial reachability | one consistent mask per subnet |
| Overlapping subnets in a plan | routing ambiguity | VLSM, allocate largest-first, no overlap |
| Using classful thinking | mis-sized nets | always CIDR; ignore A/B/C for sizing |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

Subnet literacy is assumed on every NOC shift: an alert IP must map instantly to "which subnet/site/
VLAN is this?" (IPAM, Lesson 27). When a whole subnet goes dark, knowing the network/broadcast bounds
scopes the blast radius immediately. Mask mismatches are a frequent root cause behind "this one host
can't get out" tickets — a 30-second `ipcalc` confirms it.

---

## §7 — Incident-Response Perspective

- **Detect:** "no connectivity" for a host or a whole segment.
- **Triage:** single host (mask/gateway) vs whole subnet (upstream/route) — scope by the block.
- **Diagnose (RCA):** `ipcalc` the host's IP/prefix; verify the gateway is in-range and the dst is
  classified local/remote correctly (`ip route get`).
- **Fix → Recover → Document:** correct the mask/plan, verify reachability, and record the corrected
  subnet in IPAM + the runbook.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build `docs/networking/subnet-cheatsheet.md` (the mask/host table + magic-number method)
**and** a `scripts/subnet_plan.sh` helper, then *drill the math by hand*.

### Lens C — Manual → Automated → Why
- **Manual:** compute network/broadcast/range for several IP/prefix pairs using the magic-number
  method — no tools.
- **Automated:** `subnet_plan.sh` wraps `ipcalc`/Python to print the four numbers + host count for an
  IP/prefix, and to VLSM-split a block by a list of host requirements.
- **Why:** the script speeds real planning, but you *must* be able to do it manually for interviews
  and outages where no tool is handy.

### Steps
1. By hand, for `172.16.20.37/27`: find mask, block size, network, broadcast, first/last usable,
   host count. Then verify with `ipcalc 172.16.20.37/27`.
2. VLSM-design from `10.10.0.0/24` for needs: 100, 50, 25, 10, and two P2P links. Allocate
   largest-first; write the plan.
3. Build `scripts/subnet_plan.sh` (skeleton):

```bash
#!/usr/bin/env bash
# subnet_plan.sh — print the four subnet numbers + usable count for IP/PREFIX. Lesson 04.
set -euo pipefail
cidr="${1:?usage: subnet_plan.sh <ip>/<prefix>}"
python3 - "$cidr" <<'PY'
import sys, ipaddress
n = ipaddress.ip_network(sys.argv[1], strict=False)
hosts = list(n.hosts())
print(f"network   : {n.network_address}/{n.prefixlen}")
print(f"netmask   : {n.netmask}")
print(f"broadcast : {n.broadcast_address}")
print(f"usable    : {hosts[0]} - {hosts[-1]}" if hosts else "usable    : (none)")
print(f"hosts     : {max(n.num_addresses-2,0)}")
PY
```

4. `bash -n` → `shellcheck` → run on several CIDRs; cross-check against your hand math.
5. **Drill:** generate 10 random IP/prefix pairs, compute by hand, verify with the script. Repeat
   until reflex.

### Lens D — see the local/remote AND decision
`ip route get 10.10.0.130` vs `ip route get 10.10.1.5` from a host on `10.10.0.0/25` — the kernel
prints `dev eth0` (local, same masked network) vs `via <gateway>` (remote). That's the IP-AND-mask
decision, made visible.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/subnet_plan.sh` (committed, shellcheck-clean).
2. **Config/doc:** `docs/networking/subnet-cheatsheet.md` + a worked VLSM address plan.
3. **Drill:** a mask-mismatch "can't reach gateway" drill in `troubleshooting-drills.md`.
4. **NAVI ticket:** `NAVI-04` (Task: "subnet cheatsheet + VLSM plan + subnet_plan.sh") To Do→Done.
5. **Incident report:** `docs/runbooks/incident-wrong-subnet-mask.md` — symptom→RCA→fix→verify.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Designed VLSM IP address plans and a subnet-calculation helper
  (`subnet_plan.sh`); diagnosed connectivity outages caused by subnet-mask misconfiguration."
- **Interview talking point:** subnet on the whiteboard live (network/broadcast/usable + a VLSM
  split) and explain how a wrong mask breaks gateway reachability.
- **Serves:** NOC Technician → NetOps/Jr Network Engineer (Stages 1–3) — *the* gatekeeper skill.

---

## §11 — RHCSA Crossover Notes

Subnetting underpins RHCSA networking tasks (configuring an address with the right prefix via
`nmcli`, understanding why a host can/can't reach a gateway). Pure subnet math isn't a separate RHCSA
objective but is assumed throughout the networking section.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker (1–2 line, Day-1 scale):** attackers use subnet knowledge to **sweep** a discovered
range efficiently (`T1046` Network Service Discovery / `T1018` Remote System Discovery) — a precise
prefix tells them exactly how many hosts to scan.

**🔵 Defender:** **segmentation** is a primary control — small, purpose-scoped subnets + VLANs
(Lesson 09) limit lateral movement and shrink blast radius; tighten ACLs to per-subnet need
(least-access). Verify segmentation by attempting (lab-only) cross-subnet access that should be
denied.

---

## Quiz (Interview-Style, Graded)

**Q1.** For `192.168.10.0/26`, give the block size, all four subnets, and the network/broadcast/
usable range of the third subnet.
> **Your answer:**

**Q2.** How many usable hosts in a /28? Show the formula.
> **Your answer:**

**Q3.** Why do you subtract 2 for usable hosts, and what's the exception?
> **Your answer:**

**Q4.** **Scenario:** a host `10.0.0.130/25` is configured with gateway `10.0.0.1`. It can't reach
the Internet. Why, and what's the fix?
> **Your answer:**

**Q5.** VLSM-allocate from `10.20.0.0/24` for subnets needing 60, 30, and 12 hosts plus one P2P link.
> **Your answer:**

**Q6.** Summarize `172.16.4.0/24` and `172.16.5.0/24` into one prefix.
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 05.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `subnetting cidr explained`
- `subnet mask network broadcast usable hosts`
- `magic number block size subnetting`
- `vlsm variable length subnet masking`
- `route summarization supernetting`

**Tools**
- `ipcalc linux subnet`
- `python ipaddress module subnet`
- `ip route get local vs gateway`

**Going further (future lessons)**
- `ipv4 addressing rfc1918` (L05) · `routing fundamentals` (L07) · `vlans` (L09) · `ipam` (L27)

**Red / Blue (Lens E):**
- 🔴 `subnet sweep host discovery T1018`, `network service discovery T1046`
- 🔵 `network segmentation lateral movement`, `vlan isolation`

---

## Lesson Status
- [ ] §8 lab completed (cheatsheet + VLSM plan + subnet_plan.sh; hand-math drilled)
- [ ] §4 drill done
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 05 — IPv4 Addressing**.

---

*Lesson 04 written by Navi · 2026-06-22 · full-depth. Sources to cite when worked: RFC 4632, RFC 1918,
RFC 3021, man `ipcalc`, Python `ipaddress`, CompTIA Network+ N10-009, MITRE ATT&CK T1018/T1046.*
