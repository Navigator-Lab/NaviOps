# Lesson 19 — Pure Practical: Wireshark / tshark

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `docker exec -it clab-h1 bash` (netshoot ships `tshark`); capture on the lab
> subnets. **Rules:** type it, analyze before you conclude, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: capture and dissect a conversation (fluency)

**Scenario.** `NOC-191`. Capture a TCP conversation and read the dissected layers (Eth/IP/TCP) with
`tshark`.

**Objective.** A capture you can filter by conversation, reading the protocol tree.

**Given / constraints.** `tshark` CLI. Use a capture + display filter.

**Hints.**
1. `tshark -i eth0 -f "tcp port 9000" -c 20` (capture filter) then analyze.
2. Display filters: `-Y "tcp.flags.syn==1"`, `-Y "http"`.
3. `-z conv,tcp` for a conversation summary.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'timeout 4 tshark -i eth0 -c3 -f "icmp" & sleep 1; ping -c3 10.10.1.1 >/dev/null; wait' 2>/dev/null | grep -qi icmp && echo "CAPTURE + DISSECT ✅"
```

**Pitfalls.**
- Confusing capture filters (BPF, pre-capture) with display filters (post-capture).
- Capturing everything → unreadable; filter early.
- Wrong interface.

🎯 **Stretch.** Follow a TCP stream (`-z follow,tcp,ascii,0`) and read the payload.

---

## Task 2 — Ticket-driven: "app is slow" — prove it in the packets (diagnose)

**Scenario.** `NOC-192` (P2). *"The app feels slow."* Use the capture to decide: network (retrans/RTT)
or application (server think-time)?

**Objective.** From the trace, attribute the slowness to network vs application with evidence.

**Given / constraints.** Analyze timing between packets. Base the verdict on the trace.

**Hints.**
1. Retransmissions / dup-acks → network loss. Large gap between request and response → server-side.
2. `tshark -Y "tcp.analysis.retransmission"` and `-Y "tcp.time_delta > 0.5"`.
3. State the verdict + the packet that proves it.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'timeout 4 tshark -i eth0 -Y "tcp.analysis.retransmission" -c5 2>/dev/null' ; echo "retrans check done"
```

**Pitfalls.**
- Blaming the network when the gap is server think-time.
- Ignoring retransmissions/dup-acks (the loss signature).
- No timing analysis (the whole point).

🎯 **Stretch.** Use `-z io,stat` to graph throughput over the capture.

---

## Task 3 — On-call: capture during an incident and hand off evidence (synthesis)

**Scenario.** `NOC-193` (P1, time-boxed). During an incident, capture the right traffic, extract the
telltale packets, and produce an evidence summary for the postmortem — without hoarding a huge pcap.

**Objective.** Targeted capture, key-packet extraction, and a written analysis (no raw pcap committed).

**Given / constraints.** Use capture filters to keep it small. Summarize; do **not** commit `.pcap`.

**Hints.**
1. Tight capture filter (host+port). Ring buffer if long (`-b`).
2. Extract the decisive packets (`-Y` + `-T fields`) into the note.
3. Redact/omit payloads; commit the analysis, not the capture.

✅ **Verify.**
```bash
test -f docs/learning/reports/NOC-193-capture-evidence.md && echo "EVIDENCE ✅"
ls docs/learning/reports/*.pcap 2>/dev/null && echo "PCAP COMMITTED ❌ (remove it)" || echo "NO PCAP COMMITTED ✅"
```

**Deliverable.** `docs/learning/reports/NOC-193-capture-evidence.md`: filter used · key packets · conclusion · fix.

**Pitfalls.**
- Capturing unfiltered → gigabytes, privacy exposure.
- Committing raw `.pcap` (guardrail violation).
- Evidence without a conclusion.

🎯 **Stretch.** Build a reusable capture-filter cheat sheet for common incident types.

---

## Done?
- [ ] All ✅ Verify pass · [ ] verdict backed by packets · [ ] evidence note written, no pcap committed.
- [ ] **Guardrails:** lab only; never commit `.pcap`. → [README Reflection](./README.md).
