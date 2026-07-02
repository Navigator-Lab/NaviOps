# Lesson 02 — Pure Practical: The OSI Model

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** `docker exec -it clab-h1 bash` (netshoot). **Peers:** clab-h2 (10.10.2.10), routers
> clab-r1/r2. **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: see each layer with a real tool (fluency)

**Scenario.** `NOC-021`. Make the 7 layers concrete by mapping one command/observation to each layer
you can reach from a host.

**Objective.** Produce evidence for L2 (MAC/ARP), L3 (IP/route), L4 (ports/sockets), L7 (a request).

**Given / constraints.** One tool per layer; note which layer each proves.

**Hints.**
1. L2: `ip neigh` / `arp -n`. L3: `ip route`, `ping`. L4: `ss -tuln`, `nc -vz`. L7: `curl`/`dig`.
2. Watch layers on the wire: `tcpdump -ni eth0` while you ping / curl.
3. Label each observation with its OSI layer.

✅ **Verify.**
```bash
docker exec clab-h1 ip neigh | grep -q . && echo "L2 SEEN ✅"
docker exec clab-h1 ss -tuln | grep -q . && echo "L4 SEEN ✅"
```

**Pitfalls.**
- Treating OSI as pure theory — every layer has a command.
- Confusing L2 (MAC/ARP, local) with L3 (IP, routable).
- Forgetting encapsulation order (data wrapped L7→L1).

🎯 **Stretch.** `tcpdump -e` to see Ethernet (L2) headers *and* IP (L3) in one capture.

---

## Task 2 — Ticket-driven: "connection fails" — name the layer (diagnose)

**Scenario.** `NOC-022` (P2). *"App on h1 can't talk to a service on h2."* Localize the failure to a
specific OSI layer before touching anything.

**Objective.** Identify the failing layer with evidence and fix it — bottom-up.

**Given / constraints.** Recreate a fault at one layer (link down = L1/2, no route = L3, service not
listening = L4/7). Fix that layer only.

**Hints.**
1. L2: `ip link`/`ip neigh`. L3: `ping`/`ip route get <ip>`. L4: `nc -vz h2 <port>`. L7: `curl`.
2. The lowest failing layer is the root; higher layers can't work until it's fixed.
3. State "failure is at L_ because _" before fixing.

✅ **Verify.**
```bash
docker exec clab-h1 ping -c2 10.10.2.10 >/dev/null && echo "L3 OK ✅"   # (needs OSPF up — see L07)
docker exec clab-h1 nc -vz 10.10.2.10 <port> 2>&1 | grep -qi succeeded && echo "L4 OK ✅"
```

**Pitfalls.**
- Debugging L7 (curl) when L3 (routing) is down.
- Assuming "ping works" means all layers work (it only proves L3).
- Skipping the layer-naming step and flailing.

🎯 **Stretch.** Build a one-line "layer ladder" checklist you run on every connectivity ticket.

---

## Task 3 — On-call: read a capture to pinpoint where it breaks (synthesis)

**Scenario.** `NOC-023` (P1, time-boxed). Intermittent failures. Capture traffic and use the packet to
prove which layer/handshake is failing (SYN with no SYN-ACK? ARP unanswered? RST?).

**Objective.** From a capture, identify the exact failure point and document it with the packet evidence.

**Given / constraints.** Use `tcpdump`/`tshark` on netshoot. Save a short analysis + the telltale packets.

**Hints.**
1. `tcpdump -ni eth0 host 10.10.2.10` while reproducing; look for SYN→SYN-ACK→ACK vs SYN→(nothing)/RST.
2. No ARP reply → L2. SYN no reply → L3/route or firewall. RST → service refusing (L4/7).
3. Map the observed pattern to the layer.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'tcpdump -ni eth0 -c5 icmp & sleep 1; ping -c3 10.10.1.1 >/dev/null; wait' | grep -q ICMP && echo "CAPTURE WORKS ✅"
test -f docs/learning/reports/NOC-023-capture-analysis.md && echo "ANALYSIS ✅"
```

**Deliverable.** `docs/learning/reports/NOC-023-capture-analysis.md`: symptom · capture snippet · failing layer · fix.

**Pitfalls.**
- Capturing on the wrong interface → empty pcap, wrong conclusion.
- Reading a RST as "network down" (it's the service actively refusing).
- No filter → drowning in packets.

🎯 **Stretch.** Compare a healthy vs failing handshake side by side in `tshark`.

---

## Done?
- [ ] All ✅ Verify pass · [ ] named the failing layer before fixing · [ ] capture analysis written.
- [ ] **Guardrails:** lab ranges only; no real `.pcap` committed. → [README Reflection](./README.md).
