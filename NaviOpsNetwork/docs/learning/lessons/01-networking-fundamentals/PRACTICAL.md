# Lesson 01 — Pure Practical: Networking Fundamentals

> **Companion to [`README.md`](./README.md)** (the 12-section theory). This is pure practice: 3
> scenario tasks, guided → ticket-driven → on-call. Do them after the README.
>
> **Lab:** `./infra/bootstrap.sh up` (once: `pull`). **Hosts:** `docker exec -it clab-h1 bash`
> (10.10.1.10) / `clab-h2` (10.10.2.10) — netshoot images with the full net toolkit. **Routers:**
> `docker exec -it clab-r1 vtysh` / `clab-r2`. **Rules:** type it, diagnose before you fix, run the
> ✅ **Verify** after each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: fingerprint a host's network identity (fluency)

**Scenario.** `NOC-011`. You've just been handed a node. Document its interfaces, IP/mask, MAC,
gateway, and DNS — the first thing you do on any unfamiliar machine.

**Objective.** Produce the node's full L2/L3 identity from `clab-h1`.

**Given / constraints.** Read-only. Use `ip`, not the deprecated `ifconfig`.

**Hints.**
1. `ip -br addr` (IPs), `ip -br link` (MACs/state), `ip route` (gateway).
2. DNS resolver: `cat /etc/resolv.conf`.
3. Record it as a mini "as-built" note.

✅ **Verify.**
```bash
docker exec clab-h1 ip -br addr | grep -q 10.10.1.10 && echo "IP CONFIRMED ✅"
docker exec clab-h1 ip route | grep -q default && echo "GATEWAY FOUND ✅"
```

**Pitfalls.**
- Reading `ifconfig` (may be absent/incomplete) instead of `ip`.
- Confusing the MAC (L2) with the IP (L3).
- Missing that a host can have several interfaces/addresses.

🎯 **Stretch.** Do the same on `clab-h2` and note why its subnet differs.

---

## Task 2 — Ticket-driven: "this host has no network" (diagnose → fix)

**Scenario.** `NOC-012` (P2). *"clab-h1 can't reach anything."* Work the bottom of the stack up —
is it link, address, or route?

**Objective.** Restore reachability to the local gateway, identifying the failing layer first.

**Given / constraints.** Recreate a fault: `ip link set eth0 down`, or flush the address/route. Fix the
specific cause.

**Hints.**
1. Link up? `ip -br link` (state UP/DOWN). Address present? `ip addr`. Route present? `ip route`.
2. Bring back only what's missing (`ip link set eth0 up` / `ip addr add` / `ip route add`).
3. Test the local gateway first, then beyond.

✅ **Verify.**
```bash
docker exec clab-h1 ip -br link | grep -q 'UP' && echo "LINK UP ✅"
docker exec clab-h1 ping -c2 10.10.1.1 >/dev/null && echo "GATEWAY REACHABLE ✅"
```

**Pitfalls.**
- Guessing at L3 when the interface is administratively DOWN (L1/L2).
- Ping failing on ICMP filtering and assuming "no network".
- Fixing the address but forgetting the route.

🎯 **Stretch.** Capture the difference: `ping` a live vs a dead IP and read what each returns.

---

## Task 3 — On-call: map an unknown segment fast (synthesis)

**Scenario.** `NOC-013` (P1, time-boxed). New segment, no documentation. Discover what's alive, build a
quick host inventory, and write a short note — the classic "walk into a network blind" drill.

**Objective.** Enumerate live hosts on `10.10.1.0/24`, identify the router, and document the segment.

**Given / constraints.** Use the netshoot toolkit. Non-destructive scanning only.

**Hints.**
1. Sweep: `nmap -sn 10.10.1.0/24` (ping scan). Who's the gateway? `ip route`.
2. Confirm a couple with `ping`/`arp -n` (L2 presence).
3. Note IPs, MACs, and the gateway in an inventory.

✅ **Verify.**
```bash
docker exec clab-h1 nmap -sn 10.10.1.0/24 | grep -c 'Host is up'   # ≥ the known hosts
test -f docs/learning/reports/NOC-013-segment-map.md && echo "MAP WRITTEN ✅"
```

**Deliverable.** `docs/learning/reports/NOC-013-segment-map.md`: hosts · gateway · notable ports · gaps.

**Pitfalls.**
- Aggressive scans on a production segment (do sweeps, not full port storms, without authorization).
- Trusting one tool — corroborate with `arp`/`ping`.
- No written artifact → the next tech re-discovers it.

🎯 **Stretch.** Add a port sweep of the router (`nmap -Pn -p22,80,443`) and reason about exposure.

---

## Done?
- [ ] All ✅ Verify pass · [ ] worked bottom-up in Task 2 · [ ] segment map written.
- [ ] **Guardrails:** RFC-1918 lab ranges only; no real creds. → [README Reflection](./README.md).
