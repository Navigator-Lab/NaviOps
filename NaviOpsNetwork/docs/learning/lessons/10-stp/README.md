# Lesson 10 — Spanning Tree Protocol (STP)

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** loops & broadcast storms, BPDUs, root-bridge election, port states, RSTP, PortFast/BPDU Guard.
**Primary artifact:** `docs/networking/stp-explained.md`.
**Difficulty:** **Difficult concept** — §1 uses two teaching approaches + an ASCII diagram (Lens B).

> **How to use this lesson:** STP is the answer to "why don't redundant switch links melt the
> network?" Read §1–§7, reproduce a loop + STP fix on Linux bridges in §8 (isolated lab), build
> the explainer.

---

## §1 — Concept (Scientific Theory)

### What it is
**STP** (Spanning Tree Protocol, IEEE **802.1D**; modern **RSTP** is 802.1w) prevents **Layer-2
loops**. When switches are cabled with redundant links (for resilience), frames — especially
broadcasts — can circle forever (L2 has **no TTL** to kill them), causing a **broadcast storm**
that saturates the network in seconds. STP automatically detects loops and **blocks** redundant
ports, leaving a single loop-free **tree**; if an active link fails, a blocked link is unblocked
to restore connectivity.

### Why it exists
Redundancy is good (a backup link survives a failure) but creates loops at L2, and L2 frames have
no hop limit — so one loop can take down an entire broadcast domain. STP gives you **redundancy
without loops**: keep the backup cabling, but logically block it until needed.

### Why L2 loops are catastrophic (the three symptoms)
1. **Broadcast storm:** a broadcast loops endlessly, multiplying, until links are 100% utilized.
2. **MAC table instability:** the same source MAC arrives on multiple ports (flapping), corrupting
   the CAM table.
3. **Duplicate frames:** unicast frames get duplicated around the loop.
A loop is one of the fastest, most total L2 outages there is.

### How STP works (the election + states)
- **BPDUs** (Bridge Protocol Data Units) are the messages switches exchange to build the tree.
- **Root bridge election:** the switch with the lowest **bridge ID** (priority + MAC) becomes the
  **root** — the reference point of the tree.
- **Port roles/states:** each non-root switch picks one **root port** (lowest cost to root);
  each segment picks one **designated port**; remaining redundant ports are **blocked**
  (discarding). Classic 802.1D states: **Blocking → Listening → Learning → Forwarding** (with
  delays totaling ~30–50s — slow!). **RSTP** (802.1w) collapses these for sub-second convergence
  (Discarding / Learning / Forwarding + proposal-agreement).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** if you connect two switches with two cables for backup, data can go in
  circles forever and crash the network. STP turns off one of the cables (logically) so there's
  only one path, and turns it back on if the main one breaks.
- **Level 2 — NetOps/NOC:** you recognize a loop (storm + MAC flaps), know STP should prevent it,
  and configure it correctly: set the **root bridge** deliberately (don't let the oldest switch
  win by default), enable **PortFast** on access ports (skip the delay for end devices), and
  **BPDU Guard** so a rogue switch/loop on an access port is shut down. On Linux bridges, STP is
  `ip link set br0 type bridge stp_state 1`.
- **Level 3 — Wire/Kernel (Lens D):** BPDUs are multicast (`01:80:c2:00:00:00`) frames carrying
  root ID, sender bridge ID, root path cost, port ID, and timers (Hello 2s, MaxAge 20s, FwdDelay
  15s). The Linux bridge STP state machine (`net/bridge/br_stp*.c`) runs the same election. RSTP's
  speed comes from immediate proposal/agreement handshakes instead of timer-based transitions.

### Two Teaching Approaches (Lens B) — why a loop kills, and what STP does

**Approach 1 (technical):** with redundant L2 paths, a frame with an unknown/broadcast destination
is flooded out all ports; it returns via the redundant link, gets flooded again, and so on —
infinitely, because Ethernet has no TTL. STP runs a distributed algorithm: elect a root, compute
each switch's least-cost path to it, and block every port that isn't on a least-cost path or a
designated path — yielding exactly one active path between any two points (a tree).

**Approach 2 (analogy):** a roundabout with no exit rule.
- Imagine cars (broadcast frames) entering a roundabout (the loop) where the rule is "if you
  don't know the exit, take *every* exit." Cars multiply and circle forever until total gridlock
  (broadcast storm).
- **STP is a traffic engineer who closes one road into the roundabout** (blocks a port), turning
  the loop into a dead-end tree — traffic flows, no circling. If the open road closes (link
  fails), the engineer reopens the closed one (unblocks).
- **Where it breaks down:** real cars eventually leave a roundabout; broadcast frames truly never
  stop without STP because there's no TTL — the analogy *understates* how fast and total the
  meltdown is.

### Visual (ASCII) — redundant links, STP blocks one

```
   Without STP (LOOP — storm):        With STP (loop-free tree):
     SW-A ════════ SW-B                  SW-A ──────── SW-B   (root = SW-A)
       ║            ║                       │            │
       ║            ║   <-- two paths       │       (blocked port on
     SW-C ════════ ╝     frames circle      SW-C ───X    one redundant link)
                                            single active path A-B, A-C; C-B blocked
   broadcast loops forever ➜ 100% util   STP elects root, blocks the redundant port
```

---

## §2 — Linux Networking Commands

```bash
ip link add br0 type bridge stp_state 1     # bridge with STP enabled
ip link set br0 type bridge stp_state 1     # enable STP on an existing bridge
bridge -d link show                          # per-port STP state (forwarding/blocking)
cat /sys/class/net/br0/bridge/stp_state      # 1 = STP on
mstpctl showbridge br0                        # (if mstpd/RSTP installed) detailed RSTP state
ip link set br0 type bridge priority 4096    # set bridge priority (lower = more likely root)
```

**Cisco/CCNA mapping:** `show spanning-tree` (root, port roles/states), `spanning-tree vlan 10
root primary` (set root), `spanning-tree portfast` (access ports), `spanning-tree bpduguard
enable`. CCNA tests root election, port states, PortFast, and BPDU Guard.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Resilient switch topology:** redundant uplinks between access/distribution/core switches —
   STP keeps them loop-free, failing over if a link dies.
2. **Setting the root deliberately:** the core switch should be root, not whichever switch has the
   lowest MAC by accident — `root primary` enforces a sane tree.
3. **Accidental loop:** someone patches two wall ports together → without BPDU Guard, a storm;
   with it, the port err-disables and the loop is contained.
4. **PortFast for servers/PCs:** access ports skip the 30s listening/learning delay so DHCP works
   immediately on boot.

**How NOC engineers use it:** recognizing a storm's signature (util spike + MAC flaps), knowing
STP should prevent loops, and escalating "STP topology change" / root-flap alarms.

**When NOT to:** don't enable PortFast on a switch-to-switch link (defeats loop protection);
don't leave root election to default in a designed network.

**Exam framing (Net+/CCNA):** purpose of STP, BPDUs, root election (lowest bridge ID), port
states, RSTP improvements, PortFast + BPDU Guard — all guaranteed.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Broadcast storm, MAC flaps, total slowness | L2 loop, STP off/failed | util counters, `bridge link` states, logs | enable STP / find & block the loop |
| Slow DHCP/boot on access ports | no PortFast (30s STP delay) | port stuck in listening/learning | enable PortFast on access ports |
| Random switch became root | default priority, low MAC | `show spanning-tree` root ID | set intended root (`root primary`) |
| Port err-disabled | BPDU Guard tripped (rogue BPDU/loop) | switch logs | remove loop/rogue device, re-enable |
| Frequent topology changes | flapping link/port | STP TCN logs | stabilize the flapping link |

**Redaction check:** lab bridge names/MACs in committed docs.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Disabling STP "to simplify" | one patch cable = network meltdown | leave STP on |
| PortFast on a trunk/switch link | loop risk (skips loop checks) | PortFast only on access/edge |
| Not setting the root bridge | suboptimal/unstable tree | set root on the core |
| No BPDU Guard on access ports | rogue switch/loop storms | enable BPDU Guard |
| Assuming RSTP everywhere | slow 802.1D convergence surprises | verify RSTP is in use |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

A broadcast storm is one of the few **Sev1 Layer-2** events — it takes a whole broadcast domain
down in seconds, and its dashboard signature is unmistakable (broadcast/util pegged + MAC-flap
logs). The NOC's job is fast recognition and containment (find/disable the looping port; verify
STP is on) and escalation. **STP topology-change / root-change** traps are worth alerting on —
frequent ones signal a flapping link. This is a textbook "restore first (kill the loop), RCA
second" outage (`noc/outage-management.md`).

---

## §7 — Incident-Response Perspective

- **Detect:** broadcast-storm alert, segment-wide outage, STP-change traps.
- **Triage:** storm signature ⇒ likely loop ⇒ Sev1.
- **Contain (restore first):** locate and shut the looping/redundant port to stop the storm
  immediately (`noc/outage-management.md`).
- **Diagnose (RCA):** what created the loop (a patch, a disabled STP, a failed BPDU Guard)?
- **Recover/Document:** re-enable STP/BPDU Guard correctly, verify broadcast levels normal,
  document. Related to **drill 8 family** (L2 storm in the switching lab).

---

## §8 — Practical Lab (build this yourself)

**Goal:** reproduce a loop and watch STP fix it on Linux bridges (isolated lab — a storm can
disrupt a real network, so use namespaces). Document `docs/networking/stp-explained.md`.

### Lens C — Manual → Automated → Why
- **Manual:** build two bridges with two links, observe the storm with STP off, enable STP, watch
  a port go to blocking.
- **Automated:** a script that builds the looped topology, measures broadcast/packet rates with
  STP off vs on, and proves STP blocks a port.
- **Why:** safe, repeatable loop testing lets you validate STP/BPDU-Guard config before trusting
  it in production. Network teams test failover/STP in a lab, never first in prod.

### Steps (ISOLATED netns lab only)
```bash
# Two bridges (sw1, sw2) connected by TWO veth links = a loop. STP OFF first.
ip link add sw1 type bridge stp_state 0
ip link add sw2 type bridge stp_state 0
# ... wire two veth pairs between sw1 and sw2, add a host, ping a broadcast ...
# Observe: broadcast/util climbs (storm). THEN enable STP:
ip link set sw1 type bridge stp_state 1
ip link set sw2 type bridge stp_state 1
bridge -d link show     # one of the redundant ports is now blocking/discarding
```
1. Build the looped two-bridge topology in a namespace lab.
2. With STP **off**, generate a broadcast and observe the storm (rising packet counters) — then
   tear it down quickly.
3. Enable STP, confirm one redundant port goes to **blocking**, and the storm is gone.
4. Write `docs/networking/stp-explained.md`: the loop problem, BPDU/root election, the port
   states, RSTP vs STP, and PortFast/BPDU Guard — your interview cheat-sheet.

### Lens D — see a BPDU
`tcpdump -e -ni <veth> ether dst 01:80:c2:00:00:00` captures STP BPDUs — inspect the root ID and
timers in the frame.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** the looped-topology + STP test script.
2. **Config/doc:** `docs/networking/stp-explained.md`.
3. **Drill:** loop reproduced + STP-fix demonstrated (broadcast rate before/after).
4. **NAVI ticket:** `NAVI-10` (Incident: "L2 loop broadcast storm — RCA + STP remediation").
5. **Incident report:** `docs/runbooks/incident-l2-loop.md` (symptom→contain→RCA→fix→verify).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Reproduced a Layer-2 broadcast storm and remediated it with STP on Linux
  bridges; documented root election, port states, and BPDU Guard hardening."
- **Interview talking point:** explain *why* L2 loops are catastrophic (no TTL) and how STP/RSTP +
  BPDU Guard prevent them — a high-signal answer.
- **Serves:** Linux Net Admin / Jr Network Engineer (Stages 3–4); CCNA capstone (34).

---

## §11 — RHCSA Crossover Notes

Mostly **N/A for RHCSA** (STP is switch-domain), but Linux bridges used for KVM/containers *do*
run STP, and `nmcli`/`ip link` bridge `stp` settings exist — useful awareness for RHEL
virtualization networking (e.g. avoiding bridge loops between VM hosts).

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** **STP manipulation** — sending crafted BPDUs to become the **root bridge**,
redirecting traffic through the attacker (MITM, `T1557`), or sending BPDUs on an access port to
cause topology churn / DoS.

**🔵 Defender:** **BPDU Guard** (shut down access ports that receive BPDUs), **Root Guard** (prevent
a downstream switch from becoming root), and **BPDU Filter** where appropriate. These turn STP
from an attack vector into a hardened control. Verify by (lab-only) injecting a superior BPDU on a
guarded port and confirming err-disable.

---

## Quiz (Interview-Style, Graded)

**Q1.** Why are Layer-2 loops catastrophic, and what specifically does STP do about them?
> **Your answer:**

**Q2.** How is the root bridge elected, and why should you set it deliberately?
> **Your answer:**

**Q3.** Name the classic 802.1D port states and what RSTP improves.
> **Your answer:**

**Q4.** **Scenario:** Monitoring shows broadcast utilization pegged at 100% and switch logs full
of MAC-flap messages across a VLAN. What's happening, and what's your first action?
> **Your answer:**

**Q5.** What do PortFast and BPDU Guard do, and on which ports do you enable each?
> **Your answer:**

**Q6.** How could an attacker abuse STP, and what control stops them?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 11.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `spanning tree protocol explained`
- `stp root bridge election`
- `stp port states blocking forwarding`
- `rstp vs stp convergence`
- `broadcast storm layer 2 loop`

**Tools**
- `linux bridge stp_state`
- `mstpctl rstp linux`
- `show spanning-tree cisco`

**Going further (future lessons)**
- `etherchannel link aggregation` (L11) · `portfast bpdu guard` · `per vlan spanning tree pvst`

**Red / Blue (Lens E):**
- 🔴 `stp root bridge attack bpdu spoofing T1557`, `stp dos topology change`
- 🔵 `bpdu guard root guard`, `stp hardening best practices`

---

## Lesson Status
- [ ] §8 lab completed (loop reproduced + STP fix, isolated lab)
- [ ] §4 drill done (L2 loop)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 11 — EtherChannel / Link Aggregation**.

---

*Lesson 10 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: IEEE 802.1D/802.1w,
Linux bridge STP docs, CompTIA Network+ N10-009, Cisco STP references, MITRE ATT&CK T1557.*
