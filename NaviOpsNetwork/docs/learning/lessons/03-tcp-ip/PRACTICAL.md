# Lesson 03 — Pure Practical: TCP/IP

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `docker exec -it clab-h1 bash` (netshoot); peer clab-h2 (10.10.2.10).
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: watch a TCP handshake and teardown (fluency)

**Scenario.** `NOC-031`. Prove you understand TCP by capturing the 3-way handshake and the 4-way close
of a real connection.

**Objective.** Capture SYN → SYN-ACK → ACK on connect and FIN/ACK on close.

**Given / constraints.** Start a listener on h2, connect from h1, capture on the wire.

**Hints.**
1. On h2: `nc -l -p 9000`. On h1: `tcpdump -ni eth0 port 9000 &` then `nc 10.10.2.10 9000`.
2. Watch flags `[S]`, `[S.]`, `[.]` (handshake) and `[F.]` (close).
3. Contrast with UDP (`nc -u`) — no handshake.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'tcpdump -ni eth0 -c3 tcp port 9000 & sleep 1; echo hi | nc -w1 10.10.2.10 9000; wait' 2>/dev/null | grep -qE '\[S' && echo "HANDSHAKE SEEN ✅"
```

**Pitfalls.**
- Confusing TCP (reliable, handshake) with UDP (fire-and-forget).
- Capturing without a port filter → noise.
- Forgetting the listener must be up first.

🎯 **Stretch.** Trigger a RST (connect to a closed port) and see the difference from a clean FIN.

---

## Task 2 — Ticket-driven: "connections hang / time out" (diagnose → fix)

**Scenario.** `NOC-032` (P2). *"App connections to h2 hang then time out."* Is it a dropped SYN
(routing/firewall) or a service not listening?

**Objective.** Distinguish "SYN unanswered" (network/filter) from "connection refused" (no listener)
and fix the real cause.

**Given / constraints.** Recreate: no listener (refused) vs a blackholed route (timeout). Fix the
matching cause.

**Hints.**
1. `nc -vz 10.10.2.10 <port>`: *refused* = host up, nothing listening; *timeout* = SYN lost (route/filter).
2. Confirm with `tcpdump`: SYN with no reply (lost) vs SYN→RST (refused).
3. Fix: start the service (refused) or fix the route/OSPF/filter (timeout).

✅ **Verify.**
```bash
docker exec clab-h1 nc -vz 10.10.2.10 <port> 2>&1 | grep -qi succeeded && echo "CONNECTS ✅"
```

**Pitfalls.**
- Treating "refused" and "timeout" the same — they point to opposite causes.
- Ignoring retransmit behavior (hangs = SYN retries).
- Blaming the app when L3/L4 is the issue.

🎯 **Stretch.** Read `ss -ti` connection state (SYN-SENT vs ESTABLISHED) during the failure.

---

## Task 3 — On-call: latency/loss is hurting a TCP app (synthesis)

**Scenario.** `NOC-033` (P1, time-boxed). Users report slow transfers. Quantify latency/loss/retrans
and determine whether it's the network or the endpoint; document.

**Objective.** Measure RTT + retransmissions, localize with `mtr`, and write an incident note.

**Given / constraints.** Optionally inject impairment (`tc netem` on an interface) — remove it after.
Evidence-based conclusion.

**Hints.**
1. `mtr -rw 10.10.2.10` (per-hop loss/latency). `ss -ti` for retransmits on a live socket.
2. Sustained sampling (not one ping). Where does loss appear — a hop or the endpoint?
3. Clean up any `tc` you added.

✅ **Verify.**
```bash
docker exec clab-h1 mtr -rwc10 10.10.2.10 | tail -3   # loss%/latency captured
test -f docs/learning/reports/NOC-033-latency.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-033-latency.md`: measured RTT/loss/retrans · where · fix.

**Pitfalls.**
- One ping ≠ evidence for an intermittent issue.
- Leaving an injected `tc` rule in place (you become the outage).
- Confusing app-side slowness with network loss.

🎯 **Stretch.** Explain how TCP's congestion control reacts to the loss you injected.

---

## Done?
- [ ] All ✅ Verify pass · [ ] refused-vs-timeout distinguished · [ ] latency report written · [ ] impairment removed.
- [ ] **Guardrails:** lab ranges only. → [README Reflection](./README.md).
