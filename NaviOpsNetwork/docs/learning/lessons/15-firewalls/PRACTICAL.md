# Lesson 15 — Pure Practical: Firewalls

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `nftables`/`iptables` on `clab-r1` or a netshoot host. **Rules:** type it, snapshot
> before you change, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a default-deny stateful firewall (fluency)

**Scenario.** `NOC-151`. Build a small stateful policy: default-deny inbound, allow established +
one service, allow all outbound.

**Objective.** A ruleset that blocks unsolicited inbound but permits an allowed service and return traffic.

**Given / constraints.** Stateful (`ct state established,related accept`). Keep your own access.

**Hints.**
1. `nft` base chain input drop; accept `ct state established,related`; accept the one service port.
2. Allow loopback; allow ICMP if you want ping.
3. Test allowed vs blocked from a peer.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'nft list ruleset 2>/dev/null | grep -qi "established"' && echo "STATEFUL ✅"
docker exec clab-h2 nc -vz clab-h1 <allowed-port> 2>&1 | grep -qi succeeded && echo "ALLOWED OK ✅"
```

**Pitfalls.**
- Stateless rules that forget return traffic → half-open failures.
- Locking yourself out (no allow for your session).
- Default accept "temporarily" and forgetting.

🎯 **Stretch.** Add rate-limiting on the service port (`limit rate`) to blunt floods.

---

## Task 2 — Ticket-driven: "a firewall change broke the app" (diagnose → fix)

**Scenario.** `NOC-152` (P2). *"After a rule push, the app port is unreachable."* Reconcile intended vs
actual rules and fix without opening everything.

**Objective.** Restore the required flow with a minimal rule, identifying the offending drop — diagnose
first.

**Given / constraints.** Recreate a rule that drops the app port / breaks state. Snapshot, fix
minimally.

**Hints.**
1. Snapshot: `nft list ruleset > /tmp/fw.before`. Find the drop: rule ordering matters (first match wins).
2. Test the specific flow (`nc -vz`); read counters (`nft ... -a`) to see which rule hits.
3. Insert the minimal allow in the right position.

✅ **Verify.**
```bash
docker exec clab-h2 nc -vz clab-h1 <app-port> 2>&1 | grep -qi succeeded && echo "APP REACHABLE ✅"
```

**Pitfalls.**
- Rule ordering: an early broad drop shadows a later allow.
- Opening `0.0.0.0/0` to "fix" it (over-exposure).
- No snapshot to roll back to.

🎯 **Stretch.** Diff `/tmp/fw.before` vs after and write the one-line change rationale.

---

## Task 3 — On-call: exposed service found in audit (synthesis)

**Scenario.** `NOC-153` (P1, time-boxed). An audit finds a sensitive port open to everything. Close the
exposure without cutting legitimate traffic, on a remote box, and document.

**Objective.** Scope the exposed rule to the needed source only, keep your access, verify closure, and
write a note.

**Given / constraints.** Remote host — use a rollback safety net (`sleep 300 && restore`) before
applying. Snapshot first.

**Hints.**
1. Find world-open rules (`0.0.0.0/0` on sensitive ports).
2. Schedule an auto-rollback, then replace the wide rule with a scoped one.
3. Confirm the port is refused from outside, allowed from the intended source; cancel rollback.

✅ **Verify.**
```bash
docker exec clab-h2 nc -vz clab-h1 <sensitive-port> 2>&1 | grep -qi refused && echo "EXPOSURE CLOSED ✅"
test -f docs/learning/reports/NOC-153-exposure.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-153-exposure.md`: exposed rule · scope applied · verify · prevention.

**Pitfalls.**
- Default-drop on a remote box with no allow for your session → lockout.
- Runtime change not persisted → reverts on reboot.
- Scoping to too-broad a CIDR.

🎯 **Stretch.** Persist the ruleset and add a periodic audit that flags any `0.0.0.0/0` on sensitive ports.

---

## Done?
- [ ] All ✅ Verify pass · [ ] snapshot + rollback before change · [ ] exposure note written.
- [ ] **Guardrails:** lab only; kept own access. → [README Reflection](./README.md).
