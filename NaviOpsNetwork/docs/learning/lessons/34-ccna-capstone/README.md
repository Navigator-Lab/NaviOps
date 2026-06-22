# Lesson 34 — CCNA Capstone

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** design + build + verify a multi-VLAN routed/switched network with services — the
integration of Modules 1–3.
**Primary artifact:** the built topology + verification report (full plan:
[`capstones/34-ccna-capstone.md`](../../capstones/34-ccna-capstone.md)).

> **How to use this lesson:** this is a **project**, not a reading. The detailed phase plan lives in
> `docs/learning/capstones/34-ccna-capstone.md`; this lesson README frames it in the 12-section
> schema and is where you record completion. Prereqs: Lessons 01–16. Lab/RFC-1918 only.

---

## §1 — Concept (Scientific Theory)

The CCNA Capstone integrates the **foundations + routing/switching + core services** modules into
one designed, built, and verified network. It proves the synthesis a Junior Network Engineer is
hired for: take requirements → an addressing/VLAN/routing/security **design** → a **built**
topology with services → a **verified** result where every requirement is tested. It exercises CCNA
domains end-to-end: Network Fundamentals (subnetting/addressing, L02–06), Network Access (VLAN/
trunk/STP/EtherChannel, L08–11), IP Connectivity (static + default routing, inter-VLAN, L07/09), IP
Services (DHCP/DNS/NAT, L12–14), and Security Fundamentals (ACLs/isolation, L15).

The scenario (full spec in the capstone plan): a 3-department office — **Servers** (VLAN 10),
**Staff** (VLAN 20), **Guest** (VLAN 30, isolated), **Mgmt** (VLAN 99) — with inter-VLAN routing
for Servers↔Staff, Guest isolation, DHCP/DNS for all, a default route to the WAN, a loop-free STP
topology, and one redundant EtherChannel/bonded link.

---

## §2 — Linux Networking Commands (the verification toolkit)

You'll prove the build with the tools from every prior lesson:
```bash
bridge vlan show ; ip -d link show <vlan-if>      # VLAN membership (L09)
ip route ; ip route get <dest>                     # routing + inter-VLAN (L07)
ping / mtr / traceroute                            # reachability + path (L18)
dig +short <name> ; dhclient -v                    # DNS + DHCP lease (L12/13)
nft list ruleset                                    # Guest isolation + NAT (L14/15)
cat /proc/net/bonding/bond0 ; bridge -d link        # EtherChannel + STP (L10/11)
```
Cisco mapping: `show vlan brief`, `show ip route`, `show ip interface brief`, `show spanning-tree`,
`show etherchannel summary`, `show ip dhcp binding` — close any IOS-syntax gaps in Packet
Tracer/GNS3/CML (`alignment/CCNA-ALIGNMENT.md`).

---

## §3 — Real-World Use Cases
This *is* the real-world task a Junior Network Engineer does: design a small office/branch network
from requirements and stand it up. The deliverable (design doc + built topology + verification
report) is exactly what you'd produce on the job and show in an interview.

---

## §4 — Troubleshooting Section
Every requirement that *fails* its verification check becomes a troubleshooting exercise using the
relevant lesson's method: VLAN misconfig (L09 checklist), routing/inter-VLAN (L07 `ip route get`),
DHCP/DNS (L12/13), firewall/Guest-isolation (L15 counters + capture). Capture each fix.

---

## §5 — Common Mistakes
The integration mistakes: forgetting to allow a VLAN on a trunk (L09), missing return route (L07),
Guest not actually isolated (test it!), DHCP scope/relay wrong (L12), STP not loop-free, NAT/forward
without firewall allow (L14/15). The verification report exists to catch exactly these.

---

## §6 — NOC Perspective
A fully documented, verified network is what a NOC inherits — your **as-built** topology + IPAM
(L27) + verification report is the reference the NOC uses on every future ticket. Building it the
NOC-friendly way (documented, monitored, with a clear address/VLAN plan) is part of the capstone's
value.

---

## §7 — Incident-Response Perspective
After building, **break each subsystem on purpose** (a drill per module) and run the IR lifecycle
(L26) — detect → diagnose → fix → verify → document. This produces incident runbooks for the
portfolio and proves the network is operable, not just buildable.

---

## §8 — Practical Lab (the capstone itself)
Follow the 6 phases in [`capstones/34-ccna-capstone.md`](../../capstones/34-ccna-capstone.md):
**Design → L2 (VLAN/STP/EtherChannel) → L3 (inter-VLAN/routing) → Services (DHCP/DNS) → Security
(Guest isolation/NAT) → Verify + document.** Build it Linux-first (netns/bridges/VLANs) and map to
Cisco (Packet Tracer/GNS3) to close exam gaps.

**Lens C (automation):** script the topology build (reproducible) + a verification script that runs
every requirement check and reports pass/fail — the professional pattern (test your network like
code). **Lens D:** capture a tagged frame on the trunk, a DHCP DORA, and a DNS query to *see* the
services working.

---

## §9 — GitHub Artifact (evidence 5-tuple)
1. **Script:** the topology build + verification script.
2. **Config/topology:** `infra/topologies/ccna-capstone/` + `docs/diagrams/ccna-capstone-topology.md`.
3. **Drill:** a break-and-fix per module → incident runbooks.
4. **NAVI ticket:** `NAVI-34` (Change: "build + verify the multi-VLAN routed network").
5. **Incident report:** `docs/runbooks/ccna-capstone-verification.md` + per-drill runbooks.
Plus the milestone **`PORTFOLIO.md`** (resume bullets + interview talking points).

---

## §10 — Portfolio Artifact
- **Resume bullet:** "Designed, built, and verified a multi-VLAN routed/switched network (inter-VLAN
  routing, STP, EtherChannel, DHCP/DNS, NAT, Guest isolation) end-to-end, with a full requirements
  verification report — Linux-first and mapped to Cisco IOS."
- **Interview talking point:** walk the design + the verification — the single strongest Junior
  Network Engineer portfolio piece.
- **Serves:** Junior Network Engineer (Stage 4); the CCNA-readiness integration check.

---

## §11 — RHCSA Crossover Notes
The Linux-first build exercises `nmcli`/`ip`/bridges/VLANs/firewalld/`nft` — all RHCSA-adjacent
networking skills. The verification discipline applies to any infrastructure role.

---

## §12 — Security Notes (Lens E — Attacker & Defender)
The capstone's **Guest isolation** + **NAT/firewall** are the security control — verify (lab-only)
that Guest *cannot* reach internal VLANs (segmentation, L04/09/15 against lateral movement `T1021`)
while it *can* reach the WAN. Defender: default-deny between zones, prove isolation with an actual
(blocked) reachability test, and ensure the mgmt VLAN is locked down. This makes the capstone a
*secured* network, not just a working one.

---

## Quiz (Interview-Style — defend your design)
**Q1.** Walk an interviewer through your addressing/VLAN/routing plan and justify each subnet size.
> **Your answer:**

**Q2.** How did you verify Guest isolation, and why is "I configured it" not enough?
> **Your answer:**

**Q3.** How does inter-VLAN routing work in your build, and what would break it?
> **Your answer:**

**Q4.** **Scenario:** After the build, Staff can't get DHCP leases but Servers can. Where do you look?
> **Your answer:**

**Q5.** Which CCNA domains does your capstone exercise, and where are your remaining IOS-syntax gaps?
> **Your answer:**

*(Request the "Professional Answer" comparison under each — graded before Lesson 35.)*

---

## Reflection
*(After completion)* — What integrated well? · What was hardest? · What would you redesign?

---

## Search Keywords For Further Understanding
- `ccna lab multi vlan inter-vlan routing`
- `packet tracer gns3 ccna topology`
- `network design verification testing`
- `guest vlan isolation acl`
- 🔴 `lateral movement segmentation T1021` · 🔵 `default deny inter-vlan, prove isolation`

---

## Lesson Status
- [ ] All 6 capstone phases complete (per the plan)
- [ ] Verification report passes every requirement (with captured output)
- [ ] Evidence 5-tuple + `PORTFOLIO.md` committed (§9/§10)
- [ ] Quiz (design defense) answered + professional-answer comparisons
- [ ] Reflection written

When complete, run the Update Protocol, then move to **Lesson 35 — NOC Capstone**.

---

*Lesson 34 written by Navi · 2026-06-20 · full-depth. Detailed plan:
[`capstones/34-ccna-capstone.md`](../../capstones/34-ccna-capstone.md). Sources: CCNA 200-301
blueprint, `alignment/CCNA-ALIGNMENT.md`.*
