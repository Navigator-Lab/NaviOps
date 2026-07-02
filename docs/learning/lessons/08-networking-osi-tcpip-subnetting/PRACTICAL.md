# Lesson 08 — Pure Practical: Networking (OSI, TCP/IP, Subnetting)

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** `naviops-web` (.10) & `naviops-db` (.11) on `172.28.0.0/24`. **Rules:** type it, diagnose
> before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: map the lab network layer by layer (fluency)

**Scenario.** `NAVI-081`. New to the environment, you must document the lab's addressing: each node's
IP/mask/CIDR, the gateway, and prove L3 + L4 reachability between them.

**Objective.** Produce the subnet math (network, broadcast, host range for `172.28.0.0/24`) and
confirm `naviops-web` ↔ `naviops-db` connectivity at L3 (ping) and L4 (a port).

**Given / constraints.** Read-only; don't change IPs. Show your subnet calculation.

**Hints.**
1. `ip -br addr`, `ip route` — read the interface, mask, default gateway.
2. Subnet: `/24` → 256 addresses, `.0` network, `.255` broadcast, `.1–.254` hosts. Verify with `ipcalc` if present.
3. L3: `ping -c2 172.28.0.11`. L4: `nc -vz 172.28.0.11 <port>` (or `ss -tlnp` on the target).

✅ **Verify.**
```bash
ping -c2 172.28.0.11 >/dev/null && echo "L3 REACHABLE ✅"
nc -vz 172.28.0.11 22 2>&1 | grep -qi succeeded && echo "L4 OPEN ✅"
```

**Pitfalls.**
- Confusing network/broadcast with usable hosts.
- Assuming ping failure = "down" (ICMP may be filtered; test the actual port at L4).
- Reading the wrong interface (loopback vs the lab NIC).

🎯 **Stretch.** Recompute host counts for `/25`, `/26`, `/30`; explain when you'd use a `/30` (point-to-point link).

---

## Task 2 — Ticket-driven: "app can't reach the DB" (diagnose → fix, layer by layer)

**Scenario.** `NAVI-082` (P2). *"The web node can't connect to the database. It was working
yesterday."* Symptom only — you must isolate which layer is broken.

**Objective.** Walk the OSI stack bottom-up, find the exact failing layer, and restore connectivity —
**diagnosing before changing anything.**

**Given / constraints.** Recreate a fault at one layer (e.g. wrong route, DB not listening, or a
firewall drop). Fix that layer, not a random guess.

**Hints.**
1. L3: `ping` the DB IP. L3/route: `ip route get 172.28.0.11`.
2. L4: `nc -vz` the DB port; on the DB, `ss -tlnp` — is it listening on the right interface (not just `127.0.0.1`)?
3. Firewall: `nft list ruleset` / `iptables -L -n`. Isolate: does the failure move as you fix each layer?

✅ **Verify.**
```bash
nc -vz 172.28.0.11 <dbport> 2>&1 | grep -qi succeeded && echo "CONNECTED ✅"
# and on the DB node:
ss -tlnp | grep -q '0.0.0.0:<dbport>\|172.28.0.11:<dbport>' && echo "LISTENING ON RIGHT IFACE ✅"
```

**Pitfalls.**
- Blaming the network when the service listens only on `127.0.0.1` (L7 config, not L3).
- `telnet`/`nc` to test but ignoring that the *server* firewall dropped the SYN.
- Changing IPs randomly instead of isolating the layer.

🎯 **Stretch.** Capture the failing handshake with `tcpdump -ni any port <dbport>` and read whether you see SYN/SYN-ACK/RST — the packet-level truth.

---

## Task 3 — On-call: intermittent packet loss / latency spike (synthesis)

**Scenario.** `NAVI-083` (P1, time-boxed). Users report the app is "sometimes slow". You suspect
intermittent loss or latency between nodes. Quantify it, localize it, document it.

**Objective.** Measure loss/latency, determine whether it's L3 (network) or L7 (app), and write an
incident note with the evidence.

**Given / constraints.** Simulate with `tc qdisc add dev <if> root netem delay 100ms loss 10%` (root)
if available; otherwise reason from `ping`/`mtr` output. Remove any `tc` rule you add.

**Hints.**
1. Sustained `ping -c50` → look at loss % and rtt min/avg/max/mdev.
2. `mtr 172.28.0.11` (or `traceroute`) to see *where* loss appears along the path.
3. Rule out the app: does a raw `nc`/`ping` show loss too? If yes → network, not app.

✅ **Verify.**
```bash
ping -c20 172.28.0.11 | tail -2      # loss% and rtt recorded in your note
# cleanup any injected impairment:
tc qdisc del dev <if> root 2>/dev/null; echo "IMPAIRMENT CLEARED"
test -f docs/learning/reports/NAVI-083-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-083-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- One `ping` proves nothing — intermittent issues need sustained sampling.
- Forgetting to remove an injected `tc` rule → you become the outage.
- Blaming the network for app-side GC/lock latency — correlate both.

🎯 **Stretch.** Script a `scripts/net_diag.sh` that pings a target N times and exits non-zero if loss > threshold or avg rtt > budget.

---

## Done?
- [ ] All ✅ Verify pass · [ ] isolated the layer before fixing · [ ] postmortem written.
- [ ] Any injected impairment removed. **Redaction:** lab IPs only. → [README Step 7](./README.md).
