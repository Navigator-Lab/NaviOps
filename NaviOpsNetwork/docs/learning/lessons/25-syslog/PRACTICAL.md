# Lesson 25 — Pure Practical: Syslog

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `rsyslog` on lab hosts; a host as the central collector. **Rules:** type it,
> diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: centralize logs to one collector (fluency)

**Scenario.** `NOC-251`. Ship logs from `clab-h1` to a central syslog server so events are in one place.

**Objective.** h1 forwards to a collector; a test message appears on the collector.

**Given / constraints.** rsyslog over UDP/TCP 514 on the lab net. Note facility/severity.

**Hints.**
1. Collector: enable the rsyslog input module (`imudp`/`imtcp`). Client: `*.* @@collector:514`.
2. `logger -p local0.info "NOC-251 test"` to generate.
3. Confirm it lands on the collector.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'logger -p local0.info "NOC-251 test"; echo sent'
echo "grep 'NOC-251 test' on the collector's /var/log → present ✅"
```

**Pitfalls.**
- UDP 514 blocked / wrong transport (`@` udp vs `@@` tcp).
- Facility/severity filters dropping the message.
- Clock skew scrambling event order.

🎯 **Stretch.** Switch to TCP + queueing so bursts aren't dropped.

---

## Task 2 — Ticket-driven: "logs stopped arriving from a device" (diagnose → fix)

**Scenario.** `NOC-252` (P2). *"A device's logs are missing from the central server."* Find the break in
the pipeline.

**Objective.** Restore log flow, identifying transport, filter, or disk-full issues — diagnose first.

**Given / constraints.** Recreate: blocked 514 / bad filter / collector disk full. Fix the cause.

**Hints.**
1. Send a test `logger` from the device; capture 514 on the collector (`tcpdump port 514`).
2. Arriving but not written? Filter/ruleset or disk full (`df -h`).
3. Fix and confirm end to end.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'logger "NOC-252 probe"; echo sent'
echo "collector shows NOC-252 probe → flow restored ✅"
```

**Pitfalls.**
- Assuming network when the collector's disk is full.
- Wrong transport/port.
- A ruleset dropping the facility.

🎯 **Stretch.** Add rate-limiting so one chatty device can't drown the collector.

---

## Task 3 — On-call: reconstruct an incident timeline from central logs (synthesis)

**Scenario.** `NOC-253` (P1, time-boxed). An incident spans several devices. Use the central logs to
build one timeline and find the first event.

**Objective.** A merged, time-ordered timeline across devices identifying the root event; written up.

**Given / constraints.** Normalize timestamps/timezones. Root = earliest causal event.

**Hints.**
1. Slice to the window; sort across sources by timestamp.
2. Watch for clock skew between devices.
3. Identify the first causal event vs downstream noise.

✅ **Verify.**
```bash
test -s /tmp/timeline.txt && head -3 /tmp/timeline.txt && echo "TIMELINE ✅"
test -f docs/learning/reports/NOC-253-timeline.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-253-timeline.md`: merged timeline · first event · root cause · fix.

**Pitfalls.**
- Timezone/skew making correlation wrong.
- Treating a downstream symptom log as the cause.
- No central logging → no timeline (the whole point).

🎯 **Stretch.** Pipe central logs into the SIEM/monitoring for automated correlation.

---

## Done?
- [ ] All ✅ Verify pass · [ ] pipeline verified end to end · [ ] timeline written.
- [ ] **Guardrails:** lab only; no real hostnames committed. → [README Reflection](./README.md).
