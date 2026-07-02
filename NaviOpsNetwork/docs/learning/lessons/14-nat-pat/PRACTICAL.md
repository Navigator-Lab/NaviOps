# Lesson 14 — Pure Practical: NAT & PAT

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `clab-r1` as the NAT gateway (`nftables`/`iptables` + `ip_forward`); hosts behind
> it. **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: source NAT (masquerade) for a private host (fluency)

**Scenario.** `NOC-141`. A private host must reach an "external" network via the router's address —
classic outbound NAT.

**Objective.** Masquerade `net_a` traffic out the router's core interface; a host's outbound source IP
becomes the router's.

**Given / constraints.** `ip_forward=1`; a POSTROUTING masquerade rule.

**Hints.**
1. On r1: `sysctl net.ipv4.ip_forward=1`; `iptables -t nat -A POSTROUTING -s 10.10.1.0/24 -o eth1 -j MASQUERADE`.
2. From the host, reach something across core; observe the translated source.
3. `iptables -t nat -L -v` / `conntrack -L` shows translations.

✅ **Verify.**
```bash
docker exec clab-r1 sh -c 'iptables -t nat -S 2>/dev/null | grep -qi masquerade || nft list ruleset | grep -qi masquerade' && echo "SNAT CONFIGURED ✅"
```

**Pitfalls.**
- Forwarding disabled → nothing routes to NAT.
- NAT rule on the wrong chain/interface.
- Confusing SNAT (outbound) with DNAT (inbound port-forward).

🎯 **Stretch.** Explain PAT: how many inside hosts share one outside IP via port translation.

---

## Task 2 — Ticket-driven: "port-forward to internal service not working" (diagnose → fix)

**Scenario.** `NOC-142` (P2). *"External requests to the public IP:port don't reach the internal
server."* A DNAT problem. Find it.

**Objective.** Get inbound traffic DNAT'd to the internal host, identifying a missing rule, forwarding,
or a return-path issue.

**Given / constraints.** Recreate a broken/absent DNAT. Fix so the mapping works both directions.

**Hints.**
1. `iptables -t nat -A PREROUTING -p tcp --dport <ext> -j DNAT --to <int-ip>:<int-port>`.
2. Forwarding + a FORWARD allow for the new flow. Return path: internal host's default via the NAT router.
3. `conntrack -L` to see the translated flow.

✅ **Verify.**
```bash
docker exec clab-h2 nc -vz <router-ip> <ext-port> 2>&1 | grep -qi succeeded && echo "DNAT WORKS ✅"
```

**Pitfalls.**
- DNAT set but FORWARD drops the flow.
- Internal host's return traffic bypassing the NAT router (asymmetric routing → resets).
- Wrong external interface/port.

🎯 **Stretch.** Add hairpin NAT so internal clients can reach the service via the public IP too.

---

## Task 3 — On-call: NAT table exhaustion / broken connectivity at scale (synthesis)

**Scenario.** `NOC-143` (time-boxed). Under load, new connections fail — conntrack/PAT port exhaustion.
Detect it, relieve it, and document.

**Objective.** Confirm conntrack exhaustion, relieve it (tune limits / drop stale), and write a note.

**Given / constraints.** Inspect `conntrack` counts vs max. Don't flush blindly in a way that kills
active sessions.

**Hints.**
1. `conntrack -C` (current) vs `sysctl net.netfilter.nf_conntrack_max`.
2. Near the limit → new flows dropped. Raise max / shorten timeouts / add IPs.
3. Note the exhaustion evidence.

✅ **Verify.**
```bash
docker exec clab-r1 sh -c 'conntrack -C 2>/dev/null; sysctl net.netfilter.nf_conntrack_max 2>/dev/null' ; echo "compared count vs max"
test -f docs/learning/reports/NOC-143-nat-exhaustion.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-143-nat-exhaustion.md`: symptom · conntrack count/max · fix · prevention.

**Pitfalls.**
- Blaming the app when the NAT table is full.
- Flushing conntrack and killing live sessions.
- No headroom monitoring on conntrack.

🎯 **Stretch.** Add an alert on conntrack utilization %.

---

## Done?
- [ ] All ✅ Verify pass · [ ] SNAT vs DNAT understood · [ ] exhaustion note written.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
