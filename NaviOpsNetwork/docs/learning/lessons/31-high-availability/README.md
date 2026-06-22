# Lesson 31 — High Availability

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** VRRP/keepalived, failover, ECMP, active/active vs active/passive, SPOF analysis.
**Primary artifact:** `infra/configs/keepalived.conf`.
**Difficulty:** **Difficult concept** — §1 uses two teaching approaches + an ASCII diagram (Lens B).

> **How to use this lesson:** HA removes single points of failure — it's how the LB (Lesson 30),
> gateways, and services survive a node death. Read §1–§7, build a **keepalived/VRRP** floating-IP
> failover in §8. Lab only.

---

## §1 — Concept (Scientific Theory)

### What it is
**High Availability (HA)** is designing systems to keep working despite component failures, by
eliminating **single points of failure (SPOFs)** through **redundancy** + automatic **failover**.
Network HA includes: **VRRP** (Virtual Router Redundancy Protocol — a redundant default gateway via
a **floating/virtual IP**), **keepalived** (the Linux VRRP + health-check daemon), **ECMP** (Equal-
Cost Multi-Path — multiple active routes), and redundant LBs/links/devices. Configurations are
**active/passive** (one works, a standby takes over) or **active/active** (all work, load-shared).

### Why it exists
Every component eventually fails (hardware, software, power, link). If a single failure causes an
outage, that component is a **SPOF**. HA buys "nines" of availability (`noc/sla-concepts.md`) by
ensuring a backup instantly assumes the failed component's role — turning a multi-hour outage into
a sub-second blip. It's how critical services meet strict SLAs.

### Core mechanisms
- **VRRP / floating VIP:** two routers/hosts share a **virtual IP**; the MASTER owns it; if it
  fails, the BACKUP takes over the VIP (and sends a gratuitous ARP, Lesson 05, so traffic
  redirects) — clients keep using the same gateway IP, unaware of the swap. (HSRP/GLBP are Cisco
  equivalents.)
- **keepalived:** runs VRRP + **health checks** on Linux — fails over the VIP when the service or
  node is unhealthy (often paired with HAProxy, Lesson 30, to make the LB itself HA).
- **ECMP:** multiple equal-cost routes (Lesson 07) used simultaneously — both bandwidth and
  redundancy.
- **Active/passive vs active/active:** standby idle until needed (simpler) vs all nodes serving
  (better resource use, more complex — needs state sync).
- **Split-brain:** the failure mode where both nodes think they're MASTER (both claim the VIP) —
  guarded against with priorities, preemption rules, and quorum.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** HA means having a backup that automatically takes over the instant the
  main thing fails, so users barely notice — like a spare tire that mounts itself.
- **Level 2 — NetOps/NOC:** you identify SPOFs (a single gateway, LB, link, power feed) and add
  redundancy + failover; configure **keepalived/VRRP** for a floating gateway/LB VIP with health
  checks; choose active/passive vs active/active; and avoid **split-brain**. You monitor failover
  health (a degraded HA pair — one node down — is a watch item: protected *now*, but the next
  failure is an outage).
- **Level 3 — Wire/Kernel (Lens D):** VRRP elects a MASTER by priority, advertises via multicast
  (`224.0.0.18`); on failover the new MASTER claims the VIP and **gratuitous-ARPs** (Lesson 05) so
  switches update their MAC tables (Lesson 08) to the new owner — that's why failover is near-
  instant at L2. keepalived watches a tracked script/interface and adjusts priority to trigger the
  swap. ECMP uses per-flow hashing (like Lesson 11 bonding) across equal routes in the FIB.

### Two Teaching Approaches (Lens B) — redundancy + failover

**Approach 1 (technical):** redundancy provides N components where 1 would do; a failover mechanism
detects a component's failure (health check / heartbeat) and promotes a standby (or, active/active,
sheds the failed node's share to the survivors). The client-facing identity (a VIP) moves to the
healthy node, often via gratuitous ARP at L2, so clients are unaffected. SPOF analysis = walk every
component and ask "if this dies, is there an outage?"; anywhere the answer is yes is a SPOF to
remove.

**Approach 2 (analogy):** HA is a **co-pilot in the cockpit**.
- The **pilot** (MASTER) flies; the **co-pilot** (BACKUP) is fully trained, monitoring, ready to
  take the controls instantly if the pilot is incapacitated (failover) — passengers (clients) never
  notice the handoff.
- The **controls** are the **floating VIP**: whoever is flying holds them; on a handoff the controls
  physically move to the co-pilot (gratuitous ARP redirects traffic to the new owner).
- **Active/passive** = one flies, one watches; **active/active** = two crews flying two planes that
  share the route (more capacity, more coordination).
- **Split-brain** = the nightmare where *both* grab the controls and fight — prevented by a clear
  command hierarchy (priority/preemption/quorum).
- **Where it breaks down:** a co-pilot is one backup; real HA stacks redundancy at *every* layer
  (power, links, devices, sites) — and the analogy understates that **the failover mechanism itself
  must be reliable** (a flaky health check causes false failovers/flapping).

### Visual (ASCII) — VRRP floating gateway failover

```
   clients use gateway VIP 10.0.0.1 (they never change it)
        │
   ┌────┴─────────────────────────────┐
   │ keepalived/VRRP pair (multicast)  │
   │  R1 priority 110  ── MASTER ── owns VIP 10.0.0.1   (health check OK)
   │  R2 priority 100  ── BACKUP ── idle, monitoring
   └───────────────────────────────────┘
   R1 fails ➜ R2 becomes MASTER ➜ claims VIP 10.0.0.1 ➜ gratuitous ARP ➜
   switches update MAC table ➜ clients keep using 10.0.0.1 (sub-second blip)
```

---

## §2 — Linux Networking Commands

```bash
# keepalived (VRRP + health checks) — the lab tool
systemctl status keepalived
journalctl -u keepalived -f                 # watch MASTER/BACKUP transitions
ip addr show                                 # the VIP appears on whichever node is MASTER
# Trigger/observe failover
systemctl stop keepalived                    # on the MASTER → BACKUP takes the VIP
ping <VIP>                                    # should keep working across the failover
# ECMP (multiple equal routes, Lesson 07)
ip route add 10.0.5.0/24 nexthop via 10.0.0.2 nexthop via 10.0.0.3   # two active paths
ip route show 10.0.5.0/24
# SPOF analysis is a design review, not a single command
```

**Cisco/CCNA mapping:** **HSRP**/GLBP (Cisco FHRP) are the VRRP equivalents — `standby 1 ip
10.0.0.1`, `standby 1 priority 110`, `standby 1 preempt`. CCNA tests First-Hop Redundancy Protocols
(FHRP), active/standby, and the virtual IP/MAC concept. keepalived/VRRP is the Linux-first version.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Redundant default gateway:** VRRP/HSRP so a router failure doesn't strand a subnet (the most
   common FHRP use).
2. **HA load balancer:** a keepalived VIP fronting two HAProxy nodes (Lesson 30) — so the LB itself
   isn't a SPOF.
3. **Active/active links:** ECMP across two uplinks for bandwidth + failover (complements Lesson 11
   bonding).
4. **SPOF review:** before launch, walk the design and remove every single point of failure
   (single gateway, single LB, single power feed, single uplink).

**How NOC/NetOps engineers use it:** monitoring HA pair health (a degraded pair = redundancy lost =
urgent watch item), recognizing failover events (and false/flapping failovers from bad health
checks), and verifying failover actually works (untested HA = false confidence).

**When NOT to:** don't add HA complexity where it's not warranted (it has costs); don't deploy HA
you've never failover-tested; beware split-brain in active/active without proper guards.

**Exam framing (Net+/CCNA):** FHRP (VRRP/HSRP), active/active vs active/passive, redundancy, RTO/
RPO, and SPOF elimination are in the Network Operations/availability domains.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Both nodes claim the VIP | split-brain (VRRP not communicating) | `journalctl -u keepalived` both nodes | fix VRRP comms/priority/preempt |
| Failover doesn't happen | health check/priority misconfig | check tracked script/interface | fix the health check |
| Flapping MASTER/BACKUP | flaky health check / link | logs show repeated transitions | stabilize the check; add hysteresis |
| Service down despite "HA" | the redundancy never tested / shared SPOF | failover test; SPOF review | test + remove shared SPOFs |
| Slow failover | ARP not updating / timers | confirm gratuitous ARP; VRRP timers | tune timers/preempt |

**Redaction check:** lab VIP/IPs in committed `keepalived.conf`.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Untested failover | "HA" that doesn't work when needed | regularly failover-test |
| Split-brain in active/active | both claim VIP, chaos | priority/preempt/quorum guards |
| Shared SPOF behind "redundant" nodes | one shared dependency = outage | true independence (power/link/path) |
| Flaky health check | flapping failovers | robust checks + hysteresis |
| HA without monitoring degraded state | silent loss of redundancy | alert on a degraded pair |
| Over-engineering HA everywhere | cost/complexity | apply HA where SLAs require |

---

## §6 — NOC Perspective

> NOC + Network Operations (Stages 1–2, 4, `ROADMAP.md`).

HA is what keeps a single failure from becoming an outage — but the NOC must watch the **degraded**
state: an HA pair with one node down is **protected now, exposed next** (a high-value watch item for
the handover, `noc/shift-handover.md`, not a current outage). The NOC recognizes failover events
(expected blips) vs **flapping** failovers (a real problem — bad health check). HA directly buys the
"nines" the SLA promises (`noc/sla-concepts.md`); a *tested* failover is the evidence the SLA is
real.

---

## §7 — Incident-Response Perspective

- **Detect:** a node-down alert (HA pair degraded) or a service outage despite "HA" (untested/shared
  SPOF).
- **Triage:** degraded-but-protected (urgent watch) vs actual outage (failover failed → Sev1).
- **Diagnose:** did failover happen? (logs) — if not, why (health check/priority/split-brain); if a
  shared SPOF caused it, the RCA names the missing independence.
- **Fix → Recover → Document:** restore the failed node, re-establish redundancy, and the
  **prevention** item is usually "remove the shared SPOF" or "add failover testing." Untested-HA
  failures make sobering, high-value runbooks.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build a **keepalived/VRRP** floating-VIP pair (optionally fronting the HAProxy from Lesson
30), failover-test it, and do a SPOF review; document `infra/configs/keepalived.conf`.

### Lens C — Manual → Automated → Why
- **Manual:** configure keepalived on two nodes, observe MASTER/BACKUP, fail the MASTER, watch the
  VIP move.
- **Automated:** a failover-test + degraded-state check (is the pair healthy? did failover keep the
  VIP reachable?) — the HA monitor a NOC runs.
- **Why:** HA that's never tested is false confidence; an automated failover test (in a maintenance
  window) is how mature teams *prove* redundancy works. The degraded-state alert prevents silent
  loss of protection.

### Steps (two lab nodes/namespaces)
1. Write `infra/configs/keepalived.conf` on two nodes: a VRRP instance sharing a VIP (e.g.
   `10.0.0.1`), priorities 110/100, `preempt`, and a **track_script** health check.
2. Start keepalived on both; confirm the higher-priority node is MASTER and owns the VIP
   (`ip addr show`); the other is BACKUP.
3. **Failover drill:** `ping <VIP>` continuously, then stop keepalived (or fail the health check) on
   the MASTER → BACKUP takes the VIP (gratuitous ARP) → ping barely blips → restore and watch
   preemption. Capture the transition from `journalctl -u keepalived`.
4. (Combine with L30) put the VIP in front of two HAProxy nodes so the **LB itself is HA**.
5. **SPOF review:** sketch the lab's full path and mark every component; for each, "if this dies, is
   there an outage?" — list the SPOFs and how you'd remove each.

### Lens D — gratuitous ARP on failover
`tcpdump -nei <if> arp` during a failover shows the new MASTER's **gratuitous ARP** announcing the
VIP→its-MAC — the L2 mechanism (Lessons 05/08) that makes failover near-instant.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** the failover-test + degraded-state check.
2. **Config:** `infra/configs/keepalived.conf` (VRRP VIP + health check).
3. **Drill:** failover demonstrated (VIP moves, ping continuity) + a SPOF review doc.
4. **NAVI ticket:** `NAVI-31` (Change: "keepalived/VRRP HA gateway/LB + failover test").
5. **Incident report:** a failover or split-brain runbook (and/or the SPOF-review findings).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built a keepalived/VRRP high-availability floating VIP fronting redundant
  HAProxy nodes; performed SPOF analysis and validated sub-second failover with gratuitous-ARP
  redirection."
- **Interview talking point:** SPOF analysis, VRRP/HSRP floating VIP + gratuitous ARP, active/active
  vs active/passive, split-brain, and "untested HA is false confidence" — strong availability signal.
- **Serves:** Jr Network Engineer + Network Operations + Cloud/DevOps (Stages 4, 6); the resilience
  layer for the CCNA capstone (34).

---

## §11 — RHCSA Crossover Notes

RHCSA-adjacent: keepalived runs on RHEL (package/service/firewalld for VRRP multicast); HA concepts
appear in RHEL clustering. The sibling NaviOps platform covers HA/redundancy from the
systems/storage side; here it's network failover (VRRP/ECMP).

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** **VRRP/HSRP hijacking** — sending crafted VRRP/HSRP advertisements with a high
priority to become MASTER and seize the gateway VIP, becoming a man-in-the-middle (`T1557`
Adversary-in-the-Middle). Unauthenticated FHRP on a reachable segment is the vulnerability.

**🔵 Defender:** **authenticate VRRP/HSRP** (key/MD5), run FHRP only on trusted segments, restrict
who can send VRRP (port/ACL), and monitor for unexpected MASTER changes (a sudden VIP-owner change
is suspicious — Lesson 28). HA also *defends availability* (resilience against DoS/failure). Verify
that an unauthenticated VRRP advert from a rogue node is rejected (lab).

---

## Quiz (Interview-Style, Graded)

**Q1.** What is a single point of failure, and how do you find them in a design?
> **Your answer:**

**Q2.** Explain VRRP/keepalived: what is the floating VIP, and what happens (at L2/L3) on failover?
> **Your answer:**

**Q3.** Active/passive vs active/active — trade-offs of each?
> **Your answer:**

**Q4.** **Scenario:** Your "HA" gateway pair both claim the virtual IP at once and the network is
unstable. What is this failure called, what causes it, and how do you prevent it?
> **Your answer:**

**Q5.** Why is *testing* failover essential, and what does an untested HA setup risk?
> **Your answer:**

**Q6.** How could an attacker abuse VRRP/HSRP, and what control stops them?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 32.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `high availability single point of failure`
- `vrrp keepalived floating ip`
- `active active vs active passive`
- `split brain prevention`
- `ecmp equal cost multipath`

**Tools**
- `keepalived configuration vrrp`
- `hsrp vs vrrp cisco`
- `keepalived health check track_script`

**Going further (future lessons)**
- `cloud networking ha` (L32) · `aws multi-az` (L33) · `rto rpo disaster recovery`

**Red / Blue (Lens E):**
- 🔴 `vrrp hsrp hijacking T1557`, `fhrp man in the middle`, `gratuitous arp takeover`
- 🔵 `vrrp authentication`, `fhrp trusted segment`, `monitor master change`

---

## Lesson Status
- [ ] §8 lab completed (keepalived/VRRP VIP + failover test + SPOF review)
- [ ] §4 drill done (failover / split-brain)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 32 — Cloud Networking**.

---

*Lesson 31 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: RFC 5798 (VRRP),
keepalived docs, CompTIA Network+ N10-009 (FHRP/availability), MITRE ATT&CK T1557.*
