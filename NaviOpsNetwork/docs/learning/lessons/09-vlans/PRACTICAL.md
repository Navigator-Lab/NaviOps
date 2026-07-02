# Lesson 09 — Pure Practical: VLANs

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `docker exec -it clab-h1 bash` (netshoot supports 802.1Q via `ip link add … type vlan`).
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: create tagged VLAN sub-interfaces (fluency)

**Scenario.** `NOC-091`. Segment one physical link into two VLANs (e.g. 10 and 20) using 802.1Q tags.

**Objective.** Two VLAN sub-interfaces on `eth0` with addresses, up and visible.

**Given / constraints.** `ip link … type vlan id N`. Distinct subnets per VLAN.

**Hints.**
1. `ip link add link eth0 name eth0.10 type vlan id 10` (+ `.20`); `ip addr add`; `ip link set up`.
2. Each VLAN = its own broadcast domain/subnet.
3. `ip -d link show eth0.10` shows the 802.1Q detail.

✅ **Verify.**
```bash
docker exec clab-h1 ip -d link show eth0.10 2>/dev/null | grep -q 'vlan.*id 10' && echo "VLAN10 TAGGED ✅"
docker exec clab-h1 ip -br addr | grep -q 'eth0.10' && echo "ADDRESSED ✅"
```

**Pitfalls.**
- Same subnet on two VLANs → defeats the segmentation.
- Forgetting to bring the sub-interface up.
- Confusing access (untagged) vs trunk (tagged) ports.

🎯 **Stretch.** Explain the frame difference: untagged access frame vs 802.1Q-tagged trunk frame.

---

## Task 2 — Ticket-driven: "VLANs can't talk / wrong VLAN" (diagnose → fix)

**Scenario.** `NOC-092` (P2). *"Two devices that should be isolated can talk, or two that should talk
can't."* A VLAN misassignment. Find it.

**Objective.** Correct the VLAN membership so isolation/connectivity matches intent — diagnose first.

**Given / constraints.** Recreate: a sub-interface on the wrong VLAN id or subnet. Fix the tag/subnet.

**Hints.**
1. `ip -d link show` — which VLAN id is each interface actually on?
2. Intra-VLAN needs same VLAN+subnet; inter-VLAN needs a router (L3).
3. Fix the misassigned id/subnet.

✅ **Verify.**
```bash
docker exec clab-h1 ip -d link show eth0.20 2>/dev/null | grep -q 'id 20' && echo "VLAN20 CORRECT ✅"
```

**Pitfalls.**
- Expecting two VLANs to talk without an L3 gateway (they can't by design).
- Wrong VLAN id silently bridging the wrong hosts (a security issue).
- Fixing the IP but not the tag.

🎯 **Stretch.** Reason about VLAN hopping and why "native VLAN" hygiene matters.

---

## Task 3 — On-call: inter-VLAN routing broken (synthesis)

**Scenario.** `NOC-093` (time-boxed). After a change, VLAN 10 can't reach VLAN 20 through the
router-on-a-stick. Restore inter-VLAN routing and document.

**Objective.** Get inter-VLAN traffic flowing via the L3 gateway, verify, and write a note.

**Given / constraints.** Model the router with sub-interfaces + IP forwarding. Fix the specific gap
(missing sub-interface IP, forwarding off, or wrong gateway on hosts).

**Hints.**
1. Router needs an IP per VLAN sub-interface; `sysctl net.ipv4.ip_forward=1`.
2. Hosts point their default at their VLAN's gateway.
3. Trace: host → VLAN gateway → other VLAN.

✅ **Verify.**
```bash
docker exec clab-h1 sysctl net.ipv4.ip_forward 2>/dev/null | grep -q ' = 1' && echo "FORWARDING ON ✅"
test -f docs/learning/reports/NOC-093-intervlan.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-093-intervlan.md`: symptom · gateway config · fix · verify.

**Pitfalls.**
- IP forwarding disabled on the L3 device.
- Host default gateway pointing at the wrong VLAN interface.
- Missing sub-interface address for one VLAN.

🎯 **Stretch.** Compare router-on-a-stick vs an L3 switch SVI approach.

---

## Done?
- [ ] All ✅ Verify pass · [ ] membership verified before fixing · [ ] inter-VLAN note written.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
