# Lesson 08 — Switching Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** MAC learning, the CAM table, broadcast/collision domains, frame forwarding, Linux bridges.
**Primary artifact:** `infra/topologies/switching-lab.md`.

> **How to use this lesson:** switching is Layer 2 — how frames move *within* one network. Read
> §1–§7, build a Linux bridge "switch" in §8, watch its MAC table learn. Lab only.

---

## §1 — Concept (Scientific Theory)

### What it is
A **switch** is a Layer-2 device that forwards Ethernet **frames** between ports based on **MAC
addresses**. It builds a **MAC address table** (aka **CAM table** — Content-Addressable Memory)
by *learning*: when a frame arrives on a port, the switch records "this source MAC lives on this
port." It then *forwards* frames toward the port where the destination MAC was learned (and
**floods** out all ports if the destination is unknown or a broadcast).

### Why it exists
Early networks used **hubs**, which repeated every bit out every port — one big **collision
domain** where only one device could talk at a time (half-duplex, collisions). Switches replaced
hubs by giving each port its **own collision domain** (full-duplex, simultaneous conversations)
and forwarding intelligently instead of blindly repeating — massively increasing usable
bandwidth.

### The three switch behaviors
| Behavior | When | Action |
|---|---|---|
| **Learn** | frame arrives | record src MAC → ingress port in the CAM table |
| **Forward** | dst MAC is known | send only out the learned port (unicast) |
| **Flood** | dst unknown / broadcast / multicast | send out all ports except ingress |

### Collision vs broadcast domains (a guaranteed exam concept)
- **Collision domain:** a segment where frames can collide. A **hub** = one collision domain for
  all ports; a **switch** = one collision domain **per port** (so switches "break up" collision
  domains).
- **Broadcast domain:** the set of devices that receive each other's broadcasts. A **switch** =
  all ports in **one** broadcast domain (by default); a **router** (or a **VLAN**, Lesson 09)
  breaks up broadcast domains.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** a switch is a smart mail sorter for a single building — it learns which
  desk (port) each person (MAC) sits at and delivers directly, instead of shouting to everyone.
- **Level 2 — NetOps/NOC:** you read the MAC table to answer "which port is this device on?"
  (find a host physically), spot a **MAC flapping** between ports (a loop — Lesson 10 — or a
  duplicate), and understand that a full/unknown CAM entry causes flooding. On Linux, a **bridge**
  *is* a software switch: `bridge fdb show` is the CAM table, `bridge link` shows member ports.
- **Level 3 — Wire/Kernel (Lens D):** an Ethernet frame is `[dst MAC | src MAC | EtherType/len |
  payload (46–1500B) | FCS]`. The CAM table is a hash keyed on MAC (+ VLAN) → port, aged out
  after ~5 min (default) if not refreshed. The Linux bridge (`net/bridge/`) implements learning,
  the forwarding database (FDB), and optionally STP — it's a real L2 switch in software, which is
  exactly how container/VM networking works under the hood.

### Two Teaching Approaches (Lens B) — learning & flooding

**Approach 1 (technical):** the switch's forwarding decision: look up the destination MAC in the
CAM table. Hit → forward out that one port. Miss (or broadcast/multicast) → flood out all ports
except ingress. Every received frame also updates the table with the source MAC↔port mapping
(this is how the table is built — passively, from traffic).

**Approach 2 (analogy):** a new receptionist on one office floor with a blank seating chart.
- First time *anyone* sends a memo, the receptionist doesn't know where the recipient sits, so
  they **photocopy it to every desk** (flood) — but they *do* note the **sender's** desk on the
  chart (learn).
- Soon the chart fills in, and memos go **straight to the right desk** (forward).
- A memo addressed "to everyone" (broadcast) always goes to every desk.
- **Where it breaks down:** a receptionist learns recipients over time too; a switch only ever
  learns from **source** addresses — it never learns a destination until that device *sends*
  something. That asymmetry is why the *first* frame to a silent host floods.

### Visual (ASCII) — learning then forwarding

```
  CAM table (built by learning source MACs):
    MAC-A → port1     MAC-B → port2     MAC-C → port3
  ┌──────────────────────────────────────────────┐
  │              L2 SWITCH (bridge)               │
  │ port1   port2   port3   port4                 │
  └───┬───────┬───────┬───────┬───────────────────┘
      A       B       C    (silent)
  A→B (known): out port2 only.    A→broadcast: out port2,3,4 (flood).
  A→D (D silent/unknown): FLOOD out 2,3,4 until D speaks and is learned.
```

---

## §2 — Linux Networking Commands

```bash
# A Linux bridge IS a software switch:
ip link add br0 type bridge          # create a switch
ip link set eth1 master br0          # add a port to the switch
ip link set br0 up
bridge link show                     # member ports (like 'show interfaces status')
bridge fdb show                      # the MAC/forwarding table (the CAM table)
bridge fdb show br br0               # FDB for a specific bridge
ip -s link show eth1                 # interface counters (frames, errors)
ip link show br0                     # bridge state
```

**Cisco/CCNA mapping:** `show mac address-table` (the CAM table), `show interfaces status`,
`show interfaces counters errors`. On a Cisco switch, ports are physical; on Linux, the bridge
+ veth pairs/interfaces are the equivalent — the *concepts* (learn/forward/flood, FDB aging) are
identical. CCNA tests reading the MAC table and the learn/flood behavior.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Locate a device physically:** "which switch port is `aa:bb:cc:...` on?" → `bridge fdb` /
   `show mac address-table` maps MAC→port→patch panel→desk.
2. **MAC flapping alarm:** a MAC bouncing between two ports = a Layer-2 **loop** (Lesson 10) or a
   misconfig — a real switch logs `%MAC_FLAP`; you trace it to kill the loop.
3. **Container/VM networking:** Docker/KVM use Linux bridges — understanding the FDB explains
   why a container can or can't reach another.
4. **CAM table exhaustion:** an attacker floods fake MACs to fill the table, forcing the switch
   to flood (sniffing) — §12.

**How NOC engineers use it:** reading the MAC table to localize a host, and recognizing MAC-flap
log messages as loop indicators, are core Tier-1/Tier-2 switching skills.

**When NOT to:** don't manage a flat L2 domain at scale without VLANs (Lesson 09) — one big
broadcast domain doesn't scale and is a security risk.

**Exam framing (Net+/CCNA):** learn/forward/flood, CAM table, collision vs broadcast domains,
and "switches break collision domains; routers/VLANs break broadcast domains" are guaranteed.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Host unreachable on LAN | MAC not learned / wrong port | `bridge fdb`; is the MAC present? | check cabling/port/VLAN |
| Slow LAN, lots of flooding | CAM exhaustion or unknown-unicast flood | port counters; CAM size | fix loop / port security |
| MAC appears on two ports (flap) | L2 loop or duplicate device | switch logs / `bridge fdb` changes | break the loop (STP, L10) |
| Intermittent for one host | duplicate MAC / NIC fault | `ip -s link` errors; `bridge fdb` | replace/reseat, check duplicate |
| Whole segment broadcast storm | loop, no STP | skyrocketing broadcast counters | enable STP (L10) |

**Redaction check:** use lab MACs (`aa:bb:cc:00:00:0N`) in committed docs.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Confusing collision and broadcast domains | wrong device choice | switch=per-port collision; router/VLAN=broadcast |
| Thinking a switch routes between subnets | inter-subnet fails | switch is L2; needs a router/SVI (L09) |
| Cabling two switches twice with no STP | broadcast storm / meltdown | enable STP (L10) |
| Ignoring MAC-flap logs | misses an active loop | treat flaps as loop alarms |
| No port security on access ports | CAM-flood sniffing risk | enable port security (§12) |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

Switching issues are usually localized (one segment/closet), but a Layer-2 **loop** is the
exception — it can melt an entire broadcast domain in seconds (a true Sev1). The NOC tells loops
apart from other outages by the signature: **broadcast/util skyrockets, MAC-flap logs, everything
on the VLAN slows at once**. Reading the MAC table to locate a host by port is a routine
NOC/desktop-support assist. Interface error counters (CRC, late collisions) on the dashboard are
L1/L2 signals you correlate to bad cables/SFPs/duplex.

---

## §7 — Incident-Response Perspective

- **Detect:** broadcast-storm/util alert, MAC-flap logs, segment-wide slowness.
- **Triage:** is it a loop (storm signature → Sev1) or a single-host L2 issue (Sev3)?
- **Diagnose (RCA):** trace the flapping MAC's two ports → find the redundant link causing the
  loop; or find the bad cable from error counters.
- **Contain/Fix → Recover → Document:** disable the looping port / enable STP (Lesson 10),
  confirm broadcast levels normalize, document. Maps to **drill 7 (VLAN/L2)** family.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build a Linux-bridge "switch," watch the CAM table learn, and document it in
`infra/topologies/switching-lab.md`.

### Lens C — Manual → Automated → Why
- **Manual:** create a bridge, add interfaces, generate traffic, watch `bridge fdb` populate.
- **Automated:** a small script that builds the bridge + veth hosts and dumps the FDB — a
  repeatable L2 lab you can rebuild on demand.
- **Why:** reproducible L2 labs let you safely practice loops/STP/VLANs; production teams script
  topology builds (containerlab/GNS3) for testing changes before touching real switches.

### Steps (network namespaces + a bridge)
```bash
# Build: br0 (the switch) + 3 namespaced "hosts" via veth pairs (operator scripts this).
ip link add br0 type bridge && ip link set br0 up
# for each host h1..h3: create ns, veth, attach one end to br0, address it in 10.0.0.0/24
bridge fdb show br br0          # initially sparse
ip netns exec h1 ping -c1 10.0.0.3   # generates traffic
bridge fdb show br br0          # now h1/h3 MACs are learned with their ports
```
1. Build br0 + 3 hosts; document the topology (ASCII + commands) in
   `infra/topologies/switching-lab.md`.
2. Before any traffic, `bridge fdb show` — note it's empty/sparse (only local). Ping between
   hosts, re-check — watch MACs get learned with ports.
3. Observe flooding: `tcpdump` on an *uninvolved* host's veth while pinging a not-yet-learned
   host — see the first frame flood, then stop once learned.
4. (Preview Lesson 10) add a second link between two bridges *without STP* in an isolated lab and
   observe the broadcast storm — then enable STP (`ip link set br0 type bridge stp_state 1`).

### Lens D — read a frame
`tcpdump -e -ni <veth>` shows the Ethernet header (`-e`) — src/dst MAC + EtherType — the actual
L2 frame the switch forwards on.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** the bridge/host build script (under `infra/topologies/` or `scripts/`).
2. **Config/topology:** `infra/topologies/switching-lab.md` (ASCII + build + FDB output).
3. **Drill:** observe MAC learning + flooding; optionally the loop/storm in an isolated lab.
4. **NAVI ticket:** `NAVI-08` (Task: "Linux bridge switching lab + CAM table") To Do→In Progress→Done.
5. **Incident report:** *(optional)* — a MAC-flap/loop mini runbook if you ran the storm lab.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built a Linux-bridge L2 lab demonstrating MAC learning, the CAM/forwarding
  table, and unknown-unicast flooding; reproduced and mitigated a broadcast-storm loop."
- **Interview talking point:** explain learn/forward/flood and collision-vs-broadcast domains
  from memory, and how you'd spot an L2 loop (MAC flaps + broadcast spike).
- **Serves:** Network Operations / Jr Network Engineer (Stages 2–4); foundation for VLANs/STP.

---

## §11 — RHCSA Crossover Notes

RHCSA-relevant: Linux bridges are used for VM/container networking, and `nmcli con add type
bridge` / `bridge-slave` are NetworkManager objects you may configure. Reading `ip link`/`bridge`
output and understanding L2 vs L3 connectivity helps RHEL virtualization-networking
troubleshooting. Cisco CAM-table specifics are "N/A for RHCSA."

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** **MAC flooding / CAM-table overflow** (`T1040` Network Sniffing) — flooding the
switch with thousands of fake source MACs fills the CAM table, forcing it to **flood all frames**
(fail-open), so the attacker sniffs traffic intended for others. **MAC spoofing** to impersonate
another host/bypass filters.

**🔵 Defender:** **port security** (limit MACs per port, sticky-learn, err-disable on violation),
**storm control** (rate-limit broadcast/unknown-unicast), monitor for MAC flaps, and segment with
VLANs (Lesson 09) so a sniffing attacker sees less. On Linux bridges, limit learning and use
filtering. Verify by (lab-only) running `macof`-style flooding and confirming port security
shuts the port.

---

## Quiz (Interview-Style, Graded)

**Q1.** Describe the three switch behaviors (learn, forward, flood) and when each happens.
> **Your answer:**

**Q2.** What does a switch do with a frame whose destination MAC is not in its CAM table, and why?
> **Your answer:**

**Q3.** Explain collision domains vs broadcast domains, and what a switch vs a router/VLAN does
to each.
> **Your answer:**

**Q4.** **Scenario:** Your monitoring shows a sudden broadcast/util spike and switch logs report
a MAC flapping between two ports. What's happening and what's the fix?
> **Your answer:**

**Q5.** How do you find which switch port a given device (MAC) is connected to?
> **Your answer:**

**Q6.** What is MAC flooding, what does it achieve for an attacker, and how do you defend against it?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 09.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `switch mac address table learning`
- `collision domain vs broadcast domain`
- `unknown unicast flooding`
- `ethernet frame format`

**Tools**
- `linux bridge fdb command`
- `bridge link show examples`
- `show mac address-table cisco`

**Going further (future lessons)**
- `vlan 802.1q` (L09) · `spanning tree protocol loops` (L10) · `etherchannel lacp` (L11)

**Red / Blue (Lens E):**
- 🔴 `mac flooding cam overflow T1040`, `macof sniffing`, `mac spoofing`
- 🔵 `switch port security`, `storm control broadcast`, `detect mac flapping`

---

## Lesson Status
- [ ] §8 lab completed (bridge switching lab + CAM table observed)
- [ ] §4 drill done (MAC learning/flooding; optional loop)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 09 — VLANs**.

---

*Lesson 08 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: IEEE 802.3,
Linux bridge docs, CompTIA Network+ N10-009, Cisco switching references, MITRE ATT&CK T1040.*
