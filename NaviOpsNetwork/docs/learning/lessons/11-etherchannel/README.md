# Lesson 11 — EtherChannel / Link Aggregation

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** link aggregation, LACP/PAgP, load-balancing modes, Linux bonding.
**Primary artifact:** `infra/configs/bonding-lab.md`.

> **How to use this lesson:** link aggregation = combine multiple links into one for bandwidth +
> redundancy. Read §1–§7, build a Linux **bond** in §8, test failover. Lab/VM with 2 NICs.

---

## §1 — Concept (Scientific Theory)

### What it is
**Link aggregation** (IEEE **802.3ad** / **LACP**) bundles multiple physical links between two
devices into one logical link — called an **EtherChannel** (Cisco), **port-channel**, **bond**
(Linux), or **LAG**. The bundle provides **more aggregate bandwidth** (e.g. 4×1G ≈ 4G) and
**redundancy** (if one member link fails, traffic continues on the rest) while appearing to STP
(Lesson 10) as a **single** logical link (so no loop, no blocked port).

### Why it exists
Two problems: (1) a single link can be a bandwidth bottleneck and a single point of failure; (2)
if you simply add a second cable between switches, STP **blocks** it (you get redundancy but not
extra bandwidth). Link aggregation solves both — STP sees one link, so both cables are
*active and load-shared*, and a member failure is transparent.

### How links are bundled
- **LACP** (802.3ad, open standard) — both ends negotiate the bundle dynamically (recommended).
- **PAgP** (Cisco proprietary) — Cisco's equivalent negotiation.
- **Static/"on"** — manually forced, no negotiation (risky: misconfig = loop/blackhole).
- **Load balancing:** traffic is distributed across members by a **hash** (of src/dst MAC, IP,
  or port) — so a *single flow* stays on one member (no reordering), but *many flows* spread
  across members. You don't get 4× speed for one transfer; you get 4× aggregate across flows.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** tie several network cables together so they act like one fatter, more
  reliable cable — if one is cut, the others keep working.
- **Level 2 — NetOps/NOC:** you configure a bond/port-channel with **matching config on both
  ends** (same members, same mode/LACP, same VLAN/trunk settings), pick a **hash policy**
  appropriate to traffic (L3+L4 hashing spreads flows better than MAC-only), and verify member
  status. A **mismatched** channel (one end LACP, the other static; or only one side configured)
  is a classic cause of flaps/loops. On Linux, `bonding` (mode `802.3ad`) is the LACP equivalent.
- **Level 3 — Wire/Kernel (Lens D):** LACP exchanges **LACPDUs** (slow-protocol multicast
  `01:80:c2:00:00:02`) to agree on which links join the **LAG**. The Linux bonding driver
  (`drivers/net/bonding/`) presents `bond0` as one netdev; egress frames are assigned to a member
  by the **xmit_hash_policy** (`layer2`, `layer2+3`, `layer3+4`). The hash is deterministic per
  flow so packets in a flow don't reorder.

### Two Teaching Approaches (Lens B) — aggregation & per-flow hashing

**Approach 1 (technical):** the bundle is one logical interface with N members. The sender hashes
each frame's addressing tuple to pick a member; all frames of a given flow hash to the same
member (preserving order), while different flows hash to different members (spreading load).
LACP keeps the member set in sync with the peer and removes failed links from the hash set
automatically.

**Approach 2 (analogy):** a multi-lane toll plaza feeding one highway.
- Several toll lanes (member links) feed one road (the logical link). A car (flow) is assigned a
  lane by its plate number (the hash) and stays in that lane (no lane-weaving = no packet
  reordering).
- **Throughput:** one car can't use four lanes at once (a single flow ≈ one member's speed), but
  *many* cars spread across lanes (aggregate throughput scales).
- **Redundancy:** if a lane closes (link fails), its cars are reassigned to open lanes (LACP
  removes the dead member).
- **Where it breaks down:** the analogy might imply you can split one car across lanes for 4×
  speed — you can't; per-flow hashing is the key limitation to remember.

### Visual (ASCII) — a 2-link bond between two switches

```
            ┌──────── bond0 (LACP / 802.3ad) ────────┐
   SW-A ════╪══ link1 ══════════════════════════════╪══ SW-B
            ╪══ link2 ══════════════════════════════╪
            └─ both ACTIVE (STP sees ONE logical link) ─┘
   flow X (hash→link1) ───►   flow Y (hash→link2) ───►   one flow ≤ one link's rate
   link1 fails ➜ LACP drops it ➜ all traffic shifts to link2 (transparent)
```

---

## §2 — Linux Networking Commands

```bash
# Create an LACP bond (802.3ad) with two members (operator adapts NIC names):
ip link add bond0 type bond mode 802.3ad miimon 100 xmit_hash_policy layer3+4
ip link set eth1 down && ip link set eth1 master bond0
ip link set eth2 down && ip link set eth2 master bond0
ip link set bond0 up
cat /proc/net/bonding/bond0          # full bond status: mode, members, LACP state, active links
ip -d link show bond0                # bond details
ip link set eth1 down                # simulate a member failure → watch failover
# NetworkManager (RHCSA-style):
nmcli con add type bond ifname bond0 mode 802.3ad
nmcli con add type ethernet ifname eth1 master bond0
```

**Cisco/CCNA mapping:** `channel-group 1 mode active` (LACP) / `mode desirable` (PAgP) / `mode on`
(static); `show etherchannel summary`, `show lacp neighbor`, `port-channel load-balance
src-dst-ip`. CCNA tests LACP vs PAgP, the modes, and that both ends must match.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Switch-to-switch uplinks:** bundle 2–4 links between access and distribution switches for
   bandwidth + resilience without STP blocking.
2. **Server NIC bonding:** a server with two NICs to two switches (mode 802.3ad or
   active-backup) survives a NIC/switch failure — standard for important hosts.
3. **Storage/hypervisor links:** high-throughput, redundant connectivity for SAN/VM hosts.

**How NOC engineers use it:** monitoring member-link status (a bond running "degraded" on one
member is a latent risk before a full outage) and recognizing channel-mismatch flaps.

**When NOT to:** don't expect a single large transfer to use all members (per-flow hashing); don't
use static "on" mode across a link where the other end isn't matched (loop/blackhole risk).

**Exam framing (Net+/CCNA):** LACP vs PAgP vs static, "both ends must match," the bandwidth+
redundancy purpose, and load-balancing-is-per-flow are exam points.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Bond won't come up / flaps | mode mismatch (LACP vs static/PAgP) | `/proc/net/bonding/bond0`; `show etherchannel` | match both ends |
| Only one member active | other end not configured / cabling | LACP neighbor state | configure/cable both members |
| One transfer not faster | per-flow hashing (expected) | n/a — by design | use more flows / right hash policy |
| Uneven load across members | hash policy too coarse (layer2) | check `xmit_hash_policy` | use `layer3+4` |
| Failover not happening | `miimon` off / wrong mode | bond settings | set `miimon`, correct mode |

**Redaction check:** lab interface names in committed docs.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Mismatched modes on the two ends | flaps, loop, or no bundle | both ends same (LACP↔LACP) |
| Expecting N× speed for one flow | "why isn't my copy 4× faster?" | per-flow hashing; scale with flows |
| Static "on" mode without matching | loop/blackhole | prefer LACP negotiation |
| Forgetting trunk/VLAN config on the bond | VLANs don't pass | apply trunk config to the logical interface |
| No `miimon`/link monitoring (Linux) | failover doesn't trigger | set `miimon 100` |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

A bond/port-channel running **degraded** (one of two members down) is a quiet, high-value alert:
service is fine *now*, but redundancy is lost — the next failure is an outage. Surfacing "member
down on port-channel X" before it becomes total is exactly the proactive monitoring a good NOC
does (it's a watch item in the handover, `noc/shift-handover.md`). Recognizing channel-mismatch
flaps (often after a change on one switch) routes the ticket correctly.

---

## §7 — Incident-Response Perspective

- **Detect:** bond degraded/down alarm, throughput drop, or flap after a change.
- **Triage:** degraded (redundancy lost, Sev3 but urgent) vs fully down (Sev2/1).
- **Diagnose (RCA):** member link fault (cable/SFP) vs config mismatch (mode/LACP) vs missing
  `miimon`. `/proc/net/bonding/bond0` + LACP neighbor state localize it.
- **Fix → Recover → Document:** restore the member / fix the mismatch, verify both members active
  and failover works, document.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build a Linux bond, verify it, and test failover; document `infra/configs/bonding-lab.md`.

### Lens C — Manual → Automated → Why
- **Manual:** create `bond0` with two members, read `/proc/net/bonding/bond0`, down a member,
  watch failover.
- **Automated:** a script that builds the bond and a checker that alerts if any member is down or
  the bond is degraded (the NOC watch-item check).
- **Why:** redundancy that isn't monitored is a false sense of safety; production teams alert on
  *degraded* bonds, not just down ones. The check you write is that alert.

### Steps
```bash
# On a VM with two NICs (or two veth pairs to a peer bridge):
ip link add bond0 type bond mode 802.3ad miimon 100 xmit_hash_policy layer3+4
ip link set eth1 master bond0 ; ip link set eth2 master bond0 ; ip link set bond0 up
cat /proc/net/bonding/bond0          # confirm both members "up", LACP negotiated
ip link set eth1 down                 # simulate failure
cat /proc/net/bonding/bond0          # eth1 down, traffic continues on eth2 (degraded)
ip link set eth1 up                   # restore
```
1. Build `bond0` (LACP or active-backup if no LACP peer); capture status.
2. Down a member, confirm traffic continues (ping a peer throughout) — that's failover.
3. Write `infra/configs/bonding-lab.md`: the build, `/proc/net/bonding` output (healthy +
   degraded), the hash-policy note, and a member-status check snippet.

### Lens D — see LACPDUs
`tcpdump -e -ni eth1 'ether proto 0x8809'` (slow protocols) captures LACPDUs negotiating the bond.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** bond build + member-status/degraded checker.
2. **Config/doc:** `infra/configs/bonding-lab.md` (build + healthy/degraded status).
3. **Drill:** member-failure failover demonstrated (ping continuity).
4. **NAVI ticket:** `NAVI-11` (Change: "build LACP bond" + Incident for the failover test).
5. **Incident report:** *(optional)* — a "bond degraded" mini runbook.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Configured LACP link aggregation (Linux bonding) for bandwidth + redundancy
  and validated transparent member-failover; added a degraded-bond monitoring check."
- **Interview talking point:** explain LACP, why STP doesn't block the bundle, and why one flow
  doesn't get N× bandwidth (per-flow hashing).
- **Serves:** Linux Net Admin / Jr Network Engineer (Stages 3–4); CCNA capstone (34).

---

## §11 — RHCSA Crossover Notes

Solid RHCSA overlap: **network bonding/teaming** via `nmcli` (`con add type bond`,
`bond-slave`/`team`) is an RHEL high-availability networking skill. Reading `/proc/net/bonding`
and configuring `miimon`/mode are directly applicable to RHEL server NIC redundancy.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/). (Infrastructure resilience — short note.)

**🔴 Attacker:** a misconfigured static channel (no LACP validation) can be abused to insert a
rogue link or cause a loop/DoS; physically, cutting a non-redundant uplink is a simple
availability attack — link aggregation is itself a *mitigation* against that.

**🔵 Defender:** prefer **LACP** (negotiated, validates the peer) over static "on"; monitor for
unexpected member changes; combine with **BPDU Guard** (Lesson 10) so a bundle misconfig can't
create a loop. Aggregation is primarily an **availability** control (defends against single-link
DoS/failure). Verify failover behavior in a lab before relying on it.

---

## Quiz (Interview-Style, Graded)

**Q1.** What two benefits does link aggregation provide, and how does it avoid being blocked by STP?
> **Your answer:**

**Q2.** LACP vs PAgP vs static "on" — what's the difference and which is preferred, and why?
> **Your answer:**

**Q3.** A user copies one large file across a 4-link bundle and is disappointed it's not 4× faster.
Explain why.
> **Your answer:**

**Q4.** **Scenario:** A new port-channel between two switches keeps flapping. What's the most
common cause and how do you check it?
> **Your answer:**

**Q5.** Why is a "degraded" bond (one of two members down) worth alerting on even though service
is still up?
> **Your answer:**

**Q6.** What does the load-balancing hash policy control, and why does flow order stay intact?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 12.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `link aggregation lacp 802.3ad`
- `etherchannel explained`
- `lacp vs pagp vs static`
- `port channel load balancing hash`

**Tools**
- `linux bonding mode 802.3ad`
- `/proc/net/bonding status`
- `show etherchannel summary cisco`

**Going further (future lessons)**
- `nic teaming high availability` (L31) · `mlag vpc multichassis` · `xmit_hash_policy layer3+4`

**Red / Blue (Lens E):**
- 🔴 `static etherchannel misconfig loop`, `single link dos`
- 🔵 `lacp negotiation security`, `monitor port channel member`, `bpdu guard with port-channel`

---

## Lesson Status
- [ ] §8 lab completed (bond built + failover tested)
- [ ] §4 drill done (member failure)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 12 — DHCP**.

---

*Lesson 11 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: IEEE 802.3ad,
Linux bonding docs (kernel.org), CompTIA Network+ N10-009, Cisco EtherChannel references.*
