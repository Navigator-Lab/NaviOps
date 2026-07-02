# Lesson 24 — Pure Practical: SNMP

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** run `snmpd` on a lab host and query it with `snmp` tools from netshoot.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: poll a device with snmpwalk (fluency)

**Scenario.** `NOC-241`. Query a device's OIDs (system info, interfaces) — how monitoring tools read
device state.

**Objective.** Successfully `snmpwalk` system + interface MIBs from an agent.

**Given / constraints.** SNMPv2c community for the lab (v3 in the stretch). Read-only.

**Hints.**
1. Agent: `snmpd` with a read community. Poller: `snmpwalk -v2c -c <comm> <host> system`.
2. Interfaces: `snmpwalk ... IF-MIB::ifDescr` / `ifOperStatus`.
3. `snmpget` for a single OID.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'snmpget -v2c -c public localhost sysDescr.0 2>/dev/null || echo "point at your snmpd host"' | grep -qi 'STRING\|Linux' && echo "SNMP POLL ✅"
```

**Pitfalls.**
- Wrong community string → timeout (looks like "down").
- v2c community sent in cleartext — lab only; use v3 in production.
- OID vs MIB name confusion.

🎯 **Stretch.** Switch to SNMPv3 (auth+priv) and compare security.

---

## Task 2 — Ticket-driven: "monitoring can't poll a device" (diagnose → fix)

**Scenario.** `NOC-242` (P2). *"A device dropped off the NMS."* SNMP polling fails. Find why.

**Objective.** Restore polling, identifying wrong community/version, blocked 161, or agent down —
diagnose first.

**Given / constraints.** Recreate: wrong community / blocked UDP-161 / stopped snmpd. Fix the cause.

**Hints.**
1. `snmpget` with `-v2c -c` — timeout (unreachable/blocked/agent down) vs auth error (wrong community).
2. UDP 161 reachable? `nc -vzu <host> 161`. Agent running?
3. Fix and re-poll.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'snmpget -v2c -c public <host> sysUpTime.0 2>/dev/null' | grep -qi timeticks && echo "POLLING OK ✅"
```

**Pitfalls.**
- Wrong community read as "device down".
- UDP 161 blocked by firewall.
- v2c vs v3 mismatch.

🎯 **Stretch.** Configure an SNMP trap and receive it (`snmptrapd`) — push vs poll.

---

## Task 3 — On-call: interface flapping detected via SNMP (synthesis)

**Scenario.** `NOC-243` (time-boxed). An interface is flapping; use SNMP counters to confirm, quantify
error rates, and document.

**Objective.** Poll `ifOperStatus`/error counters over time, confirm the flap + errors, write a note.

**Given / constraints.** Repeated polls; compute deltas. Evidence-based.

**Hints.**
1. Poll `ifOperStatus` repeatedly — up/down transitions = flap.
2. `ifInErrors`/`ifOutErrors` deltas over the interval.
3. Note the interface, rate, likely cause.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'for i in 1 2 3; do snmpget -v2c -c public <host> IF-MIB::ifOperStatus.2 2>/dev/null; sleep 2; done'
test -f docs/learning/reports/NOC-243-if-flap.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-243-if-flap.md`: interface · flap evidence · error deltas · likely cause · fix.

**Pitfalls.**
- Single poll can't show a flap (need over-time).
- Reading raw counters instead of deltas.
- Ignoring error counters (the physical clue).

🎯 **Stretch.** Wire the counter into Prometheus (snmp_exporter) and alert on flaps.

---

## Done?
- [ ] All ✅ Verify pass · [ ] polled over time for the flap · [ ] flap note written.
- [ ] **Guardrails:** lab only; never commit real community strings. → [README Reflection](./README.md).
