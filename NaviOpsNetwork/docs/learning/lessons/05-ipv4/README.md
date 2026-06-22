# Lesson 05 — IPv4 Addressing

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** address structure, RFC 1918 private ranges, legacy classes, APIPA, ARP, gateways, `ip addr`/`ip neigh`.
**Primary artifact:** `scripts/ip_audit.sh`.

> **How to use this lesson:** builds directly on subnetting (Lesson 04). Here you operationalize
> addressing — read it, then build `ip_audit.sh` to enumerate and sanity-check addressing on a host.

---

## §1 — Concept (Scientific Theory)

### What it is
An **IPv4 address** is a 32-bit number written as four dotted **octets** (`10.0.0.5`), each
0–255. Combined with a subnet mask (Lesson 04) it splits into network + host portions. This
lesson covers the *operational* facts around IPv4: which ranges are **private** vs **public**,
the legacy **class** system, **APIPA** (link-local self-assignment), and **ARP** (how a host
maps an IP to the MAC needed to actually deliver a frame on the LAN).

### Why it exists
IPv4 (RFC 791, 1981) is the addressing system the Internet was built on. Its scarcity (~4.3
billion addresses) drove the inventions you'll meet later: private addressing + **NAT**
(Lesson 14) to share one public IP among many private hosts, and eventually **IPv6** (Lesson 06).

### Key address ranges (memorize these)
| Range | Prefix | Purpose (RFC) |
|---|---|---|
| `10.0.0.0`–`10.255.255.255` | /8 | Private (RFC 1918) — large nets |
| `172.16.0.0`–`172.31.255.255` | /12 | Private (RFC 1918) |
| `192.168.0.0`–`192.168.255.255` | /16 | Private (RFC 1918) — home/SOHO |
| `169.254.0.0`–`169.254.255.255` | /16 | **APIPA / link-local** (RFC 3927) — DHCP failed |
| `127.0.0.0`–`127.255.255.255` | /8 | Loopback (localhost) |
| `192.0.2.0`, `198.51.100.0`, `203.0.113.0` | /24 each | **Documentation** (RFC 5737) — use in docs! |
| everything else (mostly) | — | Public / globally routable |

### Legacy classful system (know it for context + exams)
| Class | 1st octet | Default mask | Note |
|---|---|---|---|
| A | 1–126 | /8 | huge nets |
| B | 128–191 | /16 | medium |
| C | 192–223 | /24 | small |
| D | 224–239 | — | multicast |
| E | 240–255 | — | experimental |

Classes are **obsolete** for allocation (CIDR replaced them in 1993) but the vocabulary persists
and exams test it.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** your device has an IP (its address), a subnet mask (the network/host
  split), and a default gateway (the router it uses to leave the local network). Private
  addresses work inside your network; public ones are reachable on the Internet.
- **Level 2 — NetOps/NOC:** you read and set these with `ip`. A host on `169.254.x.x` means
  **DHCP failed** (APIPA self-assignment) — an instant diagnosis (Lesson 12). **ARP** resolves
  the next-hop IP to a MAC; a `FAILED`/`INCOMPLETE` ARP entry to a local host means L2 trouble.
  **Duplicate IP** is a nasty intermittent fault — two hosts answering ARP for one address.
- **Level 3 — Wire/Kernel (Lens D):** ARP (RFC 826) is an L2 broadcast: "who has `10.0.0.1`? tell
  `10.0.0.5`" → the owner unicasts back "`10.0.0.1` is at `aa:bb:..`". The kernel caches this in
  the **neighbour table** (`ip neigh`) with states (`REACHABLE`, `STALE`, `FAILED`). A
  **gratuitous ARP** (announcing your own IP→MAC) updates everyone's cache — used legitimately on
  failover (Lesson 31) and maliciously in ARP spoofing (§12).

### Visual (ASCII) — ARP resolves a destination before delivery

```
 PC-A 10.0.0.5 wants to send to 10.0.0.1 (gateway), but needs its MAC:
   A ── broadcast ── "ARP: who has 10.0.0.1? tell 10.0.0.5"  ──► everyone on LAN
   GW ── unicast ──  "ARP: 10.0.0.1 is at aa:bb:cc:00:00:01"  ──► A
   A caches it:  ip neigh →  10.0.0.1 dev eth0 lladdr aa:bb:cc:00:00:01 REACHABLE
   Now A can build the frame [dst=aa:bb:.. | ...] and send.
```

---

## §2 — Linux Networking Commands

```bash
ip -br addr                       # interfaces + IPv4 (and v6) addresses, brief
ip addr show eth0                 # full detail incl. scope, lifetime (DHCP lease)
ip addr add 10.0.0.50/24 dev eth0 # add an address (manual/static, lab)
ip neigh show                     # ARP table (IP <-> MAC, with state)
ip neigh flush all                # clear ARP cache (forces re-resolution; sudo)
arping -I eth0 10.0.0.1           # actively ARP a host (detect duplicate IPs)
ping -c1 -b 10.0.0.255            # (where allowed) broadcast ping to find live hosts
nmcli con mod eth0 ipv4.addresses 10.0.0.50/24 ipv4.gateway 10.0.0.1   # NetworkManager (RHCSA)
```

**Cisco/CCNA mapping:** `ip address 10.0.0.50 255.255.255.0` · `show ip arp` · `show ip
interface brief`. APIPA on Windows/Cisco endpoints behaves the same (`169.254.x.x` = no DHCP).

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **"New host got `169.254.x.x`":** instantly = DHCP failure (server down, scope exhausted,
   VLAN/relay wrong) — pivot straight to Lesson 12 instead of guessing.
2. **Intermittent connectivity for one host:** suspect a **duplicate IP** — `arping` shows two
   MACs answering for one address.
3. **Static addressing for infrastructure:** servers/printers/switches get static IPs (or DHCP
   reservations) so they're predictable; you document them in IPAM (Lesson 27).
4. **Audit:** enumerate which addresses are live on a subnet and flag anomalies (rogue static,
   APIPA, duplicates) — the `ip_audit.sh` you build here.

**How NOC engineers use it:** APIPA recognition and ARP-table reading are daily Tier-1 skills.
"Has an IP but it's `169.254` / has the wrong gateway / ARP won't resolve" cover a big slice of
connectivity tickets.

**When NOT to:** don't hand-assign statics across a big estate — use DHCP + reservations
(consistency, central control).

**Exam framing (Net+/CCNA):** RFC 1918 ranges, APIPA range + meaning, the legacy classes,
loopback, and ARP's role are guaranteed.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Host on `169.254.x.x` | DHCP failed (APIPA) | `ip -br addr`; `journalctl -u NetworkManager` | fix DHCP (L12) / set static |
| Has IP, no internet | missing/wrong default gateway | `ip route`; gateway in same subnet? | set correct gateway |
| Intermittent connectivity | duplicate IP | `arping -D -I eth0 <ip>` | reassign one host |
| Can't reach a local host | ARP `FAILED`/`INCOMPLETE` | `ip neigh show` | check L2/switch/VLAN; duplicate IP |
| Wrong subnet membership | mask typo | `ip -br addr` + `ipcalc` | correct prefix |

**Redaction check:** use RFC 5737 docs ranges in committed examples; never commit real public IPs.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Not recognizing `169.254` as APIPA | misdiagnose a DHCP outage | `169.254.x.x` ⇒ DHCP failed |
| Setting a gateway outside the host's subnet | no internet, silent | gateway must be in-subnet |
| Two devices with the same static IP | intermittent flaps | use reservations / `arping -D` before assigning |
| Treating classes as current allocation | confusion with CIDR | classes are legacy vocabulary only |
| Committing real public IPs to the repo | leak | RFC 5737 docs ranges only |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

APIPA is one of the fastest NOC diagnoses: a cluster of clients on `169.254.x.x` is a DHCP-scope
or relay incident (`noc/noc-scenarios.md` #2), usually Sev2/Sev1 by scope. The ARP table is your
L2 truth — during an incident, a gateway entry that suddenly changed MAC is a red flag (failover
or spoofing). Maintaining accurate IPAM (Lesson 27) means an alerting IP immediately maps to a
device + owner, which speeds triage and escalation.

---

## §7 — Incident-Response Perspective

- **Detect:** clients report no connectivity; monitoring shows them off-net or on APIPA.
- **Triage:** one host (Sev3) vs many on `169.254` (Sev1/2 — DHCP).
- **Diagnose (RCA):** APIPA → DHCP (L12); wrong gateway → addressing config; ARP flapping →
  duplicate IP or L2.
- **Fix → Recover → Document:** restore addressing, verify with `ip addr`/`ping gateway`, update
  IPAM + runbook. Duplicate-IP incidents are a great `arping`-evidence runbook.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build `scripts/ip_audit.sh` — enumerate a host's addressing + ARP table and flag
anomalies (APIPA, no gateway, duplicate IP).

### Lens C — Manual → Automated → Why
- **Manual:** `ip -br addr`, `ip route`, `ip neigh`, `arping -D`.
- **Automated:** `ip_audit.sh` runs these, parses for `169.254.*` (APIPA), missing default
  route, and (optionally) `arping -D` duplicate detection — exit non-zero on any finding.
- **Why:** a one-command addressing health check you can run on any host during onboarding or an
  incident; production teams bake this into provisioning validation.

### Steps
1. Run each §2 read command and interpret it on your machine.
2. Build `scripts/ip_audit.sh` (skeleton):

```bash
#!/usr/bin/env bash
# ip_audit.sh — audit a host's IPv4 addressing + ARP, flag APIPA / no-gateway. Lesson 05.
set -euo pipefail
rc=0
echo "== addresses =="; ip -br addr
if ip -br addr | grep -q '169\.254\.'; then echo "FLAG: APIPA address present — DHCP likely failed"; rc=1; fi
echo "== default route =="
if ! ip route show default | grep -q '^default'; then echo "FLAG: no default gateway"; rc=1; fi
echo "== ARP/neighbours =="; ip neigh show
# TODO (operator): add `arping -D` duplicate-IP detection per interface; summarize findings.
exit $rc
```

3. `bash -n` → `shellcheck` → run it. Then induce APIPA on a VM (stop DHCP, `ip addr flush dev
   eth0`, request a lease with no server) and confirm the script flags it.
4. Detect a duplicate IP (lab): set the same IP on two VMs, `arping -D -I eth0 <ip>` shows the
   conflict.

### Lens D — watch ARP live
`ip neigh flush all; sudo tcpdump -ni eth0 arp & ; ping -c1 <gateway>; ip neigh show` — see the
who-has/is-at exchange populate the neighbour table.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/ip_audit.sh` (committed, shellcheck-clean).
2. **Config/doc:** addressing notes / IPAM seed in `docs/networking/ipam.md` (redacted).
3. **Drill:** APIPA induced + flagged; or duplicate-IP detected with `arping`.
4. **NAVI ticket:** `NAVI-05` (Task: "ip_audit.sh + addressing audit") To Do→In Progress→Done.
5. **Incident report:** `docs/runbooks/incident-apipa-dhcp.md` (or duplicate-IP) — symptom→RCA→fix→verify.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built an IPv4 addressing auditor (`ip_audit.sh`) detecting APIPA,
  missing-gateway, and duplicate-IP conditions; used it in a DHCP-failure incident."
- **Interview talking point:** "`169.254.x.x` instantly tells me DHCP failed" + how ARP works and
  how you'd catch a duplicate IP.
- **Serves:** NOC Technician (Stage 1) — APIPA/ARP are bread-and-butter Tier-1.

---

## §11 — RHCSA Crossover Notes

Strong RHCSA overlap: configuring IPv4 with `nmcli` (addresses, gateway, DNS), understanding
static vs DHCP, and verifying with `ip addr`/`ip route` are core RHCSA networking objectives. The
APIPA signal and ARP table reading transfer directly to RHEL troubleshooting tasks.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** **ARP spoofing / cache poisoning** (`T1557.002`) — forging "is-at" replies to
redirect a victim's traffic through the attacker (MITM) by claiming the gateway's IP. A rogue
host can also exhaust DHCP or impersonate the gateway.

**🔵 Defender:** **Dynamic ARP Inspection** + **DHCP snooping** on switches (validate ARP against
the DHCP binding table); monitor `ip neigh` for a gateway MAC that changes; **static ARP entries**
for critical gateways in high-security segments; alert on gratuitous-ARP storms. Verify by
attempting (lab-only) an ARP spoof and confirming detection/blocking.

---

## Quiz (Interview-Style, Graded)

**Q1.** List the three RFC 1918 private ranges with their prefixes. Why do they exist?
> **Your answer:**

**Q2.** A client shows `169.254.10.7` as its IP. What does that tell you, and what are the top
causes?
> **Your answer:**

**Q3.** Explain ARP: what triggers it, what's broadcast vs unicast, and where the result is stored.
> **Your answer:**

**Q4.** **Scenario:** One host on a LAN has intermittent connectivity; others are fine. You
suspect a duplicate IP. How do you confirm it from Linux?
> **Your answer:**

**Q5.** What's wrong with configuring `10.0.0.50/24` with gateway `10.0.1.1`?
> **Your answer:**

**Q6.** What address range should you use in public documentation/screenshots, and why?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 06.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `rfc 1918 private ip ranges`
- `apipa 169.254 link local explained`
- `arp protocol how it works`
- `ipv4 address classes legacy`

**Tools**
- `ip neigh arp table linux`
- `arping duplicate ip detection`
- `nmcli set static ip gateway`

**Going further (future lessons)**
- `dhcp dora lease` (L12) · `nat private to public` (L14) · `ipv6 addressing` (L06)

**Red / Blue (Lens E):**
- 🔴 `arp spoofing mitm T1557.002`, `gratuitous arp attack`, `dhcp exhaustion`
- 🔵 `dynamic arp inspection`, `dhcp snooping`, `detect arp poisoning linux`

---

## Lesson Status
- [ ] §8 lab completed (ip_audit.sh built + APIPA/duplicate detected)
- [ ] §4 drill done
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 06 — IPv6**.

---

*Lesson 05 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: RFC 791/826/1918/3927/5737,
man7.org `ip-neighbour`, CompTIA Network+ N10-009, MITRE ATT&CK T1557.*
