# Lesson 06 — Pure Practical: IPv6

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `docker exec -it clab-h1 bash` (netshoot). **Rules:** type it, diagnose before
> you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: link-local, NDP & compression (fluency)

**Scenario.** `NOC-061`. Every IPv6 interface has a link-local address and uses NDP (not ARP). See both.

**Objective.** Identify the host's `fe80::/10` link-local, ping a neighbor over IPv6, and observe NDP.

**Given / constraints.** Use `ip -6`, `ping6`/`ping -6`, and the zone index (`%eth0`).

**Hints.**
1. `ip -6 addr` — the `fe80::…` link-local. `ip -6 neigh` — the NDP cache (ARP's IPv6 replacement).
2. Ping a link-local: `ping -6 fe80::…%eth0` (zone index required).
3. Capture NDP: `tcpdump -ni eth0 icmp6`.

✅ **Verify.**
```bash
docker exec clab-h1 ip -6 addr | grep -qi 'fe80::' && echo "LINK-LOCAL PRESENT ✅"
docker exec clab-h1 ip -6 neigh 2>/dev/null | grep -q . && echo "NDP CACHE ✅"
```

**Pitfalls.**
- Forgetting the `%eth0` zone index on link-local pings.
- Expecting ARP — IPv6 uses NDP (ICMPv6).
- Mis-compressing `::` (only one `::` allowed per address).

🎯 **Stretch.** Expand and re-compress a full IPv6 address by hand; verify with `ipcalc`/`sipcalc`.

---

## Task 2 — Ticket-driven: "IPv6 host unreachable but IPv4 works" (diagnose → fix)

**Scenario.** `NOC-062` (P2). *"Service is dual-stack; IPv4 works, IPv6 fails."* Localize the IPv6-only
fault.

**Objective.** Restore IPv6 reachability, identifying whether it's addressing, NDP, route, or RA.

**Given / constraints.** Recreate: disable IPv6 on an iface / remove the IPv6 route. Fix that.

**Hints.**
1. `sysctl net.ipv6.conf.eth0.disable_ipv6` (0 = enabled). `ip -6 route` present?
2. NDP resolving? `ip -6 neigh`. Router advertisements? `rdisc6`/capture `icmp6`.
3. Fix the specific missing piece; re-test `ping -6`.

✅ **Verify.**
```bash
docker exec clab-h1 ping -6 -c2 <peer-v6>%eth0 >/dev/null && echo "IPv6 REACHABLE ✅"
```

**Pitfalls.**
- IPv6 disabled at the sysctl level while you debug routes.
- Assuming IPv4 config implies IPv6 config (separate stacks).
- Missing the RA/prefix source for global addresses.

🎯 **Stretch.** Compare SLAAC vs DHCPv6 address assignment and when each is used.

---

## Task 3 — On-call: dual-stack service audit (synthesis)

**Scenario.** `NOC-063` (time-boxed). Confirm a service is correctly reachable over *both* stacks and
document any gap (a common real-world blind spot where IPv6 is silently broken).

**Objective.** Verify v4 and v6 reachability to a service, flag mismatches, and write a note.

**Given / constraints.** Test each stack explicitly. Don't assume parity.

**Hints.**
1. `curl -4` vs `curl -6` (or `nc -4/-6`) to the same service.
2. DNS: does the name have both A and AAAA? `dig A`, `dig AAAA`.
3. Note where one stack works and the other doesn't.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'dig +short AAAA localhost; dig +short A localhost' 2>/dev/null; echo "checked both"
test -f docs/learning/reports/NOC-063-dualstack.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-063-dualstack.md`: v4 result · v6 result · DNS A/AAAA · gaps · fix.

**Pitfalls.**
- Testing only v4 and declaring "it works" while v6 is broken.
- Missing AAAA records (v6 clients fail).
- Firewall rules applied to v4 but not v6 (or vice-versa).

🎯 **Stretch.** Check the firewall covers both stacks (ip6tables/nftables inet table).

---

## Done?
- [ ] All ✅ Verify pass · [ ] tested both stacks explicitly · [ ] dual-stack report written.
- [ ] **Guardrails:** lab ranges only. → [README Reflection](./README.md).
