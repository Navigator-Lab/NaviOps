# Lesson 20 — Pure Practical: tcpdump

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `docker exec -it clab-h1 bash` (netshoot). **Rules:** type it, filter tightly,
> run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: BPF capture filters that matter (fluency)

**Scenario.** `NOC-201`. Learn the handful of `tcpdump` filters you'll actually use on-call.

**Objective.** Capture by host, port, protocol, and TCP flags — reading the output confidently.

**Given / constraints.** Use `-n` (no DNS), `-i`, and BPF expressions.

**Hints.**
1. `tcpdump -ni eth0 host 10.10.1.1`, `... port 22`, `... 'tcp[tcpflags] & tcp-syn != 0'`.
2. `-c N` to bound; `-e` for L2; `-A`/`-X` for payload.
3. Combine: `'host X and port Y'`.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'timeout 4 tcpdump -ni eth0 -c3 icmp & sleep 1; ping -c3 10.10.1.1 >/dev/null; wait' 2>/dev/null | grep -qi ICMP && echo "FILTER WORKS ✅"
```

**Pitfalls.**
- Forgetting `-n` → DNS lookups slow/pollute output.
- No filter → firehose.
- Wrong interface (`-D` lists them).

🎯 **Stretch.** Capture only SYNs to find who's initiating connections.

---

## Task 2 — Ticket-driven: "is traffic even arriving?" (diagnose → fix)

**Scenario.** `NOC-202` (P2). *"The server says it gets no requests; the client says it sends them."*
Settle it at the wire.

**Objective.** Determine whether packets reach the server NIC, and fix the side that's wrong.

**Given / constraints.** Capture on both ends. Base the fix on where packets stop.

**Hints.**
1. Capture on the *server* for the client's traffic — arriving at all? If yes, it's the app; if no, it's the path/firewall.
2. Capture on the client — are packets actually leaving?
3. Fix the side the packets reveal.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'timeout 4 tcpdump -ni eth0 -c3 "host 10.10.2.10" & sleep 1; ping -c3 10.10.2.10 >/dev/null 2>&1; wait' 2>/dev/null | grep -q IP && echo "TRAFFIC OBSERVED ✅"
```

**Pitfalls.**
- Arguing "client vs server" without capturing on both.
- Capturing on the wrong interface and concluding "no traffic".
- Ignoring that a firewall may drop after the NIC sees it.

🎯 **Stretch.** Use two simultaneous captures (client+server) to pinpoint the drop.

---

## Task 3 — On-call: save a rotating capture to catch a rare event (synthesis)

**Scenario.** `NOC-203` (time-boxed). A rare failure needs to be caught in the act without filling the
disk. Set up a bounded rolling capture, catch the event, extract evidence, document.

**Objective.** A ring-buffer capture that survives until the event, from which you extract the decisive
packets — no giant/committed pcap.

**Given / constraints.** `-C`/`-W`/`-G` ring buffer, tight filter. Commit analysis, not pcap.

**Hints.**
1. `tcpdump -ni eth0 -C 10 -W 5 -w /tmp/cap.pcap 'host X and port Y'` (5×10MB ring).
2. When it triggers, read with `-r` + a display filter.
3. Summarize into the note; delete/omit the pcap.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'timeout 3 tcpdump -ni eth0 -C 1 -W 2 -w /tmp/cap.pcap icmp & sleep 1; ping -c3 10.10.1.1 >/dev/null; wait; ls -la /tmp/cap.pcap*' 2>/dev/null | grep -q cap && echo "RING CAPTURE ✅"
test -f docs/learning/reports/NOC-203-rare-event.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-203-rare-event.md`: capture setup · event packets · root cause · fix.

**Pitfalls.**
- Unbounded `-w` → disk fills.
- No filter → ring rotates away the event you wanted.
- Committing the pcap (guardrail).

🎯 **Stretch.** Trigger capture stop on a condition (script watching for the symptom).

---

## Done?
- [ ] All ✅ Verify pass · [ ] captured both ends when needed · [ ] rare-event note written, no pcap committed.
- [ ] **Guardrails:** lab only; never commit `.pcap`. → [README Reflection](./README.md).
