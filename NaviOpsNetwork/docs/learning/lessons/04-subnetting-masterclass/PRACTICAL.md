# Lesson 04 — Pure Practical: Subnetting Masterclass

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** the real lab subnets — net_a `10.10.1.0/24`, net_b `10.10.2.0/24`, core
> `10.0.0.0/24`. **Rules:** show your math, verify with `ipcalc`, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: fully describe the lab subnets (fluency)

**Scenario.** `NOC-041`. Document network address, broadcast, usable range, and host count for each of
the three lab subnets — the bread-and-butter of network design.

**Objective.** A correct table for `/24` (and prove it against the live hosts' IPs).

**Given / constraints.** Do the math by hand first, then confirm with `ipcalc`.

**Hints.**
1. `/24` → 256 total, `.0` net, `.255` bcast, `.1–.254` usable (254 hosts).
2. `ipcalc 10.10.1.0/24` to check.
3. Confirm h1 (.10) and r1 (.1) fall in the usable range.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'command -v ipcalc && ipcalc 10.10.1.0/24 | grep -i broadcast' 2>/dev/null || echo "compute by hand: bcast=10.10.1.255"
docker exec clab-h1 ip -br addr | grep -q 10.10.1.10 && echo "HOST IN RANGE ✅"
```

**Pitfalls.**
- Off-by-one on usable hosts (256 total − network − broadcast = 254).
- Mixing up network vs broadcast address.
- Forgetting the gateway consumes a usable address.

🎯 **Stretch.** Re-slice `10.10.1.0/24` into four `/26`s; give each block's range.

---

## Task 2 — Ticket-driven: "new host can't communicate — wrong mask?" (diagnose → fix)

**Scenario.** `NOC-042` (P2). *"A host was added but can only reach some peers."* Classic subnet-mask
mismatch. Find and fix it.

**Objective.** Identify the misconfigured mask/subnet and correct it so the host reaches its whole
segment.

**Given / constraints.** Recreate: set h1's prefix wrong (e.g. `/25` or a wrong network). Fix to match
the segment.

**Hints.**
1. `ip -br addr` — is the prefix correct (`/24`)? Does the host's address match the segment's network?
2. A wrong mask makes some peers "off-subnet" → routed to the gateway (may fail).
3. `ip addr flush` + re-add with the right prefix (or fix the config).

✅ **Verify.**
```bash
docker exec clab-h1 ip -br addr | grep -q '10.10.1.10/24' && echo "MASK CORRECT ✅"
docker exec clab-h1 ping -c2 10.10.1.1 >/dev/null && echo "SEGMENT REACHABLE ✅"
```

**Pitfalls.**
- A `/25` where `/24` is needed splits the segment silently.
- Right IP, wrong mask → "can reach some, not others".
- Fixing the IP but leaving the mask wrong.

🎯 **Stretch.** Explain exactly which peers become unreachable under the wrong mask, and why.

---

## Task 3 — On-call: design an addressing plan under constraints (synthesis)

**Scenario.** `NOC-043` (time-boxed). A new site needs subnets for 3 teams of different sizes plus
point-to-point links, from a single `/24`. Design a VLSM plan without overlaps and document it.

**Objective.** A conflict-free VLSM plan: right-sized subnets, no overlap, room to grow — written up.

**Given / constraints.** One `/24` to carve. Use VLSM (largest blocks first). No overlapping ranges.

**Hints.**
1. Size each subnet to the next power of two ≥ hosts+2; allocate largest first.
2. `/30` for point-to-point links (2 usable). Track each block's net/bcast/range.
3. Verify no overlaps.

✅ **Verify.**
```bash
test -f docs/learning/reports/NOC-043-vlsm-plan.md && echo "PLAN WRITTEN ✅"
# self-check: no two subnets share addresses (review your table)
```

**Deliverable.** `docs/learning/reports/NOC-043-vlsm-plan.md`: per-subnet net/mask/range/bcast · rationale · growth headroom.

**Pitfalls.**
- Allocating small blocks first → fragmentation/overlap.
- Forgetting network+broadcast overhead per subnet.
- No growth headroom → redesign in six months.

🎯 **Stretch.** Summarize the plan into the fewest aggregate routes (supernetting).

---

## Done?
- [ ] All ✅ Verify pass · [ ] math shown + tool-checked · [ ] VLSM plan has no overlaps.
- [ ] **Guardrails:** RFC-1918 only. → [README Reflection](./README.md).
