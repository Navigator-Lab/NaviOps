# Lesson 12 — Pure Practical: DHCP

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** run `dnsmasq` on `clab-r1`/a host to serve DHCP to `net_a`; clients on netshoot.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: stand up a DHCP scope and lease an address (fluency)

**Scenario.** `NOC-121`. Serve dynamic addresses to `net_a` and watch a client complete DORA
(Discover/Offer/Request/Ack).

**Objective.** A working scope; a client gets a lease; you can see the DORA exchange.

**Given / constraints.** `dnsmasq --dhcp-range=...`. Capture DORA with `tcpdump`.

**Hints.**
1. Server: `dnsmasq -d --interface=eth0 --dhcp-range=10.10.1.100,10.10.1.150,12h`.
2. Client: `dhclient -v eth0` (or netshoot's `udhcpc`). Watch the lease.
3. Capture: `tcpdump -ni eth0 port 67 or port 68`.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'timeout 8 dhclient -v eth0 2>&1 | grep -qiE "bound|DHCPACK"' && echo "LEASE OBTAINED ✅"
```

**Pitfalls.**
- Scope overlapping static IPs → conflicts.
- Wrong interface/subnet on the server.
- Firewall blocking UDP 67/68.

🎯 **Stretch.** Name each DORA packet in your capture and its purpose.

---

## Task 2 — Ticket-driven: "clients aren't getting IPs" (diagnose → fix)

**Scenario.** `NOC-122` (P2). *"New devices on the segment get no address (169.254.x.x APIPA)."* DHCP
is failing. Find why.

**Objective.** Restore leasing, identifying scope exhaustion, wrong interface, blocked ports, or a
missing relay — diagnose first.

**Given / constraints.** Recreate a fault (server on wrong iface / exhausted range / blocked 67-68).
Fix the specific cause.

**Hints.**
1. Client stuck at `169.254.x.x` = no DHCP reply. Capture 67/68 — is the Discover even seen by the server?
2. Server logs (`dnsmasq -d`) — offers being made? Range exhausted?
3. Different subnet than the server? You'd need a DHCP relay (helper address).

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'timeout 8 dhclient -v eth0 2>&1 | grep -qiE "bound|DHCPACK"' && echo "LEASING OK ✅"
docker exec clab-h1 ip -br addr | grep -vq '169.254' && echo "NOT APIPA ✅"
```

**Pitfalls.**
- Server not listening on the client's segment (needs relay across subnets).
- UDP 67/68 blocked by a firewall.
- Range exhausted (all leases taken) — expand or shorten lease time.

🎯 **Stretch.** Add a static reservation (MAC→IP) and prove that host always gets the same address.

---

## Task 3 — On-call: rogue DHCP server handing out bad config (synthesis)

**Scenario.** `NOC-123` (P1, time-boxed). Users get wrong gateway/DNS intermittently — a rogue DHCP
server is racing the legit one. Detect it, contain, and document.

**Objective.** Identify the rogue server (its IP/MAC), determine which clients it poisoned, recommend
containment (DHCP snooping), and write a note.

**Given / constraints.** Simulate a second `dnsmasq` with a bad gateway. Detect via the offer source.

**Hints.**
1. `nmap --script broadcast-dhcp-discover` or capture DHCPOFFER — how many distinct servers reply?
2. The offer's server-id / source MAC identifies the rogue.
3. Containment = DHCP snooping (trust only the real server's port).

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'timeout 6 tcpdump -ni eth0 -c5 port 67 2>/dev/null' | grep -qi 'boot' && echo "OFFERS CAPTURED ✅"
test -f docs/learning/reports/NOC-123-rogue-dhcp.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-123-rogue-dhcp.md`: rogue IP/MAC · affected clients · impact · containment (snooping).

**Pitfalls.**
- Assuming one DHCP server (there may be two racing).
- Trusting the client's config without tracing which server issued it.
- No DHCP snooping → the rogue keeps winning some races.

🎯 **Stretch.** Explain how DHCP snooping + dynamic ARP inspection harden the segment.

---

## Done?
- [ ] All ✅ Verify pass · [ ] traced the offer source · [ ] rogue-DHCP note written.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
